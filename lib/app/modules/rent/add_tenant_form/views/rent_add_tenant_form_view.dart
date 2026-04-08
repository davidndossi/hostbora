import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/widget/custom_app_bar.dart';
import '../../rent_theme.dart';
import '../controllers/rent_add_tenant_form_controller.dart';

/// Concierge “Add New Tenant” — beige canvas, dark teal accents, serif headlines.
class RentAddTenantFormView extends BaseView<RentAddTenantFormController> {
  RentAddTenantFormView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  static const _labelStyle = TextStyle(
    fontSize: 10,
    letterSpacing: 1.25,
    fontWeight: FontWeight.w700,
    color: Color(0xFF6B7280),
  );

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(appBarTitleText: _isSw ? 'Ongeza Mpangaji' : 'Add tenant');
  }

  @override
  Widget body(BuildContext context) {
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
                style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF4B5563)),
                children: [
                  TextSpan(text: _isSw ? 'Unganisha mpangaji na ' : 'Link a tenant to '),
                  TextSpan(
                    text: name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 22),
          _sectionCard(
            children: [
              const Text('TENANT NAME', style: _labelStyle),
              const SizedBox(height: 8),
              _whiteField(
                controller: controller.tenantNameController,
                hint: _isSw ? 'mf. Julianne Moore' : 'e.g. Julianne Moore',
                textInputAction: TextInputAction.next,
                validator: controller.validateTenantName,
              ),
              const SizedBox(height: 16),
              const Text('GENDER', style: _labelStyle),
              const SizedBox(height: 8),
              Obx(
                () => _whiteDropdown<String>(
                  value: controller.gender.value,
                  options: RentAddTenantFormController.genderOptions,
                  onChanged: controller.setGender,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _sectionCard(
            children: [
              const Text('RENT AMOUNT', style: _labelStyle),
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
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2E2E2E)),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: '0.00',
                        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 12, right: 4),
                          child: Text(
                            '\$',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A)),
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
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: Obx(
                      () => _whiteDropdown<String>(
                        value: controller.rentFrequency.value,
                        options: RentAddTenantFormController.rentFrequencyOptions,
                        onChanged: controller.setRentFrequency,
                        compact: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('LEASE PERIOD', style: _labelStyle),
              const SizedBox(height: 8),
              _leaseDateRangeField(context),
            ],
          ),
          const SizedBox(height: 14),
          _sectionCard(
            children: [
              const Text('PHONE NUMBER', style: _labelStyle),
              const SizedBox(height: 8),
              _whiteField(
                controller: controller.phoneController,
                hint: _isSw ? '+255 7XX XXX XXX' : '+1 (555) 000-0000',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: controller.validatePhone,
              ),
              const SizedBox(height: 16),
              RichText(
                text: const TextSpan(
                  style: _labelStyle,
                  children: [
                    TextSpan(text: 'EMAIL '),
                    TextSpan(
                      text: '(optional)',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.25,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _whiteField(
                controller: controller.emailController,
                hint: 'julianne@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                validator: controller.validateEmailOptional,
              ),
              const SizedBox(height: 14),
              Obx(
                () => Material(
                  color: Colors.white,
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
                            onChanged: controller.setWhatsapp,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isSw ? 'Hii ni namba yangu ya WhatsApp' : 'This is my WhatsApp number',
                            style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
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
          _residentBanner(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: controller.saveTenant,
              style: FilledButton.styleFrom(
                foregroundColor: Colors.white,
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
                foregroundColor: const Color(0xFF1A1A1A),
                backgroundColor: const Color(0xFFF3F2EF),
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

  Widget _leaseDateRangeField(BuildContext context) {
    final dateFmt = DateFormat.yMMMd();
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
        color: Colors.white,
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
                      color: hasRange ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                const Icon(Icons.expand_more_rounded, color: Color(0xFF3D3D3D)),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RentTheme.sectionMist,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _whiteField({
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
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _whiteDropdown<T>({
    required T value,
    required List<T> options,
    required ValueChanged<T?> onChanged,
    bool compact = false,
  }) {
    final v = options.contains(value) ? value : options.first;
    return DropdownButtonFormField<T>(
      initialValue: v,
      isExpanded: true,
      icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF3D3D3D)),
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 12 : 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      dropdownColor: Colors.white,
      items: options
          .map((e) => DropdownMenuItem<T>(value: e, child: Text('$e')))
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
