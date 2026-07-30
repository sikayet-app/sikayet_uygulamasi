import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikayet_uygulamasi/core/report_ui_helpers.dart';
import 'package:sikayet_uygulamasi/providers/auth_provider.dart';
import 'package:sikayet_uygulamasi/providers/report_provider.dart';
import 'package:sikayet_uygulamasi/screens/create_report_screen.dart';
import '../data/models/report.dart';
import 'dart:io';
import '../core/permission.dart';
import '../data/models/user.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final Report report;
  const ReportDetailScreen({super.key, required this.report});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  late Report _currentReport;

  @override
  void initState() {
    super.initState();
    _currentReport = widget.report;
  }

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Sil'),
          content: const Text('Şikayetinizi silmek istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false), // iptal seçeneği
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sil', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;
    if (!context.mounted) return;

    //hatayı ekrana yansıtmak için
    try {
      //onaylandıysa sil
      await ref.read(reportRepositoryProvider).deleteReport(_currentReport.id);
      ref.invalidate(reportListProvider);
      //detay sayfasından çık
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bildirim başarıyla silindi')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silinirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showNoteDialog(ReportStatus newStatus) async {
    final controller = TextEditingController();
    final String? note = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('${getStatusLabel(newStatus)} Notu'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Vatandaşa gösterilecek kısa bir açıklama yazın',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, null), // iptal seçeneği
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('Onayla'),
            ),
          ],
        );
      },
    );
    return note;
  }

  Future<User?> _showAssignDialog() async {
    final staffList = await ref.read(authRepositoryProvider).getStaffList();
    // Eğer sistemde hiç personel yoksa, boş liste göstermek yerine uyarı verip işlemi durdur
    if (staffList.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sistemde atanacak personel bulunamadı.'),
          ),
        );
      }
      return null;
    }

    //Ekranda seçim penceresini (Dialog) aç
    if (!context.mounted) return null;
    return showDialog<User>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Personel Seçin'),
          // İçeriğin ekrandan taşmasını önlemek için SizedBox ile genişliği sınırlandır
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap:
                  true, // Listenin sadece elemanları kadar yer kaplamasını sağlar
              itemCount: staffList.length,
              itemBuilder: (context, index) {
                final staff = staffList[index];
                return ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(staff.name),
                  subtitle: Text(staff.email),
                  onTap: () {
                    Navigator.pop(dialogContext, staff);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: const Text('İptal'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();
    final canEdit = canEditReport(_currentReport, currentUser);
    final canDelete = _currentReport.canDeleteReport;
    final canChangeStatus = canUpdateStatus(_currentReport, currentUser);
    final canAssign = canAssignReport(currentUser.role);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (canEdit)
            IconButton(
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateReportScreen(existingReport: _currentReport),
                  ),
                );
                // eğer kullanıcı kaydetmeden geri çıkmadıysa ve dönen veri Report tipindeyse ekranı güncelle
                if (updated != null && updated is Report) {
                  setState(() {
                    _currentReport = updated;
                  });
                }
              },
              icon: const Icon(Icons.edit_outlined),
            ),
          if (canDelete)
            IconButton(
              onPressed: () => _confirmAndDelete(context, ref),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_currentReport.imagePaths.isNotEmpty)
              SizedBox(
                height: 250,
                width: double.infinity,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal, // yatay kaydırma
                  itemCount: _currentReport.imagePaths.length,
                  itemBuilder: (context, index) {
                    final image = _currentReport.imagePaths[index];
                    return Padding(
                      padding: const EdgeInsets.only(
                        right: 4.0,
                      ), // resimler arası
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: image.startsWith('http')
                            ? Image.network(
                                image,
                                height: 320,
                                width: 250,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      height: 100,
                                      width: 110,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                      ),
                                    ),
                              )
                            : Image.file(
                                File(image),
                                height: 100,
                                width: 110,
                                fit: BoxFit.cover,
                              ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentReport.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.access_time,size: 16, color: Colors.grey),
                      SizedBox(width: 6),
                      Text(
                        getFormattedDate(_currentReport.createdAt),
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  if (canChangeStatus) ...[
                    Text(
                      'Gönderen: ${_currentReport.senderName ?? "Bilinmiyor"}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                  Text(
                    _currentReport.description,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(getCategoryLabel(_currentReport.category)),
                      ),
                      Spacer(),
                      if (!canChangeStatus)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorForStatus(_currentReport.status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(getStatusLabel(_currentReport.status)),
                        ),

                      // yöneticiyse tıklanabilir olacak
                      if (canChangeStatus)
                        PopupMenuButton<ReportStatus>(
                          // seçim yapıldığında çalışacak mantık
                          onSelected: (ReportStatus newStatus) async {
                            String? note;

                            //çözüldü,reddedildi veya asılsız seçildiğinde not sor
                            if (newStatus == ReportStatus.resolved ||
                                newStatus == ReportStatus.rejected ||
                                newStatus == ReportStatus.invalid) {
                              note = await _showNoteDialog(newStatus);

                              if (note == null) return;
                            }

                            await ref
                                .read(reportRepositoryProvider)
                                .updateStatusWithNote(
                                  _currentReport.id,
                                  newStatus,
                                  note,
                                );
                            // ekranı anında güncelle
                            setState(() {
                              _currentReport = _currentReport.copyWith(
                                status: newStatus,
                                resolutionNote: note,
                              );
                            });
                            ref.invalidate(reportListProvider);
                          },
                          // menüdeki seçenekleri oluştur
                          itemBuilder: (context) =>
                              ReportStatus.values.map((status) {
                                return PopupMenuItem(
                                  value: status,
                                  child: Text(getStatusLabel(status)),
                                );
                              }).toList(),
                          // ekranda görünen tıklanabilir çip
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorForStatus(_currentReport.status),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(getStatusLabel(_currentReport.status)),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down, size: 18),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_currentReport.assignedStaffId != null || canAssign) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueGrey[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sorumlu Personel',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _currentReport.assignedStaffName ??
                                      'Henüz personel atanmadı',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        _currentReport.assignedStaffId != null
                                        ? Colors.black87
                                        : Colors.grey[600],
                                    fontStyle:
                                        _currentReport.assignedStaffId != null
                                        ? FontStyle.normal
                                        : FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (canAssign)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey[700],
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                              icon: Icon(
                                _currentReport.assignedStaffId != null
                                    ? Icons.edit
                                    : Icons.person_add,
                                size: 18,
                              ),
                              label: Text(
                                _currentReport.assignedStaffId != null
                                    ? 'Değiştir'
                                    : 'Ata',
                              ),
                              onPressed: () async {
                                // seçilen user nesnesini dialogdan al
                                final selectedStaff = await _showAssignDialog();

                                // iptal edilmediyse api ye gönder
                                if (selectedStaff != null) {
                                  try {
                                    await ref
                                        .read(reportRepositoryProvider)
                                        .assignReport(
                                          _currentReport.id,
                                          selectedStaff.id,
                                        );

                                    setState(() {
                                      _currentReport = _currentReport.copyWith(
                                        assignedStaffId: selectedStaff.id,
                                        assignedStaffName: selectedStaff.name,
                                      );
                                    });
                                    ref.invalidate(reportListProvider);

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Personel ataması başarılı',
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Atama sırasında hata: $e',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (_currentReport.resolutionNote != null &&
                      _currentReport.resolutionNote!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        'Not: ${_currentReport.resolutionNote}',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
