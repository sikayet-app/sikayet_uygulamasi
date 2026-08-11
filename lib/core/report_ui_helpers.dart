import 'package:intl/intl.dart';

import '../data/models/report.dart';
import 'package:flutter/material.dart';

Color colorForStatus(ReportStatus status) {
  switch (status) {
    case ReportStatus.pending:
      return Colors.blue;
    case ReportStatus.inProgress:
      return Colors.orange;
    case ReportStatus.resolved:
      return Colors.green;
    case ReportStatus.rejected:
      return Colors.red;
    case ReportStatus.invalid:
      return Colors.grey.shade600;
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
