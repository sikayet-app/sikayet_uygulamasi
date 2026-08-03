import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../data/models/user.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    final isAdmin = currentUser.role == UserRole.admin;
    List<UserRole> allowedFilterRoles = [];
    if (isAdmin) {
      allowedFilterRoles = [
        UserRole.managing,
        UserRole.staff,
        UserRole.citizen,
      ];
    } else {
      allowedFilterRoles = [UserRole.staff, UserRole.citizen];
    }
    final title = isAdmin ? 'Sorumlular' : 'Personeller';

    final listProvider = isAdmin ? managingListProvider : staffListProvider;

    final userAsync = ref.watch(filteredUserListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Kullanıcı Yönetimi'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                isScrollControlled: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                context: context,
                builder: (context) {
                  return Consumer(
                    builder: (context, ref, child) {
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          24,
                          24,
                          MediaQuery.of(context).padding.bottom + 24,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Filtrele',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Kullanıcılar',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8.0, // yatay boşluk
                              runSpacing:
                                  8.0, // alt satıra geçerse dikey boşluk
                              children: [
                                FilterChip(
                                  label: const Text('Tümü'),
                                  selected:
                                      ref.watch(filterUserProvider) == null,
                                  onSelected: (_) {
                                    ref
                                            .read(filterUserProvider.notifier)
                                            .state =
                                        null;
                                  },
                                  backgroundColor: Colors.grey.withValues(
                                    alpha: 0.1,
                                  ),
                                  selectedColor: Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.2),
                                  side: BorderSide.none,
                                ),
                                ...allowedFilterRoles.map((role) {
                                  final isSelected =
                                      ref.watch(filterUserProvider) == role;
                                  return FilterChip(
                                    label: Text(getRoleLabel(role)),
                                    selected: isSelected,
                                    onSelected: (_) {
                                      ref
                                          .read(filterUserProvider.notifier)
                                          .state = isSelected
                                          ? null
                                          : role;
                                    },
                                    backgroundColor: Colors.grey.withValues(
                                      alpha: 0.1,
                                    ),
                                    selectedColor: Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.2),
                                  );
                                }).toList(),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: userAsync.when(
        data: (users) {
          if (users.isEmpty) return const Center(child: Text('Liste boş'));
          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                elevation: 0,
                child: ListTile(
                  title: Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(user.email),
                  trailing: IconButton(
                    icon: Icon(Icons.person_remove, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Yetkiyi Al'),
                            content: Text(
                              '${user.name} isimli kulllanıcının yetkisini almak istediğinize emin misiniz?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('İptal'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  try {
                                    await ref
                                        .read(authRepositoryProvider)
                                        .updateUserRole(
                                          user.id,
                                          UserRole.citizen.name,
                                        );
                                    ref.invalidate(listProvider);
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
                                        SnackBar(content: Text('Hata: $e')),
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
                  leading: CircleAvatar(child: Icon(Icons.person)),
                ),
              );
            },
          );
        },
        error: (err, stack) => Center(child: Text('Bir hata oluştu: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        onPressed: () {
          // giren kişi admin ise sorumlu, sorumlu ise personel atayacak
          final roleToCreate = isAdmin ? UserRole.managing : UserRole.staff;
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) =>
                CitizenSelectionSheet(targetRole: roleToCreate),
          );
        },
        icon: const Icon(Icons.person_add),
        label: Text(isAdmin ? 'Sorumlu Ekle' : 'Personel Ekle'),
      ),
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
  // değişen arama metni
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            Text(
              widget.targetRole == UserRole.managing
                  ? 'Yeni Sorumlu Seç'
                  : 'Yeni Personel Seç',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            // arama çubuğu
            TextField(
              decoration: InputDecoration(
                hintText: 'İsim ara',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
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
                        return const Text('Sonuç bulunamadı');
                      return ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.3),
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
                              subtitle: Text(user.email),
                              leading: CircleAvatar(child: Icon(Icons.person)),
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
                                          onPressed: () {
                                            Navigator.pop(
                                              context,
                                            ); // uyarı pencerisini kapatır
                                          },
                                          child: const Text('İptal'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            try {
                                              // backend e rol güncelleme isteği at
                                              await ref
                                                  .read(authRepositoryProvider)
                                                  .updateUserRole(
                                                    user.id,
                                                    widget.targetRole.name,
                                                  );
                                              // işlem başarılı olursa ilgili listeleri yenile
                                              ref.invalidate(
                                                citizenListProvider,
                                              ); // vatandaş listesi yenilensin
                                              ref.invalidate(
                                                widget.targetRole ==
                                                        UserRole.managing
                                                    ? managingListProvider
                                                    : staffListProvider,
                                              ); // hangi rol eklendiye o liste yenilensin

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
                                                Navigator.pop(
                                                  context,
                                                ); // bu uyarı pencerini kapatır
                                                Navigator.pop(
                                                  context,
                                                ); // bu da alttaki arama penceresini kapatır
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
