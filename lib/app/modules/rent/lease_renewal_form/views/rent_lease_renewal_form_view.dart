import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_lease_renewal_form_controller.dart';

class _RenewalUi {
  _RenewalUi(this.context);

  final BuildContext context;
  ThemeData get _t => Theme.of(context);
  bool get dark => _t.brightness == Brightness.dark;

  /// Design cream; dark uses scaffold.
  Color get canvas =>
      dark ? _t.scaffoldBackgroundColor : const Color(0xFFF8F8F5);

  Color get card => dark ? _t.cardColor : Colors.white;

  Color get onSurface =>
      dark ? const Color(0xFFF2F2F7) : const Color(0xFF111827);

  Color get muted =>
      dark ? const Color(0xFFAEAEB2) : const Color(0xFF6B7280);

  static const Color forest = Color(0xFF004D40);
  static const Color lightTeal = Color(0xFF80CBC4);
  static const Color expenseBrown = Color(0xFF8B3A3A);

  Color get forestAccent => dark ? lightTeal : forest;

  Color get iconCircleBg =>
      dark ? const Color(0xFF3A3A3C) : RentTheme.sectionMist;

  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.28 : 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

/// Lease renewal — Concierge Editorial layout (cream, teal, serif sections, white cards).
class RentLeaseRenewalFormView extends BaseView<RentLeaseRenewalFormController> {
  RentLeaseRenewalFormView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  Color pageBackgroundColor(BuildContext context) => _RenewalUi(context).canvas;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return rentAppBar(
      _isSw ? 'Kuongeza mkataba' : 'Lease Renewal',
    );
  }

