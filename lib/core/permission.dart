import '../data/models/user.dart';
import '../data/models/report.dart';

bool canViewAllReports(UserRole role) {
  return role == UserRole.admin;
}

bool canEditReport(Report report, User currentUser) {
  if (currentUser.role == UserRole.admin) return true;
  return report.userId == currentUser.id;
}

bool canDeleteReport(Report report, User currentUser) {
  if (currentUser.role == UserRole.admin) return true;
  return report.userId == currentUser.id;
}

bool canUpdateStatus(UserRole role) {
  return role == UserRole.admin;
}
