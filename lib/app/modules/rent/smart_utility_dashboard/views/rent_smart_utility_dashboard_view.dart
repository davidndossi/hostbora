import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../../core/widget/skeleton_presets.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/form_surface_colors.dart';
import '../../../../core/values/app_colors.dart';

import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../../../core/widget/custom_app_bar.dart';
import '../../../../../l10n/app_localizations.dart';
import '../controllers/rent_smart_utility_dashboard_controller.dart';
import '../../../../data/local/service/currency_service.dart';
import '../utils/luku_sms_ocr_parser.dart';

class RentSmartUtilityDashboardView
    extends RentBaseView<RentSmartUtilityDashboardController> {
  RentSmartUtilityDashboardView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: _isSw ? 'Umeme na Maji' : 'Utilities',
      showLanguageToggle: false,
      showThemeToggle: false,
    );
  }

  @override
  Color pageBackgroundColor(BuildContext context) =>
      FormSurfaceColors.of(context).scaffold;

  @override
  Widget body(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return SafeArea(
      child: Obx(() {
        if (controller.loading.value) {
          return const Center(child: DefaultScreenSkeleton());
        }
        return RefreshIndicator(
          color: AppColors.colorPrimary,
          onRefresh: controller.loadAll,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _globalStatusRow(c),
              if (controller.availableUnits.length > 1) ...[
                const SizedBox(height: 12),
                _unitSelector(c),
              ],
              const SizedBox(height: 16),
              _lukuCard(c),
              const SizedBox(height: 12),
              _waterCard(c),
              const SizedBox(height: 20),
              _weeklyUsageCard(c),
              const SizedBox(height: 20),
              _recentActivityHeader(context, c),
              const SizedBox(height: 10),
              if (controller.activities.isEmpty)
                _emptyActivityTile(c)
              else
                ...controller.activities.map((a) => _activityTile(c, a)),
            ],
          ),
        );
      }),
    );
  }

  Widget _unitSelector(FormSurfaceColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSw ? 'Chagua Unit' : 'Filter by unit',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: c.secondary,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Obx(() {
            final selected = controller.selectedUnitId.value;
            return Row(
              children: [
                _unitChip(
                  c: c,
                  label: _isSw ? 'Zote' : 'All units',
                  selected: selected.isEmpty,
                  onTap: () => controller.selectUnit(''),
                ),
                ...controller.availableUnits.map(
                  (unit) => _unitChip(
                    c: c,
                    label: unit.unitName.trim(),
                    selected: selected == unit.unitId,
                    onTap: () => controller.selectUnit(unit.unitId),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _unitChip({
    required FormSurfaceColors c,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.colorPrimary
                : c.fill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.colorPrimary : c.secondary.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : c.headline,
            ),
          ),
        ),
      ),
    );
  }

  Widget _globalStatusRow(FormSurfaceColors c) {
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
                  fontSize: 18,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                  color: c.secondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                controller.globalStatus.value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: c.headline,
                ),
              ),
            ],
          ),
        ),
        // Container(
        //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        //   decoration: BoxDecoration(
        //     color: c.card,
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
        //       const Icon(Icons.shield_outlined, size: 18, color: AppColors.colorPrimary),
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
        //               color: c.secondary,
        //             ),
        //           ),
        //           Text(
        //             '${controller.trustScore.value.toStringAsFixed(1)}/10',
        //             style: TextStyle(
        //               fontSize: 12,
        //               fontWeight: FontWeight.w800,
        //               color: c.headline,
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

  Widget _lukuCard(FormSurfaceColors c) {
    return Builder(
      builder: (ctx) => Obx(() {
        final unitName = controller.selectedUnitName.value.trim();
        final title = unitName.isEmpty
            ? 'LUKU Units'
            : 'LUKU · $unitName';
        return _utilityCard(
          c: c,
          iconBg: AppColors.colorPrimary,
          icon: Icons.bolt_outlined,
          title: title,
          actionLabel: _isSw ? 'JAZA' : 'TOP UP',
          onAction: () => _openTopUpSheet(ctx, isLuku: true),
          value: controller.lukuUnits.value.toStringAsFixed(1),
          unit: _isSw ? 'kWh Zilizobaki' : 'kWh Left',
          progress: controller.lukuProgress,
          footer: _isSw
              ? 'Makadirio ya siku: ${controller.lukuCoverageDays.value}'
              : 'Estimated coverage: ${controller.lukuCoverageDays.value} days',
          onUsageGraph: controller.openLukuUsageGraph,
          usageGraphLabel: AppLocalizations.of(
            ctx,
          )!.rentUtilityLukuUsageGraphLink,
          watermarkIcon: Icons.bolt_outlined,
          watermarkAngle: 0.14,
        );
      }),
    );
  }

  Widget _waterCard(FormSurfaceColors c) {
    return Builder(
      builder: (ctx) => _utilityCard(
        c: c,
        iconBg: AppColors.colorPrimaryDark,
        icon: Icons.water_drop_outlined,
        title: _isSw ? 'Salio la Maji' : 'Water Balance',
        actionLabel: _isSw ? 'JAZA' : 'RECHARGE',
        onAction: () => _openTopUpSheet(ctx, isLuku: false),
        value: controller.waterLiters.value
            .toStringAsFixed(0)
            .replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]},',
            ),
        unit: _isSw ? 'Lita' : 'Litres',
        progress: controller.waterProgress,
        footer: controller.nextMeterReadingLabel.value,
        onUsageGraph: controller.openWaterUsageGraph,
        usageGraphLabel: AppLocalizations.of(
          ctx,
        )!.rentUtilityWaterUsageGraphLink,
        watermarkIcon: Icons.water_drop_outlined,
      ),
    );
  }

  Future<void> _openTopUpSheet(
    BuildContext context, {
    required bool isLuku,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UtilityTopUpSheet(
        isLuku: isLuku,
        onSubmit:
            ({
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
        onImportLukuTopUps: controller.addLukuTopUpsFromSms,
      ),
    );
  }

  Widget _utilityCard({
    required FormSurfaceColors c,
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
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: c.headline,
                ),
              ),
            ),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.colorPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
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
                fontSize: 38,
                fontWeight: FontWeight.w600,
                height: 1,
                color: c.headline,
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
                  color: c.secondary,
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
            minHeight: 8,
            // Dark: brighter track + teal accent so the bar stays readable.
            backgroundColor: c.isDark
                ? const Color(0xFF48484A)
                : const Color(0xFFE8E6E1),
            color: c.isDark ? c.tokens.accent : AppColors.colorPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(footer, style: TextStyle(fontSize: 11, color: c.secondary)),
        if (onUsageGraph != null && usageGraphLabel != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onUsageGraph,
              icon: const Icon(
                Icons.show_chart_outlined,
                size: 18,
                color: AppColors.colorPrimary,
              ),
              label: Text(
                usageGraphLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.45,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.colorPrimary,
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
        color: c.card,
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
                      color: c.isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : iconBg.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Padding(padding: const EdgeInsets.all(16), child: column),
              ],
            )
          : Padding(padding: const EdgeInsets.all(16), child: column),
    );
  }

  Widget _weeklyUsageCard(FormSurfaceColors c) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final data = controller.weeklyUsage;
    final maxY = data.fold<double>(0, (a, b) => a > b ? a : b);
    final chartMax = maxY <= 0 ? 1.0 : maxY * 1.25;
    final peakValue = maxY;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: c.fill,
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
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: c.headline,
                  ),
                ),
              ),
              Text(
                _isSw ? 'SIKU 7' : '7 DAY TREND',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: c.secondary,
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
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            days[i],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: c.secondary,
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
                        color: isPeak ? AppColors.colorPrimary : AppColors.colorPrimaryLight,
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

  Widget _recentActivityHeader(BuildContext context, FormSurfaceColors c) {
    return Row(
      children: [
        Expanded(
          child: Text(
            _isSw ? 'Shughuli za Hivi Karibuni' : 'Recent Activity',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: c.headline,
            ),
          ),
        ),
        TextButton(
          onPressed: () => _showFullUtilityHistory(context),
          style: TextButton.styleFrom(foregroundColor: AppColors.colorPrimary),
          child: Text(
            _isSw ? 'TAZAMA ZOTE' : 'VIEW ALL',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showFullUtilityHistory(BuildContext context) async {
    final c = FormSurfaceColors.of(context);
    // Capture once — do not create a new Future on each sheet rebuild.
    final historyFuture = controller.loadFullActivityHistory();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final maxH = MediaQuery.sizeOf(ctx).height * 0.78;
        return Container(
          height: maxH,
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isSw ? 'Historia ya Huduma' : 'Utility History',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: c.headline,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: Icon(Icons.close_outlined, color: c.secondary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<UtilityActivityItem>>(
                    future: historyFuture,
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _isSw
                                  ? 'Imeshindwa kupakia historia ya huduma'
                                  : 'Could not load utility history',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: c.secondary,
                              ),
                            ),
                          ),
                        );
                      }
                      if (snap.connectionState != ConnectionState.done) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                color: AppColors.colorPrimary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _isSw
                                    ? 'Inapakia historia kamili…'
                                    : 'Loading full utility history…',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: c.secondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final items = snap.data ?? const <UtilityActivityItem>[];
                      if (items.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _isSw
                                  ? 'Hakuna historia ya huduma iliyopatikana'
                                  : 'No utility history available',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: c.secondary,
                              ),
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount: items.length,
                        itemBuilder: (_, i) => _activityTile(c, items[i]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _activityTile(FormSurfaceColors c, UtilityActivityItem a) {
    final icon = switch (a.type) {
      UtilityActivityType.lukuTopUp => Icons.credit_card_outlined,
      UtilityActivityType.waterBill => Icons.water_drop_outlined,
      UtilityActivityType.other => Icons.receipt_long_outlined,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: c.fill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.colorPrimary),
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
                    color: c.headline,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  a.subtitle,
                  style: TextStyle(fontSize: 11, color: c.secondary),
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
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: a.isPositive ? AppColors.colorPrimary : c.headline,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                a.amountLabel,
                style: TextStyle(fontSize: 11, color: c.secondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyActivityTile(FormSurfaceColors c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Text(
        _isSw
            ? 'Bado hakuna shughuli za huduma.'
            : 'No utility activity recorded yet.',
        style: TextStyle(
          fontSize: 13,
          color: c.secondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

typedef _UtilityTopUpSubmit =
    Future<void> Function({
      required double units,
      required double amount,
      required String provider,
      required String notes,
      required DateTime date,
    });

typedef _LukuTopUpImport =
    Future<void> Function(List<LukuSmsTopUpDraft> drafts);

class _UtilityTopUpSheet extends StatefulWidget {
  const _UtilityTopUpSheet({
    required this.isLuku,
    required this.onSubmit,
    required this.onImportLukuTopUps,
  });

  final bool isLuku;
  final _UtilityTopUpSubmit onSubmit;
  final _LukuTopUpImport onImportLukuTopUps;

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
  bool _scanning = false;

  static const _providers = <String>[
    'SMS OCR',
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
          colorScheme: Theme.of(
            ctx,
          ).colorScheme.copyWith(primary: AppColors.colorPrimary),
        ),
        child: child!,
      ),
      locale: const Locale('en', 'GB'),
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

  Future<void> _scanLukuSmsPhoto() async {
    if (_submitting || _scanning) return;
    final source = await _pickImageSource();
    if (source == null || !mounted) return;

    setState(() => _scanning = true);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 92,
      );
      if (!mounted) return;
      if (image == null) return;

      final recognized = await recognizer.processImage(
        InputImage.fromFilePath(image.path),
      );
      final drafts = const LukuSmsOcrParser().parse(recognized.text);
      if (!mounted) return;

      if (drafts.isEmpty) {
        _showScanMessage(
          _isSw
              ? 'Hatukupata ujumbe wa LUKU kwenye picha hii.'
              : 'No LUKU token messages were found in this image.',
        );
      } else if (drafts.length == 1) {
        _applyDraftToForm(drafts.single);
        _showScanMessage(
          _isSw
              ? 'Taarifa za LUKU zimejazwa. Hakiki kisha hifadhi.'
              : 'LUKU details filled. Review them, then save.',
        );
      } else {
        await _confirmImportMany(drafts);
      }
    } on Exception catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      final denied = msg.contains('permission') ||
          msg.contains('denied') ||
          msg.contains('access');
      _showScanMessage(
        denied
            ? (_isSw
                ? 'Ruhusu kamera au picha kwenye mipangilio kisha jaribu tena.'
                : 'Allow camera or photo access in Settings, then try again.')
            : (_isSw
                ? 'Imeshindikana kusoma picha. Jaribu picha iliyo wazi zaidi.'
                : 'Could not read this image. Try a clearer screenshot or photo.'),
      );
    } finally {
      await recognizer.close();
      if (mounted) setState(() => _scanning = false);
    }
  }

  /// Source chooser must use the root navigator — this sheet is already a
  /// modal, and a nested bottom sheet often never appears.
  Future<ImageSource?> _pickImageSource() {
    final c = FormSurfaceColors.of(context);
    return showDialog<ImageSource>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: c.card,
          title: Text(
            _isSw ? 'Soma picha ya SMS' : 'Scan SMS photo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.headline,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.colorPrimary,
                ),
                title: Text(
                  _isSw ? 'Piga picha' : 'Take photo',
                  style: TextStyle(color: c.headline),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.colorPrimary,
                ),
                title: Text(
                  _isSw ? 'Chagua picha' : 'Choose from photos',
                  style: TextStyle(color: c.headline),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(_isSw ? 'Ghairi' : 'Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _applyDraftToForm(LukuSmsTopUpDraft draft) {
    setState(() {
      _unitsCtrl.text = _formatNumber(draft.unitsKwh);
      _amountCtrl.text = _formatNumber(draft.amountTsh);
      _notesCtrl.text = draft.notes;
      _date = draft.date;
      _provider = 'SMS OCR';
    });
  }

  Future<void> _confirmImportMany(List<LukuSmsTopUpDraft> drafts) async {
    final importAll = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            _isSw
                ? 'Malipo ${drafts.length} yamepatikana'
                : '${drafts.length} LUKU top-ups found',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSw
                      ? 'Unataka kuyaingiza yote?'
                      : 'Do you want to import all of them?',
                ),
                const SizedBox(height: 12),
                ...drafts.take(6).map(_importPreviewTile),
                if (drafts.length > 6)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _isSw
                          ? 'Na mengine ${drafts.length - 6}'
                          : 'And ${drafts.length - 6} more',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(_isSw ? 'HAPANA' : 'NO'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.colorPrimary),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(_isSw ? 'INGIZA YOTE' : 'IMPORT ALL'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (importAll == true) {
      setState(() => _submitting = true);
      try {
        await widget.onImportLukuTopUps(drafts);
        if (mounted) Navigator.of(context).pop();
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    } else if (drafts.isNotEmpty) {
      _applyDraftToForm(drafts.first);
      _showScanMessage(
        _isSw
            ? 'Taarifa ya kwanza imejazwa kwa uhakiki.'
            : 'The first record has been filled for review.',
      );
    }
  }

  Widget _importPreviewTile(LukuSmsTopUpDraft draft) {
    final dateLabel =
        '${draft.date.day.toString().padLeft(2, '0')}/${draft.date.month.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$dateLabel • ${_formatNumber(draft.unitsKwh)} kWh • '
        '${Get.find<CurrencyService>().formatBase(draft.amountTsh.round())} • Meter ${draft.meterNumber}',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showScanMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
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
    final unitHint = isLuku
        ? (_isSw ? 'Weka vitengo (mf. 50)' : 'Enter units (e.g. 50)')
        : (_isSw ? 'Weka lita (mf. 1500)' : 'Enter liters (e.g. 1500)');
    final amountHint = _isSw
        ? 'Weka kiasi kilicholipwa (mf. 35000)'
        : 'Enter amount paid (e.g. 35000)';
    final notesHint = isLuku
        ? (_isSw
            ? 'Maelezo hiari (mf. Meter 01013211901)'
            : 'Optional notes (e.g. Meter 01013211901)')
        : (_isSw
            ? 'Maelezo hiari (mf. DAWASA Account 12345)'
            : 'Optional notes (e.g. DAWASA Account 12345)');
    final icon = isLuku ? Icons.bolt_outlined : Icons.water_drop_outlined;
    final dateLabel =
        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
    final c = FormSurfaceColors.of(context);
    final isDark = c.isDark;
    final hintColor =
        isDark ? const Color(0xFFD1D1D6) : const Color(0xFF6B7280);
    final fieldFill =
        isDark ? const Color(0xFF1C1C1E) : c.inputFill;
    final fieldBorder =
        isDark ? const Color(0xFF636366) : c.border;

    final sheet = Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
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
                        color: c.border,
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
                          color: AppColors.colorPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: AppColors.colorPrimary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: c.headline,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_outlined),
                        color: c.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (isLuku) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: (_submitting || _scanning)
                            ? null
                            : _scanLukuSmsPhoto,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.colorPrimary,
                          side: const BorderSide(color: AppColors.colorPrimary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _scanning
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.colorPrimary,
                                ),
                              )
                            : const Icon(Icons.document_scanner_outlined),
                        label: Text(
                          _scanning
                              ? (_isSw
                                    ? 'INASOMA PICHA...'
                                    : 'SCANNING PHOTO...')
                              : (_isSw
                                    ? 'SOMA PICHA YA SMS'
                                    : 'SCAN SMS PHOTO'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _fieldLabel(unitLabel),
                  TextFormField(
                    controller: _unitsCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: c.headline,
                    ),
                    decoration: _inputDecoration(
                      hint: unitHint,
                      hintColor: hintColor,
                      fill: fieldFill,
                      borderColor: fieldBorder,
                    ),
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
                  _fieldLabel(
                    _isSw
                        ? 'Kiasi (${Get.find<CurrencyService>().inputSuffix})'
                        : 'Amount Paid (${Get.find<CurrencyService>().inputSuffix})',
                  ),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: c.headline,
                    ),
                    decoration: _inputDecoration(
                      hint: amountHint,
                      hintColor: hintColor,
                      fill: fieldFill,
                      borderColor: fieldBorder,
                    ),
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.headline,
                    ),
                    dropdownColor: c.dropdownBg,
                    decoration: _inputDecoration(
                      hintColor: hintColor,
                      fill: fieldFill,
                      borderColor: fieldBorder,
                    ),
                    items: _providers
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                              p,
                              style: TextStyle(color: c.headline),
                            ),
                          ),
                        )
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
                      decoration: _inputDecoration(
                        hintColor: hintColor,
                        fill: fieldFill,
                        borderColor: fieldBorder,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.event_outlined,
                            size: 18,
                            color: AppColors.colorPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateLabel,
                            style: TextStyle(
                              fontSize: 14,
                              color: c.headline,
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
                    style: TextStyle(
                      fontSize: 15,
                      color: c.headline,
                    ),
                    decoration: _inputDecoration(
                      hint: notesHint,
                      hintColor: hintColor,
                      fill: fieldFill,
                      borderColor: fieldBorder,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.colorPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _submitting ? null : _handleSubmit,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isLuku
                                  ? (_isSw ? 'ONGEZA LUKU' : 'ADD LUKU UNITS')
                                  : (_isSw ? 'ONGEZA MAJI' : 'ADD WATER UNITS'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
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

    return Theme(
      data: Theme.of(context).copyWith(
        hintColor: hintColor,
        inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
          hintStyle: TextStyle(
            color: hintColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      child: sheet,
    );
  }

  Widget _fieldLabel(String text) {
    final c = FormSurfaceColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w700,
          color: c.secondary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hint,
    required Color hintColor,
    required Color fill,
    required Color borderColor,
  }) {
    const radius = BorderRadius.all(Radius.circular(12));
    return InputDecoration(
      isDense: false,
      hintText: hint,
      hintMaxLines: 2,
      hintStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: hintColor,
      ),
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.colorPrimary, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Color(0xFFDC2626)),
      ),
    );
  }
}
