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
import '../core/app_colors.dart'; // YENİ: Merkezi renk dosyamız

class ReportDetailScreen extends ConsumerStatefulWidget {
  final Report report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  late Report _currentReport;
  int _currentImageIndex = 0; // Çoklu görsel takibi için

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

  Widget _buildImmersiveHeader(ColorScheme colorScheme, bool isDarkMode) {
    final hasImage = _currentReport.imagePaths.isNotEmpty;
    // Eğer görsel yoksa yazılar siyah kalsın (açık modda)
    final textColor = (hasImage || isDarkMode) ? Colors.white : colorScheme.onSurface;
    final subtitleColor = (hasImage || isDarkMode) ? Colors.white70 : colorScheme.onSurfaceVariant;

    return Stack(
      children: [
        // Arka plan görseli (Çoklu görsel desteği ile)
        Container(
          height: 380,
          width: double.infinity,
          color: colorScheme.surfaceContainerHighest,
          child: hasImage
              ? PageView.builder(
                  itemCount: _currentReport.imagePaths.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final path = _currentReport.imagePaths[index];
                    return path.startsWith('http') || kIsWeb
                        ? Image.network(path, fit: BoxFit.cover)
                        : Image.file(File(path), fit: BoxFit.cover);
                  },
                )
              : Icon(Icons.broken_image, size: 64, color: colorScheme.outline),
        ),

        // Karartma katmanı (Sadece görsel varsa)
        if (hasImage)
          Container(
            height: 380,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.5),
                  Colors.black.withValues(alpha: 0.9),
                ],
              ),
            ),
          ),

        // Çoklu görsel göstergesi (Badge)
        if (hasImage && _currentReport.imagePaths.length > 1)
          Positioned(
            top: 100, // AppBar'ın altına denk gelmesi için
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${_currentReport.imagePaths.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),

        // İçerik katmanı
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kategori ve durum etiketi
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: hasImage ? Colors.white.withValues(alpha: 0.2) : colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      getCategoryLabel(_currentReport.category),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorForStatus(_currentReport.status, isDarkMode: isDarkMode),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      getStatusLabel(_currentReport.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Başlık (Taşma korumalı)
              Text(
                _currentReport.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              // Tarih
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: subtitleColor),
                  const SizedBox(width: 6),
                  Text(
                    getFormattedDate(_currentReport.createdAt),
                    style: TextStyle(color: subtitleColor, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Dikey zaman çizelgesi süreç geçmişi
  Widget _buildVerticalTimeline(ColorScheme colorScheme, bool isDarkMode) {
    bool isInProgress = _currentReport.status == ReportStatus.inProgress ||
        _currentReport.status == ReportStatus.resolved ||
        _currentReport.status == ReportStatus.rejected ||
        _currentReport.status == ReportStatus.invalid;
    bool isFinished = _currentReport.status == ReportStatus.resolved ||
        _currentReport.status == ReportStatus.rejected ||
        _currentReport.status == ReportStatus.invalid;

    return _buildModularCard(
      colorScheme: colorScheme,
      isDarkMode: isDarkMode,
      overline: 'SÜREÇ GEÇMİŞİ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimelineStep(
            colorScheme: colorScheme,
            title: 'Bildirildi',
            subtitle: '${_currentReport.senderName ?? "Bilinmiyor"} - ${getFormattedDate(_currentReport.createdAt)}',
            isActive: true,
            isLast: _currentReport.assignedStaffId == null && !isInProgress,
            iconColor: colorScheme.primary, // Sabit renk yerine temaya uygun renk
          ),
          if (_currentReport.assignedStaffId != null)
            _buildTimelineStep(
              colorScheme: colorScheme,
              title: '${_currentReport.assignedStaffName} personeline atandı',
              subtitle: 'Sistem tarafından yönlendirildi',
              isActive: true,
              isLast: !isInProgress,
              iconColor: colorScheme.primary,
            ),
          if (isInProgress)
            _buildTimelineStep(
              colorScheme: colorScheme,
              title: 'İnceleniyor / İşlemde',
              subtitle: isFinished ? 'Süreç tamamlandı' : 'Şu an devam ediyor',
              isActive: true,
              isLast: !isFinished,
              iconColor: isFinished ? colorScheme.primary : colorForStatus(ReportStatus.inProgress, isDarkMode: isDarkMode),
            ),
          if (isFinished)
            _buildTimelineStep(
              colorScheme: colorScheme,
              title: getStatusLabel(_currentReport.status),
              subtitle: 'Talep sonuçlandırıldı',
              isActive: true,
              isLast: true,
              iconColor: colorForStatus(_currentReport.status, isDarkMode: isDarkMode),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required ColorScheme colorScheme,
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isLast,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: colorScheme.surfaceContainerHighest,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModularCard({
    required ColorScheme colorScheme,
    required bool isDarkMode,
    required String overline,
    required Widget child,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDarkMode ? colorScheme.surfaceContainer : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor ?? (isDarkMode ? colorScheme.outline.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05)),
        ),
        boxShadow: isDarkMode || backgroundColor != null
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            overline,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.outline,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    final canAssignStaff = currentUser.permissions.contains('assign_staff') ||
        currentUser.role == UserRole.admin ||
        currentUser.role == UserRole.managing;

    final canUpdateStatusPermission = currentUser.permissions.contains('update_report_status') ||
        currentUser.role == UserRole.admin ||
        currentUser.role == UserRole.managing ||
        currentUser.role == UserRole.staff;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    final canEdit = _currentReport.canEditReport;
    final canDelete = _currentReport.canDeleteReport;
    final canChangeStatus = canUpdateStatusPermission;
    final canAssign = canAssignStaff;

    return Scaffold(
      backgroundColor: isDarkMode ? colorScheme.surface : AppColors.surfaceWarmLight,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
          child: CircleAvatar(
            backgroundColor: colorScheme.surface,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.onSurface, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          if (canEdit)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: CircleAvatar(
                backgroundColor: colorScheme.surface,
                child: IconButton(
                  onPressed: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateReportScreen(existingReport: _currentReport),
                      ),
                    );
                    if (updated != null && updated is Report) {
                      setState(() {
                        _currentReport = updated;
                      });
                    }
                  },
                  icon: Icon(Icons.edit_outlined, color: colorScheme.onSurface, size: 20),
                ),
              ),
            ),
          if (canDelete)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 12.0, left: 4.0),
              child: CircleAvatar(
                backgroundColor: colorScheme.surface,
                child: IconButton(
                  onPressed: () => _confirmAndDelete(context, ref),
                  icon: Icon(Icons.delete_outline, color: colorScheme.error, size: 20),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: canChangeStatus
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mevcut Durum',
                          style: TextStyle(fontSize: 12, color: colorScheme.outline),
                        ),
                        Text(
                          getStatusLabel(_currentReport.status),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorForStatus(_currentReport.status, isDarkMode: isDarkMode),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
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
                      itemBuilder: (context) => ReportStatus.values.map((status) {
                        return PopupMenuItem(
                          value: status,
                          child: Text(getStatusLabel(status)),
                        );
                      }).toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary, // Sabit lacivert yerine primary color
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Durumu Güncelle',
                              style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.keyboard_arrow_down, color: colorScheme.onPrimary, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImmersiveHeader(colorScheme, isDarkMode),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildModularCard(
                    colorScheme: colorScheme,
                    isDarkMode: isDarkMode,
                    overline: 'AÇIKLAMA',
                    child: Text(
                      _currentReport.description,
                      style: TextStyle(fontSize: 16, height: 1.6, color: colorScheme.onSurface),
                    ),
                  ),
                  _buildModularCard(
                    colorScheme: colorScheme,
                    isDarkMode: isDarkMode,
                    overline: 'AÇIK ADRES',
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                          child: Icon(Icons.location_on_outlined, color: colorScheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _currentReport.fullAddress ?? 'Adres bilgisi bulunmuyor',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: colorScheme.outline),
                      ],
                    ),
                  ),
                  _buildVerticalTimeline(colorScheme, isDarkMode),
                  if (canChangeStatus || canAssign)
                    _buildModularCard(
                      colorScheme: colorScheme,
                      isDarkMode: isDarkMode,
                      overline: 'GÖNDEREN BİLGİLERİ',
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.person_outline, color: colorScheme.onSurfaceVariant, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentReport.senderName ?? "Bilinmiyor",
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                                if (_currentReport.contactPhone != null && _currentReport.contactPhone!.isNotEmpty)
                                  Text(
                                    'İletişim: ${_currentReport.contactPhone}',
                                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_currentReport.assignedStaffId != null || canAssign)
                    _buildModularCard(
                      colorScheme: colorScheme,
                      isDarkMode: isDarkMode,
                      overline: 'SORUMLU PERSONEL',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _currentReport.assignedStaffName ?? 'Henüz atanmadı',
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: _currentReport.assignedStaffId != null ? FontStyle.normal : FontStyle.italic,
                              fontWeight: _currentReport.assignedStaffId != null ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (canAssignStaff)
                            OutlinedButton(
                              onPressed: () async {
                                final selectedStaff = await _showAssignDialog();
                                if (selectedStaff != null) {
                                  try {
                                    if (_currentReport.assignedStaffId == null) {
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
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Atama başarılı')),
                                      );
                                    }
                                  } catch (e) {}
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                _currentReport.assignedStaffId != null ? 'Değiştir' : 'Ata',
                                style: TextStyle(color: colorScheme.onSurface),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (_currentReport.resolutionNote != null && _currentReport.resolutionNote!.isNotEmpty)
                    _buildModularCard(
                      colorScheme: colorScheme,
                      isDarkMode: isDarkMode,
                      overline: 'ÇÖZÜM NOTU',
                      backgroundColor: getStatusBgColor(_currentReport.status, isDarkMode: isDarkMode),
                      borderColor: colorForStatus(_currentReport.status, isDarkMode: isDarkMode).withValues(alpha: 0.2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: colorForStatus(_currentReport.status, isDarkMode: isDarkMode),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _currentReport.resolutionNote!,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                                color: colorForStatus(_currentReport.status, isDarkMode: isDarkMode), // Yeni kontrast rengi
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}