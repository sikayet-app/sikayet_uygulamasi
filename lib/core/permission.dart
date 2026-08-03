/*
import '../data/models/user.dart';
import '../data/models/report.dart';

bool canViewAllReports(UserRole role) {
  return role == UserRole.admin || role == UserRole.managing;
}


bool canEditReport(Report report, User currentUser) {
  if (currentUser.role == UserRole.citizen) {
    return report.userId == currentUser.id &&
        report.status == ReportStatus.pending;
  }
  return false;
}

bool canDeleteReport(Report report, User currentUser) {
  // sistem yöneticisi her şeyi silebilir
  if (currentUser.role == UserRole.admin) return true;
  // sorumlu,gereksiz ve saçma şikayetleri silebilir.
  if (currentUser.role == UserRole.managing) return true;
  // vatandaş sadece kendi şikayetini ve sadece bekleme aşamasındaysa silebilir
  if (currentUser.role == UserRole.citizen) {
    return report.userId == currentUser.id &&
        report.status == ReportStatus.pending;
  }
  return false;


bool canUpdateStatus(Report report, User currentUser) {
  // sorumlu herkesin durumunu güncelleyebilir
  if (currentUser.role == UserRole.managing) return true;
  //personel sadece kendisine atanan şikayetlerin durumunu güncelleyebilir
  if (currentUser.role == UserRole.staff) {
    return report.assignedStaffId == currentUser.id;
  }
  return false;
}

bool canAssignReport(UserRole role) {
  return role == UserRole.managing;
}


bool canViewUsers(UserRole role) {
  return role == UserRole.admin || role == UserRole.managing;
}

bool canManageManaging(UserRole role) {
  return role == UserRole.admin;
}

bool canViewAssignedReportsOnly(UserRole role) {
  return role == UserRole.staff;
}

bool canCreateReport(UserRole role) {
  return role == UserRole.citizen;
}
}*/