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
