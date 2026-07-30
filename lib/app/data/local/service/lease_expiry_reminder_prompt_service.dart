import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/service/launch_prompt_gate.dart';
import '../db/recurring_reminder_local_data_source.dart';
import '../../repository/app_repository.dart';

/// Prompts the host when a tenant lease has expired but recurring reminders are active.
class LeaseExpiryReminderPromptService extends GetxService {
  LeaseExpiryReminderPromptService({
    required RecurringReminderLocalDataSource recurringLocal,
    required AppRepository repository,
  })  : _recurringLocal = recurringLocal,
        _repository = repository;

  final RecurringReminderLocalDataSource _recurringLocal;
  final AppRepository _repository;
  bool _showing = false;

  Future<void> maybePrompt() async {
    if (_showing) return;
    if (Get.context == null) return;
    final pending = await _recurringLocal.getPendingLeaseDecisions();
    if (pending.isEmpty) return;
    // Prefer lease decisions over review/tips, but never stack soft prompts.
    if (Get.isRegistered<LaunchPromptGate>() &&
        !Get.find<LaunchPromptGate>().tryClaimSoftPrompt()) {
      return;
    }
    _showing = true;
    final row = pending.first;
    final isSw = Get.locale?.languageCode == 'sw';
    final context = Get.context!;
    if (!context.mounted) {
      _showing = false;
      return;
    }

    final decision = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSw ? 'Mkataba Umeisha' : 'Lease Expired'),
        content: Text(
          isSw
              ? 'Mkataba wa ${row.tenantName} (${row.propertyLabel}) umeisha. Endelea kutuma vikumbusho?'
              : '${row.tenantName}\'s lease at ${row.propertyLabel} has ended. Continue sending reminders?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isSw ? 'Ondoa' : 'Remove'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isSw ? 'Endelea' : 'Continue'),
          ),
        ],
      ),
    );

    final continueAfter = decision == true;
    await _recurringLocal.updateLeaseDecision(
      id: row.id,
      continueAfterLeaseExpiry: continueAfter ? 1 : 0,
      active: continueAfter,
    );
    if (row.backendId.isNotEmpty) {
      try {
        await _repository.updateRecurringReminderLeaseDecision(
          row.backendId,
          continueAfterLeaseExpiry: continueAfter,
        );
      } catch (_) {}
    }
    _showing = false;
    if (pending.length > 1) {
      await maybePrompt();
    }
  }
}
