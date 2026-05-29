import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../modules/rent/manage_expenses/controllers/manage_expenses_controller.dart';
import '../models/item_sync_status.dart';

/// Long-press / contextual actions for a manage-expenses row.
Future<void> showExpenseRowQuickActionsSheet({
  required BuildContext context,
  required ManageExpensesRowUi row,
  required VoidCallback onRetrySync,
}) {
  final isSw = Get.locale?.languageCode == 'sw';
  final title = row.tenantName.isNotEmpty
      ? row.tenantName
      : (row.categoryLabel.isNotEmpty ? row.categoryLabel : '—');

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          if (row.apartmentLine.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.apartment_outlined),
              title: Text(row.apartmentLine),
              dense: true,
            ),
          ListTile(
            leading: const Icon(Icons.copy_outlined),
            title: Text(isSw ? 'Nakili maelezo' : 'Copy details'),
            onTap: () {
              final lines = <String>[
                if (row.tenantName.isNotEmpty) row.tenantName,
                if (row.apartmentLine.isNotEmpty) row.apartmentLine,
                if (row.categoryLabel.isNotEmpty) row.categoryLabel,
                if (row.notes.isNotEmpty) row.notes,
              ];
              Clipboard.setData(ClipboardData(text: lines.join('\n')));
              Navigator.pop(ctx);
              Get.snackbar(
                isSw ? 'Imenakiliwa' : 'Copied',
                isSw ? 'Maelezo yamekwenda kwenye ubao wa kunakili' : 'Expense details copied',
              );
            },
          ),
          if (row.syncStatus == ItemSyncStatus.failed)
            ListTile(
              leading: const Icon(Icons.sync),
              title: Text(isSw ? 'Jaribu kusawazisha tena' : 'Retry sync'),
              onTap: () {
                Navigator.pop(ctx);
                onRetrySync();
              },
            ),
        ],
      ),
    ),
  );
}
