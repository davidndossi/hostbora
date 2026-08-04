import 'package:flutter/material.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/theme/form_surface_colors.dart';

import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/widget/loading_button.dart';
import '../../../data/local/service/currency_service.dart';
import '../controllers/add_new_booking_controller.dart';

const _bookingNavTeal = Color(0xFF1E8877);

class AddNewBookingView extends BaseView<AddNewBookingController> {
  AddNewBookingView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: context.tokens.textPrimary,
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
        color: FormSurfaceColors.of(context).hint,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: FormSurfaceColors.of(context).isDark
          ? const Color(0xFF1F1F1F)
          : AppColors.colorWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: BorderSide(
          color: FormSurfaceColors.of(context).inputBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: BorderSide(
          color: FormSurfaceColors.of(context).inputBorder,
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
      return LoadingButton(
        label: isSaving
            ? _t(context, en: 'Saving...', sw: 'Inahifadhi...')
            : _t(context, en: 'Save booking', sw: 'Hifadhi booking'),
        onPressed: controller.saveBooking,
        isLoading: isSaving,
        icon: Icons.calendar_today,
        minimumSize: const Size.fromHeight(AppValues.formButtonHeight + 4),
        style: ElevatedButton.styleFrom(
          backgroundColor: _bookingNavTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppValues.radius_6),
          ),
          elevation: 0,
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
                            color: context.tokens.textPrimary,
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
              textCapitalization: TextCapitalization.words,
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
                      en: 'e.g. 0712345678',
                      sw: 'mf. 0712345678',
                    ),
                  ).copyWith(
                    suffixIcon: Icon(
                      Icons.phone_outlined,
                      size: 22,
                      color: FormSurfaceColors.of(context).isDark
                          ? Colors.white70
                          : AppColors.designPlaceholder,
                    ),
                  ),
              validator: controller.validateGuestPhone,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 20),
            Obx(() {
              final sendLink = controller.sendPaymentLink.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: sendLink,
                          onChanged: (v) =>
                              controller.setSendPaymentLink(v ?? false),
                          activeColor: _bookingNavTeal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => controller.setSendPaymentLink(!sendLink),
                          child: _buildLabel(
                            context,
                            _t(
                              context,
                              en: 'Send Snippe payment link via WhatsApp',
                              sw: 'Tuma kiungo cha malipo cha Snippe kupitia WhatsApp',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (sendLink) ...[
                    const SizedBox(height: 12),
                    _buildLabel(
                      context,
                      _t(
                        context,
                        en: 'Amount (${Get.find<CurrencyService>().inputSuffix})',
                        sw: 'Kiasi (${Get.find<CurrencyService>().inputSuffix})',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.pushToPayAmountController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        context,
                        hint: _t(context, en: 'e.g. 50000', sw: 'mf. 50000'),
                      ),
                      validator: controller.validatePaymentLinkAmount,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _t(
                        context,
                        en: 'Requires internet. Guest receives a WhatsApp message with a secure payment link.',
                        sw: 'Inahitaji mtandao. Mgeni atapokea ujumbe wa WhatsApp wenye kiungo cha malipo.',
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: FormSurfaceColors.of(context).isDark
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
                    color: FormSurfaceColors.of(context).isDark
                        ? const Color(0xFF1F1F1F)
                        : AppColors.colorWhite,
                    borderRadius: BorderRadius.circular(AppValues.radius_6),
                    border: Border.all(
                      color: FormSurfaceColors.of(context).inputBorder,
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
                          color: FormSurfaceColors.of(context).isDark
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
                        color: FormSurfaceColors.of(context).isDark
                            ? Colors.white70
                            : AppColors.designPlaceholder,
                      ),
                    ),
                hint: Text(
                  _t(context, en: 'Choose a listing', sw: 'Chagua tangazo'),
                  style: TextStyle(
                    color: FormSurfaceColors.of(context).isDark
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
                validator: controller.validateProperty,
              );
            }),
            const SizedBox(height: 20),
            Obx(() {
              if (controller.propertyUnits.length <= 1) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(
                    context,
                    _t(context, en: 'Select Property Unit', sw: 'Chagua Unit ya Jengo'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: controller.selectedUnitId.value,
                    decoration:
                        _inputDecoration(
                          context,
                          hint: _t(context, en: 'Choose a unit', sw: 'Chagua unit'),
                        ).copyWith(
                          suffixIcon: Icon(
                            Icons.keyboard_arrow_down,
                            color: FormSurfaceColors.of(context).isDark
                                ? Colors.white70
                                : AppColors.designPlaceholder,
                          ),
                        ),
                    hint: Text(
                      _t(context, en: 'Choose a unit', sw: 'Chagua unit'),
                      style: TextStyle(
                        color: FormSurfaceColors.of(context).isDark
                            ? Colors.white70
                            : AppColors.designPlaceholder,
                        fontSize: 16,
                      ),
                    ),
                    icon: const SizedBox.shrink(),
                    isExpanded: true,
                    items: controller.propertyUnits
                        .map(
                          (u) => DropdownMenuItem<String>(
                            value: u.id,
                            child: Text(u.unitName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => controller.selectedUnitId.value = v,
                    validator: controller.validateUnit,
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }),
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
                      TextFormField(
                        readOnly: true,
                        onTap: controller.pickCheckIn,
                        controller: controller.checkInDateController,
                        decoration:
                            _inputDecoration(
                              context,
                              hint: _t(context, en: 'Select date', sw: 'Chagua tarehe'),
                            ).copyWith(
                              suffixIcon: Icon(
                                Icons.calendar_today_outlined,
                                size: 20,
                                color: FormSurfaceColors.of(context).isDark
                                    ? Colors.white70
                                    : AppColors.designPlaceholder,
                              ),
                            ),
                        validator: controller.validateCheckIn,
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
                      TextFormField(
                        readOnly: true,
                        onTap: controller.pickCheckOut,
                        controller: controller.checkOutDateController,
                        decoration:
                          _inputDecoration(
                            context,
                            hint: _t(context, en: 'Select date', sw: 'Chagua tarehe'),
                          ).copyWith(
                            suffixIcon: Icon(
                              Icons.calendar_today_outlined,
                              size: 20,
                              color: FormSurfaceColors.of(context).isDark
                                  ? Colors.white70
                                  : AppColors.designPlaceholder,
                            ),
                          ),
                        validator: controller.validateCheckOut,
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
                      color: FormSurfaceColors.of(context).isDark
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