  @override
  Widget body(BuildContext context) {
    final u = _RenewalUi(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(
          () => controller.loadingRealData.value
              ? const LinearProgressIndicator(minHeight: 2)
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _screenHeader(context),
                  const SizedBox(height: 8),
                  Obx(() => _renewalInsightBanner(context)),
                  const SizedBox(height: 18),
                  _sectionCard(
                    context,
                    icon: Icons.person_outline_rounded,
                    title: _isSw ? 'Taarifa za mpangaji' : 'Tenant information',
                    children: [
                      _fieldLabel(context, _isSw ? 'JINA LA MPANGAJI' : 'TENANT NAME'),
                      const SizedBox(height: 8),
                      _textField(
                        context,
                        controller: controller.tenantNameController,
                        hint: _isSw ? 'mf. Aisha Mohammed' : 'e.g. Aisha Mohammed',
                        validator: controller.validateTenantName,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel(context, _isSw ? 'MALI / ANWANI' : 'PROPERTY / ADDRESS'),
                      const SizedBox(height: 8),
                      _textField(
                        context,
                        controller: controller.propertyLineController,
                        hint: _isSw ? 'Mali au kitengo' : 'Building or unit line',
                        validator: controller.validateProperty,
                        textInputAction: TextInputAction.next,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    context,
                    icon: Icons.description_outlined,
                    title: _isSw ? 'Masharti mapya ya mkataba' : 'New lease terms',
                    children: [
                      _fieldLabel(context, _isSw ? 'KIPINDI CHA MKATABA MPYA' : 'NEW LEASE PERIOD'),
                      const SizedBox(height: 8),
                      _leaseDateRangeField(context),
                      const SizedBox(height: 16),
                      _fieldLabel(context, _isSw ? 'KIASI CHA KODI (TZS)' : 'RENT AMOUNT (TZS)'),
                      const SizedBox(height: 8),
                      _textField(
                        context,
                        controller: controller.rentAmountController,
                        hint: _isSw ? 'Si lazima' : 'Optional',
                        keyboardType: TextInputType.number,
                        validator: controller.validateRent,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel(context, _isSw ? 'MZUNGUKO WA MALIPO' : 'RENT FREQUENCY'),
                      const SizedBox(height: 8),
                      _frequencyDropdown(context),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    context,
                    icon: Icons.sticky_note_2_outlined,
                    title: _isSw ? 'Maelezo ya ziada' : 'Internal notes',
                    children: [
                      _fieldLabel(
                        context,
                        _isSw ? 'MAELEZO (SI LAZIMA)' : 'NOTES (OPTIONAL)',
                      ),
                      const SizedBox(height: 8),
                      _textField(
                        context,
                        controller: controller.notesController,
                        hint: _isSw
                            ? 'Vigezo maalum, marekebisho ya kodi…'
                            : 'Special terms, adjustments…',
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: controller.submitRenewal,
                      style: FilledButton.styleFrom(
                        backgroundColor: _RenewalUi.forest,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _isSw ? 'WASILISHA UHUISHAJI' : 'SUBMIT RENEWAL',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Get.back(),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            u.dark ? const Color(0xFF3A3A3C) : const Color(0xFFE8E8E8),
                        foregroundColor: u.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isSw ? 'GHAIRI' : 'CANCEL',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _screenHeader(BuildContext context) {
    final u = _RenewalUi(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSw ? 'UHESHIMI WA MKATABA' : 'LEASE RENEWAL',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
            color: u.muted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isSw ? 'Panua au sasisha mkataba' : 'Extend or update the lease',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1.15,
            color: u.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _renewalInsightBanner(BuildContext context) {
    final d = controller.realData.value;
    if (d == null) return const SizedBox.shrink();
    final u = _RenewalUi(context);
    if (d.expiringLeasesIn30Days == 0) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _RenewalUi.forest.withValues(alpha: u.dark ? 0.35 : 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _RenewalUi.forest.withValues(alpha: u.dark ? 0.5 : 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_outlined, color: u.forestAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isSw
                  ? '${d.expiringLeasesIn30Days} mikataba inakaribia kuisha ndani ya siku 30.'
                  : '${d.expiringLeasesIn30Days} lease(s) expiring within 30 days.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: u.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final u = _RenewalUi(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: u.cardShadow,
        border: u.dark
            ? Border.all(color: const Color(0xFF3A3A3C).withValues(alpha: 0.85))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: u.iconCircleBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: u.forestAccent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: u.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _fieldLabel(BuildContext context, String text) {
    final u = _RenewalUi(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        letterSpacing: 1.15,
        fontWeight: FontWeight.w800,
        color: u.muted,
      ),
    );
  }

  Widget _textField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    final u = _RenewalUi(context);
    final fill = u.dark ? const Color(0xFF3A3A3C) : const Color(0xFFFAFAF8);
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: u.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: u.muted.withValues(alpha: 0.85),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: u.dark ? const Color(0xFF48484A) : RentTheme.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: u.dark ? const Color(0xFF48484A) : RentTheme.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _RenewalUi.forest, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _RenewalUi.expenseBrown.withValues(alpha: 0.8)),
        ),
      ),
    );
  }

  Widget _leaseDateRangeField(BuildContext context) {
    final u = _RenewalUi(context);
    final dateFmt = DateFormat.yMMMd();
    final fill = u.dark ? const Color(0xFF3A3A3C) : const Color(0xFFFAFAF8);

    return Obx(() {
      final start = controller.newLeaseStart.value;
      final end = controller.newLeaseEnd.value;
      final hasRange = start != null && end != null;
      final label = hasRange
          ? '${dateFmt.format(start)} – ${dateFmt.format(end)}'
          : (_isSw ? 'Gusa kuchagua tarehe' : 'Tap to select dates');

      return Material(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () async {
            final now = DateTime.now();
            final initial = hasRange
                ? DateTimeRange(start: start, end: end)
                : DateTimeRange(
                    start: now,
                    end: now.add(const Duration(days: 365)),
                  );
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(now.year - 1),
              lastDate: DateTime(now.year + 10, 12, 31),
              initialDateRange: initial,
              builder: (ctx, child) {
                return Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: Theme.of(ctx).colorScheme.copyWith(
                          primary: _RenewalUi.forest,
                        ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) controller.setNewLeaseRange(picked);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: u.dark ? const Color(0xFF48484A) : RentTheme.border,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.date_range_outlined, color: u.forestAccent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: hasRange ? u.onSurface : u.muted,
                    ),
                  ),
                ),
                Icon(Icons.expand_more_rounded, color: u.muted),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _frequencyDropdown(BuildContext context) {
    final u = _RenewalUi(context);
    final fill = u.dark ? const Color(0xFF3A3A3C) : const Color(0xFFFAFAF8);

    String label(String en) {
      if (!_isSw) return en;
      switch (en) {
        case 'Monthly':
          return 'Kila mwezi';
        case 'Quarterly':
          return 'Kila robo mwaka';
        case 'Annually':
          return 'Kila mwaka';
        default:
          return en;
      }
    }

    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: u.dark ? const Color(0xFF48484A) : RentTheme.border,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: controller.rentFrequency.value,
            isExpanded: true,
            icon: Icon(Icons.expand_more_rounded, color: u.muted),
            dropdownColor: u.card,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: u.onSurface,
            ),
            items: RentLeaseRenewalFormController.frequencyOptions
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(label(e)),
                  ),
                )
                .toList(),
            onChanged: controller.setRentFrequency,
          ),
        ),
      ),
    );
  }
}
