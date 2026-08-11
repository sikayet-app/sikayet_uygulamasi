import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikayet_uygulamasi/core/report_ui_helpers.dart';
import 'package:sikayet_uygulamasi/providers/auth_provider.dart';
import 'package:sikayet_uygulamasi/providers/report_provider.dart';
import 'package:sikayet_uygulamasi/screens/create_report_screen.dart';
import '../data/models/report.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
              onPressed: () => Navigator.pop(dialogContext, false),
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
      await ref.read(reportRepositoryProvider).deleteReport(_currentReport.id);
      ref.invalidate(reportListProvider);
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

  //  SÜREÇ TAKİBİ

  Widget _buildProcessStepper(ColorScheme colorScheme, ReportStatus status) {
    int currentStep = 0;
    bool isError = false;

    if (status == ReportStatus.inProgress) {
      currentStep = 1;
    } else if (status == ReportStatus.resolved) {
      currentStep = 2;
    } else if (status == ReportStatus.rejected ||
        status == ReportStatus.invalid) {
      currentStep = 2;
      isError = true;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          _buildStep(colorScheme, 'Bildirildi', true, false, true),
          _buildLine(colorScheme, currentStep >= 1),
          _buildStep(colorScheme, 'İşlemde', currentStep >= 1, false, false),
          _buildLine(colorScheme, currentStep >= 2),
          _buildStep(
            colorScheme,
            isError ? getStatusLabel(status) : 'Çözüldü',
            currentStep >= 2,
            isError,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
    ColorScheme colorScheme,
    String label,
    bool isActive,
    bool isError,
    bool isFirst,
  ) {
    Color circleColor = colorScheme.surfaceContainerHighest;
    Color iconColor = colorScheme.outline;
    IconData icon = Icons.circle;
    double iconSize = 12;

    if (isActive) {
      if (isError) {
        circleColor = colorScheme.error;
        iconColor = colorScheme.onError;
        icon = Icons.close;
        iconSize = 16;
      } else {
        circleColor = const Color(
          0xFF1E293B,
        ); // Koyu Lacivert (Tasarımdaki gibi)
        iconColor = Colors.white;
        icon = Icons.check;
        iconSize = 16;
      }
    }

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: iconSize),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive
                ? (isError ? colorScheme.error : colorScheme.onSurface)
                : colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(ColorScheme colorScheme, bool isActive) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 24,
          left: 8,
          right: 8,
        ), // Metin boşluğunu telafi etmek için margin
        height: 3,
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF1E293B)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
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
    final isDarkMode = theme.brightness == Brightness.dark;

    final canEdit = _currentReport.canEditReport;
    final canDelete = _currentReport.canDeleteReport;
    final canChangeStatus = canUpdateStatusPermission;
    final canAssign = canAssignStaff;

    return Scaffold(
      backgroundColor: isDarkMode ? colorScheme.surface : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Talep Detayı',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDarkMode ? colorScheme.surface : Colors.grey.shade50,
        foregroundColor: colorScheme.onSurface,
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
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FOTOĞRAF ALANI
            if (_currentReport.imagePaths.isNotEmpty)
              _currentReport.imagePaths.length == 1
                  ? SizedBox(
                      height: 280,
                      width: double.infinity,
                      child:
                          _currentReport.imagePaths.first.startsWith('http') ||
                              kIsWeb
                          ? Image.network(
                              _currentReport.imagePaths.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildImageError(colorScheme),
                            )
                          : Image.file(
                              File(_currentReport.imagePaths.first),
                              fit: BoxFit.cover,
                            ),
                    )
                  : SizedBox(
                      height: 240,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _currentReport.imagePaths.length,
                        itemBuilder: (context, index) {
                          final image = _currentReport.imagePaths[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: 300,
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

            //  İÇERİK ALANI
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori ve Durum Değiştirme Butonu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.label_outline,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            getCategoryLabel(_currentReport.category),
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      // Yöneticiler için durumu güncelleme butonu
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
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Durumu Güncelle',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_drop_down,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Başlık ve Tarih
                  Text(
                    _currentReport.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        getFormattedDate(_currentReport.createdAt),
                        style: TextStyle(
                          color: colorScheme.outline,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // SÜREÇ TAKİBİ BİLEŞENİ
                  _buildProcessStepper(colorScheme, _currentReport.status),
                  const SizedBox(height: 24),

                  // Açıklama Metni
                  Text(
                    _currentReport.description,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // İLETİŞİM VE ADRES KARTLARI
                  if (canChangeStatus || canAssign) ...[
                    _buildInfoCard(
                      colorScheme,
                      Icons.person_outline,
                      'Gönderen Bilgileri',
                      _currentReport.senderName ?? "Bilinmiyor",
                      subtext:
                          _currentReport.contactPhone != null &&
                              _currentReport.contactPhone!.isNotEmpty
                          ? 'İletişim: ${_currentReport.contactPhone}'
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],

                  _buildInfoCard(
                    colorScheme,
                    Icons.location_on_outlined,
                    'Açık Adres',
                    _currentReport.fullAddress ?? 'Adres bilgisi bulunmuyor',
                  ),
                  const SizedBox(height: 24),

                  // PERSONEL ATAMA VE ÇÖZÜM NOTU ALANI
                  if (_currentReport.assignedStaffId != null || canAssign) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.15),
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
                                const SizedBox(height: 6),
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
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                        color: colorForStatus(
                          _currentReport.status,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorForStatus(
                            _currentReport.status,
                          ).withValues(alpha: 0.2),
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
                                color: colorForStatus(_currentReport.status),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Çözüm Notu',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorForStatus(_currentReport.status),
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
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    ColorScheme colorScheme,
    IconData icon,
    String title,
    String mainText, {
    String? subtext,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mainText,
                  style: TextStyle(
                    fontSize: 15,
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtext != null) ...[
                  const SizedBox(height: 4),
                  SelectableText(
                    subtext,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageError(ColorScheme colorScheme) {
    return Container(
      height: 280,
      width: double.infinity,
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.broken_image, color: colorScheme.outline, size: 48),
    );
  }
}
