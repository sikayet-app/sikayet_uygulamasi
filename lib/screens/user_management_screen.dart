import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../data/models/user.dart';
import '../widgets/app_card.dart';
import '../core/report_ui_helpers.dart';
import '../core/app_colors.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(filteredUserListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    Future.microtask(() {
      if (mounted) ref.read(filterUserProvider.notifier).state = null;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    final canEditUsers = currentUser.permissions.contains('edit_users');
    final canDeleteUsers = currentUser.permissions.contains('delete_users');
    final isAdmin = currentUser.role == UserRole.admin;
    final isManaging = currentUser.role == UserRole.managing;
    final canManageRoles = isAdmin || isManaging;

    List<UserRole> allowedFilterRoles = isAdmin
        ? [UserRole.managing, UserRole.staff, UserRole.citizen]
        : [UserRole.staff, UserRole.citizen];

    final state = ref.watch(filteredUserListProvider);

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
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
          ? Center(
              child: Text(
                'Hata: ${state.error}',
                style: TextStyle(color: colorScheme.error),
              ),
            )
          : state.users.isEmpty
          ? Center(
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
            )
          : RefreshIndicator(
              onRefresh: () async {
                // ana listeyi 1.sayfadan tekrar yükle
                await ref
                    .read(filteredUserListProvider.notifier)
                    .loadFirstPage();
                ref.invalidate(managingListProvider);
                ref.invalidate(staffListProvider);

                try {
                  if (isAdmin) await ref.read(managingListProvider.future);
                  await ref.read(staffListProvider.future);
                } catch (_) {}
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                itemCount: state.users.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.users.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  final user = state.users[index];
                  final isSelf = user.id == currentUser.id;
                  final roleColor = getColorForRole(
                    user.role,
                    isDarkMode: isDarkMode,
                  );

                  bool canDemote = false;
                  if (canManageRoles &&
                      !isSelf &&
                      user.role != UserRole.citizen) {
                    if (isAdmin) {
                      canDemote = true; // Admin vatandaşa kadar herkesi düşürür
                    } else if (isManaging && user.role == UserRole.staff) {
                      canDemote = true; // Managing sadece staff'ı düşürür
                    }
                  }

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

                        trailing: (isSelf || (!canDemote && canDeleteUsers))
                            ? null
                            : PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                onSelected: (value) {
                                  if (value == 'demote') {
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
                                                backgroundColor:
                                                    colorScheme.error,
                                                foregroundColor:
                                                    colorScheme.onError,
                                              ),
                                              onPressed: () async {
                                                try {
                                                  await ref
                                                      .read(
                                                        authRepositoryProvider,
                                                      )
                                                      .updateUserRole(
                                                        user.id,
                                                        UserRole.citizen.name,
                                                      );
                                                  // İşlem bitince kendi provider'ını 1. sayfadan tazele
                                                  ref
                                                      .read(
                                                        filteredUserListProvider
                                                            .notifier,
                                                      )
                                                      .loadFirstPage();
                                                  ref.invalidate(
                                                    managingListProvider,
                                                  );
                                                  ref.invalidate(
                                                    staffListProvider,
                                                  );
                                                  ref.invalidate(
                                                    citizenListProvider,
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
                                                        content: Text(
                                                          'Hata: $e',
                                                        ),
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
                                  } else if (value == 'delete') {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text(
                                            'Kullanıcıyı Sil',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          content: Text(
                                            '${user.name} isimli kullanıcıyı tamamen silmek istediğinize emin misiniz? Bu işlem geri alınamaz!',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('İptal'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    colorScheme.error,
                                                foregroundColor:
                                                    colorScheme.onError,
                                              ),
                                              onPressed: () async {
                                                try {
                                                  await ref
                                                      .read(
                                                        authRepositoryProvider,
                                                      )
                                                      .deleteUser(user.id);
                                                  ref
                                                      .read(
                                                        filteredUserListProvider
                                                            .notifier,
                                                      )
                                                      .loadFirstPage();
                                                  ref.invalidate(
                                                    managingListProvider,
                                                  );
                                                  ref.invalidate(
                                                    staffListProvider,
                                                  );
                                                  ref.invalidate(
                                                    citizenListProvider,
                                                  );
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Kullanıcı başarıyla silindi',
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
                                                        content: Text(
                                                          'Silinirken hata oluştu: $e',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              child: const Text('Sil'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  // Sadece yetkisi olanları (personel, sorumlu) düşürebiliriz
                                  if (canDemote)
                                    const PopupMenuItem(
                                      value: 'demote',
                                      child: Row(
                                        children: [
                                          Icon(Icons.arrow_downward, size: 20),
                                          SizedBox(width: 12),
                                          Text('Yetkiyi Al'),
                                        ],
                                      ),
                                    ),
                                  // Silme yetkisi varsa "Sil" butonu görünür
                                  if (canDeleteUsers)
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.person_remove,
                                            size: 20,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Sil',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: (canManageRoles && canEditUsers)
          ? FloatingActionButton.extended(
              heroTag: 'user_manage_fab',
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              onPressed: () {
                final roleToCreate = isAdmin
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
              label: Text(isAdmin ? 'Sorumlu Ekle' : 'Personel Ekle'),
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
                                              ref
                                                  .read(
                                                    filteredUserListProvider
                                                        .notifier,
                                                  )
                                                  .loadFirstPage();
                                              ref.invalidate(
                                                managingListProvider,
                                              );
                                              ref.invalidate(staffListProvider);
                                              ref.invalidate(
                                                citizenListProvider,
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
