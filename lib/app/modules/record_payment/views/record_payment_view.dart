import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/widget/currency_dropdown_field.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/widget/loading_button.dart';
import '../controllers/record_payment_controller.dart';

class RecordPaymentView extends BaseView<RecordPaymentController> {
  RecordPaymentView({super.key, this.sheetMode = false, this.scrollController});

  final bool sheetMode;
  final ScrollController? scrollController;

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  bool get applyModuleDefaultTextStyle => !sheetMode;

  /// Sheet host already pads for the keyboard — avoid double inset shrink.
  @override
  bool get resizeToAvoidBottomInset => !sheetMode;

  @override
  bool get safeAreaTop => !sheetMode;

  @override
  bool get safeAreaBottom => !sheetMode;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    if (sheetMode) return null;
    return CustomAppBar(
      appBarTitleText: appLocalization.addPayment,
      isCentered: true,
    );
  }

  @override
  Color pageBackgroundColor(BuildContext context) =>
      FormSurfaceColors.of(context).scaffold;

  @override
  Widget body(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final headlineColor = c.headline;
    final hintMuted = c.hint;
    final dropdownText = c.headline;
    final chevronColor = c.secondary;

    final content = SingleChildScrollView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(18, sheetMode ? 4 : 10, 18, 26),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSw
                  ? 'Rekodi malipo kwa mjengo huu'
                  : 'Record a payment for this property',
              style: TextStyle(fontSize: 18, color: headlineColor, height: 1.3),
            ),
            const SizedBox(height: 22),
            _label(_isSw ? 'CHAGUA MJENGO' : 'SELECT PROPERTY', colors: c),
            Obx(() {
              final hasProperties = controller.hasProperties;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    // Rebuild when options finish loading so the menu isn't stuck empty.
                    key: ValueKey(
                      'rp-property-${controller.propertyOptions.length}-'
                      '${controller.selectedProperty.value}',
                    ),
                    initialValue:
                        controller.propertyOptions.contains(
                          controller.selectedProperty.value,
                        )
                        ? controller.selectedProperty.value
                        : null,
                    isExpanded: true,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: dropdownText,
                    ),
                    dropdownColor: c.dropdownBg,
                    icon: Icon(Icons.expand_more_rounded, color: chevronColor),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: _isSw ? 'Chagua mjengo' : 'Choose property',
                      hintStyle: TextStyle(color: hintMuted, fontSize: 16),
                    ),
                    validator: controller.validateSelectedProperty,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    items: controller.propertyDropdownMenuItems(dropdownText),
                    onChanged: hasProperties
                        ? controller.updateSelectedProperty
                        : null,
                  ),
                  if (!hasProperties)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 2),
                      child: Text(
                        _isSw
                            ? 'Bado hakuna mjengo - ongeza mjengo kwanza.'
                            : 'No properties yet - add property first.',
                        style: TextStyle(fontSize: 12, color: hintMuted),
                      ),
                    ),
                ],
              );
            }),
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
                  _label(
                    _isSw ? 'KITENGO (HIARI)' : 'UNIT (OPTIONAL)',
                    colors: c,
                  ),
                  DropdownButtonFormField<String?>(
                    initialValue: value,
                    isExpanded: true,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: dropdownText,
                    ),
                    dropdownColor: c.dropdownBg,
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
            Obx(() {
              if (!controller.hasProperties) return const SizedBox.shrink();
              final options = controller.bookingOptions;
              final sel = controller.selectedBookingKey.value;
              final valid =
                  sel != null && options.any((o) => o.bookingKey == sel);
              final value = valid ? sel : null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _label(appLocalization.linkedBookingOptional, colors: c),
                  if (controller.loadingBookings.value)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  else if (options.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 2),
                      child: Text(
                        appLocalization.noActiveBookingsForProperty,
                        style: TextStyle(fontSize: 12, color: hintMuted),
                      ),
                    )
                  else
                    DropdownButtonFormField<String?>(
                      key: ValueKey(
                        'rp-booking-${options.length}-${value ?? ''}-'
                        '${options.map((o) => o.label).join('|')}',
                      ),
                      initialValue: value,
                      isExpanded: true,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: dropdownText,
                      ),
                      dropdownColor: c.dropdownBg,
                      icon: Icon(
                        Icons.expand_more_rounded,
                        color: chevronColor,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: appLocalization.chooseBooking,
                        hintStyle: TextStyle(color: hintMuted, fontSize: 15),
                      ),
                      items: controller.bookingDropdownMenuItems(
                        itemColor: dropdownText,
                        hintColor: hintMuted,
                        optionalNoBookingLabel:
                            appLocalization.optionalNoBooking,
                      ),
                      onChanged: controller.updateSelectedBooking,
                    ),
                ],
              );
            }),
            const SizedBox(height: 16),
            _label(_isSw ? 'KIASI KILICHOLIPWA' : 'AMOUNT PAID', colors: c),
            Obx(
              () => _field(
                c,
                controller.amountController,
                hint: '0.00',
                prefixText: '${controller.selectedCurrency.value} ',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: controller.validateAmount,
                inputFormatters: [controller.amountThousandsFormatter],
              ),
            ),
            const SizedBox(height: 16),
            _label(_isSw ? 'SARAFU' : 'CURRENCY', colors: c),
            CurrencyDropdownField(
              selectedCurrency: controller.selectedCurrency,
              label: _isSw ? 'SARAFU' : 'CURRENCY',
            ),
            const SizedBox(height: 16),
            _label(_isSw ? 'TAREHE YA MALIPO' : 'DATE PAID', colors: c),
            _field(
              c,
              controller.datePaidController,
              hint: _isSw ? 'dd/MM/yyyy' : 'dd/MM/yyyy',
              suffix: Icons.calendar_today_outlined,
              readOnly: true,
              onTap: () => _pickDatePaid(context),
              validator: controller.validateDatePaid,
            ),
            const SizedBox(height: 16),
            _label(_isSw ? 'KATEGORIA' : 'CATEGORY', colors: c),
            Obx(
              () => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  controller.categories.length,
                  (i) => _CategoryChip(
                    colors: c,
                    label: controller.categories[i],
                    selected: controller.selectedCategoryIndex.value == i,
                    onTap: () => controller.selectCategory(i),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _label(_isSw ? 'MAELEZO (HIARI)' : 'NOTES (OPTIONAL)', colors: c),
            _field(
              c,
              controller.notesController,
              hint: _isSw
                  ? 'Ongeza maelezo yoyote kuhusu muamala huu...'
                  : 'Add any specific details regarding this transaction...',
              isMultiline: true,
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.impactBannerBg,
                borderRadius: BorderRadius.circular(14),
                border: c.isDark ? Border.all(color: c.border) : null,
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
                          _isSw
                              ? 'Athari kwa Utendaji'
                              : 'Impact on Performance',
                          style: TextStyle(
                            color: c.headline,
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
                            color: c.secondary,
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
            Obx(
              () => LoadingButton(
                label: _isSw ? 'Hifadhi Mapato' : 'Save Income',
                icon: Icons.check,
                onPressed: controller.saveIncomeOffline,
                isLoading: controller.saving.value,
              ),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.center,
              child: InkWell(
                onTap: () => Get.back(),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Text(
                    _isSw ? 'Ghairi' : 'Cancel',
                    style: TextStyle(
                      fontSize: 15,
                      color: c.headline,
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
    return content;
    // return SingleChildScrollView(
    //   padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
    //   child: Form(
    //     key: controller.formKey,
    //     child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         Text(
    //           _t(context, en: 'Record New Payment', sw: 'Rekodi Malipo Mapya'),
    //           style: TextStyle(
    //             fontSize: 26,
    //             fontWeight: FontWeight.w700,
    //             color: Theme.of(context).colorScheme.onSurface,
    //             letterSpacing: -0.5,
    //           ),
    //         ),
    //         const SizedBox(height: 8),
    //         Text(
    //           _t(
    //             context,
    //             en: 'Log a payment received from a guest for your property.',
    //             sw: 'Andika malipo yaliyopokelewa kutoka kwa mgeni wa mali yako.',
    //           ),
    //           style: TextStyle(
    //             fontSize: 15,
    //             color: c.secondary,
    //             height: 1.4,
    //           ),
    //         ),
    //         const SizedBox(height: 24),
    //         _buildLabel(context, _t(context, en: 'Amount', sw: 'Kiasi')),
    //         const SizedBox(height: 8),
    //         TextFormField(
    //           controller: controller.amountController,
    //           keyboardType: const TextInputType.numberWithOptions(
    //             decimal: true,
    //           ),
    //           decoration: _inputDecoration(context, hint: '0.00').copyWith(
    //             prefixText: 'TZS ',
    //             prefixStyle: TextStyle(
    //               color: c.isDark ? Colors.white70 : AppColors.designPlaceholder,
    //               fontSize: 16,
    //             ),
    //           ),
    //           validator: (v) {
    //             if (v == null || v.trim().isEmpty) {
    //               return _t(
    //                 context,
    //                 en: 'Amount is required',
    //                 sw: 'Kiasi kinahitajika',
    //               );
    //             }
    //             final cleaned = v
    //                 .replaceFirst(RegExp(r'^(TZS|\$)\s*'), '')
    //                 .trim();
    //             final n = double.tryParse(cleaned);
    //             if (n == null || n <= 0) {
    //               return _t(
    //                 context,
    //                 en: 'Enter a valid amount',
    //                 sw: 'Weka kiasi sahihi',
    //               );
    //             }
    //             return null;
    //           },
    //         ),
    //         const SizedBox(height: 20),
    //         _buildLabel(
    //           context,
    //           _t(context, en: 'Payment Method', sw: 'Njia ya Malipo'),
    //         ),
    //         const SizedBox(height: 8),
    //         Obx(
    //           () => DropdownButtonFormField<String>(
    //             initialValue: controller.selectedPaymentMethod.value,
    //             decoration:
    //                 _inputDecoration(
    //                   context,
    //                   hint: _t(context, en: 'Select method', sw: 'Chagua njia'),
    //                 ).copyWith(
    //                   suffixIcon: Icon(
    //                     Icons.keyboard_arrow_down,
    //                     color: c.isDark
    //                         ? Colors.white70
    //                         : AppColors.designPlaceholder,
    //                   ),
    //                 ),
    //             icon: const SizedBox.shrink(),
    //             isExpanded: true,
    //             items: controller.paymentMethods
    //                 .map((e) => DropdownMenuItem(value: e, child: Text(e)))
    //                 .toList(),
    //             onChanged: controller.selectPaymentMethod,
    //           ),
    //         ),
    //         const SizedBox(height: 20),
    //         _buildLabel(
    //           context,
    //           _t(context, en: 'Linked Booking', sw: 'Uhifadhi Uliounganishwa'),
    //         ),
    //         const SizedBox(height: 8),
    //         TextFormField(
    //           controller: controller.linkedBookingController,
    //           decoration:
    //               _inputDecoration(
    //                 context,
    //                 hint: _t(
    //                   context,
    //                   en: 'Search guest name or booking ID...',
    //                   sw: 'Tafuta jina la mgeni au ID ya uhifadhi...',
    //                 ),
    //               ).copyWith(
    //                 prefixIcon: Icon(
    //                   Icons.search,
    //                   size: 22,
    //                   color: c.isDark
    //                       ? Colors.white70
    //                       : AppColors.designPlaceholder,
    //                 ),
    //               ),
    //         ),
    //         const SizedBox(height: 20),
    //         _buildLabel(
    //           context,
    //           _t(context, en: 'Payment Date', sw: 'Tarehe ya Malipo'),
    //         ),
    //         const SizedBox(height: 8),
    //         _DateField(
    //           label: controller.paymentDateLabel,
    //           onTap: controller.pickPaymentDate,
    //           c.isDark: c.isDark,
    //         ),
    //         const SizedBox(height: 20),
    //         _buildLabel(context, _t(context, en: 'Status', sw: 'Hali')),
    //         const SizedBox(height: 8),
    //         Obx(() => _buildStatusToggle(context)),
    //         const SizedBox(height: 28),
    //         _buildRecordButton(context),
    //       ],
    //     ),
    //   ),
    // );
  }

  Widget _label(String text, {required FormSurfaceColors colors}) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: colors.sectionLabel,
      ),
    ),
  );

  Widget _field(
    FormSurfaceColors colors,
    TextEditingController fieldController, {
    required String hint,
    IconData? suffix,
    bool isMultiline = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    Future<void> Function()? onTap,
    String prefixText = '',
  }) {
    final hintStyle = TextStyle(
      fontSize: 14,
      color: colors.hint,
      height: isMultiline ? 1.35 : 1.2,
    );

    return TextFormField(
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
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.headline,
        height: isMultiline ? 1.35 : 1.25,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: hintStyle,
        prefixText: prefixText.isEmpty ? null : prefixText,
        prefixStyle: TextStyle(
          fontSize: 16,
          color: colors.headline,
          fontWeight: FontWeight.w700,
        ),
        suffixIcon: suffix == null
            ? null
            : Icon(suffix, size: 20, color: colors.secondary),
      ),
    );
  }

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
      locale: const Locale('en', 'GB'),
    );
    
    if (picked == null) return;
    final month = picked.month.toString().padLeft(2, '0');
    final day = picked.day.toString().padLeft(2, '0');
    final year = picked.year.toString();
    controller.datePaidController.text = '$day/$month/$year';
  }

  // Widget _buildLabel(BuildContext context, String text) {
  //   return Text(
  //     text,
  //     style: TextStyle(
  //       fontSize: 15,
  //       fontWeight: FontWeight.w600,
  //       color: Theme.of(context).colorScheme.onSurface,
  //     ),
  //   );
  // }

  // InputDecoration _inputDecoration(
  //   BuildContext context, {
  //   required String hint,
  //   Widget? prefixIcon,
  // }) {
  //   final c = FormSurfaceColors.of(context);
  //   return InputDecoration(
  //     hintText: hint,
  //     hintStyle: TextStyle(
  //       color: c.isDark ? Colors.white70 : AppColors.designPlaceholder,
  //     ),
  //     prefixIcon: prefixIcon,
  //     filled: true,
  //     fillColor: c.isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
  //     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  //     border: OutlineInputBorder(
  //       borderRadius: BorderRadius.circular(AppValues.radius_6),
  //       borderSide: BorderSide(
  //         color: c.isDark
  //             ? Colors.white.withValues(alpha: 0.18)
  //             : AppColors.designInputBorder,
  //       ),
  //     ),
  //     enabledBorder: OutlineInputBorder(
  //       borderRadius: BorderRadius.circular(AppValues.radius_6),
  //       borderSide: BorderSide(
  //         color: c.isDark
  //             ? Colors.white.withValues(alpha: 0.18)
  //             : AppColors.designInputBorder,
  //       ),
  //     ),
  //     focusedBorder: OutlineInputBorder(
  //       borderRadius: BorderRadius.circular(AppValues.radius_6),
  //       borderSide: const BorderSide(color: AppColors.designAccent, width: 1.5),
  //     ),
  //     errorBorder: OutlineInputBorder(
  //       borderRadius: BorderRadius.circular(AppValues.radius_6),
  //       borderSide: const BorderSide(color: AppColors.errorColor),
  //     ),
  //   );
  // }

  // Widget _buildStatusToggle(BuildContext context) {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: _StatusChip(
  //           label: _t(context, en: 'Paid', sw: 'Imelipwa'),
  //           isSelected: controller.status.value == PaymentStatus.paid,
  //           icon: Icons.check,
  //           onTap: () => controller.setStatus(PaymentStatus.paid),
  //         ),
  //       ),
  //       const SizedBox(width: 12),
  //       Expanded(
  //         child: _StatusChip(
  //           label: _t(context, en: 'Pending', sw: 'Inasubiri'),
  //           isSelected: controller.status.value == PaymentStatus.pending,
  //           onTap: () => controller.setStatus(PaymentStatus.pending),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildRecordButton(BuildContext context) {
  //   return Obx(() {
  //     final isSaving = controller.saving.value;
  //     return SizedBox(
  //       width: double.infinity,
  //       height: AppValues.formButtonHeight + 4,
  //       child: ElevatedButton.icon(
  //         onPressed: isSaving ? null : controller.recordPayment,
  //         icon: isSaving
  //             ? const SizedBox(
  //                 width: 20,
  //                 height: 20,
  //                 child: CircularProgressIndicator(
  //                   strokeWidth: 2,
  //                   color: Colors.white,
  //                 ),
  //               )
  //             : const Icon(
  //                 Icons.check_circle_outline,
  //                 size: 20,
  //                 color: Colors.white,
  //               ),
  //         label: Text(
  //           isSaving
  //               ? _t(context, en: 'Recording...', sw: 'Inarekodiwa...')
  //               : _t(context, en: 'Record Payment', sw: 'Rekodi Malipo'),
  //           style: TextStyle(
  //             fontSize: 16,
  //             fontWeight: FontWeight.w600,
  //             color: Colors.white,
  //           ),
  //         ),
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: _transactionTeal,
  //           foregroundColor: Colors.white,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(AppValues.radius_6),
  //           ),
  //           elevation: 0,
  //         ),
  //       ),
  //     );
  //   });
  // }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.colors,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final FormSurfaceColors colors;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? colors.tokens.accent : colors.chipUnselectedBg;
    final fg = selected ? Colors.white : colors.headline;
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
      child: const Icon(
        Icons.account_balance_wallet_outlined,
        color: Colors.white,
        size: 19,
      ),
    );
  }
}

