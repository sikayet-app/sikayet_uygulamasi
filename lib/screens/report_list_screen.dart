import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikayet_uygulamasi/core/report_ui_helpers.dart';
import 'package:sikayet_uygulamasi/providers/auth_provider.dart';
import 'package:sikayet_uygulamasi/widgets/create_report_fab.dart';
import '../providers/report_provider.dart';
import '../data/models/report.dart';
import 'report_detail_screen.dart';
import '../data/models/user.dart';
import '../widgets/notification_bell.dart';

class ReportListScreen extends ConsumerWidget {
  const ReportListScreen({super.key});

  String _getPageTitle(UserRole? role) {
    if (role == UserRole.citizen) return 'Taleplerim';
    if (role == UserRole.staff) return 'Görevlerim';
    if (role == UserRole.admin || role == UserRole.managing)
      return 'Tüm Kayıtlar';
    return 'Bildirim Listesi';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(filteredReportListProvider);
    final currentUser = ref.watch(currentUserProvider);
    //final showSenderInfo = currentUser != null && currentUser.role != UserRole.citizen;
    final currentStatus = ref.watch(filterStatusProvider);
    final isCitizen = currentUser?.role == UserRole.citizen;

    // Tema Değişkenleri
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    final appBarBgColor = isDarkMode
        ? colorScheme.surface
        : const Color(0xFF1E293B);
    final appBarFgColor = isDarkMode ? colorScheme.onSurface : Colors.white;
    final appBarSubtitleColor = isDarkMode
        ? colorScheme.onSurfaceVariant
        : Colors.grey.shade400;

    return Scaffold(
      backgroundColor: isDarkMode ? colorScheme.surface : Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: appBarBgColor,
        foregroundColor: appBarFgColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Merhaba, ${currentUser?.name ?? 'Kullanıcı'}',
              style: TextStyle(
                fontSize: 13,
                color: appBarSubtitleColor,
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              _getPageTitle(currentUser?.role),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          const NotificationBell(),
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.tune),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        backgroundColor: colorScheme.surface,
        child: const SafeArea(child: FilterDrawerContent()),
      ),
      floatingActionButton: const CreateReportFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          // YATAY DURUM FİLTRELERİ
          Container(
            width: double.infinity,
            color: isDarkMode ? colorScheme.surface : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: const Text('Tümü'),
                      selected: currentStatus == null,
                      onSelected: (selected) {
                        if (selected)
                          ref.read(filterStatusProvider.notifier).state = null;
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: isDarkMode
                          ? colorScheme.surfaceContainerHighest
                          : Colors.grey.shade100,
                      selectedColor: isDarkMode
                          ? colorScheme.primary.withValues(alpha: 0.3)
                          : const Color(0xFF1E293B),
                      labelStyle: TextStyle(
                        color: currentStatus == null
                            ? (isDarkMode ? colorScheme.primary : Colors.white)
                            : colorScheme.onSurfaceVariant,
                        fontWeight: currentStatus == null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      side: BorderSide.none,
                    ),
                  ),
                  ...ReportStatus.values.map((status) {
                    final isSelected = currentStatus == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(getStatusLabel(status)),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected)
                            ref.read(filterStatusProvider.notifier).state =
                                status;
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        backgroundColor: isDarkMode
                            ? colorScheme.surfaceContainerHighest
                            : Colors.grey.shade100,
                        selectedColor: isDarkMode
                            ? colorScheme.primary.withValues(alpha: 0.3)
                            : const Color(0xFF1E293B),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? (isDarkMode
                                    ? colorScheme.primary
                                    : Colors.white)
                              : colorScheme.onSurfaceVariant,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        side: BorderSide.none,
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // LİSTE ALANI
          Expanded(
            child: reportAsync.when(
              data: (reports) {
                if (reports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Henüz bildirim yok',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(reportListProvider);
                    try {
                      await ref.read(reportListProvider.future);
                    } catch (_) {}
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      final senderName = report.senderName ?? 'Bilinmiyor';
                      final statusColor = colorForStatus(report.status);

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ReportDetailScreen(report: report),
                            ),
                          );
                        },

                        child: isCitizen
                            ? _buildCitizenCard(
                                report,
                                statusColor,
                                colorScheme,
                                isDarkMode,
                              )
                            : _buildStaffCard(
                                report,
                                statusColor,
                                colorScheme,
                                isDarkMode,
                              ),
                      );
                    },
                  ),
                );
              },
              error: (error, stackTrace) => Center(
                child: Text(
                  'Bir hata oluştu: $error',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }

  // vatandaş görünümü
  Widget _buildCitizenCard(
    Report report,
    Color statusColor,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Sol Renkli Çizgi
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            // 2. Orta İçerik
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kategori ve Durum Etiketi
                    Row(
                      children: [
                        Icon(
                          getCategoryIcon(report.category),
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          getCategoryLabel(report.category),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            getStatusLabel(report.status),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Başlık ve Açıklama
                    Text(
                      report.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      report.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Adres ve Gönderen
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            report.fullAddress ?? 'Adres belirtilmemiş',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.outline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // 3. Sağ Resim Thumbnail (Eğer varsa)
            if (report.imagePaths.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 85,
                    height:
                        100, // Yüksekliği hafif artırdık, IntrinsicHeight ile uyumlu esner
                    child: report.imagePaths.first.startsWith('http') || kIsWeb
                        ? Image.network(
                            report.imagePaths.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholderImage(colorScheme),
                          )
                        : Image.file(
                            File(report.imagePaths.first),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholderImage(colorScheme),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.broken_image, color: colorScheme.outline),
    );
  }

  // personel ve yönetici görünümü
  Widget _buildStaffCard(
    Report report,
    Color statusColor,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              getCategoryIcon(report.category),
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${getCategoryLabel(report.category)} - ${report.fullAddress ?? "Adres yok"}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                getStatusLabel(report.status),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: colorScheme.outline, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class FilterDrawerContent extends ConsumerStatefulWidget {
  const FilterDrawerContent({super.key});

  @override
  ConsumerState<FilterDrawerContent> createState() =>
      _FilterDrawerContentState();
}

class _FilterDrawerContentState extends ConsumerState<FilterDrawerContent> {
  ReportCategory? _tempCategory;

  @override
  void initState() {
    super.initState();
    _tempCategory = ref.read(filterCategoryProvider);
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
                        onPressed: () {
                          setState(() {
                            _tempCategory = null;
                          });
                        },
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
                      'Kategori',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    initiallyExpanded:
                        true, // Zaten tek filtre olduğu için açık gelsin
                    children: [
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          FilterChip(
                            label: const Text('Tüm Kategoriler'),
                            selected: _tempCategory == null,
                            onSelected: (_) {
                              setState(() {
                                _tempCategory = null;
                              });
                            },
                            backgroundColor: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            selectedColor: colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                            side: BorderSide.none,
                          ),
                          ...ReportCategory.values.map((category) {
                            final isSelected = _tempCategory == category;
                            return FilterChip(
                              avatar: Icon(
                                getCategoryIcon(category),
                                size: 16,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              label: Text(getCategoryLabel(category)),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _tempCategory = isSelected ? null : category;
                                });
                              },
                              backgroundColor: colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              selectedColor: colorScheme.primary.withValues(
                                alpha: 0.2,
                              ),
                              side: BorderSide.none,
                            );
                          }).toList(),
                        ],
                      ),
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
              // Sadece kategori provider'ını güncelliyoruz, durum (status) zaten ana ekrandan yönetiliyor
              ref.read(filterCategoryProvider.notifier).state = _tempCategory;
              Navigator.pop(context);
            },
            child: const Text('Sonuçları Göster'),
          ),
        ),
      ],
    );
  }
}
