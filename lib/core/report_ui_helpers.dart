import 'package:intl/intl.dart';

import '../data/models/report.dart';
import '../data/models/user.dart';
import 'package:flutter/material.dart';

Color colorForStatus(ReportStatus status, {bool isDarkMode = false}) {
  switch (status) {
    case ReportStatus.pending: 
      return isDarkMode ? Colors.grey.shade400 : const Color(0xFF757575);
    case ReportStatus.inProgress: 
      return isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFF854F0B); // Açık Amber / Koyu Amber
    case ReportStatus.resolved: 
      return isDarkMode ? const Color(0xFF34D399) : const Color(0xFF085041); // Açık Teal / Koyu Teal
    case ReportStatus.rejected: 
      return isDarkMode ? const Color(0xFFF87171) : const Color(0xFFC1493B); // Açık Kırmızı / Koyu Kırmızı
    case ReportStatus.invalid: 
      return isDarkMode ? Colors.grey.shade500 : Colors.black54;
  }
}
// 2. Şikayet Durumu Arka Plan (Tint) Renkleri (Koyu Tema Uyumlu)
Color getStatusBgColor(ReportStatus status, {bool isDarkMode = false}) {
  if (isDarkMode) {
    // Koyu temada fosforlu renkler yerine, ana rengin %15 şeffaf hali kullanılır.
    return colorForStatus(status, isDarkMode: true).withValues(alpha: 0.15);
  }

  // Açık tema için orijinal pastel (tint) tasarım renklerin
  switch (status) {
    case ReportStatus.pending: return const Color(0xFFE5E5E5);
    case ReportStatus.inProgress: return const Color(0xFFFAEEDA);
    case ReportStatus.resolved: return const Color(0xFFE1F5EE);
    case ReportStatus.rejected: return const Color(0xFFF9EAE8);
    case ReportStatus.invalid: return Colors.grey.shade200;
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


