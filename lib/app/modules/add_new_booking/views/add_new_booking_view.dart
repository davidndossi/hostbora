import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:paa_yangu/app/core/widget/custom_app_bar.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../data/service/azampay_service.dart';
import '../controllers/add_new_booking_controller.dart';

const _bookingNavTeal = Color(0xFF1E8877);

class AddNewBookingView extends BaseView<AddNewBookingController> {
  AddNewBookingView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: _isDark(context) ? Colors.white : AppColors.textColorPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: _isDark(context) ? Colors.white70 : AppColors.designPlaceholder,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _isDark(context)
          ? const Color(0xFF1F1F1F)
          : AppColors.colorWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: BorderSide(
          color: _isDark(context)
              ? Colors.white.withValues(alpha: 0.18)
              : AppColors.designInputBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: BorderSide(
          color: _isDark(context)
              ? Colors.white.withValues(alpha: 0.18)
              : AppColors.designInputBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: const BorderSide(color: AppColors.designAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: const BorderSide(color: AppColors.errorColor),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Obx(() {
      final isSaving = controller.saving.value;
      return SizedBox(
        width: double.infinity,
        height: AppValues.formButtonHeight + 4,
        child: ElevatedButton.icon(
          onPressed: isSaving ? null : controller.saveBooking,
          icon: isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.calendar_today, size: 20, color: Colors.white),
          label: Text(
            isSaving
                ? _t(context, en: 'Saving...', sw: 'Inahifadhi...')
                : _t(context, en: 'Save Booking', sw: 'Hifadhi Uhifadhi'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _bookingNavTeal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppValues.radius_6),
            ),
            elevation: 0,
          ),
        ),
      );
    });
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.addBooking,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              final pending = controller.pendingCount.value;
              final syncing = controller.syncing.value;
              if (pending > 0) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.colorPrimaryLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppValues.radius_6),
                    border: Border.all(
                      color: AppColors.colorPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        syncing ? Icons.sync : Icons.cloud_off_outlined,
                        size: 22,
                        color: AppColors.colorPrimary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          syncing
                              ? _t(
                                  context,
                                  en: 'Syncing offline bookings...',
                                  sw: 'Inasawazisha uhifadhi wa nje ya mtandao...',
                                )
                              : '$pending ${_t(context, en: 'booking', sw: 'uhifadhi')}${pending == 1 ? '' : 's'} ${_t(context, en: 'saved offline. Will sync when online.', sw: 'umehifadhiwa nje ya mtandao. Yatasawazishwa mtandaoni.')}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _isDark(context)
                                ? Colors.white
                                : AppColors.textColorPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            _buildLabel(
              context,
              _t(context, en: 'Guest Name', sw: 'Jina la Mgeni'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.guestNameController,
              decoration: _inputDecoration(
                context,
                hint: _t(
                  context,
                  en: "Enter guest's full name",
                  sw: 'Weka jina kamili la mgeni',
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? _t(
                      context,
                      en: 'Guest name is required',
                      sw: 'Jina la mgeni linahitajika',
                    )
                  : null,
            ),
            const SizedBox(height: 20),
            _buildLabel(
              context,
              _t(context, en: 'Phone Number', sw: 'Namba ya Simu'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.guestPhoneController,
              keyboardType: TextInputType.phone,
              decoration:
                  _inputDecoration(
                    context,
                    hint: _t(
                      context,
                      en: 'e.g. 255 712 345 678',
                      sw: 'mf. 255 712 345 678',
                    ),
                  ).copyWith(
                    suffixIcon: Icon(
                      Icons.phone_outlined,
                      size: 22,
                      color: _isDark(context)
                          ? Colors.white70
                          : AppColors.designPlaceholder,
                    ),
                  ),
            ),
            const SizedBox(height: 20),
            Obx(() {
              if (!controller.isAzamPayEnabled) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: controller.sendPushToPay.value,
                          onChanged: (v) =>
                              controller.setSendPushToPay(v ?? false),
                          activeColor: _bookingNavTeal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => controller.setSendPushToPay(
                            !controller.sendPushToPay.value,
                          ),
                          child: _buildLabel(
                            context,
                            _t(
                              context,
                              en: 'Send Push to Pay to guest (AzamPay)',
                              sw: 'Tuma ombi la Push to Pay kwa mgeni (AzamPay)',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (controller.sendPushToPay.value) ...[
                    const SizedBox(height: 12),
                    _buildLabel(
                      context,
                      _t(context, en: 'Amount (TZS)', sw: 'Kiasi (TZS)'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.pushToPayAmountController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        context,
                        hint: _t(context, en: 'e.g. 50000', sw: 'mf. 50000'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLabel(
                      context,
                      _t(
                        context,
                        en: 'Mobile provider',
                        sw: 'Mtoa huduma wa simu',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: controller.selectedProvider.value,
                      decoration:
                          _inputDecoration(
                            context,
                            hint: _t(
                              context,
                              en: 'Provider',
                              sw: 'Mtoa huduma',
                            ),
                          ).copyWith(
                            suffixIcon: Icon(
                              Icons.keyboard_arrow_down,
                              color: _isDark(context)
                                  ? Colors.white70
                                  : AppColors.designPlaceholder,
                            ),
                          ),
                      isExpanded: true,
                      items: azamPayProviders
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e),
                            ),
                          )
                          .toList(),
                      onChanged: controller.selectProvider,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _t(
                        context,
                        en: 'A payment request will be sent to the guest\'s phone.',
                        sw: 'Ombi la malipo litatumwa kwenye simu ya mgeni.',
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: _isDark(context)
                            ? Colors.white70
                            : AppColors.designPlaceholder,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else
                    const SizedBox(height: 20),
                ],
              );
            }),
            _buildLabel(
              context,
              _t(context, en: 'Select Property', sw: 'Chagua Mali'),
            ),
            const SizedBox(height: 8),
            Obx(() {
              if (controller.listingsLoading.value) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: _isDark(context)
                        ? const Color(0xFF1F1F1F)
                        : AppColors.colorWhite,
                    borderRadius: BorderRadius.circular(AppValues.radius_6),
                    border: Border.all(
                      color: _isDark(context)
                          ? Colors.white.withValues(alpha: 0.18)
                          : AppColors.designInputBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _t(
                          context,
                          en: 'Loading properties...',
                          sw: 'Inapakia mali...',
                        ),
                        style: TextStyle(
                          color: _isDark(context)
                              ? Colors.white70
                              : AppColors.designPlaceholder,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 12),
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ),
                );
              }
              return DropdownButtonFormField<String>(
                initialValue: controller.selectedListingId.value,
                decoration:
                    _inputDecoration(
                      context,
                      hint: _t(
                        context,
                        en: 'Choose a listing',
                        sw: 'Chagua tangazo',
                      ),
                    ).copyWith(
                      suffixIcon: Icon(
                        Icons.keyboard_arrow_down,
                        color: _isDark(context)
                            ? Colors.white70
                            : AppColors.designPlaceholder,
                      ),
                    ),
                hint: Text(
                  _t(context, en: 'Choose a listing', sw: 'Chagua tangazo'),
                  style: TextStyle(
                    color: _isDark(context)
                        ? Colors.white70
                        : AppColors.designPlaceholder,
                    fontSize: 16,
                  ),
                ),
                icon: const SizedBox.shrink(),
                isExpanded: true,
                items: controller.listings
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e.id,
                        child: Text(e.propertyName),
                      ),
                    )
                    .toList(),
                onChanged: controller.selectProperty,
                validator: (v) => v == null || v.isEmpty
                    ? _t(
                        context,
                        en: 'Please select a property',
                        sw: 'Tafadhali chagua mali',
                      )
                    : null,
              );
            }),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(
                        context,
                        _t(
                          context,
                          en: 'Check-in Date',
                          sw: 'Tarehe ya Kuingia',
                        ),
                      ),
                      const SizedBox(height: 8),
                      _DateField(
                        label: controller.checkInLabel,
                        onTap: controller.pickCheckIn,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(
                        context,
                        _t(
                          context,
                          en: 'Check-out Date',
                          sw: 'Tarehe ya Kutoka',
                        ),
                      ),
                      const SizedBox(height: 8),
                      _DateField(
                        label: controller.checkOutLabel,
                        onTap: controller.pickCheckOut,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildLabel(
              context,
              _t(context, en: 'Number of Guests', sw: 'Idadi ya Wageni'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.numberOfGuestsController,
              keyboardType: TextInputType.number,
              decoration:
                  _inputDecoration(
                    context,
                    hint: _t(context, en: 'e.g. 2', sw: 'mf. 2'),
                  ).copyWith(
                    suffixIcon: Icon(
                      Icons.people_outline,
                      size: 22,
                      color: _isDark(context)
                          ? Colors.white70
                          : AppColors.designPlaceholder,
                    ),
                  ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return _t(
                    context,
                    en: 'Number of guests is required',
                    sw: 'Idadi ya wageni inahitajika',
                  );
                }
                final n = int.tryParse(v.trim());
                if (n == null || n < 1) {
                  return _t(
                    context,
                    en: 'Enter a valid number',
                    sw: 'Weka namba sahihi',
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildLabel(context, _t(context, en: 'Notes', sw: 'Maelezo')),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.notesController,
              maxLines: 3,
              decoration: _inputDecoration(
                context,
                hint: _t(
                  context,
                  en: 'Any special requests or details...',
                  sw: 'Mahitaji maalum au maelezo...',
                ),
              ),
            ),
            const SizedBox(height: 28),
            _buildSaveButton(context),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DateField({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSw = Get.locale?.languageCode == 'sw';
    return Material(
      color: isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
      borderRadius: BorderRadius.circular(AppValues.radius_6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppValues.radius_6),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : AppColors.designInputBorder,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label == 'Select date' && isSw ? 'Chagua tarehe' : label,
                  style: TextStyle(
                    fontSize: 16,
                    color: (label == 'Select date' || label == 'Chagua tarehe')
                        ? (isDark
                              ? Colors.white70
                              : AppColors.designPlaceholder)
                        : (isDark ? Colors.white : AppColors.textColorPrimary),
                  ),
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: isDark ? Colors.white70 : AppColors.designPlaceholder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
