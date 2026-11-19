import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/local/preference/preference_manager.dart';
import '../../data/local/service/currency_service.dart';
import '../../data/service/subscription_service.dart';
import '../../routes/app_pages.dart';
import '../access/plan_agents.dart';
import '../access/plan_loss_snapshot.dart';

/// Which subscription tier a feature requires.
enum RequiredPlan { any, pro, ultra }

/// Checks whether the current user's subscription meets the [required] tier.
///
/// Usage:
/// ```dart
/// // Block feature entirely:
/// if (!PlanGate.check(RequiredPlan.pro)) {
///   PlanGate.showUpgradeSheet(RequiredPlan.pro, featureName: 'SMS / WhatsApp');
///   return;
/// }
///
/// // Or inline in a button:
/// onPressed: PlanGate.guard(RequiredPlan.pro, featureName: 'Staff tools', () { ... })
/// ```
class PlanGate {
  PlanGate._();

  static SubscriptionService get _svc => Get.find<SubscriptionService>();

  static Future<bool> isPortfolioManagerSession() async {
    try {
      final prefs = Get.find<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      );
      return prefs.getBool(
        PreferenceManager.keyIsPortfolioManager,
        defaultValue: false,
      );
    } catch (_) {
      return false;
    }
  }

  /// Returns true if the user's active plan satisfies [required].
  static bool check(RequiredPlan required) {
    final svc = _svc;
    if (!svc.isActive) return false;
    switch (required) {
      case RequiredPlan.any:   return true;
      case RequiredPlan.pro:   return svc.isProOrAbove;
      case RequiredPlan.ultra: return svc.isUltra;
    }
  }

  /// Shows an upgrade bottom sheet and navigates to the subscription page.
  static void showUpgradeSheet(
    RequiredPlan required, {
    required String featureName,
    String? subtitle,
    String? planName,
  }) {
    // Managers cannot change host billing — skip upgrade CTA.
    isPortfolioManagerSession().then((isManager) {
      if (isManager) {
        Get.snackbar(
          Get.locale?.languageCode == 'sw' ? 'Bili' : 'Billing',
          Get.locale?.languageCode == 'sw'
              ? 'Wasimamizi hawawezi kubadilisha mpango wa malipo.'
              : 'Managers cannot change billing plans.',
        );
        return;
      }
      _showUpgradeSheetImpl(
        required,
        featureName: featureName,
        subtitle: subtitle,
        planName: planName,
      );
    });
  }

  static void _showUpgradeSheetImpl(
    RequiredPlan required, {
    required String featureName,
    String? subtitle,
    String? planName,
  }) {
    final ctx = Get.context;
    if (ctx == null) return;

    final resolvedPlan = planName ??
        (required == RequiredPlan.ultra ? 'Ultra' : 'Pro');

    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UpgradeSheet(
        featureName: featureName,
        subtitle: subtitle,
        planName: resolvedPlan,
      ),
    );
  }

  /// Wraps [action] with a plan check. If the check fails, shows the upgrade sheet.
  static VoidCallback guard(
    RequiredPlan required, {
    required String featureName,
    required VoidCallback action,
  }) {
    return () {
      if (check(required)) {
        action();
      } else {
        showUpgradeSheet(required, featureName: featureName);
      }
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────

const _accent = Color(0xFF1C6E64);

bool get _isSw => Get.locale?.languageCode == 'sw';

String _t(String en, String sw) => _isSw ? sw : en;

/// Capabilities of a tier by name, so the sheet can put the plan the host is
/// on next to the one they are being asked to buy.
PlanAccessAgent _agentNamed(String name) {
  switch (name.trim().toLowerCase()) {
    case 'ultra':
      return const UltraPlanAgent();
    case 'pro':
      return const ProPlanAgent();
    case 'starter':
      return const FreeStarterPlanAgent(isFree: false);
    default:
      return const FreeStarterPlanAgent(isFree: true);
  }
}

/// Tier ordering, used only to detect an inconsistent pairing. While
/// subscription status is still loading, [PlanAccess.agent] reports Ultra so
/// nothing flickers as locked — which would otherwise let this sheet print
/// "Reports is off on Ultra".
int _rank(PlanAccessAgent agent) {
  if (agent is UltraPlanAgent) return 3;
  if (agent is ProPlanAgent) return 2;
  if (agent is FreeStarterPlanAgent) return agent.isFree ? 0 : 1;
  return 0;
}

PlanInfo? _planInfoNamed(String name) {
  final key = name.trim().toLowerCase();
  for (final info in hostBoraPlanInfos) {
    if (info.key == key) return info;
  }
  return null;
}

String _money(double amount) {
  if (Get.isRegistered<CurrencyService>()) {
    return Get.find<CurrencyService>().formatBase(amount);
  }
  return amount.toStringAsFixed(0);
}

/// Upgrade prompt framed around what the current plan is holding back.
///
/// Three deliberate departures from a standard paywall:
///
/// 1. The headline names the host's own plan as the thing in the way, rather
///    than stating a rule about the paid tier. "Reports are off on Free" is
///    the same fact as "Reports requires Pro", but only one of them describes
///    a loss the host is already taking.
/// 2. The figures come from [PlanLossSnapshot] — the host's own records, on
///    this device, that the plan filters out of view. Nothing is shown unless
///    the data is really there.
/// 3. The dismissal is labelled with the choice it makes. "Maybe later" frames
///    the decision as postponed and therefore free; "Stay on Free" is the same
///    single tap, equally available, but it is a decision rather than a
///    deferral. Deliberately not made slower, hidden, or guilt-worded — that
///    would be a dark pattern and a store-review risk.
class _UpgradeSheet extends StatefulWidget {
  const _UpgradeSheet({
    required this.featureName,
    required this.subtitle,
    required this.planName,
  });

  final String featureName;

  /// Caller-supplied override (the property and unit caps pass their own).
  final String? subtitle;
  final String planName;

  @override
  State<_UpgradeSheet> createState() => _UpgradeSheetState();
}

class _UpgradeSheetState extends State<_UpgradeSheet> {
  PlanLossSnapshot? _loss;

  @override
  void initState() {
    super.initState();
    // Loaded after the sheet is already on screen: reading the whole income
    // and expense history must never delay the prompt from opening.
    PlanLossSnapshot.load().then((snapshot) {
      if (mounted) setState(() => _loss = snapshot);
    });
  }

  PlanAccessAgent get _current => PlanAccess.agent;

  PlanAccessAgent get _target => _agentNamed(widget.planName);

  /// False when the resolved current tier is not actually below the target.
  /// Everything comparative is suppressed in that case rather than printed
  /// as a contradiction.
  bool get _comparable => _rank(_current) < _rank(_target);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark
        ? theme.colorScheme.onSurfaceVariant
        : const Color(0xFF6B7280);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),

            Text(
              _headline(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _supporting(),
              style: TextStyle(fontSize: 14, height: 1.45, color: muted),
            ),

            if (_panel() case final panel?) ...[
              const SizedBox(height: 18),
              panel,
            ],

            if (_comparable) ...[
              const SizedBox(height: 18),
              _ContrastTable(
                currentLabel:
                    _t('${_current.name} now', '${_current.name} sasa'),
                targetLabel: widget.planName,
                rows: _contrastRows(),
                isDark: isDark,
              ),
            ],
            const SizedBox(height: 22),

            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Get.toNamed(Routes.SUBSCRIPTION);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _ctaLabel(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Same one tap as before, now labelled with what it chooses.
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _comparable
                    ? _t(
                        'Stay on ${_current.name}',
                        'Endelea na ${_current.name}',
                      )
                    : _t('Not now', 'Sasa hapana'),
                style: TextStyle(color: muted, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Copy ──────────────────────────────────────────────────────────────────

  /// Names the restriction the host is living with, not the rule they failed.
  String _headline() {
    if (!_comparable) {
      return _t(
        '${widget.featureName} needs ${widget.planName}',
        '${widget.featureName} inahitaji ${widget.planName}',
      );
    }
    final plan = _current.name;
    return _t(
      '${widget.featureName} is off on $plan',
      '${widget.featureName} imezimwa kwenye $plan',
    );
  }

  String _supporting() {
    final override = widget.subtitle?.trim();
    if (override != null && override.isNotEmpty) return override;
    if (!_comparable) {
      return _t(
        '${widget.featureName} is included from ${widget.planName} upwards.',
        '${widget.featureName} imejumuishwa kuanzia ${widget.planName}.',
      );
    }

    final loss = _loss;
    final months = loss?.monthsOnDevice ?? 0;
    if (_current.currentMonthOnly && months > 1) {
      return _t(
        'You have $months months of records on this phone. '
            '${_current.name} shows this month only.',
        'Unayo kumbukumbu za miezi $months kwenye simu hii. '
            '${_current.name} inaonyesha mwezi huu tu.',
      );
    }
    return _t(
      'Your ${_current.name} plan does not include ${widget.featureName.toLowerCase()}.',
      'Mpango wako wa ${_current.name} haujumuishi ${widget.featureName.toLowerCase()}.',
    );
  }

  String _ctaLabel() {
    final price = _planInfoNamed(widget.planName)?.priceFormatted;
    if (price == null) {
      return _t('Unlock with ${widget.planName}', 'Fungua na ${widget.planName}');
    }
    // Price shown here because the old sheet made the host navigate away to
    // find out what they were being asked to pay.
    return _t(
      'Unlock with ${widget.planName} — $price',
      'Fungua na ${widget.planName} — $price',
    );
  }

  // ── Panels ────────────────────────────────────────────────────────────────

  /// At most one figure panel, so the sheet never shows two competing
  /// framings. Withheld history wins when it exists because it is the larger
  /// and more concrete loss; the cap is the fallback so a host on a plan with
  /// full history — Starter sitting on three properties, say — still gets a
  /// number of their own rather than only the comparison table.
  Widget? _panel() {
    final history = _hiddenHistoryRows();
    if (history.isNotEmpty) {
      return _LossPanel(
        label: _t('HIDDEN RIGHT NOW', 'IMEFICHWA SASA'),
        rows: history,
        isDark: Theme.of(context).brightness == Brightness.dark,
      );
    }
    final cap = _capRow();
    if (cap != null) {
      return _LossPanel(
        label: _t('AT YOUR LIMIT', 'UMEFIKIA KIKOMO'),
        rows: [cap],
        isDark: Theme.of(context).brightness == Brightness.dark,
      );
    }
    return null;
  }

  /// The property cap, but only once the host is actually against it. Stating
  /// "1 of 10" to someone with room left would be an invented constraint.
  _LossRow? _capRow() {
    final loss = _loss;
    final cap = _current.maxProperties;
    if (loss == null || cap == null) return null;
    if (loss.propertyCount < cap) return null;
    final targetCap = _target.maxProperties;
    return _LossRow(
      amount: '${loss.propertyCount} / $cap',
      detail: targetCap == null
          ? _t(
              'properties — ${widget.planName} removes the cap',
              'mali — ${widget.planName} inaondoa kikomo',
            )
          : _t(
              'properties — ${widget.planName} allows $targetCap',
              'mali — ${widget.planName} inaruhusu $targetCap',
            ),
    );
  }

  /// The host's own withheld records. Empty unless there is genuinely
  /// something older than this month sitting in the database.
  List<_LossRow> _hiddenHistoryRows() {
    final loss = _loss;
    if (loss == null || !loss.hasHiddenHistory) return const [];
    if (!_current.currentMonthOnly) return const [];
    return [
      if (loss.hiddenIncomeCount > 0)
        _LossRow(
          amount: _money(loss.hiddenIncomeTotal),
          detail: _t(
            '${loss.hiddenIncomeCount} ${loss.hiddenIncomeCount == 1 ? 'payment' : 'payments'}',
            'malipo ${loss.hiddenIncomeCount}',
          ),
        ),
      if (loss.hiddenExpenseCount > 0)
        _LossRow(
          amount: _money(loss.hiddenExpenseTotal),
          detail: _t(
            '${loss.hiddenExpenseCount} ${loss.hiddenExpenseCount == 1 ? 'expense' : 'expenses'}',
            'gharama ${loss.hiddenExpenseCount}',
          ),
        ),
    ];
  }

  /// Side-by-side capabilities. Rows where the two tiers agree are dropped —
  /// an identical pair reads as filler and weakens the rows that do differ.
  List<_ContrastRow> _contrastRows() {
    final rows = <_ContrastRow>[];
    final loss = _loss;

    if (_current.currentMonthOnly != _target.currentMonthOnly) {
      final months = loss?.monthsOnDevice ?? 0;
      rows.add(
        _ContrastRow(
          label: _t('History', 'Historia'),
          current: _t('This month', 'Mwezi huu'),
          target: months > 1
              ? _t('All $months months', 'Miezi yote $months')
              : _t('Everything', 'Yote'),
        ),
      );
    }

    final currentCap = _current.maxProperties;
    final targetCap = _target.maxProperties;
    if (currentCap != targetCap) {
      rows.add(
        _ContrastRow(
          label: _t('Properties', 'Mali'),
          current: currentCap == null
              ? _t('Unlimited', 'Bila kikomo')
              : _t('$currentCap max', 'Hadi $currentCap'),
          target: targetCap == null
              ? _t('Unlimited', 'Bila kikomo')
              : _t('$targetCap max', 'Hadi $targetCap'),
        ),
      );
    }

    rows.add(
      _ContrastRow(
        label: widget.featureName,
        current: _t('Off', 'Imezimwa'),
        target: _t('Included', 'Imejumuishwa'),
      ),
    );
    return rows;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _LossRow {
  const _LossRow({required this.amount, required this.detail});

  final String amount;
  final String detail;
}

/// Calls out the host's withheld records as a figure rather than a feature.
class _LossPanel extends StatelessWidget {
  const _LossPanel({
    required this.label,
    required this.rows,
    required this.isDark,
  });

  final String label;
  final List<_LossRow> rows;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final border = isDark ? const Color(0xFF3F3A33) : const Color(0xFFF0DFC4);
    final fill = isDark ? const Color(0xFF2A251F) : const Color(0xFFFDF7EC);
    final labelColor = isDark ? const Color(0xFFD9A94B) : const Color(0xFF946C12);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  rows[i].amount,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  rows[i].detail,
                  style: TextStyle(fontSize: 13, color: labelColor),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ContrastRow {
  const _ContrastRow({
    required this.label,
    required this.current,
    required this.target,
  });

  final String label;
  final String current;
  final String target;
}

/// Puts the current plan beside the target one. A price judged on its own has
/// nothing to be judged against; the same price next to what it replaces is a
/// comparison the host can actually make.
class _ContrastTable extends StatelessWidget {
  const _ContrastTable({
    required this.currentLabel,
    required this.targetLabel,
    required this.rows,
    required this.isDark,
  });

  final String currentLabel;
  final String targetLabel;
  final List<_ContrastRow> rows;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = isDark
        ? theme.colorScheme.onSurfaceVariant
        : const Color(0xFF6B7280);
    final divider = isDark ? const Color(0xFF34302B) : const Color(0xFFEDEDED);

    Widget headerCell(String text, {required bool emphasised}) => Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: emphasised ? _accent : muted,
          ),
        );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                const Spacer(flex: 4),
                Expanded(
                  flex: 3,
                  child: headerCell(currentLabel, emphasised: false),
                ),
                Expanded(
                  flex: 3,
                  child: headerCell(targetLabel, emphasised: true),
                ),
              ],
            ),
          ),
          for (final row in rows)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      row.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      row.current,
                      style: TextStyle(fontSize: 13, color: muted),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      row.target,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
