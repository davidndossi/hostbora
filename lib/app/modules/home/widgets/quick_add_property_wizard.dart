import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/form_surface_colors.dart';
import '../../add_listing/bindings/add_listing_binding.dart';
import '../../add_listing/controllers/add_listing_controller.dart';
import '../../add_listing/views/add_units_section.dart';
import 'quick_wizard_shell.dart';

/// Opens the condensed "Add Property" step-by-step wizard from the home
/// quick-actions dialog. Returns `true` when a property was saved.
Future<bool?> showQuickAddPropertyWizard() {
  return showQuickWizardSheet<bool>(
    title: 'Add Property',
    builder: (_) => const _QuickAddPropertyWizardBody(),
  );
}

class _QuickAddPropertyWizardBody extends StatefulWidget {
  const _QuickAddPropertyWizardBody();

  @override
  State<_QuickAddPropertyWizardBody> createState() =>
      _QuickAddPropertyWizardBodyState();
}

class _QuickAddPropertyWizardBodyState
    extends State<_QuickAddPropertyWizardBody> {
  late final AddListingController controller;
  int _currentIndex = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AddListingController>()) {
      Get.delete<AddListingController>(force: true);
    }
    AddListingBinding().dependencies();
    controller = Get.find<AddListingController>();
  }

  @override
  void dispose() {
    if (Get.isRegistered<AddListingController>()) {
      Get.delete<AddListingController>(force: true);
    }
    super.dispose();
  }

  List<_WizardStep> get _steps {
    final steps = <_WizardStep>[
      _WizardStep(
        title: 'Property name',
        required: true,
        content: (context) => _nameStep(context),
        validate: () {
          if (controller.propertyNameController.text.trim().isEmpty) {
            return 'Please enter a property name';
          }
          return null;
        },
      ),
      _WizardStep(
        title: 'Property location',
        required: true,
        content: (context) => _locationStep(context),
        validate: () {
          if (controller.propertyLocationController.text.trim().isEmpty) {
            return 'Please enter a property location';
          }
          return null;
        },
      ),
      _WizardStep(
        title: 'Physical address',
        required: false,
        content: (context) => _addressStep(context),
      ),
      _WizardStep(
        title: 'Property type',
        required: true,
        content: (context) => _typeStep(context),
        validate: () {
          if ((controller.selectedPropertyType.value ?? '').trim().isEmpty) {
            return 'Please choose a property type';
          }
          return null;
        },
      ),
      _WizardStep(
        title: 'Listing mode',
        required: true,
        content: (context) => _modeStep(context),
      ),
      if (controller.isApartmentProperty)
        _WizardStep(
          title: 'Apartment units',
          required: true,
          content: (context) => _unitsStep(context),
          validate: () {
            if (controller.apartmentUnits.isEmpty) {
              return 'Add at least one apartment unit';
            }
            return null;
          },
        ),
      _WizardStep(
        title: 'Minimum rental duration',
        required: true,
        content: (context) => _minDurationStep(context),
        isFinal: true,
      ),
    ];
    return steps;
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
      await controller.saveProperty(skipRentAmountRequirement: true);
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
      title: 'Add Property',
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

  Widget _nameStep(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quickWizardHeading(context, 'What is the property called?'),
        quickWizardLabel(context, 'PROPERTY NAME'),
        const SizedBox(height: 8),
        TextField(
          controller: controller.propertyNameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(fontSize: 16, color: c.headline),
          decoration: _decoration(context, hint: 'e.g., AB Apartment'),
        ),
      ],
    );
  }

  Widget _locationStep(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quickWizardHeading(context, 'Where is it located?'),
        quickWizardLabel(context, 'PROPERTY LOCATION'),
        const SizedBox(height: 8),
        TextField(
          controller: controller.propertyLocationController,
          autofocus: true,
          minLines: 1,
          maxLines: 3,
          textCapitalization: TextCapitalization.words,
          keyboardType: TextInputType.streetAddress,
          style: TextStyle(fontSize: 16, color: c.headline),
          decoration: _decoration(context, hint: 'Enter street address or area'),
        ),
      ],
    );
  }

  Widget _addressStep(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quickWizardHeading(context, 'Physical address (optional)'),
        quickWizardLabel(context, 'PHYSICAL ADDRESS'),
        const SizedBox(height: 8),
        TextField(
          controller: controller.streetAddressController,
          autofocus: true,
          minLines: 1,
          maxLines: 3,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(fontSize: 16, color: c.headline),
          decoration: _decoration(context, hint: 'Plot number, street, landmark…'),
        ),
      ],
    );
  }

  Widget _typeStep(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quickWizardHeading(context, 'What type of property is this?'),
        Obx(
          () => _ChipSelector(
            options: controller.propertyTypes,
            selected: controller.selectedPropertyType.value,
            onSelected: controller.selectPropertyType,
          ),
        ),
      ],
    );
  }

  Widget _modeStep(BuildContext context) {
    const options = ['bnb', 'rent', 'both'];
    final labels = {
      'bnb': 'BnB / short stays',
      'rent': 'Rent / long-term',
      'both': 'Both BnB and Rent',
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quickWizardHeading(context, 'How will you list this property?'),
        Obx(
          () => _ChipSelector(
            options: options,
            optionLabels: labels,
            selected: controller.listingMode.value,
            onSelected: controller.updateListingMode,
          ),
        ),
      ],
    );
  }

  Widget _unitsStep(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quickWizardHeading(context, 'Add the apartment units'),
        buildAddUnitsSection(context, controller),
      ],
    );
  }

  Widget _minDurationStep(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quickWizardHeading(context, 'Minimum rental duration'),
        Obx(
          () => _ChipSelector(
            options: controller.minRentalDurationOptions,
            selected: controller.minRentalDuration.value,
            onSelected: controller.updateMinRentalDuration,
          ),
        ),
      ],
    );
  }

  InputDecoration _decoration(BuildContext context, {required String hint}) {
    final c = FormSurfaceColors.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: c.hint),
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

class _WizardStep {
  _WizardStep({
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

/// Simple single-selection chip row used across the quick-add wizards.
class _ChipSelector extends StatelessWidget {
  const _ChipSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
    this.optionLabels,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;
  final Map<String, String>? optionLabels;

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((o) {
        final isSelected = o == selected;
        return ChoiceChip(
          label: Text(optionLabels?[o] ?? o),
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        );
      }).toList(),
    );
  }
}
