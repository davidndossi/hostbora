import 'package:flutter/material.dart';
import 'package:host_bora/app/core/theme/app_theme_tokens.dart';

import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../../../core/utils/thousand_separator.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_define_tenant_charges_controller.dart';

class _ChargesUi {
  _ChargesUi(this.context);

  final BuildContext context;

  ThemeData get _t => Theme.of(context);

  bool get dark => _t.brightness == Brightness.dark;

  static const Color teal = Color(0xFF005D5D);

  Color get brandTeal => dark ? const Color(0xFF4DB6AC) : teal;

  Color get onSurface => dark ? const Color(0xFFF2F2F7) : const Color(0xFF1A1A1A);

  Color get onSurfaceSecondary => dark ? const Color(0xFFAEAEB2) : const Color(0xFF374151);

  Color get muted => dark ? const Color(0xFF8E8E93) : const Color(0xFF757575);

  Color get labelCaps => dark ? const Color(0xFF98989D) : const Color(0xFF616161);

  Color get fieldFill => dark ? context.tokens.elevatedSurface : const Color(0xFFEBEBEB);

  Color get sectionBg => dark ? context.tokens.cardBackground : const Color(0xFFF0F0EE);

  Color get card => _t.cardColor;

  Color get border => dark ? const Color(0xFF48484A) : const Color(0xFFE0DFDC);

  Color get insightBg => dark ? const Color(0xFF1E2E2C) : const Color(0xFFE8EEED);

  Color get accentOrange => dark ? const Color(0xFFFF8A65) : const Color(0xFFC05020);

  Color get prefixText => dark ? const Color(0xFFD1D1D6) : const Color(0xFF4A4A4A);

  Color get imagePlaceholder => dark ? context.tokens.elevatedSurface : const Color(0xFFBDBDBD);

  Color get dragHandle => dark ? const Color(0xFF636366) : const Color(0xFFBDBDBD);

  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.35 : 0.06),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  List<BoxShadow> get chargeRowShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.28 : 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
}

/// **Tenant Charges** — new charge form, property banner, defined charges, insight.
class RentDefineTenantChargesView extends RentBaseView<RentDefineTenantChargesController> {
  RentDefineTenantChargesView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(_isSw ? 'Bainisha Tozo za Mpangaji' : 'Define Tenant Charges');

