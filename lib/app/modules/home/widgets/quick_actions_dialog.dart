import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/form_surface_colors.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/service/quick_action_intent_resolver.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import 'quick_add_expense_wizard.dart';
import 'quick_add_income_wizard.dart';
import 'quick_add_property_wizard.dart';

/// The five concrete actions the home quick-actions dialog can trigger,
/// either by direct tap or resolved from free text via AI ("Other").
enum QuickHomeAction {
  addProperty,
  addIncome,
  addExpense,
  addBooking,
  addTenant,
  sendReminder,
}

/// Shows the single Home **Create** menu and runs the chosen action
/// (tile tap or AI-resolved "Other"). Calls [onDataChanged] when an action
/// completes successfully.
///
/// [portfolioRole] filters options: `bnb` | `rent` | `both` (default).
Future<void> showCreateMenu({
  required Future<void> Function() onDataChanged,
  String portfolioRole = 'both',
}) async {
  final outcome = await Get.dialog<_OtherActionOutcome>(
    QuickActionsDialog(portfolioRole: portfolioRole),
    barrierDismissible: true,
  );
  if (outcome == null) return;

  final route = outcome.route;
  if (route != null) {
    await Get.toNamed(route);
    return;
  }

  final action = outcome.action;
  if (action == null) return;
  final saved = await _runQuickAction(action);
  if (saved == true) {
    await onDataChanged();
  }
}

/// @Deprecated — use [showCreateMenu].
Future<void> showQuickActionsDialog({
  required Future<void> Function() onDataChanged,
  String portfolioRole = 'both',
}) =>
    showCreateMenu(
      onDataChanged: onDataChanged,
      portfolioRole: portfolioRole,
    );

Future<bool?> _runQuickAction(QuickHomeAction action) {
  switch (action) {
    case QuickHomeAction.addProperty:
      return showQuickAddPropertyWizard();
    case QuickHomeAction.addIncome:
      return showQuickAddIncomeWizard();
    case QuickHomeAction.addExpense:
      return showQuickAddExpenseWizard();
    case QuickHomeAction.addBooking:
      return Get.toNamed(Routes.ADD_NEW_BOOKING)?.then((r) => r == true) ??
          Future.value(false);
    case QuickHomeAction.addTenant:
      return Get.toNamed(Routes.ADD_NEW_TENANT)?.then((r) => r == true) ??
          Future.value(false);
    case QuickHomeAction.sendReminder:
      return Get.toNamed(Routes.RENT_RECURRING_REMINDERS)?.then((r) => r == true) ??
          Future.value(false);
  }
}

QuickHomeAction? _actionFromIntent(QuickActionIntent intent) {
  switch (intent) {
    case QuickActionIntent.addProperty:
      return QuickHomeAction.addProperty;
    case QuickActionIntent.addIncome:
      return QuickHomeAction.addIncome;
    case QuickActionIntent.addExpense:
      return QuickHomeAction.addExpense;
    case QuickActionIntent.addBooking:
      return QuickHomeAction.addBooking;
    case QuickActionIntent.addTenant:
      return QuickHomeAction.addTenant;
    case QuickActionIntent.unknown:
      return null;
  }
}

/// Result of the "Other (Specify)" step: either one of the five headline
/// quick actions (handled the same way as a direct tile tap), or a plain
/// navigation to some other HostBora screen the AI matched the request to.
class _OtherActionOutcome {
  const _OtherActionOutcome.wizard(this.action) : route = null;
  const _OtherActionOutcome.route(this.route) : action = null;

  final QuickHomeAction? action;
  final String? route;
}

class QuickActionsDialog extends StatefulWidget {
  const QuickActionsDialog({super.key, this.portfolioRole = 'both'});

  /// `bnb` | `rent` | `both` — hides create options that don't apply.
  final String portfolioRole;

  @override
  State<QuickActionsDialog> createState() => _QuickActionsDialogState();
}

class _QuickActionsDialogState extends State<QuickActionsDialog> {
  bool _showOtherInput = false;
  final _otherController = TextEditingController();
  bool _resolving = false;
  String? _error;

