import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../controllers/failed_controller.dart';

class FailedView extends BaseView<FailedController> {
  FailedView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: controller.goBack,
      ),
      title: Text(
        appLocalization.failed,
        style: const TextStyle(
          color: AppColors.appBarTextColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppValues.padding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.errorColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppColors.errorColor,
            ),
          ),
          const SizedBox(height: 32),
          Obx(
            () => Text(
              controller.msg.value.isNotEmpty
                  ? controller.msg.value
                  : appLocalization.failed,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textColorPrimary,
                height: 1.4,
              ),
            ),
          ),
          Obx(
            () => controller.responseCode.value.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Code: ${controller.responseCode.value}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textColorSecondary,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: AppValues.formButtonHeight,
            child: ElevatedButton(
              onPressed: controller.goBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.colorPrimary,
                foregroundColor: AppColors.textColorWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppValues.radius_6),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: controller.goToHome,
            child: Text(
              'Go to Home',
              style: TextStyle(
                color: AppColors.colorPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