  @override
  Widget body(BuildContext context) {
    final u = _ChargesUi(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _newChargeCard(u),
            const SizedBox(height: 18),
            _propertyBanner(u),
            const SizedBox(height: 20),
            _definedChargesSection(u),
            const SizedBox(height: 20),
            _editorialInsight(u),
          ],
        ),
      ),
    );
  }

  Widget _newChargeCard(_ChargesUi u) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: u.cardShadow,
        border: u.dark ? Border.all(color: u.border.withValues(alpha: 0.55)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? 'Ingizo Jipya la Tozo' : 'New Charge Entry',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: u.brandTeal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSw
                ? 'Bainisha wajibu wa kifedha kwa mkataba unaokuja wa upangaji.'
                : 'Specify the financial obligations for the upcoming tenancy agreement.',
            style: TextStyle(fontSize: 13, height: 1.4, color: u.muted),
          ),
          const SizedBox(height: 18),
          _capsLabel(u, 'CHARGE TYPE'),
          const SizedBox(height: 8),
          Obx(
            () => DropdownButtonFormField<String>(
              initialValue: RentDefineTenantChargesController.chargeTypeOptions
                      .contains(controller.selectedChargeType.value)
                  ? controller.selectedChargeType.value
                  : RentDefineTenantChargesController.chargeTypeOptions.first,
              decoration: _inputDeco(u),
              dropdownColor: u.card,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: u.onSurface,
              ),
              icon: Icon(Icons.expand_more_rounded, color: u.onSurface),
              items: RentDefineTenantChargesController.chargeTypeOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: controller.updateChargeType,
            ),
          ),
          const SizedBox(height: 14),
          _capsLabel(u, 'AMOUNT'),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller.amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            inputFormatters: [
              ThousandsSeparatorInputFormatter()
            ],
            validator: controller.validateAmount,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: u.onSurface),
            cursorColor: u.brandTeal,
            decoration: InputDecoration(
              filled: true,
              fillColor: u.fieldFill,
              prefixText: 'Tsh ',
              prefixStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: u.prefixText,
              ),
              hintText: '0.00',
              hintStyle: TextStyle(color: u.muted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: u.border.withValues(alpha: u.dark ? 0.45 : 0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: u.brandTeal, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            ),
          ),
          const SizedBox(height: 14),
          _capsLabel(u, _isSw ? 'MAELEZO NA MASHARTI' : 'DESCRIPTION & TERMS'),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller.descriptionController,
            minLines: 4,
            maxLines: 8,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            textCapitalization: TextCapitalization.sentences,
            validator: controller.validateDescription,
            style: TextStyle(color: u.onSurface, fontSize: 14, height: 1.35),
            cursorColor: u.brandTeal,
            decoration: InputDecoration(
              filled: true,
              fillColor: u.fieldFill,
              alignLabelWithHint: true,
              hintText: _isSw
                  ? 'Weka masharti maalum au mgawanyo wa tozo...'
                  : 'Enter specific terms or breakdown of the charge...',
              hintStyle: TextStyle(color: u.muted, height: 1.35),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 8, right: 8),
                child: Align(
                  alignment: Alignment.bottomRight,
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Icon(Icons.drag_indicator, size: 18, color: u.dragHandle),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: u.border.withValues(alpha: u.dark ? 0.45 : 0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: u.brandTeal, width: 1.5),
              ),
              contentPadding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => controller.submitCharge(addAnother: false),
              style: FilledButton.styleFrom(
                backgroundColor: _ChargesUi.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _isSw ? 'Hifadhi Tozo' : 'Save Charge',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => controller.submitCharge(addAnother: true),
              icon: Icon(Icons.add, size: 20, color: u.brandTeal),
              label: Text(
                _isSw ? 'Ongeza Nyingine' : 'Add Another',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: u.brandTeal),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: u.brandTeal,
                side: BorderSide(color: u.brandTeal, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _propertyBanner(_ChargesUi u) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Image.asset(
              'images/luxury_room_view.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: u.imagePlaceholder,
                child: Icon(Icons.apartment, size: 48, color: u.onSurface.withValues(alpha: 0.45)),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: u.accentOrange,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _isSw ? 'MALI ILIYOCHAGULIWA' : 'SELECTED PROPERTY',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Obx(
              () => Text(
                controller.selectedPropertyTitle.value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _definedChargesSection(_ChargesUi u) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: u.sectionBg,
        borderRadius: BorderRadius.circular(16),
        border: u.dark ? Border.all(color: u.border.withValues(alpha: 0.45)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _isSw ? 'Tozo Zilizobainishwa' : 'Defined Charges',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: u.onSurface,
                  ),
                ),
              ),
              Obx(
                () => Text(
                  'TOTAL: ${controller.totalFormatted}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: u.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Obx(
            () => Column(
              children: [
                ...controller.charges.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _chargeRow(u, c),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chargeRow(_ChargesUi u, TenantChargeEntry c) {
    final (bg, iconColor, icon) = controller.styleForChargeType(c.chargeType);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: u.chargeRowShadow,
        border: u.dark ? Border.all(color: u.border.withValues(alpha: 0.4)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.chargeType,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: u.onSurface),
                ),
                if (c.subtitleLine.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    c.subtitleLine,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      fontStyle: FontStyle.italic,
                      color: u.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            c.amountFormatted,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: u.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _editorialInsight(_ChargesUi u) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: u.insightBg,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: u.brandTeal, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: u.brandTeal.withValues(alpha: 0.95)),
              const SizedBox(width: 8),
              Text(
                'EDITORIAL INSIGHT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: u.brandTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 13, height: 1.45, color: u.onSurfaceSecondary),
              children: [
                const TextSpan(text: 'Most high-end properties in Dar es Salaam require a '),
                TextSpan(
                  text: '3-month security deposit',
                  style: TextStyle(fontWeight: FontWeight.w800, color: u.onSurface),
                ),
                const TextSpan(
                  text: ' as standard. Ensure your utility fees cover both water and basic maintenance.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _capsLabel(_ChargesUi u, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w800,
        color: u.labelCaps,
      ),
    );
  }

  InputDecoration _inputDeco(_ChargesUi u) {
    return InputDecoration(
      filled: true,
      fillColor: u.fieldFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: u.border.withValues(alpha: u.dark ? 0.45 : 0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: u.brandTeal, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }
}
