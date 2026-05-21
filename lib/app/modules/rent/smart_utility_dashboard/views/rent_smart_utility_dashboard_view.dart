import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../../../../l10n/app_localizations.dart';
import '../controllers/rent_smart_utility_dashboard_controller.dart';

class _UtilUi {
  _UtilUi(this.context);

  final BuildContext context;
  ThemeData get _t => Theme.of(context);
  bool get dark => _t.brightness == Brightness.dark;

  static const Color forest = Color(0xFF0A5C5C);
  static const Color deepForest = Color(0xFF004040);
  static const Color mint = Color(0xFFCFE6DF);
  static const Color cream = Color(0xFFFBF9F4);

  Color get bg => dark ? _t.scaffoldBackgroundColor : cream;
  Color get card => dark ? _t.cardColor : Colors.white;
  Color get softSurface => dark ? const Color(0xFF2C2C2E) : const Color(0xFFF4F2EC);
  Color get onSurface => dark ? const Color(0xFFF2F2F7) : const Color(0xFF111827);
  Color get muted => dark ? const Color(0xFFAEAEB2) : const Color(0xFF6B7280);
}

class RentSmartUtilityDashboardView extends BaseView<RentSmartUtilityDashboardController> {
  RentSmartUtilityDashboardView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) => null;

  @override
  Color pageBackgroundColor(BuildContext context) => _UtilUi(context).bg;

  @override
  Widget body(BuildContext context) {
    final u = _UtilUi(context);
    return SafeArea(
      child: Obx(() {
        if (controller.loading.value) {
          return const Center(
            child: CircularProgressIndicator(color: _UtilUi.forest),
          );
        }
        return RefreshIndicator(
          color: _UtilUi.forest,
          onRefresh: controller.loadAll,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const SizedBox(height: 20),
              _globalStatusRow(u),
              const SizedBox(height: 16),
              _lukuCard(u),
              const SizedBox(height: 12),
              _waterCard(u),
              const SizedBox(height: 20),
              _weeklyUsageCard(u),
              const SizedBox(height: 20),
              _recentActivityHeader(u),
              const SizedBox(height: 10),
              if (controller.activities.isEmpty)
                _emptyActivityTile(u)
              else
                ...controller.activities.map((a) => _activityTile(u, a)),
            ],
          ),
        );
      }),
    );
  }

  Widget _globalStatusRow(_UtilUi u) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.unitLabel.value,
                // _isSw ? 'HALI KUU' : 'GLOBAL STATUS',
                style: TextStyle(
                  fontSize: 22,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  color: u.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                controller.globalStatus.value,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: u.onSurface,
                ),
              ),
            ],
          ),
        ),
        // Container(
        //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        //   decoration: BoxDecoration(
        //     color: u.card,
        //     borderRadius: BorderRadius.circular(14),
        //     boxShadow: const [
        //       BoxShadow(
        //         color: Color(0x12000000),
        //         blurRadius: 10,
        //         offset: Offset(0, 3),
        //       ),
        //     ],
        //   ),
        //   child: Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       const Icon(Icons.shield_rounded, size: 18, color: _UtilUi.forest),
        //       const SizedBox(width: 6),
        //       Column(
        //         crossAxisAlignment: CrossAxisAlignment.start,
        //         children: [
        //           Text(
        //             _isSw ? 'NIDA IMANI' : 'NIDA TRUST',
        //             style: TextStyle(
        //               fontSize: 9,
        //               letterSpacing: 1.0,
        //               fontWeight: FontWeight.w800,
        //               color: u.muted,
        //             ),
        //           ),
        //           Text(
        //             '${controller.trustScore.value.toStringAsFixed(1)}/10',
        //             style: TextStyle(
        //               fontSize: 12,
        //               fontWeight: FontWeight.w800,
        //               color: u.onSurface,
        //             ),
        //           ),
        //         ],
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  Widget _lukuCard(_UtilUi u) {
    return Builder(
      builder: (ctx) => _utilityCard(
        u: u,
        iconBg: _UtilUi.forest,
        icon: Icons.bolt_rounded,
        title: 'LUKU Units',
        actionLabel: _isSw ? 'JAZA' : 'TOP UP',
        onAction: () => _openTopUpSheet(ctx, isLuku: true),
        value: controller.lukuUnits.value.toStringAsFixed(1),
        unit: _isSw ? 'kWh Zilizobaki' : 'kWh Left',
        progress: controller.lukuProgress,
        footer: _isSw
            ? 'Makadirio ya siku: ${controller.lukuCoverageDays.value}'
            : 'Estimated coverage: ${controller.lukuCoverageDays.value} days',
        onUsageGraph: controller.openLukuUsageGraph,
        usageGraphLabel: AppLocalizations.of(ctx)!.rentUtilityLukuUsageGraphLink,
        watermarkIcon: Icons.bolt_rounded,
        watermarkAngle: 0.14,
      ),
    );
  }

  Widget _waterCard(_UtilUi u) {
    return Builder(
      builder: (ctx) => _utilityCard(
        u: u,
        iconBg: _UtilUi.deepForest,
        icon: Icons.water_drop_rounded,
        title: _isSw ? 'Salio la Maji' : 'Water Balance',
        actionLabel: _isSw ? 'JAZA' : 'RECHARGE',
        onAction: () => _openTopUpSheet(ctx, isLuku: false),
        value: controller.waterLiters.value.toStringAsFixed(0).replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]},',
            ),
        unit: _isSw ? 'Lita' : 'Litres',
        progress: controller.waterProgress,
        footer: controller.nextMeterReadingLabel.value,
        onUsageGraph: controller.openWaterUsageGraph,
        usageGraphLabel: AppLocalizations.of(ctx)!.rentUtilityWaterUsageGraphLink,
        watermarkIcon: Icons.water_drop_rounded,
      ),
    );
  }

  Future<void> _openTopUpSheet(BuildContext context, {required bool isLuku}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UtilityTopUpSheet(
        isLuku: isLuku,
        onSubmit: ({
          required double units,
          required double amount,
          required String provider,
          required String notes,
          required DateTime date,
        }) async {
          if (isLuku) {
            await controller.addLukuTopUp(
              kwh: units,
              amountTsh: amount,
              provider: provider,
              notes: notes,
              date: date,
            );
          } else {
            await controller.addWaterTopUp(
              liters: units,
              amountTsh: amount,
              provider: provider,
              notes: notes,
              date: date,
            );
          }
        },
      ),
    );
  }

  Widget _utilityCard({
    required _UtilUi u,
    required Color iconBg,
    required IconData icon,
    required String title,
    required String actionLabel,
    required VoidCallback onAction,
    required String value,
    required String unit,
    required double progress,
    required String footer,
    VoidCallback? onUsageGraph,
    String? usageGraphLabel,
    IconData? watermarkIcon,
    double watermarkAngle = 0,
  }) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconBg, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: u.onSurface,
                ),
              ),
            ),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                backgroundColor: _UtilUi.forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 38,
                fontWeight: FontWeight.w700,
                height: 1,
                color: u.onSurface,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: u.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: u.softSurface,
            color: _UtilUi.forest,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          footer,
          style: TextStyle(fontSize: 11, color: u.muted),
        ),
        if (onUsageGraph != null && usageGraphLabel != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onUsageGraph,
              icon: const Icon(Icons.show_chart_rounded, size: 18, color: _UtilUi.forest),
              label: Text(
                usageGraphLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.45,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: _UtilUi.forest,
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ],
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: watermarkIcon != null
          ? Stack(
              children: [
                Positioned(
                  right: -6,
                  bottom: 4,
                  child: Transform.rotate(
                    angle: watermarkAngle,
                    child: Icon(
                      watermarkIcon,
                      size: 118,
                      color: u.dark
                          ? Colors.white.withValues(alpha: 0.06)
                          : iconBg.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: column,
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: column,
            ),
    );
  }

  Widget _weeklyUsageCard(_UtilUi u) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final data = controller.weeklyUsage;
    final maxY = data.fold<double>(0, (a, b) => a > b ? a : b);
    final chartMax = maxY <= 0 ? 1.0 : maxY * 1.25;
    final peakValue = maxY;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: u.softSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _isSw ? 'Matumizi ya Wiki' : 'Weekly Usage',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: u.onSurface,
                  ),
                ),
              ),
              Text(
                _isSw ? 'SIKU 7' : '7 DAY TREND',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  color: u.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartMax,
                barTouchData: BarTouchData(enabled: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= days.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            days[i],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: u.muted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(days.length, (i) {
                  final v = i < data.length ? data[i] : 0.0;
                  final isPeak = peakValue > 0 && v == peakValue;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: v,
                        width: 18,
                        color: isPeak ? _UtilUi.forest : _UtilUi.mint,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentActivityHeader(_UtilUi u) {
    return Row(
      children: [
        Expanded(
          child: Text(
            _isSw ? 'Shughuli za Hivi Karibuni' : 'Recent Activity',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: u.onSurface,
            ),
          ),
        ),
        TextButton(
          onPressed: controller.onViewAllActivity,
          style: TextButton.styleFrom(foregroundColor: _UtilUi.forest),
          child: Text(
            _isSw ? 'TAZAMA ZOTE' : 'VIEW ALL',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _activityTile(_UtilUi u, UtilityActivityItem a) {
    final icon = switch (a.type) {
      UtilityActivityType.lukuTopUp => Icons.credit_card_rounded,
      UtilityActivityType.waterBill => Icons.water_drop_rounded,
      UtilityActivityType.other => Icons.receipt_long_rounded,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAE6DE)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: u.softSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: _UtilUi.forest),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: u.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  a.subtitle,
                  style: TextStyle(fontSize: 11, color: u.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                a.impactLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: a.isPositive ? _UtilUi.forest : u.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                a.amountLabel,
                style: TextStyle(fontSize: 11, color: u.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyActivityTile(_UtilUi u) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAE6DE)),
      ),
      child: Text(
        _isSw ? 'Bado hakuna shughuli za huduma.' : 'No utility activity recorded yet.',
        style: TextStyle(fontSize: 13, color: u.muted, fontWeight: FontWeight.w600),
      ),
    );
  }
}

typedef _UtilityTopUpSubmit = Future<void> Function({
  required double units,
  required double amount,
  required String provider,
  required String notes,
  required DateTime date,
});

class _UtilityTopUpSheet extends StatefulWidget {
  const _UtilityTopUpSheet({
    required this.isLuku,
    required this.onSubmit,
  });

  final bool isLuku;
  final _UtilityTopUpSubmit onSubmit;

  @override
  State<_UtilityTopUpSheet> createState() => _UtilityTopUpSheetState();
}

class _UtilityTopUpSheetState extends State<_UtilityTopUpSheet> {
  final _formKey = GlobalKey<FormState>();
  final _unitsCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  String _provider = 'M-Pesa';
  bool _submitting = false;

  static const _providers = <String>[
    'M-Pesa',
    'Tigo Pesa',
    'Airtel Money',
    'Halopesa',
    'Bank Transfer',
    'Cash',
  ];

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  void dispose() {
    _unitsCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: _UtilUi.forest,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final units = double.tryParse(_unitsCtrl.text.replaceAll(',', '')) ?? 0;
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(
        units: units,
        amount: amount,
        provider: _provider,
        notes: _notesCtrl.text.trim(),
        date: _date,
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLuku = widget.isLuku;
    final title = isLuku
        ? (_isSw ? 'Jaza Vitengo vya LUKU' : 'Top Up LUKU Units')
        : (_isSw ? 'Jaza Salio la Maji' : 'Recharge Water Balance');
    final unitLabel = isLuku
        ? (_isSw ? 'Vitengo (kWh)' : 'Units (kWh)')
        : (_isSw ? 'Lita (L)' : 'Liters (L)');
    final unitHint = isLuku ? 'e.g. 50' : 'e.g. 1500';
    final icon =
        isLuku ? Icons.bolt_rounded : Icons.water_drop_rounded;
    final dateLabel =
        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFBF9F4),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8D4CB),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _UtilUi.forest.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: _UtilUi.forest, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: const Color(0xFF6B7280),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _fieldLabel(unitLabel),
                  TextFormField(
                    controller: _unitsCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: _inputDecoration(hint: unitHint),
                    validator: (v) {
                      final n = double.tryParse((v ?? '').replaceAll(',', ''));
                      if (n == null || n <= 0) {
                        return _isSw
                            ? 'Weka idadi halali'
                            : 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _fieldLabel(_isSw ? 'Kiasi (TZS)' : 'Amount Paid (TZS)'),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: _inputDecoration(hint: 'e.g. 35000'),
                    validator: (v) {
                      final n = double.tryParse((v ?? '').replaceAll(',', ''));
                      if (n == null || n < 0) {
                        return _isSw
                            ? 'Weka kiasi halali'
                            : 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _fieldLabel(_isSw ? 'Njia ya Malipo' : 'Payment Method'),
                  DropdownButtonFormField<String>(
                    initialValue: _provider,
                    decoration: _inputDecoration(),
                    items: _providers
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _provider = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  _fieldLabel(_isSw ? 'Tarehe' : 'Date'),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: _inputDecoration(),
                      child: Row(
                        children: [
                          const Icon(Icons.event_rounded,
                              size: 18, color: _UtilUi.forest),
                          const SizedBox(width: 8),
                          Text(
                            dateLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _fieldLabel(_isSw ? 'Maelezo (Hiari)' : 'Notes (optional)'),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: _inputDecoration(
                      hint: isLuku
                          ? (_isSw
                              ? 'Mf. Meter 01013211901'
                              : 'e.g. Meter 01013211901')
                          : (_isSw
                              ? 'Mf. DAWASA Account 12345'
                              : 'e.g. DAWASA Account 12345'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _UtilUi.forest,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _submitting ? null : _handleSubmit,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              isLuku
                                  ? (_isSw ? 'ONGEZA LUKU' : 'ADD LUKU UNITS')
                                  : (_isSw
                                      ? 'ONGEZA MAJI'
                                      : 'ADD WATER UNITS'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w800,
            color: Color(0xFF6B7280),
          ),
        ),
      );

  InputDecoration _inputDecoration({String? hint}) {
    const radius = BorderRadius.all(Radius.circular(12));
    return InputDecoration(
      isDense: true,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Color(0xFFE5E1D8)),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Color(0xFFE5E1D8)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: _UtilUi.forest, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Color(0xFFDC2626)),
      ),
    );
  }
}
