import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Long-press quick actions for staff list tiles.
Future<void> showStaffQuickActionsSheet({
  required BuildContext context,
  required String staffName,
  required VoidCallback onEdit,
  required VoidCallback onRemove,
}) {
  final isSw = Get.locale?.languageCode == 'sw';
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
                staffName,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(isSw ? 'Hariri' : 'Edit'),
            onTap: () {
              Navigator.pop(ctx);
              onEdit();
            },
          ),
          ListTile(
            leading: Icon(Icons.person_remove_outlined, color: Theme.of(ctx).colorScheme.error),
            title: Text(
              isSw ? 'Ondoa' : 'Remove',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
            onTap: () {
              Navigator.pop(ctx);
              onRemove();
            },
          ),
        ],
      ),
    ),
  );
}
