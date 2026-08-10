import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikayet_uygulamasi/core/report_ui_helpers.dart';
import 'package:sikayet_uygulamasi/providers/auth_provider.dart';
import 'package:sikayet_uygulamasi/providers/report_provider.dart';
import 'package:sikayet_uygulamasi/screens/create_report_screen.dart';
import '../data/models/report.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // kIsWeb kullanmayı sağlar.
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
              onPressed: () => Navigator.pop(dialogContext, null),
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

    if (!context.mounted) return null;

    return showDialog<User>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Personel Seçin'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
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
    final canAssignStaff = currentUser.permissions.contains('assign_staff');
    final canUpdateStatusPermission = currentUser.permissions.contains(
      'update_report_status',
    );
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final canEdit = _currentReport.canEditReport;
    final canDelete = _currentReport.canDeleteReport;
    final canChangeStatus = canUpdateStatusPermission;
    final canAssign = canAssignStaff;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Şikayet Detayı'),
        centerTitle: true,
        elevation: 0,
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
            // DİNAMİK FOTOĞRAF ALANI
            if (_currentReport.imagePaths.isNotEmpty)
              _currentReport.imagePaths.length == 1
                  ? SizedBox(
                      height: 250,
                      width: double.infinity,
                      child:
                          _currentReport.imagePaths.first.startsWith('http') ||
                              kIsWeb
                          ? Image.network(
                              _currentReport.imagePaths.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 250,
                                    width: double.infinity,
                                    color: colorScheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.broken_image,
                                      color: colorScheme.outline,
                                    ),
                                  ),
                            )
                          : Image.file(
                              File(_currentReport.imagePaths.first),
                              fit: BoxFit.cover,
                            ),
                    )
                  : SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        itemCount: _currentReport.imagePaths.length,
                        itemBuilder: (context, index) {
                          final image = _currentReport.imagePaths[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 280,
                                child: image.startsWith('http') || kIsWeb
                                    ? Image.network(image, fit: BoxFit.cover)
                                    : Image.file(
                                        File(image),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

            // İÇERİK ALANI
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HİYERARŞİ 1: KATEGORİ VE DURUM ETİKETLERİ
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          getCategoryLabel(_currentReport.category),
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (!canChangeStatus)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorForStatus(
                              _currentReport.status,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            getStatusLabel(_currentReport.status),
                            style: TextStyle(
                              color: colorForStatus(_currentReport.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (canChangeStatus)
                        PopupMenuButton<ReportStatus>(
                          onSelected: (ReportStatus newStatus) async {
                            String? note;
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
                            setState(() {
                              _currentReport = _currentReport.copyWith(
                                status: newStatus,
                                resolutionNote: note,
                              );
                            });
                            ref.invalidate(reportListProvider);
                          },
                          itemBuilder: (context) =>
                              ReportStatus.values.map((status) {
                                return PopupMenuItem(
                                  value: status,
                                  child: Text(getStatusLabel(status)),
                                );
                              }).toList(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorForStatus(
                                _currentReport.status,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  getStatusLabel(_currentReport.status),
                                  style: TextStyle(
                                    color: colorForStatus(
                                      _currentReport.status,
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_drop_down,
                                  size: 18,
                                  color: colorForStatus(_currentReport.status),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // HİYERARŞİ 2: BAŞLIK VE TARİH
                  Text(
                    _currentReport.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        getFormattedDate(_currentReport.createdAt),
                        style: TextStyle(color: colorScheme.outline),
                      ),
                    ],
                  ),

                  // Admin veya yetkili personel ise gönderen ve iletişim bilgisini göster
                  if (canChangeStatus || canAssign) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Gönderen: ${_currentReport.senderName ?? "Bilinmiyor"}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          if (_currentReport.contactPhone != null &&
                              _currentReport.contactPhone!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                SelectableText(
                                  'İletişim: ${_currentReport.contactPhone}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentReport.fullAddress ??
                              'Adres bilgisi bulunmuyor',
                          style: TextStyle(
                            fontSize: 15,
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Divider(
                    height: 32,
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),

                  // HİYERARŞİ 3: AÇIKLAMA METNİ
                  Text(
                    _currentReport.description,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // HİYERARŞİ 4: ATAMA VE NOT BÖLÜMÜ
                  if (_currentReport.assignedStaffId != null || canAssign) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
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
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _currentReport.assignedStaffName ??
                                      'Henüz personel atanmadı',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontStyle:
                                        _currentReport.assignedStaffId != null
                                        ? FontStyle.normal
                                        : FontStyle.italic,
                                    fontWeight:
                                        _currentReport.assignedStaffId != null
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (canAssignStaff)
                            FilledButton.icon(
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
                                final selectedStaff = await _showAssignDialog();
                                if (selectedStaff != null) {
                                  try {
                                    if (_currentReport.assignedStaffId ==
                                        null) {
                                      await ref
                                          .read(reportRepositoryProvider)
                                          .assignReport(
                                            _currentReport.id,
                                            selectedStaff.id,
                                          );
                                    } else {
                                      await ref
                                          .read(reportRepositoryProvider)
                                          .updateAssignedStaff(
                                            _currentReport.id,
                                            selectedStaff.id,
                                          );
                                    }
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
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Çözüm Notu',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentReport.resolutionNote!,
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                        ],
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
