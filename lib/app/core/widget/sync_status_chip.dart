import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/item_sync_status.dart';
import '../theme/app_theme_tokens.dart';

/// Compact badge for offline queue state on list rows.
class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({
    super.key,
    required this.status,
    this.onRetry,
    this.compact = false,
  });

  final ItemSyncStatus status;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!status.showSyncBadge) return const SizedBox.shrink();

    final isSw = Get.locale?.languageCode == 'sw';
    final tokens = context.tokens;

    switch (status) {
      case ItemSyncStatus.pending:
      case ItemSyncStatus.syncing:
        return _badge(
          context,
          label: isSw ? 'Inasawazisha' : 'Syncing',
          background: tokens.warning.withValues(alpha: 0.18),
          foreground: tokens.warning,
          trailing: SizedBox(
            width: compact ? 10 : 12,
            height: compact ? 10 : 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: tokens.warning,
            ),
          ),
        );
      case ItemSyncStatus.failed:
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onRetry,
            borderRadius: BorderRadius.circular(4),
            child: _badge(
              context,
              label: isSw ? 'Gusa kujaribu' : 'Tap to retry',
              background: Theme.of(context).colorScheme.error.withValues(alpha: 0.12),
              foreground: Theme.of(context).colorScheme.error,
            ),
          ),
        );
      case ItemSyncStatus.synced:
        return const SizedBox.shrink();
    }
  }

  Widget _badge(
    BuildContext context, {
    required String label,
    required Color background,
    required Color foreground,
    Widget? trailing,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 6,
        vertical: compact ? 2 : 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) ...[
            trailing,
            SizedBox(width: compact ? 4 : 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
