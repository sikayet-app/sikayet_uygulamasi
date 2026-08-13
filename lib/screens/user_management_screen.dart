import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../data/models/user.dart';
import '../widgets/app_card.dart';
import '../core/report_ui_helpers.dart';
import '../core/app_colors.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    final canEditUsers = currentUser.permissions.contains('edit_users');
    final canManageAdmins = currentUser.permissions.contains('manage_admins');

    List<UserRole> allowedFilterRoles = canManageAdmins
        ? [UserRole.managing, UserRole.staff, UserRole.citizen]
        : [UserRole.staff, UserRole.citizen];

    final userAsync = ref.watch(filteredUserListProvider);

    return Scaffold(
      backgroundColor: isDarkMode
          ? colorScheme.surface
          : AppColors.surfaceWarmLight,
      appBar: AppBar(
        title: const Text('Kullanıcı Yönetimi'),
        centerTitle: true,
        elevation: 0,
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              );
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        backgroundColor: colorScheme.surface,
        child: SafeArea(
          child: UserFilterDrawerContent(allowedRoles: allowedFilterRoles),
        ),
      ),
      body: userAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_off_outlined,
                    size: 64,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  const Text('Liste boş'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                canManageAdmins ? managingListProvider : staffListProvider,
              );
              try {
                await ref.read(
                  (canManageAdmins ? managingListProvider : staffListProvider)
                      .future,
                );
              } catch (_) {}
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final isSelf = user.id == currentUser.id;
                final roleColor = getColorForRole(
                  user.role,
                  isDarkMode: isDarkMode,
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: roleColor,
                        child: Text(
                          getInitials(user.name),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              getRoleLabel(user.role),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: roleColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      trailing:
                          (!canEditUsers ||
                              isSelf ||
                              user.role == UserRole.citizen)
                          ? null
                          : IconButton(
                              icon: Icon(
                                Icons.person_remove,
                                color: colorScheme.error,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Yetkiyi Al'),
                                      content: Text(
                                        '${user.name} isimli kullanıcının yetkisini almak istediğinize emin misiniz?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('İptal'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: colorScheme.error,
                                            foregroundColor:
                                                colorScheme.onError,
                                          ),
                                          onPressed: () async {
                                            try {
                                              await ref
                                                  .read(authRepositoryProvider)
                                                  .updateUserRole(
                                                    user.id,
                                                    UserRole.citizen.name,
                                                  );
                                              ref.invalidate(
                                                managingListProvider,
                                              );
                                              ref.invalidate(staffListProvider);
                                              ref.invalidate(
                                                citizenListProvider,
                                              );
                                              ref.invalidate(
                                                filteredUserListProvider,
                                              );
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Kullanıcı rolü başarıyla güncellendi',
                                                    ),
                                                  ),
                                                );
                                                Navigator.pop(context);
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Hata: $e'),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          child: const Text('Onayla'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        error: (err, stack) => Center(child: Text('Bir hata oluştu: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: canEditUsers
          ? FloatingActionButton.extended(
              heroTag: 'user_manage_fab',
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              onPressed: () {
                final roleToCreate = canManageAdmins
                    ? UserRole.managing
                    : UserRole.staff;
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: colorScheme.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (context) =>
                      CitizenSelectionSheet(targetRole: roleToCreate),
                );
              },
              icon: const Icon(Icons.person_add),
              label: Text(canManageAdmins ? 'Sorumlu Ekle' : 'Personel Ekle'),
            )
          : null,
    );
  }
}

class UserFilterDrawerContent extends ConsumerStatefulWidget {
  final List<UserRole> allowedRoles;
  const UserFilterDrawerContent({super.key, required this.allowedRoles});
  @override
  ConsumerState<UserFilterDrawerContent> createState() =>
      _UserFilterDrawerContentState();
}

class _UserFilterDrawerContentState
    extends ConsumerState<UserFilterDrawerContent> {
  UserRole? _tempRole;
  @override
  void initState() {
    super.initState();
    _tempRole = ref.read(filterUserProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtrele',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _tempRole = null),
                        child: Text(
                          'Temizle',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    textColor: colorScheme.primary,
                    iconColor: colorScheme.primary,
                    title: const Text(
                      'Kullanıcı Tipi',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    initiallyExpanded: true,
                    children: [
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          FilterChip(
                            label: const Text('Tümü'),
                            selected: _tempRole == null,
                            onSelected: (_) => setState(() => _tempRole = null),
                            backgroundColor: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            selectedColor: colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                            side: BorderSide.none,
                            labelStyle: TextStyle(
                              color: _tempRole == null
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                            ),
                          ),
                          ...widget.allowedRoles.map((role) {
                            final isSelected = _tempRole == role;
                            return FilterChip(
                              label: Text(getRoleLabel(role)),
                              selected: isSelected,
                              onSelected: (_) => setState(
                                () => _tempRole = isSelected ? null : role,
                              ),
                              backgroundColor: colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              selectedColor: colorScheme.primary.withValues(
                                alpha: 0.2,
                              ),
                              side: BorderSide.none,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () {
              ref.read(filterUserProvider.notifier).state = _tempRole;
              Navigator.pop(context);
            },
            child: const Text('Sonuçları Göster'),
          ),
        ),
      ],
    );
  }
}

class CitizenSelectionSheet extends ConsumerStatefulWidget {
  final UserRole targetRole;
  const CitizenSelectionSheet({super.key, required this.targetRole});
  @override
  ConsumerState<CitizenSelectionSheet> createState() =>
      _CitizenSelectionSheetState();
}

class _CitizenSelectionSheetState extends ConsumerState<CitizenSelectionSheet> {
  String _searchQuery = '';
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          24,
          20,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Text(
              widget.targetRole == UserRole.managing
                  ? 'Yeni Sorumlu Seç'
                  : 'Yeni Personel Seç',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: 'İsim ara...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ref
                  .watch(citizenListProvider)
                  .when(
                    data: (users) {
                      final filteredUsers = users
                          .where(
                            (u) => u.name.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ),
                          )
                          .toList();
                      if (filteredUsers.isEmpty)
                        return Center(
                          child: Text(
                            'Sonuç bulunamadı',
                            style: TextStyle(color: colorScheme.outline),
                          ),
                        );
                      return ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final roleColor = getColorForRole(
                            user.role,
                            isDarkMode: isDarkMode,
                          );
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: colorScheme.outline.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            elevation: 0,
                            child: ListTile(
                              title: Text(
                                user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                user.email,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              leading: CircleAvatar(
                                backgroundColor: roleColor,
                                child: Text(
                                  getInitials(user.name),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Emin misiniz?'),
                                      content: Text(
                                        '${user.name} isimli kullanıcıyı ${widget.targetRole == UserRole.managing ? 'Sorumlu' : 'Personel'} yapmak istediğinize emin misiniz?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('İptal'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            try {
                                              await ref
                                                  .read(authRepositoryProvider)
                                                  .updateUserRole(
                                                    user.id,
                                                    widget.targetRole.name,
                                                  );
                                              ref.invalidate(
                                                managingListProvider,
                                              );
                                              ref.invalidate(staffListProvider);
                                              ref.invalidate(
                                                citizenListProvider,
                                              );
                                              ref.invalidate(
                                                filteredUserListProvider,
                                              );
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Kullanıcı rolü başarıyla güncellendi',
                                                    ),
                                                  ),
                                                );
                                                Navigator.pop(context);
                                                Navigator.pop(context);
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Hata: $e'),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          child: const Text('Onayla'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                    error: (err, stack) =>
                        Center(child: Text('Bir hata oluştu: $err')),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
