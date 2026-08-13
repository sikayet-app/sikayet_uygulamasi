import 'package:intl/intl.dart';
import 'app_colors.dart';
import '../data/models/report.dart';
import '../data/models/user.dart';
import 'package:flutter/material.dart';

Color colorForStatus(ReportStatus status, {bool isDarkMode = false}) {
  switch (status) {
    case ReportStatus.pending:
      return isDarkMode ? AppColors.pendingFgDark : AppColors.pendingFg;
    case ReportStatus.inProgress:
      return isDarkMode ? AppColors.inProgressFgDark : AppColors.inProgressFg;
    case ReportStatus.resolved:
      return isDarkMode ? AppColors.resolvedFgDark : AppColors.resolvedFg;
    case ReportStatus.rejected:
      return isDarkMode ? AppColors.rejectedFgDark : AppColors.rejectedFg;
    case ReportStatus.invalid:
      return isDarkMode ? AppColors.invalidFgDark : AppColors.invalidFg;
}
}
// 2. Şikayet Durumu Arka Plan (Tint) Renkleri (Koyu Tema Uyumlu)
Color getStatusBgColor(ReportStatus status, {bool isDarkMode = false}) {
  if (isDarkMode) {
    
    return colorForStatus(status, isDarkMode: true).withValues(alpha: 0.15);
  }
  switch (status) {
    case ReportStatus.pending: return AppColors.pendingBg;
    case ReportStatus.inProgress: return AppColors.inProgressBg;
    case ReportStatus.resolved: return AppColors.resolvedBg;
    case ReportStatus.rejected: return AppColors.rejectedBg;
    case ReportStatus.invalid: return AppColors.invalidBg;
  }
}

String getFormattedDate(DateTime date) {
  return DateFormat('dd.MM.yyyy HH:mm').format(date);
}

IconData getCategoryIcon(ReportCategory category) {
  switch (category) {
    case ReportCategory.infrastructure:
    return Icons.construction;
    case ReportCategory.lighting:
    return Icons.lightbulb_outline;
    case ReportCategory.garbage:
    return Icons.delete_outline;
    case ReportCategory.pothole:
    return Icons.edit_road;
    case ReportCategory.other:
    return Icons.label_outline;
  }
}

// 5. Rol Renkleri (Koyu Tema Uyumlu)
Color getColorForRole(UserRole role, {bool isDarkMode = false}) {
  switch (role) {
    case UserRole.admin:
    case UserRole.staff:
      return isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF1E293B); 
    case UserRole.managing:
      return isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFFD97706); 
    case UserRole.citizen:
      return isDarkMode ? Colors.grey.shade400 : const Color(0xFF9A988E); 
  }
}

// 6. İsimden Baş Harf Bulucu
String getInitials(String name) {
  List<String> names = name.trim().split(RegExp(r'\s+'));
  String initials = "";
  int numWords = names.length > 2 ? 2 : names.length;
  for (int i = 0; i < numWords; i++) {
    if (names[i].isNotEmpty) {
      initials += names[i][0].toUpperCase();
    }
  }
  return initials;
}


