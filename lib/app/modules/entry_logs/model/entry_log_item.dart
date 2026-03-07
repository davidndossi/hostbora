import 'package:flutter/material.dart';

enum EntryLogStatus { success, completed, manual, alert }

enum EntryLogIconType { phone, lock, key, keypad, warning }

class EntryLogItem {
  final String id;
  final EntryLogIconType iconType;
  final String title;
  final String detail;
  final String time;
  final EntryLogStatus status;
  final DateTime date;
  final bool isAppUnlock;
  final bool isPinCode;

  const EntryLogItem({
    required this.id,
    required this.iconType,
    required this.title,
    required this.detail,
    required this.time,
    required this.status,
    required this.date,
    this.isAppUnlock = false,
    this.isPinCode = false,
  });
}
