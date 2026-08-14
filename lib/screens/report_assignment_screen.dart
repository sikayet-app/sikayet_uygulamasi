import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikayet_uygulamasi/data/models/report.dart';
import 'package:sikayet_uygulamasi/providers/report_provider.dart';
import 'package:sikayet_uygulamasi/providers/auth_provider.dart';
import '../widgets/app_card.dart';
import '../core/report_ui_helpers.dart';
import '../core/app_colors.dart';

// 2 ayrı durum için 2 ayrı sayfalamalı liste sağlayıcısı oluştur
// .family sayesinde aynı notifier ı farklı parametrelerle çoğaltabilirsin

class ReportAssignmentScreen extends ConsumerStatefulWidget {
  const ReportAssignmentScreen({super.key});

  @override
  ConsumerState<ReportAssignmentScreen> createState() =>
      _ReportAssignmentScreenState();
}

// TabController kullanabilmek için SingleTickerProviderStateMixin ekliyoruz
class _ReportAssignmentScreenState extends ConsumerState<ReportAssignmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 2 Sekme: Bekleyenler (0), İşlemde (1)
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ekrana girildiği an personelleri arka planda yükle (Önbellekleme).
    // Böylece butona basıldığında bekleme yaşanmaz.
    ref.watch(staffListProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? colorScheme.surface
          : AppColors.surfaceWarmLight,
      appBar: AppBar(
        title: const Text('Şikayetler ve İş Atama'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.primary,
          tabs: const [
            Tab(text: 'Bekleyenler (Yeni)'),
            Tab(text: 'İşlemde Olanlar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // SEKME 1: Bekleyenler
          _AssignmentListView(
            status: ReportStatus.pending,
            emptyMessage: 'Atanacak yeni şikayet bulunmuyor.',
          ),
          // SEKME 2: İşlemde Olanlar
          _AssignmentListView(
            status: ReportStatus.inProgress,
            emptyMessage: 'Sahada işlemde olan şikayet bulunmuyor.',
          ),
        ],
      ),
    );
  }
}

// İki sekme için de kullanılacak ortak liste widget'ı
class _AssignmentListView extends ConsumerStatefulWidget {
  final ReportStatus status;
  final String emptyMessage;

  const _AssignmentListView({required this.status, required this.emptyMessage});

  @override
  ConsumerState<_AssignmentListView> createState() =>
      _AssignmentListViewState();
}

class _AssignmentListViewState extends ConsumerState<_AssignmentListView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // En alta gelince ilgili sekmenin provider'ından yeni sayfa iste
        ref.read(assignmentTabProvider(widget.status).notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sadece bu sekmenin durumuna ait state'i dinle
    final state = ref.watch(assignmentTabProvider(widget.status));

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(child: Text('Hata: ${state.error}'));
    }

    if (state.reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 64,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(widget.emptyMessage, style: const TextStyle(fontSize: 16)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        // İlgili sekmeyi baştan yükle
        final notifier = ref.read(
          assignmentTabProvider(widget.status).notifier,
        );
        notifier.state = const ReportListState(isLoading: true);
        final result = await ref
            .read(reportRepositoryProvider)
            .getReportsPage(page: 1, status: widget.status.name);
        notifier.state = ReportListState(
          reports: result.items,
          currentPage: result.currentPage,
          hasMore: result.hasMore,
          isLoading: false,
        );
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        itemCount: state.reports.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
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
          final statusBgColor = getStatusBgColor(
            report.status,
            isDarkMode: isDarkMode,
          );
          final canAssign = report.canAssignReport;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: AppCard(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          report.status == ReportStatus.pending
                              ? 'Bekliyor'
                              : 'İşlemde',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        getFormattedDate(report.createdAt),
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          getCategoryIcon(report.category),
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          report.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          report.fullAddress ?? 'Adres belirtilmemiş',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SORUMLU PERSONEL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.outline,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report.assignedStaffName ?? 'Henüz atanmadı',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: report.assignedStaffName == null
                                  ? colorForStatus(
                                      ReportStatus.rejected,
                                      isDarkMode: isDarkMode,
                                    )
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      if (canAssign)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            report.status == ReportStatus.pending
                                ? Icons.person_add_alt_1
                                : Icons.edit,
                            size: 18,
                          ),
                          label: Text(
                            report.status == ReportStatus.pending
                                ? 'Personel Ata'
                                : 'Güncelle',
                          ),
                          onPressed: () {
                            _showStaffSelectionSheet(
                              context,
                              ref,
                              report,
                              widget.status,
                              colorScheme,
                              isDarkMode,
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showStaffSelectionSheet(
    BuildContext context,
    WidgetRef ref,
    Report report,
    ReportStatus currentTabStatus,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          final staffAsync = ref.watch(staffListProvider);
          return Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  report.assignedStaffId == null
                      ? 'Personel Ata'
                      : 'Personeli Güncelle',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: staffAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Hata: $err')),
                  data: (staffList) {
                    if (staffList.isEmpty) {
                      return const Center(
                        child: Text('Sistemde kayıtlı personel bulunamadı.'),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: staffList.length,
                      itemBuilder: (context, index) {
                        final staff = staffList[index];
                        final isCurrentlyAssigned =
                            report.assignedStaffId == staff.id;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCurrentlyAssigned
                                ? colorScheme.primary
                                : colorScheme.primaryContainer,
                            child: Text(
                              getInitials(staff.name),
                              style: TextStyle(
                                color: isCurrentlyAssigned
                                    ? colorScheme.onPrimary
                                    : colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            staff.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isCurrentlyAssigned
                                  ? colorScheme.primary
                                  : null,
                            ),
                          ),
                          subtitle: Text(staff.email),
                          trailing: isCurrentlyAssigned
                              ? Icon(
                                  Icons.check_circle,
                                  color: colorScheme.primary,
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: isCurrentlyAssigned
                              ? null
                              : () async {
                                  try {
                                    if (report.assignedStaffId == null) {
                                      await ref
                                          .read(reportRepositoryProvider)
                                          .assignReport(report.id, staff.id);
                                    } else {
                                      await ref
                                          .read(reportRepositoryProvider)
                                          .updateAssignedStaff(
                                            report.id,
                                            staff.id,
                                          );
                                    }
                                    // SADECE İŞLEM YAPILAN SEKMEYİ YENİLE
                                    final notifier = ref.read(
                                      assignmentTabProvider(
                                        currentTabStatus,
                                      ).notifier,
                                    );
                                    notifier.state = const ReportListState(
                                      isLoading: true,
                                    );
                                    final result = await ref
                                        .read(reportRepositoryProvider)
                                        .getReportsPage(
                                          page: 1,
                                          status: currentTabStatus.name,
                                        );
                                    notifier.state = ReportListState(
                                      reports: result.items,
                                      currentPage: result.currentPage,
                                      hasMore: result.hasMore,
                                      isLoading: false,
                                    );

                                    // Dashboard grafiklerini yenile
                                    ref.invalidate(reportListProvider);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${staff.name} başarıyla atandı.',
                                          ),
                                          backgroundColor:
                                              Colors.green.shade700,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Atama yapılamadı: $e'),
                                          backgroundColor: colorScheme.error,
                                        ),
                                      );
                                    }
                                  }
                                },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
