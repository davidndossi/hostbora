import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/add_tenant_form_controller.dart';

class AddTenantFormView extends BaseView<AddTenantFormController> {
  AddTenantFormView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  TextStyle _labelStyle(bool isDark) => TextStyle(
        fontSize: 10,
        letterSpacing: 1.25,
        fontWeight: FontWeight.w700,
        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
      );

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(appBarTitleText: _isSw ? 'Ongeza Mpangaji' : 'Add tenant');
  }

  @override
  Widget body(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final introMuted = isDark ? const Color(0xFF8E8E93) : const Color(0xFF4B5563);
    final introStrong = isDark ? Colors.white : const Color(0xFF1F2937);

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
                style: TextStyle(fontSize: 14, height: 1.4, color: introMuted),
                children: [
                  TextSpan(text: _isSw ? 'Unganisha mpangaji na ' : 'Link a tenant to '),
                  TextSpan(
                    text: name,
                    style: TextStyle(fontWeight: FontWeight.w700, color: introStrong),
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
                isDark: isDark,
                children: [
                  Text(
                    _isSw ? 'KITENGO CHA GHOROFA' : 'APARTMENT UNIT',
                    style: _labelStyle(isDark),
                  ),
                  const SizedBox(height: 8),
                  _whiteDropdown<String>(
                    isDark: isDark,
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
            isDark: isDark,
            children: [
              Text('TENANT NAME', style: _labelStyle(isDark)),
              const SizedBox(height: 8),
              _whiteField(
                isDark: isDark,
                controller: controller.tenantNameController,
                hint: _isSw ? 'mf. Aisha Mohammed' : 'e.g. Julianne Moore',
                textInputAction: TextInputAction.next,
                validator: controller.validateTenantName,
              ),
              const SizedBox(height: 16),
              Text('GENDER', style: _labelStyle(isDark)),
              const SizedBox(height: 8),
              Obx(
                () => _whiteDropdown<String>(
                  isDark: isDark,
                  value: controller.gender.value,
                  options: AddTenantFormController.genderOptions,
                  onChanged: controller.setGender,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _sectionCard(
            isDark: isDark,
            children: [
              Text('RENT AMOUNT', style: _labelStyle(isDark)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: controller.rentAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: controller.validateRentAmount,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF2E2E2E),
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? const Color(0xFF3A3A3C) : Colors.white,
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF9CA3AF),
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 4),
                          child: Text(
                            'Tshs.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFAEAEB2) : const Color(0xFF4A4A4A),
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
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('LEASE PERIOD', style: _labelStyle(isDark)),
              const SizedBox(height: 8),
              _leaseDateRangeField(context, isDark),
            ],
          ),
          const SizedBox(height: 14),
          _sectionCard(
            isDark: isDark,
            children: [
              Text('PHONE NUMBER', style: _labelStyle(isDark)),
              const SizedBox(height: 8),
              _whiteField(
                isDark: isDark,
                controller: controller.phoneController,
                hint: '07XXXXXXXX',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: controller.validatePhone,
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: _labelStyle(isDark),
                  children: [
                    const TextSpan(text: 'EMAIL '),
                    TextSpan(
                      text: '(optional)',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.25,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _whiteField(
                isDark: isDark,
                controller: controller.emailController,
                hint: 'julianne@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                validator: controller.validateEmailOptional,
              ),
              const SizedBox(height: 14),
              Obx(
                () => Material(
                  color: isDark ? const Color(0xFF3A3A3C) : Colors.white,
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
                            side: BorderSide(
                              color: isDark ? const Color(0xFF636366) : const Color(0xFFD1D5DB),
                            ),
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
                              color: isDark ? const Color(0xFFE8E8ED) : const Color(0xFF374151),
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
          // const SizedBox(height: 20),
          // _residentBanner(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: controller.saveTenant,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _isSw ? 'HIFADHI MPANGAJI' : 'SAVE TENANT',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Get.back(),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    isDark ? const Color(0xFFE8E8ED) : const Color(0xFF1A1A1A),
                backgroundColor:
                    isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF3F2EF),
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

  Widget _leaseDateRangeField(BuildContext context, bool isDark) {
    final dateFmt = DateFormat.yMMMd();
    final fieldBg = isDark ? const Color(0xFF3A3A3C) : Colors.white;
    final chevronColor = isDark ? const Color(0xFFAEAEB2) : const Color(0xFF3D3D3D);

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
        label = _isSw ? 'Mwanzo wa mkataba – mwisho' : 'Lease start – end';
      }
      return Material(
        color: fieldBg,
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
                      color: hasRange
                          ? (isDark ? Colors.white : const Color(0xFF1F2937))
                          : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF9CA3AF)),
                    ),
                  ),
                ),
                Icon(Icons.expand_more_rounded, color: chevronColor),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _sectionCard({required bool isDark, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Color(0xFFEBE9E4),
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: const Color(0xFF3A3A3C)) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _whiteField({
    required bool isDark,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
  }) {
    final fill = isDark ? const Color(0xFF3A3A3C) : Colors.white;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      textCapitalization: TextCapitalization.words,
      validator: validator,
      style: TextStyle(
        fontSize: 15,
        color: isDark ? Colors.white : const Color(0xFF1F2937),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: fill,
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF9CA3AF),
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
    required bool isDark,
    T? value,
    required List<T> options,
    required ValueChanged<T?> onChanged,
    bool compact = false,
    String? hintText,
    String Function(T value)? labelForOption,
  }) {
    String label(T e) => labelForOption != null ? labelForOption(e) : '$e';
    final fill = isDark ? const Color(0xFF3A3A3C) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final hintColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF9CA3AF);
    final iconColor = isDark ? const Color(0xFFAEAEB2) : const Color(0xFF3D3D3D);

    return DropdownButtonFormField<T>(
      initialValue: value != null && options.contains(value) ? value : null,
      isExpanded: true,
      hint: hintText != null
          ? Text(hintText, style: TextStyle(color: hintColor, fontSize: 15))
          : null,
      icon: Icon(Icons.expand_more_rounded, color: iconColor),
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
      decoration: InputDecoration(
        filled: true,
        fillColor: fill,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 12 : 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      dropdownColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      items: options
          .map(
            (e) => DropdownMenuItem<T>(
              value: e,
              child: Text(
                label(e),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _residentBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.designAccent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -8,
            top: -12,
            child: Icon(
              Icons.person_add_alt_1_outlined,
              size: 96,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                child: const Icon(Icons.face_rounded, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 14),
              Text(
                _isSw ? 'Mpangaji Mpya Anaingia' : 'New Resident Entry',
                textAlign: TextAlign.center,
                style: TextStyle(
                  
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isSw
                    ? 'Kuunganisha mpangaji huyu kutazalisha kiotomatiki kifurushi cha ukaribisho na funguo za kidijitali za mali.'
                    : 'Linking this tenant will automatically generate a welcome package and digital access keys for the property.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
