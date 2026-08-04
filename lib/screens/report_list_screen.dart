import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sikayet_uygulamasi/core/report_ui_helpers.dart';
import 'package:sikayet_uygulamasi/providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../data/models/report.dart';
import 'report_detail_screen.dart';
import '../data/models/user.dart';

class ReportListScreen extends ConsumerWidget {
  const ReportListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(filteredReportListProvider);
    final currentUser = ref.watch(currentUserProvider);
    final showSenderInfo =
        currentUser != null && currentUser.role != UserRole.citizen;
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        centerTitle: true,
        title: const Text('Şikayet Listesi'),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: Icon(Icons.filter_list),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: SafeArea(child: const FilterDrawerContent()),
      ),
      body: reportAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  const Text('Henüz bildirim yok'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final senderName = report.senderName ?? 'Bilinmiyor';
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),

                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ReportDetailScreen(report: report),
                      ),
                    );
                  },

                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.label, color: Colors.grey),
                            Text(getCategoryLabel(report.category)),
                            Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: colorForStatus(
                                  report.status,
                                ).withValues(alpha: 0.15),
                              ),
                              child: Text(
                                '${getStatusLabel(report.status)}',
                                style: TextStyle(
                                  color: colorForStatus(report.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        report.imagePaths.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child:
                                    report.imagePaths.first.startsWith(
                                          'http',
                                        ) ||
                                        kIsWeb
                                    ? Image.network(
                                        report.imagePaths.first,
                                        width: double.infinity,
                                        height: 180,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  width: double.infinity,
                                                  height: 180,
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                      )
                                    : Image.file(
                                        File(report.imagePaths.first),
                                        width: double.infinity,
                                        height: 180,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  width: double.infinity,
                                                  height: 180,
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                      ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey.withValues(alpha: 0.2),
                                ),
                                width: double.infinity,
                                height: 180,
                                child: Icon(Icons.report_problem),
                                alignment: Alignment.center,
                              ),

                        const SizedBox(height: 16),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),

                            SizedBox(height: 8),

                            Text(
                              report.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),

                            SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                Text(
                                  'Bekleniyor',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (showSenderInfo) ...[
                                  Spacer(),
                                  Text(
                                    'Gönderen: $senderName',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        error: (error, StackTrace) =>
            Center(child: Text('Bir hata oluştu: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
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
  ReportStatus? _tempStatus;
  ReportCategory? _tempCategory;

  @override
  void initState() {
    super.initState();
    _tempStatus = ref.read(filterStatusProvider);
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
                            _tempStatus = null;
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
                    textColor: Theme.of(context).primaryColor,
                    iconColor: Theme.of(context).primaryColor,
                    title: const Text(
                      'Durum',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),

                    initiallyExpanded: false,

                    children: [
                      Wrap(
                        spacing: 8.0, // yatay boşluk
                        runSpacing: 8.0, // alt satıra geçerse dikey boşluk
                        children: [
                          FilterChip(
                            label: const Text('Tümü'),
                            selected: _tempStatus == null,
                            onSelected: (_) {
                              setState(() {
                                _tempStatus = null;
                              });
                            },
                            backgroundColor: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            selectedColor: colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                            side: BorderSide.none,
                          ),
                          ...ReportStatus.values.map((status) {
                            final isSelected = _tempStatus == status;

                            return FilterChip(
                              label: Text(getStatusLabel(status)),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _tempStatus = isSelected ? null : status;
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
                      const SizedBox(height: 16),
                    ],
                  ),
                  ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    textColor: colorScheme.primary,
                    iconColor: colorScheme.primary,
                    title: const Text(
                      'Kategori',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    initiallyExpanded: false,
                    children: [
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          FilterChip(
                            label: Text('Tüm Kategoriler'),
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
              minimumSize: Size(double.infinity, 48),
            ),
            onPressed: () {
              ref.read(filterStatusProvider.notifier).state = _tempStatus;
              ref.read(filterCategoryProvider.notifier).state = _tempCategory;
              Navigator.pop(context);
            },
            child: Text('Sonuçları Göster'),
          ),
        ),
      ],
    );
  }
}
