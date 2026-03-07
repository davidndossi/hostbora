import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../controllers/add_listing_controller.dart';

class AddListingView extends BaseView<AddListingController> {
  AddListingView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return _buildStepAppBar(context);
  }

  PreferredSizeWidget _buildStepAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.pageBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: controller.goBack,
        icon: const Icon(Icons.arrow_back),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'STEP ${controller.currentStep.value} OF ${AddListingController.totalSteps}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textColorSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          _buildStepDots(),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: controller.openHelp,
          icon: const Icon(Icons.help_outline, size: 24),
          color: AppColors.textColorPrimary,
        ),
      ],
    );
  }

  Widget _buildStepDots() {
    return Obx(() {
      final current = controller.currentStep.value;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(AddListingController.totalSteps, (i) {
          final filled = i < current;
          final isCurrent = i == current - 1;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 24,
            height: isCurrent ? 5 : 4,
            decoration: BoxDecoration(
              color: filled ? AppColors.colorPrimary : AppColors.designInputBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      );
    });
  }

  @override
  Widget body(BuildContext context) {
    return Obx(() {
      final step = controller.currentStep.value;
      return Column(
        children: [
          if (step == 1) _buildProgress(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: step == 1
                  ? _buildStep1Content(context)
                  : step == 2
                      ? _buildStep2Content(context)
                      : step == 3
                          ? _buildStep3Content(context)
                          : _buildStep4Content(context),
            ),
          ),
          _buildBottomBar(context),
        ],
      );
    });
  }

  Widget _buildStep1Content(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Add New Property',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textColorPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by giving us the basic details of your wonderful space.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textColorSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _buildLabel('PROPERTY NAME'),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller.propertyNameController,
            decoration: _inputDecoration(hint: 'e.g., Cozy Beachfront Villa'),
            validator: (v) =>
                controller.validateRequired(v, 'Property name'),
          ),
          const SizedBox(height: 20),
          _buildLabel('PROPERTY TYPE'),
          const SizedBox(height: 8),
          Obx(
            () => DropdownButtonFormField<String>(
              value: controller.selectedPropertyType.value,
              decoration: _inputDecoration(hint: 'Select property type'),
              hint: Text(
                'Select property type',
                style: TextStyle(
                  color: AppColors.designPlaceholder,
                  fontSize: 16,
                ),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.designPlaceholder,
              ),
              items: controller.propertyTypes
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    ),
                  )
                  .toList(),
              onChanged: controller.selectPropertyType,
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Property type is required';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildLabel('STREET ADDRESS'),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller.streetAddressController,
            decoration: _inputDecoration(
              hint: 'Enter full address',
              prefixIcon: Icon(
                Icons.location_on_outlined,
                size: 22,
                color: AppColors.designPlaceholder,
              ),
            ),
            validator: (v) =>
                controller.validateRequired(v, 'Street address'),
          ),
          const SizedBox(height: 16),
          _buildMapPreview(context),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStep2Content(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Showcase your space',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textColorPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'High-quality photos increase bookings by up to 40%. Add at least 5 photos to get started.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textColorSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        _buildUploadZone(context),
        const SizedBox(height: 24),
        _buildUploadProgress(context),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildStep3Content(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Pricing',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textColorPrimary,
                letterSpacing: -0.5,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.chat_bubble_outline, size: 20, color: AppColors.colorPrimary),
            ),
            Text(
              'Rules',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textColorPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Set your rates and define how guests can book your space.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textColorSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel('PRICING'),
        const SizedBox(height: 12),
        _buildLabel('Base Nightly Rate'),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller.baseNightlyRateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _inputDecoration(hint: '0.00').copyWith(
            prefixText: '\$ ',
            prefixStyle: TextStyle(
              fontSize: 16,
              color: AppColors.textColorPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('Cleaning Fee'),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller.cleaningFeeController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _inputDecoration(hint: '0.00').copyWith(
            prefixText: '\$ ',
            prefixStyle: TextStyle(
              fontSize: 16,
              color: AppColors.textColorPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel('HOUSE RULES'),
        const SizedBox(height: 12),
        _buildRuleRow(
          title: 'Instant Book',
          subtitle: 'Guests can book without manual approval',
          value: controller.instantBook,
        ),
        const SizedBox(height: 12),
        _buildRuleRow(
          title: 'Pets Allowed',
          subtitle: 'Allow guests to bring their furry friends',
          value: controller.petsAllowed,
        ),
        const SizedBox(height: 24),
        _buildPricingTipBox(context),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildRuleRow({
    required String title,
    required String subtitle,
    required Rx<bool> value,
  }) {
    return Obx(() => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(color: AppColors.designInputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColorPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textColorSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value.value,
            onChanged: (v) => value.value = v,
            activeTrackColor: AppColors.colorPrimaryLight,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return AppColors.colorPrimary;
              return AppColors.designInputBorder;
            }),
          ),
        ],
      ),
    ));
  }

  Widget _buildPricingTipBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.colorPrimaryLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(color: AppColors.colorPrimary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 22, color: AppColors.colorPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Setting a competitive nightly rate can help you get your first bookings faster. Check similar listings in your area for guidance.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textColorPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Content(BuildContext context) {
    final title = controller.propertyNameController.text.trim().isEmpty
        ? 'Modern Lakeside Cabin'
        : controller.propertyNameController.text;
    final price = controller.baseNightlyRateController.text.trim().isEmpty
        ? '150'
        : controller.baseNightlyRateController.text;
    final location = controller.streetAddressController.text.trim().isEmpty
        ? 'Lake Tahoe, California'
        : controller.streetAddressController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Final Review',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textColorPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Review your listing details before going live on the platform.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textColorSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel('LISTING PREVIEW'),
        const SizedBox(height: 12),
        _buildListingPreviewCard(
          context,
          title: title,
          price: price,
          location: location,
        ),
        const SizedBox(height: 24),
        Text(
          'Ready to Publish',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textColorPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildReadyItem('Address verified'),
        const SizedBox(height: 8),
        _buildReadyItem('Photos uploaded'),
        const SizedBox(height: 8),
        _buildReadyItem('Pricing set'),
        const SizedBox(height: 20),
        Text(
          'By clicking "Publish Listing", you agree to our Hosting Terms and Cancellation Policies.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textColorSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.publishListing,
            icon: const Icon(Icons.rocket_launch, size: 20, color: Colors.white),
            label: const Text('Publish Listing'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.colorPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppValues.radius_6),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildListingPreviewCard(
    BuildContext context, {
    required String title,
    required String price,
    required String location,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                color: AppColors.lightGreyColor.withOpacity(0.5),
                child: Icon(
                  Icons.home_work_outlined,
                  size: 64,
                  color: AppColors.designPlaceholder,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.designBackgroundDark,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14, color: AppColors.paaYanguWarm),
                      const SizedBox(width: 4),
                      Text(
                        'New',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColorWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textColorPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '\$$price',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textColorPrimary,
                      ),
                    ),
                    Text(
                      '/night',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textColorSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: AppColors.textColorSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textColorSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.bed_outlined, size: 18, color: AppColors.textColorSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '2 Bedrooms',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textColorSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.bathtub_outlined, size: 18, color: AppColors.textColorSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '1.5 Baths',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textColorSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.people_outline, size: 18, color: AppColors.textColorSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '4 Guests',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textColorSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: controller.editListingDetails,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_outlined, size: 20, color: AppColors.colorPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'Edit Listing Details',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.colorPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyItem(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(color: AppColors.designInputBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.designInputBorder.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(Icons.check, size: 18, color: AppColors.colorPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textColorPrimary,
              ),
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: AppColors.textColorSecondary),
        ],
      ),
    );
  }

  Widget _buildUploadZone(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: open image picker
        controller.photoSlotsFilled.value = (controller.photoSlotsFilled.value + 1).clamp(0, AddListingController.photoSlotsCount);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        decoration: BoxDecoration(
          color: AppColors.colorWhite,
          borderRadius: BorderRadius.circular(AppValues.radius_12),
          border: Border.all(
            color: AppColors.designInputBorder,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 56,
              color: AppColors.colorPrimary,
            ),
            const SizedBox(height: 12),
            Text(
              'Upload Photos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textColorPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Drag & drop or tap to browse',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textColorSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadProgress(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upload progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textColorPrimary,
              ),
            ),
            Obx(() => Text(
              '${controller.photoSlotsFilled.value}/${AddListingController.photoSlotsCount} slots filled',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.colorPrimary,
              ),
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildPhotoSlotCard('LIVING ROOM', Icons.photo_library_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _buildPhotoSlotCard('BEDROOM', Icons.bed_outlined)),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoSlotCard(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(color: AppColors.designInputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.designPlaceholder),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textColorSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(BuildContext context) {
    const step = 1;
    const total = 4;
    final percent = step / total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STEP $step OF $total',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColorSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                '${(percent * 100).round()}% COMPLETE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColorSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: AppColors.lightGreyColor,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.colorPrimary),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.textColorPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.designPlaceholder),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: AppColors.colorWhite,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: const BorderSide(color: AppColors.designInputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: const BorderSide(color: AppColors.designInputBorder),
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

  Widget _buildMapPreview(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.lightGreyColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        border: Border.all(color: AppColors.designInputBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on,
            size: 48,
            color: AppColors.colorPrimary,
          ),
          const SizedBox(height: 8),
          Text(
            'LIVE LOCATION PREVIEW',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.textColorSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Obx(() {
      final step = controller.currentStep.value;
      return Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: AppColors.pageBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (step == 1)
              TextButton(
                onPressed: controller.saveDraft,
                child: Text(
                  'Save Draft',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.colorPrimary,
                  ),
                ),
              ),
            if (step >= 2)
              OutlinedButton(
                onPressed: controller.goBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textColorPrimary,
                  side: const BorderSide(color: AppColors.designInputBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppValues.radius_6),
                  ),
                ),
                child: const Text('Back'),
              ),
            if (step >= 2 && step < 4) const SizedBox(width: 12),
            if (step < 4)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: controller.nextStep,
                  icon: const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                  label: Text(step == 3 ? 'Continue' : 'Next Step'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.colorPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppValues.radius_6),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            if (step == 4) const Spacer(),
          ],
        ),
      );
    });
  }
}
