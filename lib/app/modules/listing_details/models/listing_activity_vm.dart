import 'package:flutter/material.dart';

enum ActivityType {
  expense,
  income,
  tenant,
  maintenance,
  staff,
  unit,
  remote,
}

class ListingActivityVm {
  ListingActivityVm({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.timeLabel,
    required this.accentColor,
    this.activityType = ActivityType.remote,
    this.expenseId,
    this.incomeId,
    this.tenantId,
    this.maintenanceId,
    this.staffId,
    this.unitLocalId,
    this.unitLocalPropertyRef,
    this.unitLocalName,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final String timeLabel;
  final Color accentColor;

  final ActivityType activityType;

  /// Local SQLite row IDs — set for the matching activity type.
  final int? expenseId;
  final int? incomeId;
  final int? tenantId;
  final int? maintenanceId;
  final int? staffId;
  final int? unitLocalId;

  /// Extra context needed to open the EDIT_UNIT route.
  final String? unitLocalPropertyRef;
  final String? unitLocalName;

  bool get isExpense => activityType == ActivityType.expense;
  bool get isIncome => activityType == ActivityType.income;
  bool get isTenant => activityType == ActivityType.tenant;
  bool get isMaintenance => activityType == ActivityType.maintenance;
  bool get isStaff => activityType == ActivityType.staff;
  bool get isUnit => activityType == ActivityType.unit;
  bool get isRemote => activityType == ActivityType.remote;

  /// True when this activity can be navigated to for editing.
  bool get canEdit => !isRemote;

  /// True when this activity has a local row that can be deleted.
  bool get canDelete =>
      expenseId != null ||
      incomeId != null ||
      tenantId != null ||
      maintenanceId != null ||
      staffId != null ||
      unitLocalId != null;
}
