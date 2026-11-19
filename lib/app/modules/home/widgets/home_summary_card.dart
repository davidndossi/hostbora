import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/month_rent_collection.dart';
import '../../../core/values/app_colors.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../data/model/rewards_dashboard.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../controllers/home_controller.dart';
import 'link_payments_sheet.dart';

// Same palette as the Host Score card in Settings.
const _scoreMuted = Color(0xFFD0E5DB);
const _scoreAccent = AppColors.colorPrimaryLight;
const _pending = Color(0xFFEDF5F1);
const _mask = '••••••';

/// Top-of-Home money summary. Styled like the Host Score card in Settings
/// (flat primary surface, same type scale and translucent-white details).
/// Collected and yet-to-collect come first; expected total and the current
/// challenge are supporting detail.
class HomeSummaryCard extends StatelessWidget {
  const HomeSummaryCard({
    super.key,
    required this.controller,
    required this.bnbOnly,
  });

  final HomeController controller;

  /// BnB-only hosts have no monthly rent target, so "yet to collect" is the
  /// unpaid balance on guests instead of expected minus collected.
  final bool bnbOnly;

  static const _monthsEn = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _monthsSw = [
    'Januari',
    'Februari',
    'Machi',
    'Aprili',
    'Mei',
    'Juni',
    'Julai',
    'Agosti',
    'Septemba',
    'Oktoba',
    'Novemba',
    'Desemba',
  ];

