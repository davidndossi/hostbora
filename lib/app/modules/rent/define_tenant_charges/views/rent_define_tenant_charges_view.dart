import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_define_tenant_charges_controller.dart';

/// **Tenant Charges** — new charge form, property banner, defined charges, insight, bottom nav.
class RentDefineTenantChargesView extends BaseView<RentDefineTenantChargesController> {
  RentDefineTenantChargesView({super.key});

  static const _teal = Color(0xFF005D5D);
  static const _fieldFill = Color(0xFFEBEBEB);
  static const _accentOrange = Color(0xFFC05020);
  static const _sectionGrey = Color(0xFFF0F0EE);

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Define Tenant Charges');

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          _newChargeCard(),
          const SizedBox(height: 18),
          _propertyBanner(),
          const SizedBox(height: 20),
          _definedChargesSection(),
          const SizedBox(height: 20),
          _editorialInsight(),
        ],
        ),
      ),
    );
  }

  Widget _newChargeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Charge Entry',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _teal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Specify the financial obligations for the upcoming tenancy agreement.',
            style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 18),
          _capsLabel('CHARGE TYPE'),
          const SizedBox(height: 8),
          Obx(
            () => DropdownButtonFormField<String>(
              initialValue: RentDefineTenantChargesController.chargeTypeOptions
                      .contains(controller.selectedChargeType.value)
                  ? controller.selectedChargeType.value
                  : RentDefineTenantChargesController.chargeTypeOptions.first,
              decoration: _inputDeco(),
              icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF3D3D3D)),
              items: RentDefineTenantChargesController.chargeTypeOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: controller.updateChargeType,
            ),
          ),
          const SizedBox(height: 14),
          _capsLabel('AMOUNT'),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller.amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: controller.validateAmount,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            decoration: InputDecoration(
              filled: true,
              fillColor: _fieldFill,
              prefixText: 'Tsh ',
              prefixStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF4A4A4A),
              ),
              hintText: '0.00',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            ),
          ),
          const SizedBox(height: 14),
          _capsLabel('DESCRIPTION & TERMS'),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller.descriptionController,
            minLines: 4,
            maxLines: 8,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: controller.validateDescription,
            decoration: InputDecoration(
              filled: true,
              fillColor: _fieldFill,
              alignLabelWithHint: true,
              hintText: 'Enter specific terms or breakdown of the charge...',
              hintStyle: TextStyle(color: Colors.grey.shade500, height: 1.35),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 8, right: 8),
                child: Align(
                  alignment: Alignment.bottomRight,
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Icon(Icons.drag_indicator, size: 18, color: Colors.grey.shade400),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
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
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Save Charge',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => controller.submitCharge(addAnother: true),
              icon: const Icon(Icons.add, size: 20, color: _teal),
              label: const Text(
                'Add Another',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _teal),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _teal,
                side: const BorderSide(color: _teal, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _propertyBanner() {
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
                color: Colors.grey.shade400,
                child: const Icon(Icons.apartment, size: 48, color: Colors.white),
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
                color: _accentOrange,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'SELECTED PROPERTY',
                style: TextStyle(
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

  Widget _definedChargesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _sectionGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Defined Charges',
                  style: TextStyle(
                    
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Obx(
                () => Text(
                  'TOTAL: ${controller.totalFormatted}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
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
                      child: _chargeRow(c),
                    )),
              ],
            ),
          ),
          // _awaitingPlaceholder(),
        ],
      ),
    );
  }

  Widget _chargeRow(TenantChargeEntry c) {
    final (bg, iconColor, icon) = controller.styleForChargeType(c.chargeType);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                if (c.subtitleLine.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    c.subtitleLine,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            c.amountFormatted,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _awaitingPlaceholder() {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
  //     margin: const EdgeInsets.only(top: 4),
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: Colors.grey.shade400, width: 1.2),
  //       color: Colors.white.withValues(alpha: 0.5),
  //     ),
  //     child: Column(
  //       children: [
  //         Icon(Icons.payments_outlined, size: 32, color: Colors.grey.shade400),
  //         const SizedBox(height: 8),
  //         Text(
  //           'AWAITING ADDITIONAL ENTRIES',
  //           style: TextStyle(
  //             fontSize: 11,
  //             fontWeight: FontWeight.w800,
  //             letterSpacing: 0.8,
  //             color: Colors.grey.shade500,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _editorialInsight() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEED),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: _teal, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: _teal.withValues(alpha: 0.9)),
              const SizedBox(width: 8),
              const Text(
                'EDITORIAL INSIGHT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: _teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 13, height: 1.45, color: Colors.grey.shade800),
              children: const [
                TextSpan(text: 'Most high-end properties in Dar es Salaam require a '),
                TextSpan(
                  text: '3-month security deposit',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(
                  text: ' as standard. Ensure your utility fees cover both water and basic maintenance.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _capsLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w800,
        color: Colors.grey.shade700,
      ),
    );
  }

  InputDecoration _inputDeco() {
    return InputDecoration(
      filled: true,
      fillColor: _fieldFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }
}
