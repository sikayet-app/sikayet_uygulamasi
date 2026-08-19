class CategoryStat {
  final String category;
  final int total;

  CategoryStat({required this.category, required this.total});

  factory CategoryStat.fromMap(Map<String, dynamic> map) {
    return CategoryStat(
      category: map['category'] ?? 'other',
      total: map['total'] ?? 0,
    );
  }
}

class MonthlyStat {
  final int month;
  final int total;

  MonthlyStat({required this.month, required this.total});

  factory MonthlyStat.fromMap(Map<String, dynamic> map) {
    return MonthlyStat(month: map['month'] ?? 1, total: map['total'] ?? 0);
  }
}

class DashboardStats {
  final int totalReports;
  final int pendingReports;
  final int inProgressReports;
  final int resolvedReports;
  final int rejectedReports;
  final int unfoundedReports;
  final int managingCount;
  final int staffCount;
  final int citizenCount;
  final List<CategoryStat> categoryBreakdown;
  final List<MonthlyStat> monthlyReports;

  DashboardStats({
    required this.totalReports,
    required this.pendingReports,
    required this.inProgressReports,
    required this.resolvedReports,
    required this.rejectedReports,
    required this.unfoundedReports,
    required this.managingCount,
    required this.staffCount,
    required this.citizenCount,
    required this.categoryBreakdown,
    required this.monthlyReports,
  });

  factory DashboardStats.fromMap(Map<String, dynamic> map) {
    return DashboardStats(
      totalReports: map['total_reports'] ?? 0,
      pendingReports: map['pending_reports'] ?? 0,
      inProgressReports: map['in_progress_reports'] ?? 0,
      resolvedReports: map['resolved_reports'] ?? 0,
      rejectedReports: map['rejected_reports'] ?? 0,
      unfoundedReports: map['unfounded_reports'] ?? 0,
      managingCount: map['managing_count'] ?? 0,
      staffCount: map['staff_count'] ?? 0,
      citizenCount: map['citizen_count'] ?? 0,
      categoryBreakdown:
          (map['category_breakdown'] as List<dynamic>?)
              ?.map((e) => CategoryStat.fromMap(e))
              .toList() ??
          [],
      monthlyReports:
          (map['monthly_reports'] as List<dynamic>?)
              ?.map((e) => MonthlyStat.fromMap(e))
              .toList() ??
          [],
    );
  }
}

class MyStats {
  final String role;
  final int assignedReports;
  final int openReports;
  final int resolvedReports;

  MyStats({
    required this.role,
    required this.assignedReports,
    required this.openReports,
    required this.resolvedReports,
  });

  factory MyStats.fromMap(Map<String, dynamic> map) {
    return MyStats(
      role: map['role'] ?? '',
      assignedReports: map['assigned_reports'] ?? map['total_reports'] ?? 0,
      openReports: map['open_reports'] ?? map['pending_reports'] ?? 0,
      resolvedReports: map['resolved_reports'] ?? 0,
    );
  }
}
