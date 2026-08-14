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
import '../core/app_colors.dart';

class ReportListScreen extends ConsumerStatefulWidget {
  final ReportStatus? initialStatusFilter;
  const ReportListScreen({super.key, this.initialStatusFilter});
  @override
  ConsumerState<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends ConsumerState<ReportListScreen> {
  
  // sonsuz kaydırma için controller
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // liste aşağı kaydırıldıkça yeni sayfa yüklenmesi için dinleyici
    _scrollController.addListener(() {
      if(_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(filteredReportListProvider.notifier).loadMore();
      }
    });
    // Ekran açıldığında parametre varsa Riverpod state'ine yazdırıyoruz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(filterCategoryProvider.notifier).state = null;
      ref.read(filterStatusProvider.notifier).state =
          widget.initialStatusFilter;
    });
  }

  // controller ı temizle ve filtreleri sıfırla ki diğer ekranlar bozulmasın
   @override
  void dispose() {
    _scrollController.dispose();
    Future.microtask(() {
      if (mounted) {
        ref.read(filterStatusProvider.notifier).state = null;
        ref.read(filterCategoryProvider.notifier).state = null;
      }
    });
    super.dispose();
  }

  String _getPageTitle(List<String>? permissions) {
    if (permissions == null) return 'Bildirim Listesi';
    if (permissions.contains('view_users')) return 'Tüm Kayıtlar';
    if (permissions.contains('update_report_status')) return 'Görevlerim';
    return 'Taleplerim';
  }


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(filteredReportListProvider);
    final currentUser = ref.watch(currentUserProvider);
    final currentStatus = ref.watch(filterStatusProvider);

    final useCompactCard =
        currentUser?.permissions.contains('update_report_status') ?? false;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    final appBarBgColor = isDarkMode ? colorScheme.surface : AppColors.navy;
    final appBarFgColor = isDarkMode ? colorScheme.onSurface : Colors.white;
    final appBarSubtitleColor = isDarkMode
        ? colorScheme.onSurfaceVariant
        : Colors.grey.shade400;

    return Scaffold(
      backgroundColor: isDarkMode
          ? colorScheme.surface
          : AppColors.surfaceWarmLight,
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
              _getPageTitle(currentUser?.permissions),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          const NotificationBell(),
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.tune),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              );
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        backgroundColor: colorScheme.surface,
        child: const SafeArea(child: FilterDrawerContent()),
      ),

      floatingActionButton:
          currentUser?.permissions.contains('add_report') == true
          ? const Padding(
              padding: EdgeInsets.only(bottom: 90.0),
              child: CreateReportFab(),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
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
                          : AppColors.navy,
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
                            : AppColors.navy,
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
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(
                        child: Text(
                          'Bir hata oluştu: ${state.error}',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      )
                    : state.reports.isEmpty
                        ? Center(
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
                  )
                
                : RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(filteredReportListProvider.notifier).loadFirstPage();
                              ref.invalidate(reportListProvider);
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(
                      top: 8,
                      bottom: 120,
                    ), // LİSTE ALT BOŞLUĞU EKLENDİ
                    itemCount: state.reports.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {

                      // En alta inildi ve hala sayfa varsa Loading dairesi göster
                                if (index >= state.reports.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  );
                                }
                      final report = state.reports[index];
                      final statusColor = colorForStatus(
                        report.status,
                        isDarkMode: isDarkMode,
                      );
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ReportDetailScreen(report: report),
                            ),
                          ).then((_) {
                            // Detaydan geri dönünce listeyi 1. sayfadan tazele
                            ref.read(filteredReportListProvider.notifier).loadFirstPage();
                          });
                        },
                        child: !useCompactCard
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
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            color: getStatusBgColor(
                              report.status,
                              isDarkMode: isDarkMode,
                            ),
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
            if (report.imagePaths.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 85,
                    height: 100,
                    child: report.imagePaths.first.startsWith('http') || kIsWeb
                        ? Image.network(
                            report.imagePaths.first,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                _buildPlaceholderImage(colorScheme),
                          )
                        : Image.file(
                            File(report.imagePaths.first),
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: getStatusBgColor(report.status, isDarkMode: isDarkMode),
              borderRadius: BorderRadius.circular(8),
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
                    initiallyExpanded: true,
                    children: [
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          FilterChip(
                            avatar: Icon(
                              Icons.category,
                              size: 16,
                              color: _tempCategory == null
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
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

                            labelStyle: TextStyle(
                              color: _tempCategory == null
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                            ),
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

                              labelStyle: TextStyle(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
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
