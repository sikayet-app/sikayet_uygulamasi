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
    final title = isAdmin ? 'Sorumlular' : 'Personeller';

    final listProvider = isAdmin ? managingListProvider : staffListProvider;

    final userAsync = ref.watch(listProvider);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                elevation: 0,
                child: ListTile(
                  title: Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(user.email),
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
                            color: Colors.grey.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
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
