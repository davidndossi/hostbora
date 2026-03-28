import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../routes/app_pages.dart';
import '../controllers/interior_design_studio_controller.dart';

class InteriorDesignStudioView extends BaseView<InteriorDesignStudioController> {
  InteriorDesignStudioView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: 'AI Interior Design Studio',
      isCentered: true,
    );
  }

  @override
  Color pageBackgroundColor(BuildContext context) => AppColors.colorWhite;

  @override
  Widget body(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUploadCard(),
                const SizedBox(height: 18),
                _buildStyleHeader(),
                const SizedBox(height: 10),
                _buildStyleGrid(),
                const SizedBox(height: 14),
                _buildGenerateButton(),
                const SizedBox(height: 18),
                Text(
                  'Reimagined Results',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textColorPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _buildResultList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.designInputBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.colorPrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.photo_camera_outlined, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            'Upload a photo of your room',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textColorPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'For best results, ensure the room is well-lit',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textColorSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: controller.uploadPhoto,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.colorPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              minimumSize: const Size(140, 48)
            ),
            child: const Text('Select Photo', style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.35,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleHeader() {
    return Row(
      children: [
        Text(
          'Select Style',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textColorPrimary,
          ),
        ),
        const Spacer(),
        Text(
          '4 STYLES AVAILABLE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.colorPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStyleGrid() {
    return Obx(() {
      return GridView.builder(
        itemCount: controller.styleOptions.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.2,
        ),
        itemBuilder: (context, index) {
          final style = controller.styleOptions[index];
          final selected = controller.selectedStyle.value == style.style;
          return GestureDetector(
            onTap: () => controller.selectStyle(style.style),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.colorPrimary : AppColors.designInputBorder,
                  width: selected ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(style.imagePath, fit: BoxFit.cover),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withOpacity(0.06), Colors.black.withOpacity(0.42)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Text(
                        style.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildGenerateButton() {
    return Obx(() {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: controller.generating.value ? null : controller.generateIdeas,
          icon: controller.generating.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.auto_awesome, size: 18),
          label: Text(controller.generating.value ? 'Generating...' : 'Generate Design Ideas', style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.45,
          )),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.colorPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildResultList() {
    return Column(
      children: controller.results
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.colorWhite,
                borderRadius: BorderRadius.circular(AppValues.radius_12),
                border: Border.all(color: AppColors.designInputBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppValues.radius_12)),
                    child: Image.asset(
                      item.imagePath,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textColorPrimary,
                            ),
                          ),
                        ),
                        Text(
                          item.priceRange,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.colorPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textColorSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: item.tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.pageBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.designInputBorder),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textColorSecondary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Get.toNamed(Routes.DESIGN_MOODBOARD),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          side: BorderSide(color: AppColors.designInputBorder),
                          foregroundColor: AppColors.textColorPrimary,
                        ),
                        child: const Text('View Material List', style: TextStyle(
                          color: AppColors.colorPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          // height: 1.33,
                        )),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
