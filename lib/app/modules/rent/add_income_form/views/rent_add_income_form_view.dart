import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/widget/custom_app_bar.dart';
import '../controllers/rent_add_income_form_controller.dart';

class RentAddIncomeFormView extends BaseView<RentAddIncomeFormController> {
  RentAddIncomeFormView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  Color pageBackgroundColor(BuildContext context) => const Color(0xFFF9F8F6);

  @override
  PreferredSizeWidget? appBar(BuildContext context) => CustomAppBar(
    appBarTitleText: _isSw ? 'Ongeza Mapato' : 'Add Income'
  );

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            _isSw ? 'Rekodi malipo kwa mali hii' : 'Record a payment for this property',
            style: TextStyle(fontSize: 18, color: Color(0xFF2E2E2E)),
          ),
          const SizedBox(height: 22),
          _label(_isSw ? 'CHAGUA MALI' : 'SELECT PROPERTY'),
          Obx(
            () {
              final hasProperties = controller.hasProperties;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: controller.propertyOptions.contains(controller.selectedProperty.value)
                        ? controller.selectedProperty.value
                        : null,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: _isSw ? 'Chagua mali' : 'Choose property',
                    ),
                    validator: controller.validateSelectedProperty,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    items: controller.propertyOptions
                        .map((p) => DropdownMenuItem<String>(value: p, child: Text(p)))
                        .toList(),
                    onChanged: hasProperties ? controller.updateSelectedProperty : null,
                  ),
                  if (!hasProperties)
                    Padding(
                      padding: EdgeInsets.only(top: 6, left: 2),
                      child: Text(
                        _isSw ? 'Bado hakuna mali - ongeza mali kwanza.' : 'No properties yet - add property first.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _label(_isSw ? 'CHAGUA MPANGAJI' : 'SELECT TENANT'),
          _field(
            controller.tenantController,
            hint: _isSw ? 'Chagua mgeni au mkazi wa muda mrefu' : 'Choose a guest or long-term resident',
            suffix: Icons.expand_more,
            validator: controller.validateTenant,
          ),
          const SizedBox(height: 16),
          _label(_isSw ? 'KIASI KILICHOLIPWA' : 'AMOUNT PAID'),
          _field(
            controller.amountController,
            hint: 'TZS 0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: controller.validateAmount,
          ),
          const SizedBox(height: 16),
          _label(_isSw ? 'TAREHE YA MALIPO' : 'DATE PAID'),
          _field(
            controller.datePaidController,
            hint: _isSw ? 'dd/mm/yyyy' : 'mm/dd/yyyy',
            suffix: Icons.calendar_today_outlined,
            validator: controller.validateDatePaid,
          ),
          const SizedBox(height: 16),
          _label(_isSw ? 'KATEGORIA' : 'CATEGORY'),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                controller.categories.length,
                (i) => _CategoryChip(
                  label: controller.categories[i],
                  selected: controller.selectedCategoryIndex.value == i,
                  onTap: () => controller.selectCategory(i),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _label(_isSw ? 'MAELEZO (HIARI)' : 'NOTES (OPTIONAL)'),
          _field(
            controller.notesController,
            hint: _isSw ? 'Ongeza maelezo yoyote maalum kuhusu muamala huu...' : 'Add any specific details regarding this transaction...',
            minHeight: 120,
            isMultiline: true,
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F3EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ImpactIcon(),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isSw ? 'Athari kwa Utendaji' : 'Impact on Performance',
                          style: TextStyle(
                              color: Color(0xFF0E0E0E),
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text(
                        _isSw
                            ? 'Kurekodi mapato haya\nkutasasisha mara moja\ntakwimu za mapato ya mwezi\nna ripoti za thamani ya ujazaji.'
                            : 'Recording this income will\nimmediately update your monthly\nrevenue stats and occupancy value\nreports.',
                        style: TextStyle(
                            color: Color(0xFF2B2B2B), fontSize: 13, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: controller.saveIncomeOffline,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF006D73),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11)),
              ),
              icon: const Icon(Icons.check, size: 20),
              label: Text(_isSw ? 'Hifadhi Mapato' : 'Save Income',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.center,
            child: InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  _isSw ? 'Ghairi' : 'Cancel',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF111111),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            )),
      );

  Widget _field(
    TextEditingController fieldController, {
    required String hint,
    IconData? suffix,
    bool isMultiline = false,
    double minHeight = 48,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    const textColor = Color(0xFF5B5B5B);
    final hintStyle = TextStyle(
      fontSize: 14,
      color: textColor.withValues(alpha: 0.72),
      height: isMultiline ? 1.35 : 1.2,
    );
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: fieldController,
        keyboardType: keyboardType ?? TextInputType.text,
        maxLines: isMultiline ? null : 1,
        minLines: isMultiline ? 3 : 1,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: validator,
        style: TextStyle(
          fontSize: 14,
          color: textColor,
          height: isMultiline ? 1.35 : 1.25,
        ),
        decoration: InputDecoration(
          isDense: false,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: hintStyle,
          suffixIcon: suffix == null
              ? null
              : Padding(
                  padding: EdgeInsets.only(left: 8, top: isMultiline ? 12 : 0),
                  child: Icon(
                    suffix,
                    size: 20,
                    color: const Color(0xFF2D2D2D),
                  ),
                ),
          suffixIconConstraints: BoxConstraints(
            minWidth: suffix != null ? 40 : 0,
            minHeight: suffix != null ? (isMultiline ? 52 : 40) : 0,
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF006D73) : const Color(0xFFF1F1EE);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        splashColor: selected ? Colors.white24 : Colors.black12,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF1E1E1E),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ImpactIcon extends StatelessWidget {
  const _ImpactIcon();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFA34E2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.account_balance_wallet_outlined,
          color: Colors.white, size: 19),
    );
  }
}