// class _DateField extends StatelessWidget {
//   final String label;
//   final VoidCallback onTap;
//   final bool isDark;
//
//   const _DateField({
//     required this.label,
//     required this.onTap,
//     required this.isDark,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: c.isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
//       borderRadius: BorderRadius.circular(AppValues.radius_6),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(AppValues.radius_6),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(AppValues.radius_6),
//             border: Border.all(
//               color: c.isDark
//                   ? Colors.white.withValues(alpha: 0.18)
//                   : AppColors.designInputBorder,
//             ),
//           ),
//           child: Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Theme.of(context).colorScheme.onSurface,
//                   ),
//                 ),
//               ),
//               Icon(
//                 Icons.calendar_today_outlined,
//                 size: 20,
//                 color: c.isDark ? Colors.white70 : AppColors.designPlaceholder,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _StatusChip extends StatelessWidget {
//   final String label;
//   final bool isSelected;
//   final IconData? icon;
//   final VoidCallback onTap;
//
//   const _StatusChip({
//     required this.label,
//     required this.isSelected,
//     this.icon,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final c = FormSurfaceColors.of(context);
//     return Material(
//       color: isSelected
//           ? _transactionTeal
//           : (c.isDark
//                 ? Colors.white.withValues(alpha: 0.12)
//                 : AppColors.lightGreyColor.withValues(alpha: 0.4)),
//       borderRadius: BorderRadius.circular(AppValues.radius_6),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(AppValues.radius_6),
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 14),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               if (icon != null && isSelected) ...[
//                 Icon(icon, size: 18, color: Colors.white),
//                 const SizedBox(width: 6),
//               ],
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w600,
//                   color: isSelected
//                       ? Colors.white
//                       : (c.isDark
//                             ? Colors.white70
//                             : AppColors.textColorSecondary),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