  bool get _showBnbActions {
    final r = widget.portfolioRole;
    return r == 'bnb' || r == 'both' || r == 'all';
  }

  bool get _showRentActions {
    final r = widget.portfolioRole;
    return r == 'rent' || r == 'both' || r == 'all';
  }

  String _t(String en, String sw) =>
      Get.locale?.languageCode == 'sw' ? sw : en;

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  Future<void> _handleOtherSubmit() async {
    final text = _otherController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _resolving = true;
      _error = null;
    });
    try {
      final resolver = QuickActionIntentResolver(
        repository: Get.find<AppRepository>(tag: (AppRepository).toString()),
      );
      final resolution = await resolver.resolve(text);

      if (resolution.routeName != null) {
        Get.back(result: _OtherActionOutcome.route(resolution.routeName!));
        return;
      }

      final action = resolution.wizardAction == null
          ? null
          : _actionFromIntent(resolution.wizardAction!);
      if (action == null) {
        setState(() {
          _error = _t(
            'Sorry, cannot help you with this request.',
            'Samahani, siwezi kukusaidia na ombi hili.',
          );
        });
        return;
      }
      Get.back(result: _OtherActionOutcome.wizard(action));
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    // Flutter's [Dialog] adds MediaQuery.viewInsets (the keyboard) on top of
    // insetPadding, so opening the keyboard for the "Other" text field can
    // shrink the space available to the dialog well below its natural
    // content height, pushing it partly off-screen instead of resizing in
    // place. Capping the height against the *full* screen (not the
    // keyboard-shrunk remainder) and making the content shrink-wrap a
    // scroll view keeps the dialog fully visible and scrollable instead.
    final maxHeight = MediaQuery.of(context).size.height * 0.8;
    return Dialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 60),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _showOtherInput
                ? _buildOtherView(context)
                : _buildOptionsView(context),
          ),
        ),
      ),
    );
  }

  // Widget _buildOptionsView(BuildContext context) {
  //   final c = FormSurfaceColors.of(context);
  //   return Column(
  //     key: const ValueKey('options'),
  //     mainAxisSize: MainAxisSize.min,
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Row(
  //         children: [
  //           Expanded(
  //             child: Text(
  //               'What would you like to do?',
  //               style: TextStyle(
  //                 fontSize: 18,
  //                 fontWeight: FontWeight.w700,
  //                 color: c.headline,
  //               ),
  //             ),
  //           ),
  //           IconButton(
  //             onPressed: () => Get.back(),
  //             icon: Icon(Icons.close_rounded, color: c.hint),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 2),
  //       _optionTile(
  //         context,
  //         icon: Icons.home_work_outlined,
  //         label: 'Add Property',
  //         onTap: () => Get.back(
  //           result: const _OtherActionOutcome.wizard(QuickHomeAction.addProperty),
  //         ),
  //       ),
  //       _optionTile(
  //         context,
  //         icon: Icons.payments_outlined,
  //         label: 'Add Income',
  //         onTap: () => Get.back(
  //           result: const _OtherActionOutcome.wizard(QuickHomeAction.addIncome),
  //         ),
  //       ),
  //       _optionTile(
  //         context,
  //         icon: Icons.receipt_long_outlined,
  //         label: 'Add Expense',
  //         onTap: () => Get.back(
  //           result: const _OtherActionOutcome.wizard(QuickHomeAction.addExpense),
  //         ),
  //       ),
  //       _optionTile(
  //         context,
  //         icon: Icons.event_available_outlined,
  //         label: 'Add Booking',
  //         onTap: () => Get.back(
  //           result: const _OtherActionOutcome.wizard(QuickHomeAction.addBooking),
  //         ),
  //       ),
  //       _optionTile(
  //         context,
  //         icon: Icons.person_add_alt_outlined,
  //         label: 'Add Tenant',
  //         onTap: () => Get.back(
  //           result: const _OtherActionOutcome.wizard(QuickHomeAction.addTenant),
  //         ),
  //       ),
  //       _optionTile(
  //         context,
  //         icon: Icons.chat_bubble_outline_rounded,
  //         label: 'Other (Specify)',
  //         onTap: () => setState(() => _showOtherInput = true),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildOptionsView(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final theme = Theme.of(context);

    return Column(
      key: const ValueKey('options'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Create', 'Unda'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: c.headline,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      _t('Choose what to add', 'Chagua unachotaka kuongeza'),
                      style: TextStyle(
                        fontSize: 12,
                        color: c.hint,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Get.back(),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: c.hint.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded, size: 16, color: c.hint),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Divider label ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _t('PROPERTIES & PEOPLE', 'MALI NA WATU'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: c.hint.withOpacity(0.6),
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 6),

        _optionTile(context,
          icon: Icons.home_work_outlined,
          label: _t('Add Property', 'Ongeza Mali'),
          subtitle: _t('Register a new property', 'Sajili mali mpya'),
          iconColor: const Color(0xFF6C63FF),
          onTap: () => Get.back(
            result: const _OtherActionOutcome.wizard(QuickHomeAction.addProperty),
          ),
        ),
        if (_showRentActions)
          _optionTile(context,
            icon: Icons.person_add_alt_outlined,
            label: _t('Add Tenant', 'Ongeza Mpangaji'),
            subtitle: _t('Assign tenant to a unit', 'Weka mpangaji kwenye chumba'),
            iconColor: const Color(0xFF00BFA5),
            onTap: () => Get.back(
              result: const _OtherActionOutcome.wizard(QuickHomeAction.addTenant),
            ),
          ),
        if (_showRentActions)
          _optionTile(context,
            icon: Icons.notifications_active_outlined,
            label: _t('Send Reminder', 'Tuma Kikumbusho'),
            subtitle: _t(
              'WhatsApp rent reminder to tenants',
              'Kikumbusho cha kodi kwa WhatsApp',
            ),
            iconColor: const Color(0xFF1565C0),
            onTap: () => _handleSendReminderTap(context),
          ),

        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _t('FINANCES', 'FEDHA'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: c.hint.withOpacity(0.6),
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 6),

        _optionTile(context,
          icon: Icons.payments_outlined,
          label: _t('Add Income', 'Ongeza Mapato'),
          subtitle: _t('Record a payment received', 'Rekodi malipo yaliyopokelewa'),
          iconColor: const Color(0xFF2E7D32),
          onTap: () => Get.back(
            result: const _OtherActionOutcome.wizard(QuickHomeAction.addIncome),
          ),
        ),
        _optionTile(context,
          icon: Icons.receipt_long_outlined,
          label: _t('Add Expense', 'Ongeza Matumizi'),
          subtitle: _t('Log a cost or bill', 'Rekodi gharama au bili'),
          iconColor: const Color(0xFFE53935),
          onTap: () => Get.back(
            result: const _OtherActionOutcome.wizard(QuickHomeAction.addExpense),
          ),
        ),
        if (_showBnbActions)
          _optionTile(context,
            icon: Icons.event_available_outlined,
            label: _t('Add Booking', 'Ongeza Uhifadhi'),
            subtitle: _t('Schedule a reservation', 'Panga uhifadhi'),
            iconColor: const Color(0xFFF57C00),
            onTap: () => Get.back(
              result: const _OtherActionOutcome.wizard(QuickHomeAction.addBooking),
            ),
          ),

        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _showOtherInput = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: c.hint.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 16, color: c.hint),
                  const SizedBox(width: 10),
                  Text(
                    _t(
                      'Other — specify your request',
                      'Nyingine — eleza unachotaka',
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: c.hint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: c.hint.withOpacity(0.5)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _handleSendReminderTap(BuildContext context) async {
    try {
      final tenants =
          await Get.find<TenantLocalDataSource>().getAllNewestFirst();
      if (!mounted) return;
      if (tenants.isEmpty) {
        await _showNoTenantsPrompt(context);
        return;
      }
      Get.back(
        result: const _OtherActionOutcome.wizard(QuickHomeAction.sendReminder),
      );
    } catch (_) {
      if (!mounted) return;
      await _showNoTenantsPrompt(context);
    }
  }

  Future<void> _showNoTenantsPrompt(BuildContext context) async {
    final c = FormSurfaceColors.of(context);
    final isSw = Get.locale?.languageCode == 'sw';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text(isSw ? 'Hakuna Wapangaji' : 'No Tenants Yet'),
        content: Text(
          isSw
              ? 'Ongeza mpangaji kwanza ili kutuma ukumbusho wa WhatsApp.'
              : 'Add at least one tenant before you can send a reminder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isSw ? 'Ghairi' : 'Cancel', style: TextStyle(fontSize: 14)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Get.back(
                result: const _OtherActionOutcome.wizard(QuickHomeAction.addTenant),
              );
            },
            child: Text(isSw ? 'Ongeza Mpangaji' : 'Add Tenant', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

// ── Updated option tile ─────────────────────────────────────────────────────
//   Widget _optionTile(
//       BuildContext context, {
//         required IconData icon,
//         required String label,
//         required VoidCallback onTap,
//         String? subtitle,
//         Color iconColor = const Color(0xFF6C63FF),
//       }) {
//     final c = FormSurfaceColors.of(context);
//     return InkWell(
//       onTap: onTap,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
//         child: Row(
//           children: [
//             Container(
//               width: 42,
//               height: 42,
//               decoration: BoxDecoration(
//                 color: iconColor.withOpacity(0.10),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(icon, size: 20, color: iconColor),
//             ),
//             const SizedBox(width: 14),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     label,
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: c.headline,
//                     ),
//                   ),
//                   if (subtitle != null)
//                     Text(
//                       subtitle,
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: c.hint,
//                         fontWeight: FontWeight.w400,
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//             Icon(Icons.chevron_right_rounded, size: 18, color: c.hint.withOpacity(0.4)),
//           ],
//         ),
//       ),
//     );
//   }

  Widget _optionTile(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
        String? subtitle,
        Color? iconColor,
      }) {
    final c = FormSurfaceColors.of(context);
    final resolvedIconColor = iconColor ?? c.tokens.accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: resolvedIconColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: resolvedIconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.headline,
                        letterSpacing: -0.1,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: c.hint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: c.hint.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _optionTile(
  //   BuildContext context, {
  //   required IconData icon,
  //   required String label,
  //   required VoidCallback onTap,
  // }) {
  //   final c = FormSurfaceColors.of(context);
  //   return InkWell(
  //     borderRadius: BorderRadius.circular(12),
  //     onTap: onTap,
  //     child: Padding(
  //       padding: const EdgeInsets.symmetric(vertical: 10),
  //       child: Row(
  //         children: [
  //           Container(
  //             width: 40,
  //             height: 40,
  //             decoration: BoxDecoration(
  //               color: c.chipUnselectedBg,
  //               borderRadius: BorderRadius.circular(10),
  //             ),
  //             child: Icon(icon, color: c.tokens.accent, size: 20),
  //           ),
  //           const SizedBox(width: 14),
  //           Expanded(
  //             child: Text(
  //               label,
  //               style: TextStyle(
  //                 fontSize: 15,
  //                 fontWeight: FontWeight.w600,
  //                 color: c.headline,
  //               ),
  //             ),
  //           ),
  //           Icon(Icons.chevron_right_rounded, color: c.hint),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildOtherView(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Column(
      key: const ValueKey('other'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() {
                _showOtherInput = false;
                _error = null;
              }),
              icon: Icon(Icons.arrow_back_rounded, color: c.headline),
            ),
            Expanded(
              child: Text(
                _t('Tell us what you want to do', 'Tuambie unachotaka kufanya'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.headline,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Get.back(),
              icon: Icon(Icons.close_rounded, color: c.hint),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _otherController,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          style: TextStyle(color: c.headline),
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: _t(
              'e.g. "Add a new tenant to my apartment"',
              'mf. "Ongeza mpangaji mpya kwenye apartment"',
            ),
            hintStyle: TextStyle(color: c.hint),
            filled: true,
            fillColor: c.inputFill,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.inputBorder),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _resolving ? null : _handleOtherSubmit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _resolving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    _t('Submit', 'Wasilisha'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }
}
