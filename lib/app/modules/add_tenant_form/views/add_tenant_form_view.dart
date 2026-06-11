import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_view.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/utils/tenant_rent_billing.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widget/currency_dropdown_field.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/widget/loading_button.dart';
import '../controllers/add_tenant_form_controller.dart';

class AddTenantFormView extends BaseView<AddTenantFormController> {
  AddTenantFormView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  String _rentRateLabel(String frequency) {
    final f = frequency.trim().toLowerCase();
    if (_isSw) {
      switch (f) {
        case 'per night':
        case 'per day':
          return 'KODI (KWA USIKU)';
        case 'per week':
          return 'KODI (KWA WIKI)';
        case 'per year':
          return 'KODI (KWA MWAKA)';
        case 'per month':
        default:
          return 'KODI (KWA MWEZI)';
      }
    }
    switch (f) {
      case 'per night':
      case 'per day':
        return 'RATE PER NIGHT';
      case 'per week':
        return 'RENT RATE (PER WEEK)';
      case 'per year':
        return 'RENT RATE (PER YEAR)';
      case 'per month':
      default:
        return 'RENT RATE (PER MONTH)';
    }
  }

  TextStyle _labelStyle(FormSurfaceColors colors) => TextStyle(
        fontSize: 10,
        letterSpacing: 1.25,
        fontWeight: FontWeight.w700,
        color: colors.sectionLabel,
      );

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(appBarTitleText: _isSw ? 'Ongeza Mpangaji' : 'Add tenant');
  }

  @override
  Widget body(BuildContext context) {
    final c = FormSurfaceColors.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const SizedBox(height: 10),
          Obx(() {
            final name = controller.propertyContextLabel.value;
            return RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, height: 1.4, color: c.secondary),
                children: [
                  TextSpan(text: _isSw ? 'Unganisha mpangaji na ' : 'Link a tenant to '),
                  TextSpan(
                    text: name,
                    style: TextStyle(fontWeight: FontWeight.w700, color: c.headline),
                  ),
                ],
              ),
            );
          }),
          Obx(() {
            if (controller.availableUnitDrafts.isEmpty) return const SizedBox.shrink();
            final keys = controller.unitSelectionKeys;
            if (keys.isEmpty) return const SizedBox.shrink();
            final sel = controller.selectedUnitKey.value;
            final value = sel != null && keys.contains(sel) ? sel : null;
            return Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _sectionCard(
                colors: c,
                children: [
                  Text(
                    _isSw ? 'KITENGO CHA GHOROFA' : 'APARTMENT UNIT',
                    style: _labelStyle(c),
                  ),
                  const SizedBox(height: 8),
                  _whiteDropdown<String>(
                    colors: c,
                    value: value,
                    options: keys,
                    hintText: _isSw ? 'Chagua kitengo' : 'Select unit',
                    labelForOption: controller.unitDisplayLabel,
                    onChanged: controller.setSelectedUnitKey,
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 22),
          _sectionCard(
            colors: c,
            children: [
              Text('TENANT NAME', style: _labelStyle(c)),
              const SizedBox(height: 8),
              _whiteField(
                colors: c,
                controller: controller.tenantNameController,
                hint: _isSw ? 'mf. Aisha Mohammed' : 'e.g. Julianne Moore',
                textInputAction: TextInputAction.next,
                validator: controller.validateTenantName,
              ),
              const SizedBox(height: 16),
              Text('GENDER', style: _labelStyle(c)),
              const SizedBox(height: 8),
              Obx(
                () => _whiteDropdown<String>(
                  colors: c,
                  value: controller.gender.value,
                  options: AddTenantFormController.genderOptions,
                  onChanged: controller.setGender,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _sectionCard(
            colors: c,
            children: [
              Obx(
                () => Text(
                  controller.isRentFlow.value
                      ? (_isSw ? 'KODI' : 'RENT AMOUNT')
                      : _rentRateLabel(controller.rentFrequency.value),
                  style: _labelStyle(c),
                ),
              ),
              const SizedBox(height: 8),
              Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Amount field — full width so numbers are never clipped ──
                  TextFormField(
                    controller: controller.rentAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    onChanged: controller.isRentFlow.value
                        ? null
                        : controller.onRentAmountChanged,
                    validator: controller.validateRentAmount,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.headline,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: c.inputFill,
                      hintText: '0.00',
                      hintStyle: TextStyle(color: c.hint),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 4),
                        child: Text(
                          '${controller.selectedCurrency.value} ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: c.secondary,
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ── Currency + Frequency on their own row ──────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: CurrencyDropdownField(
                          selectedCurrency: controller.selectedCurrency,
                          label: _isSw ? 'Sarafu' : 'Currency',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _whiteDropdown<String>(
                          colors: c,
                          value: controller.rentFrequency.value,
                          options: controller.rentFrequencyOptions,
                          onChanged: controller.setRentFrequency,
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                ],
              )),
              const SizedBox(height: 16),
              Text('LEASE PERIOD', style: _labelStyle(c)),
              const SizedBox(height: 8),
              _leaseDateRangeField(context, c),
              Obx(() {
                if (controller.isRentFlow.value) return const SizedBox.shrink();
                final total = controller.stayTotalPreview.value;
                final units = controller.stayBillingUnits.value;
                if (total <= 0 || units <= 0) return const SizedBox.shrink();
                final freq = controller.rentFrequency.value;
                final isPerDay = freq.trim().toLowerCase() == 'per night' || freq.trim().toLowerCase() == 'per day';
                final unitLabel = isPerDay
                    ? (units == 1
                        ? (_isSw ? 'usiku' : 'night')
                        : (_isSw ? 'usiku' : 'nights'))
                    : () {
                        final period =
                            TenantRentBilling.periodLabel(freq, sw: _isSw);
                        return units == 1 ? period : '${period}s';
                      }();
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _isSw
                        ? 'Jumla ya kukaa ($units $unitLabel): TZS ${NumberFormat('#,###').format(total.round())}'
                        : 'Total for stay ($units $unitLabel): TZS ${NumberFormat('#,###').format(total.round())}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.secondary,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 14),
          _sectionCard(
            colors: c,
            children: [
              Text('PHONE NUMBER', style: _labelStyle(c)),
              const SizedBox(height: 8),
              _whiteField(
                colors: c,
                controller: controller.phoneController,
                hint: '07XXXXXXXX',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: controller.validatePhone,
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: _labelStyle(c),
                  children: [
                    const TextSpan(text: 'EMAIL '),
                    TextSpan(
                      text: '(optional)',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.25,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        color: c.sectionLabel,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _whiteField(
                colors: c,
                controller: controller.emailController,
                hint: 'julianne@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                validator: controller.validateEmailOptional,
              ),
              const SizedBox(height: 14),
              Obx(
                () => Material(
                  color: c.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: controller.isWhatsapp.value,
                            activeColor: AppColors.colorPrimary,
                            checkColor: Colors.white,
                            side: BorderSide(color: c.border),
                            onChanged: controller.setWhatsapp,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isSw ? 'Hii ni namba yangu ya WhatsApp' : 'This is my WhatsApp number',
                            style: TextStyle(
                              fontSize: 14,
                              color: c.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(
            () => LoadingButton(
              label: _isSw ? 'HIFADHI MPANGAJI' : 'SAVE TENANT',
              onPressed: controller.saveTenant,
              isLoading: controller.saving.value,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Get.back(),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.secondary,
                backgroundColor: c.isDark ? c.fill : c.chipUnselectedBg,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(_isSw ? 'GHAIRI' : 'CANCEL', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _leaseDateRangeField(BuildContext context, FormSurfaceColors colors) {
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Obx(() {
      final start = controller.leaseStart.value;
      final end = controller.leaseEnd.value;
      final String label;
      final bool hasRange;
      if (start != null && end != null) {
        hasRange = true;
        label = '${dateFmt.format(start)} – ${dateFmt.format(end)}';
      } else {
        hasRange = false;
        label = _isSw ? 'Mwanzo – mwisho wa mkataba' : 'Lease start – end';
      }
      return Material(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () async {
            final now = DateTime.now();
            final initial = hasRange && start != null && end != null
                ? DateTimeRange(start: start, end: end)
                : DateTimeRange(
                    start: now,
                    end: now.add(const Duration(days: 365)),
                  );
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(now.year - 2),
              lastDate: DateTime(now.year + 10, 12, 31),
              initialDateRange: initial,
              locale: const Locale('en', 'GB'),
            );
            if (picked != null) {
              controller.setLeaseDateRange(picked);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.date_range_outlined, size: 22, color: AppColors.colorPrimary.withValues(alpha: 0.9)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: hasRange ? colors.headline : colors.hint,
                    ),
                  ),
                ),
                Icon(Icons.expand_more_rounded, color: colors.secondary),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _sectionCard({required FormSurfaceColors colors, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: colors.isDark ? Border.all(color: colors.border) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _whiteField({
    required FormSurfaceColors colors,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      textCapitalization: TextCapitalization.words,
      validator: validator,
      style: TextStyle(
        fontSize: 15,
        color: colors.headline,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: colors.inputFill,
        hintText: hint,
        hintStyle: TextStyle(
          color: colors.hint,
          fontSize: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _whiteDropdown<T>({
    required FormSurfaceColors colors,
    T? value,
    required List<T> options,
    required ValueChanged<T?> onChanged,
    bool compact = false,
    String? hintText,
    String Function(T value)? labelForOption,
  }) {
    String label(T e) => labelForOption != null ? labelForOption(e) : '$e';

    return DropdownButtonFormField<T>(
      initialValue: value != null && options.contains(value) ? value : null,
      isExpanded: true,
      hint: hintText != null
          ? Text(hintText, style: TextStyle(color: colors.hint, fontSize: 15))
          : null,
      icon: Icon(Icons.expand_more_rounded, color: colors.secondary),
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.headline),
      decoration: InputDecoration(
        filled: true,
        fillColor: colors.inputFill,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 12 : 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      dropdownColor: colors.dropdownBg,
      items: options
          .map(
            (e) => DropdownMenuItem<T>(
              value: e,
              child: Text(
                label(e),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.headline,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
