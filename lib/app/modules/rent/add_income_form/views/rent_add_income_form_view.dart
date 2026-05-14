import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/widget/custom_app_bar.dart';
import '../controllers/rent_add_income_form_controller.dart';

class RentAddIncomeFormView extends BaseView<RentAddIncomeFormController> {
  RentAddIncomeFormView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  DateTime _parseExistingDate(String raw) {
    final parts = raw.trim().split('/');
    if (parts.length != 3) return DateTime.now();
    final month = int.tryParse(parts[0]) ?? 0;
    final day = int.tryParse(parts[1]) ?? 0;
    final year = int.tryParse(parts[2]) ?? 0;
    if (month < 1 || month > 12 || day < 1 || day > 31 || year < 1900) {
      return DateTime.now();
    }
    return DateTime(year, month, day);
  }

  Future<void> _pickDatePaid(BuildContext context) async {
    final now = DateTime.now();
    final initial = controller.datePaidController.text.trim().isEmpty
        ? now
        : _parseExistingDate(controller.datePaidController.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    final month = picked.month.toString().padLeft(2, '0');
    final day = picked.day.toString().padLeft(2, '0');
    final year = picked.year.toString();
    controller.datePaidController.text = '$day/$month/$year';
  }

  @override
  Color pageBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF9F8F6);
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) => CustomAppBar(
    appBarTitleText: _isSw ? 'Ongeza Mapato' : 'Add Income'
  );

  @override
  Widget body(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headlineColor = isDark ? Colors.white : const Color(0xFF2E2E2E);
    final hintMuted = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8A8A8A);
    final dropdownText = isDark ? Colors.white : const Color(0xFF1F2937);
    final chevronColor = isDark ? const Color(0xFFAEAEB2) : const Color(0xFF3D3D3D);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            _isSw ? 'Rekodi mjengopo kwa mjengo hii' : 'Record a payment for this property',
            style: TextStyle(fontSize: 18, color: headlineColor, height: 1.3),
          ),
          const SizedBox(height: 22),
          _label(_isSw ? 'CHAGUA MJENGO' : 'SELECT PROPERTY', isDark: isDark),
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
                    isExpanded: true,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: dropdownText,
                    ),
                    dropdownColor:
                        isDark ? const Color(0xFF2C2C2E) : Colors.white,
                    icon: Icon(Icons.expand_more_rounded, color: chevronColor),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: _isSw ? 'Chagua mjengo' : 'Choose property',
                      hintStyle: TextStyle(color: hintMuted, fontSize: 16),
                    ),
                    validator: controller.validateSelectedProperty,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    items: controller.propertyDropdownMenuItems(dropdownText),
                    onChanged: hasProperties ? controller.updateSelectedProperty : null,
                  ),
                  if (!hasProperties)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 2),
                      child: Text(
                        _isSw ? 'Bado hakuna mjengo - ongeza mjengo kwanza.' : 'No properties yet - add property first.',
                        style: TextStyle(fontSize: 12, color: hintMuted),
                      ),
                    ),
                ],
              );
            },
          ),
          Obx(() {
            if (!controller.showIncomeUnitPicker) {
              return const SizedBox.shrink();
            }
            final units = controller.incomeUnitsForSelectedProperty;
            if (units.isEmpty) return const SizedBox.shrink();
            final sel = controller.selectedIncomeUnitKey.value;
            final valid =
                sel != null && units.any((u) => u.selectionKey == sel);
            final value = valid ? sel : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _label(_isSw ? 'KITENGO (HIARI)' : 'UNIT (OPTIONAL)', isDark: isDark),
                DropdownButtonFormField<String?>(
                  initialValue: value,
                  isExpanded: true,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: dropdownText,
                  ),
                  dropdownColor:
                      isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  icon: Icon(Icons.expand_more_rounded, color: chevronColor),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: _isSw ? 'Chagua kitengo' : 'Select unit',
                    hintStyle: TextStyle(color: hintMuted, fontSize: 15),
                  ),
                  items: controller.unitIncomeDropdownMenuItems(
                    itemColor: dropdownText,
                    hintColor: hintMuted,
                    optionalWholePropertyLabel: _isSw
                        ? 'Sio lazima — mjengo wote'
                        : 'Optional — whole property',
                  ),
                  onChanged: controller.updateSelectedIncomeUnit,
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          // _label(_isSw ? 'CHAGUA MPANGAJI' : 'SELECT TENANT', isDark: isDark),
          // _field(
          //   isDark,
          //   controller.tenantController,
          //   hint: _isSw ? 'Chagua mgeni au mkazi wa muda mrefu' : 'Choose a guest or long-term resident',
          //   suffix: Icons.expand_more,
          //   validator: controller.validateTenant,
          // ),
          // const SizedBox(height: 16),
          _label(_isSw ? 'KIASI KILICHOLIPWA' : 'AMOUNT PAID', isDark: isDark),
          _field(
            isDark,
            controller.amountController,
            hint: 'TZS 0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: controller.validateAmount,
            inputFormatters: [controller.amountThousandsFormatter],
          ),
          const SizedBox(height: 16),
          _label(_isSw ? 'TAREHE YA MALIPO' : 'DATE PAID', isDark: isDark),
          _field(
            isDark,
            controller.datePaidController,
            hint: _isSw ? 'dd/MM/yyyy' : 'dd/MM/yyyy',
            suffix: Icons.calendar_today_outlined,
            readOnly: true,
            onTap: () => _pickDatePaid(context),
            validator: controller.validateDatePaid,
          ),
          const SizedBox(height: 16),
          _label(_isSw ? 'KATEGORIA' : 'CATEGORY', isDark: isDark),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                controller.categories.length,
                (i) => _CategoryChip(
                  isDark: isDark,
                  label: controller.categories[i],
                  selected: controller.selectedCategoryIndex.value == i,
                  onTap: () => controller.selectCategory(i),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _label(_isSw ? 'MAELEZO (HIARI)' : 'NOTES (OPTIONAL)', isDark: isDark),
          _field(
            isDark,
            controller.notesController,
            hint: _isSw ? 'Ongeza maelezo yoyote kuhusu muamala huu...' : 'Add any specific details regarding this transaction...',
            minHeight: 120,
            isMultiline: true,
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF4F3EF),
              borderRadius: BorderRadius.circular(14),
              border: isDark
                  ? Border.all(color: const Color(0xFF3A3A3C))
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ImpactIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSw ? 'Athari kwa Utendaji' : 'Impact on Performance',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0E0E0E),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isSw
                            ? 'Kurekodi mapato haya\nkutasasisha mara moja\ntakwimu za mapato ya mwezi\nna ripoti za thamani ya ujazaji.'
                            : 'Recording this income will\nimmediately update your monthly\nrevenue stats and occupancy value\nreports.',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFAEAEB2)
                              : const Color(0xFF2B2B2B),
                          fontSize: 13,
                          height: 1.35,
                        ),
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
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  _isSw ? 'Ghairi' : 'Cancel',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark
                        ? const Color(0xFFE8E8ED)
                        : const Color(0xFF111111),
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

  Widget _label(String text, {required bool isDark}) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
          ),
        ),
      );

  Widget _field(
    bool isDark,
    TextEditingController fieldController, {
    required String hint,
    IconData? suffix,
    bool isMultiline = false,
    double minHeight = 48,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    final textColor =
        isDark ? const Color(0xFFE8E8ED) : const Color(0xFF5B5B5B);
    final hintColor =
        isDark ? const Color(0xFF8E8E93) : const Color(0xFF5B5B5B).withValues(alpha: 0.72);
    final hintStyle = TextStyle(
      fontSize: 14,
      color: hintColor,
      height: isMultiline ? 1.35 : 1.2,
    );
    final suffixColor =
        isDark ? const Color(0xFFAEAEB2) : const Color(0xFF2D2D2D);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A3A3C) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: fieldController,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType ?? TextInputType.text,
        inputFormatters: inputFormatters,
        maxLines: isMultiline ? null : 1,
        minLines: isMultiline ? 3 : 1,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        textCapitalization: TextCapitalization.sentences,
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
                    color: suffixColor,
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
    required this.isDark,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final bool isDark;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? const Color(0xFF006D73)
        : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF1F1EE));
    final fg = selected
        ? Colors.white
        : (isDark ? const Color(0xFFE8E8ED) : const Color(0xFF1E1E1E));
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
              color: fg,
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
