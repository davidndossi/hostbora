import 'package:flutter/material.dart';

class ListingActivityVm {
  ListingActivityVm({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.timeLabel,
    required this.accentColor,
    this.expenseId,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final String timeLabel;
  final Color accentColor;

  /// Set for expense-type activities to enable edit / delete actions.
  final int? expenseId;

  bool get isExpense => expenseId != null;
}