  @override
  Widget build(BuildContext context) {
    final isSw = Localizations.localeOf(context).languageCode == 'sw';
    final night = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final month = (isSw ? _monthsSw : _monthsEn)[now.month - 1];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: night ? AppColors.colorPrimaryDark : AppColors.colorPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(20, 19, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => _buildMoney(context, isSw, '$month ${now.year}')),
          _ChallengeStrip(isSw: isSw),
        ],
      ),
    );
  }

  Widget _buildMoney(BuildContext context, bool isSw, String monthLabel) {
    final cs = Get.find<CurrencyService>();
    final loading = controller.snapshotSectionLoading.value;
    final hidden = controller.hideHomeAmounts.value;

    double collected;
    double remaining;
    double? expected;
    if (bnbOnly) {
      collected = controller.bnbRevenueValue.value;
      remaining = controller.overdueOccupants
          .where((o) => o.isBnb)
          .fold<double>(0, (sum, o) => sum + o.amountOwed);
    } else {
      collected = controller.collectedIncomeValue.value;
      expected = controller.expectedIncomeValue.value;
      remaining = (expected - collected).clamp(0, double.infinity).toDouble();
    }
    final total = bnbOnly ? collected + remaining : (expected ?? 0);
    final pct = total <= 0
        ? 0
        : ((collected / total) * 100).round().clamp(0, 100);

    final billed = controller.billedTenantsCount.value;
    final paid = controller.paidTenantsCount.value;
    final showPaidPill = !bnbOnly && billed > 0;
    final unlinked = controller.unlinkedPaymentsCount.value;
    final other = controller.otherIncomeValue.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.emoji_events_outlined, size: 17, color: _scoreMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      monthLabel.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                        color: _scoreMuted,
                      ),
                    ),
                  ),
                  // Loaded in the background; fades in once the count is ready.
                  Flexible(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      alignment: Alignment.centerLeft,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: showPaidPill
                            ? Padding(
                                key: ValueKey('$paid/$billed'),
                                padding: const EdgeInsets.only(left: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.09),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    isSw
                                        ? '$paid kati ya $billed wamelipa'
                                        : '$paid of $billed paid',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(key: ValueKey('none')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.white.withValues(alpha: 0.08),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: controller.toggleHideHomeAmounts,
                child: Tooltip(
                  message: hidden
                      ? (isSw ? 'Onyesha kiasi' : 'Show amounts')
                      : (isSw ? 'Ficha kiasi' : 'Hide amounts'),
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: Icon(
                      hidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: controller.openTodayRevenue,
          borderRadius: BorderRadius.circular(12),
          child: loading
              ? const SizedBox(
                  height: 130,
                  child: Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stretch needs a bounded height; Home scrolls, so size to
                    // the tallest tile instead.
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _AmountTile(
                              label: isSw ? 'Imekusanywa' : 'Collected',
                              dot: _scoreAccent,
                              currency: cs.baseCurrency.value,
                              amount: hidden
                                  ? _mask
                                  : cs.formatNumber(collected),
                              amountColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _AmountTile(
                              label: isSw ? 'Bado kukusanya' : 'Yet to collect',
                              dot: _pending,
                              currency: cs.baseCurrency.value,
                              amount: hidden
                                  ? _mask
                                  : cs.formatNumber(remaining),
                              amountColor: _pending,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (total > 0) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.13),
                          valueColor: const AlwaysStoppedAnimation(
                            _scoreAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _MetaText(
                            bold: '$pct%',
                            rest: isSw ? ' imekusanywa' : ' collected',
                          ),
                          if (!bnbOnly)
                            _MetaText(
                              rest: isSw ? 'Inayotarajiwa ' : 'Expected ',
                              bold: hidden
                                  ? _mask
                                  : cs.formatBaseShort(expected ?? 0),
                              boldAfter: true,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
        ),
        if (!bnbOnly && !loading && (unlinked > 0 || other > 0))
          _UnlinkedNotice(
            isSw: isSw,
            count: unlinked,
            otherLabel: other > 0
                ? '${cs.baseCurrency.value} ${hidden ? _mask : cs.formatNumber(other)}'
                : null,
            onLink: unlinked > 0 ? () => showLinkPaymentsSheet(context) : null,
          ),
      ],
    );
  }
}

/// Payments with no tenant are kept out of rent collection; this says so and
/// offers the fix instead of letting the totals quietly disagree.
class _UnlinkedNotice extends StatelessWidget {
  const _UnlinkedNotice({
    required this.isSw,
    required this.count,
    required this.otherLabel,
    required this.onLink,
  });

  final bool isSw;
  final int count;

  /// Formatted other income this month, or null when there is none.
  final String? otherLabel;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final title = count > 0
        ? (isSw
              ? 'Malipo $count hayajaunganishwa na mpangaji'
              : (count == 1
                    ? '1 payment not linked to a tenant'
                    : '$count payments not linked to a tenant'))
        : (isSw ? 'Mapato mengine' : 'Other income');
    final detail = otherLabel == null
        ? null
        : (isSw
              ? '$otherLabel mwezi huu, haijahesabiwa kwenye ukusanyaji'
              : '$otherLabel this month, not counted in collection');

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.link_off_rounded, size: 18, color: _scoreAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  if (detail != null)
                    Text(
                      detail,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: _scoreMuted,
                      ),
                    ),
                ],
              ),
            ),
            if (onLink != null) ...[
              const SizedBox(width: 8),
              Material(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(30),
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: onLink,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Text(
                      isSw ? 'Unganisha' : 'Link',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AmountTile extends StatelessWidget {
  const _AmountTile({
    required this.label,
    required this.dot,
    required this.currency,
    required this.amount,
    required this.amountColor,
  });

  final String label;
  final Color dot;
  final String currency;
  final String amount;
  final Color amountColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: _scoreMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            currency,
            style: const TextStyle(fontSize: 11, color: _scoreMuted),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              maxLines: 1,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                letterSpacing: -1,
                height: 1,
                color: amountColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({
    required this.bold,
    required this.rest,
    this.boldAfter = false,
  });

  final String bold;
  final String rest;

  /// When true the text reads `rest` then `bold` (e.g. "Expected TZS 900K").
  final bool boldAfter;

  @override
  Widget build(BuildContext context) {
    const soft = TextStyle(fontSize: 12, height: 1.5, color: _scoreMuted);
    const strong = TextStyle(
      fontSize: 12,
      height: 1.5,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );
    return Text.rich(
      TextSpan(
        children: boldAfter
            ? [
                TextSpan(text: rest, style: soft),
                TextSpan(text: bold, style: strong),
              ]
            : [
                TextSpan(text: bold, style: strong),
                TextSpan(text: rest, style: soft),
              ],
      ),
    );
  }
}

/// Current rewards challenge: thin progress line under the money summary.
class _ChallengeStrip extends StatefulWidget {
  const _ChallengeStrip({required this.isSw});

  final bool isSw;

  @override
  State<_ChallengeStrip> createState() => _ChallengeStripState();
}

class _ChallengeStripState extends State<_ChallengeStrip> {
  RewardsDashboard? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (!Get.isRegistered<AppRepository>(tag: (AppRepository).toString())) {
        return;
      }
      final repo = Get.find<AppRepository>(tag: (AppRepository).toString());
      final response = await repo.getRewards();
      final raw = response.data;
      if (!mounted || raw is! Map) return;
      var dashboard = RewardsDashboard.fromJson(Map<String, dynamic>.from(raw));
      dashboard = await _applyLocalCollection(dashboard);
      if (!mounted) return;
      setState(() => _data = dashboard);
    } catch (_) {
      // Home stays usable if rewards are unavailable.
    }
  }

  Future<RewardsDashboard> _applyLocalCollection(
    RewardsDashboard dashboard,
  ) async {
    try {
      if (!Get.isRegistered<TenantLocalDataSource>() ||
          !Get.isRegistered<IncomeLocalDataSource>()) {
        return dashboard;
      }
      final tenants = await Get.find<TenantLocalDataSource>()
          .getAllNewestFirst();
      final incomes = await Get.find<IncomeLocalDataSource>()
          .getAllNewestFirst();
      return MonthRentCollection.fromRecords(
        tenants: tenants,
        incomes: incomes,
      ).applyTo(dashboard);
    } catch (_) {
      return dashboard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = widget.isSw;
    final challenge = _data?.challenges.isNotEmpty == true
        ? _data!.challenges.first
        : null;
    final title =
        challenge?.title ??
        (isSw
            ? 'Pata HB Points kwa usimamizi mzuri.'
            : 'Earn HB Points for good hosting.');

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.only(top: 14),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
        ),
        child: InkWell(
          onTap: () => Get.toNamed(Routes.CHALLENGES_REWARDS),
          borderRadius: BorderRadius.circular(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 18, color: _scoreAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: _scoreMuted,
                      ),
                    ),
                  ),
                  if (challenge != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${challenge.pct}% · ${_data?.balance ?? 0} HB',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
              if (challenge != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: (challenge.pct / 100).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.13),
                    valueColor: const AlwaysStoppedAnimation(_pending),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
