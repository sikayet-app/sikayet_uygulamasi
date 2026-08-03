import 'dart:io';

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
        title: const Text('Şikayet Listesi'),
        actions: [
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ), // sadece üst köşeler yuvarlak oldu
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
                              'Durum',
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
                                      ref.watch(filterStatusProvider) == null,
                                  onSelected: (_) {
                                    ref
                                            .read(filterStatusProvider.notifier)
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
                                ...ReportStatus.values.map((status) {
                                  final isSelected =
                                      ref.watch(filterStatusProvider) == status;

                                  return FilterChip(
                                    label: Text(getStatusLabel(status)),
                                    selected: isSelected,
                                    onSelected: (_) {
                                      ref
                                          .read(filterStatusProvider.notifier)
                                          .state = isSelected
                                          ? null
                                          : status;
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
                            const SizedBox(height: 16),
                            const Text(
                              'Kategori',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: [
                                FilterChip(
                                  label: Text('Tüm Kategoriler'),
                                  selected:
                                      ref.watch(filterCategoryProvider) == null,
                                  onSelected: (_) {
                                    ref
                                            .read(
                                              filterCategoryProvider.notifier,
                                            )
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
                                ...ReportCategory.values.map((category) {
                                  final isSelected =
                                      ref.watch(filterCategoryProvider) ==
                                      category;
                                  return FilterChip(
                                    label: Text(getCategoryLabel(category)),
                                    selected: isSelected,
                                    onSelected: (_) {
                                      ref
                                          .read(filterCategoryProvider.notifier)
                                          .state = isSelected
                                          ? null
                                          : category;
                                    },
                                    backgroundColor: Colors.grey.withValues(
                                      alpha: 0.1,
                                    ),
                                    selectedColor: Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.2),
                                    side: BorderSide.none,
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
            icon: Icon(Icons.filter_list),
          ),
        ],
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        report.imagePaths.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child:
                                    report.imagePaths.first.startsWith('http')
                                    ? Image.network(
                                        report.imagePaths.first,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  width: 50,
                                                  height: 50,
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                      )
                                    : Image.file(
                                        File(report.imagePaths.first),
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  width: 50,
                                                  height: 50,
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
                                width: 50,
                                height: 50,
                                child: Icon(Icons.report_problem),
                                alignment: Alignment.center,
                              ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),

                              SizedBox(height: 6),

                              Text(
                                report.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(),
                              ),

                              SizedBox(height: 6),

                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${getCategoryLabel(report.category)}',
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: colorForStatus(report.status),
                                    ),
                                    child: Text(
                                      '${getStatusLabel(report.status)}',
                                    ),
                                  ),
                                ],
                              ),
                              if (showSenderInfo) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Gönderen: $senderName',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
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
