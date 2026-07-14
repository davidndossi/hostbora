import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/form_surface_colors.dart';
import '../../../core/widget/currency_dropdown_field.dart';
import '../../record_payment/bindings/record_payment_binding.dart';
import '../../record_payment/controllers/record_payment_controller.dart';
import 'quick_wizard_shell.dart';

/// Opens the condensed "Add Income" step-by-step wizard from the home
/// quick-actions dialog. Returns `true` when income was recorded.
Future<bool?> showQuickAddIncomeWizard() {
  return showQuickWizardSheet<bool>(
    title: 'Add Income',
    builder: (_) => const _QuickAddIncomeWizardBody(),
  );
}

class _QuickAddIncomeWizardBody extends StatefulWidget {
  const _QuickAddIncomeWizardBody();

  @override
  State<_QuickAddIncomeWizardBody> createState() =>
      _QuickAddIncomeWizardBodyState();
}

class _QuickAddIncomeWizardBodyState
    extends State<_QuickAddIncomeWizardBody> {
  late final RecordPaymentController controller;
  int _currentIndex = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<RecordPaymentController>()) {
      Get.delete<RecordPaymentController>(force: true);
    }
    RecordPaymentBinding().dependencies();
    controller = Get.find<RecordPaymentController>();
    controller.datePaidController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    if (Get.isRegistered<RecordPaymentController>()) {
      Get.delete<RecordPaymentController>(force: true);
    }
    super.dispose();
  }

  List<_Step> get _steps {
    return [
      _Step(
        title: 'Property',
        required: true,
        content: (context) => _propertyStep(context),
        validate: () {
          if (controller.selectedProperty.value.trim().isEmpty) {
            return 'Please select a property';
          }
          return null;
        },
      ),
      if (controller.showIncomeUnitPicker)
        _Step(
          title: 'Unit',
          required: true,
          content: (context) => _unitStep(context),
          validate: () {
            if ((controller.selectedIncomeUnitKey.value ?? '').trim().isEmpty) {
              return 'Please select a unit';
            }
            return null;
          },
        ),
      _Step(
        title: 'Booking',
        required: false,
        content: (context) => _bookingStep(context),
      ),
      _Step(
        title: 'Amount',
        required: true,
        content: (context) => _amountStep(context),
        validate: () {
          final raw = controller.amountController.text.trim().replaceAll(',', '');
          final n = double.tryParse(raw);
          if (raw.isEmpty || n == null || n <= 0) {
            return 'Please enter a valid amount';
          }
          return null;
        },
      ),
      _Step(
        title: 'Date paid',
        required: true,
        content: (context) => _dateStep(context),
        validate: () {
          if (controller.validateDatePaid(controller.datePaidController.text) != null) {
            return 'Please choose a valid date';
          }
          return null;
        },
      ),
      _Step(
        title: 'Payment method',
        required: false,
        content: (context) => _paymentMethodStep(context),
      ),
      _Step(
        title: 'Notes',
        required: false,
        content: (context) => _notesStep(context),
        isFinal: true,
      ),
    ];
  }

  void _goPrevious() {
    if (_currentIndex == 0) {
      Get.back(result: false);
      return;
    }
    setState(() => _currentIndex--);
  }

  void _goNext() {
    final steps = _steps;
    final step = steps[_currentIndex];
    final error = step.validate?.call();
    if (error != null) {
      Get.snackbar('Required', error);
      return;
    }
    if (step.isFinal) {
      _submit();
      return;
    }
    setState(() {
      _currentIndex = (_currentIndex + 1).clamp(0, steps.length - 1);
    });
  }

  void _skip() {
    final steps = _steps;
    setState(() {
      _currentIndex = (_currentIndex + 1).clamp(0, steps.length - 1);
    });
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await controller.saveIncomeOffline();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final index = _currentIndex.clamp(0, steps.length - 1);
    final step = steps[index];
    return QuickWizardBody(
      title: 'Add Income',
      stepIndex: index,
      totalSteps: steps.length,
      stepContent: step.content(context),
      onClose: () => Get.back(result: false),
      onPrevious: _goPrevious,
      onNext: _goNext,
      nextLabel: step.isFinal ? 'Submit' : 'Next',
      onSkip: !step.required ? _skip : null,
      isSubmitting: _submitting,
    );
  }

  Widget _propertyStep(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quickWizardHeading(context, 'Which property is this income for?'),
        if (!controller.hasProperties)
          Text(
            'No properties yet — add a property first.',
            style: TextStyle(color: c.hint),
          )
        else
          Obx(
            () => DropdownButtonFormField<String>(
              initialValue: controller.propertyOptions.contains(controller.selectedProperty.value)
                  ? controller.selectedProperty.value
                  : null,
              decoration: _decoration(context, hint: 'Select property'),
              items: controller.propertyOptions
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: controller.updateSelectedProperty,
            ),
          ),
      ],
    );
  }

  Widget _unitStep(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quickWizardHeading(context, 'Which unit?'),
        Obx(
          () => DropdownButtonFormField<String>(
            initialValue: controller.selectedIncomeUnitKey.value,
            decoration: _decoration(context, hint: 'Select unit'),
            items: controller.incomeUnitsForSelectedProperty
                .map((u) => DropdownMenuItem(value: u.selectionKey, child: Text(u.unitName)))
                .toList(),
            onChanged: controller.updateSelectedIncomeUnit,
          ),
        ),
      ],
    );
  }

  Widget _bookingStep(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quickWizardHeading(context, 'Link an existing booking? (optional)'),
        Obx(() {
          if (controller.loadingBookings.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.bookingOptions.isEmpty) {
            return Text(
              'No active bookings found for this property.',
              style: TextStyle(color: FormSurfaceColors.of(context).hint),
            );
          }
          return DropdownButtonFormField<String?>(
            initialValue: controller.selectedBookingKey.value,
            decoration: _decoration(context, hint: 'No booking selected'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('No booking')),
              ...controller.bookingOptions.map(
                (o) => DropdownMenuItem<String?>(value: o.bookingKey, child: Text(o.label)),
              ),
            ],
            onChanged: controller.updateSelectedBooking,
          );
        }),
      ],
    );
  }

  Widget _amountStep(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quickWizardHeading(context, 'How much was paid?'),
        quickWizardLabel(context, 'CURRENCY'),
        const SizedBox(height: 8),
        CurrencyDropdownField(selectedCurrency: controller.selectedCurrency, label: 'Currency'),
        const SizedBox(height: 16),
        quickWizardLabel(context, 'AMOUNT'),
        const SizedBox(height: 8),
        Obx(
          () => TextField(
            controller: controller.amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [controller.amountThousandsFormatter],
            style: TextStyle(fontSize: 16, color: c.headline),
            decoration: _decoration(
              context,
              hint: '0.00',
              prefixText: '${controller.selectedCurrency.value} ',
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateStep(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quickWizardHeading(context, 'When was it paid?'),
        TextField(
          controller: controller.datePaidController,
          readOnly: true,
          style: TextStyle(fontSize: 16, color: c.headline),
          decoration: _decoration(
            context,
            hint: 'dd/mm/yyyy',
            suffixIcon: Icon(Icons.calendar_today_outlined, color: c.hint),
          ),
          onTap: () => _pickDate(context),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    DateTime initial = now;
    try {
      if (controller.datePaidController.text.trim().isNotEmpty) {
        initial = DateFormat('dd/MM/yyyy').parseStrict(controller.datePaidController.text.trim());
      }
    } catch (_) {}
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('en', 'GB'),
    );
    if (picked == null) return;
    controller.datePaidController.text = DateFormat('dd/MM/yyyy').format(picked);
  }

  Widget _paymentMethodStep(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quickWizardHeading(context, 'How was it paid?'),
        Obx(
          () => _ChipRow(
            options: controller.paymentMethods,
            selected: controller.selectedPaymentMethod.value,
            onSelected: controller.selectPaymentMethod,
          ),
        ),
      ],
    );
  }

  Widget _notesStep(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quickWizardHeading(context, 'Anything else to note? (optional)'),
        TextField(
          controller: controller.notesController,
          minLines: 3,
          maxLines: 6,
          style: TextStyle(fontSize: 16, color: c.headline),
          decoration: _decoration(context, hint: 'Add any specific details…'),
        ),
      ],
    );
  }

  InputDecoration _decoration(
    BuildContext context, {
    required String hint,
    String? prefixText,
    Widget? suffixIcon,
  }) {
    final c = FormSurfaceColors.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: c.hint),
      prefixText: prefixText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: c.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.tokens.accent, width: 1.5),
      ),
    );
  }
}

class _Step {
  _Step({
    required this.title,
    required this.required,
    required this.content,
    this.validate,
    this.isFinal = false,
  });

  final String title;
  final bool required;
  final WidgetBuilder content;
  final String? Function()? validate;
  final bool isFinal;
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.options, required this.selected, required this.onSelected});

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((o) {
        final isSelected = o == selected;
        return ChoiceChip(
          label: Text(o),
          selected: isSelected,
          onSelected: (_) => onSelected(o),
          selectedColor: c.tokens.accent,
          backgroundColor: c.chipUnselectedBg,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : c.headline,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isSelected ? c.tokens.accent : c.border),
          ),
        );
      }).toList(),
    );
  }
}
