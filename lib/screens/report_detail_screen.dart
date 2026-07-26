import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikayet_uygulamasi/core/report_ui_helpers.dart';
import 'package:sikayet_uygulamasi/providers/auth_provider.dart';
import 'package:sikayet_uygulamasi/providers/report_provider.dart';
import 'package:sikayet_uygulamasi/screens/create_report_screen.dart';
import '../data/models/report.dart';
import 'dart:io';
import '../core/permission.dart';

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

    //onaylandıysa sil
    await ref.read(reportRepositoryProvider).deleteReport(_currentReport.id);
    ref.invalidate(reportListProvider);

    //detay sayfasından çık
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();
    final canEdit = canEditReport(_currentReport, currentUser);
    final canDelete = canDeleteReport(_currentReport, currentUser);
    final canChangeStatus = canUpdateStatus(currentUser.role);
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentReport.title),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_currentReport.imagePaths.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _currentReport.imagePaths.map((image) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(image),
                      height: 100,
                      width: 110,
                      fit: BoxFit.cover,
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 16),
            Text(
              _currentReport.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            if (canChangeStatus) ...[
              ref
                  .watch(userByIdProvider(_currentReport.userId))
                  .when(
                    data: (user) => Text(
                      'Gönderen: ${user?.name ?? "Bilinmiyor"}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    loading: () => const Text(
                      'Göndern yükleniyor...',
                      style: TextStyle(color: Colors.grey),
                    ),
                    error: (e, st) => const SizedBox.shrink(),
                  ),
              const SizedBox(height: 12),
            ],
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
                      await ref
                          .read(reportRepositoryProvider)
                          .updateStatus(_currentReport.id, newStatus);
                      setState(() {
                        _currentReport = _currentReport.copyWith(
                          status: newStatus,
                        );
                      });
                      ref.invalidate(reportListProvider);
                    },
                    // menüdeki seçenekleri oluştur
                    itemBuilder: (context) => ReportStatus.values.map((status) {
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
          ],
        ),
      ),
    );
  }
}
