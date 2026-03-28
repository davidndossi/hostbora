import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../controllers/ai_automations_controller.dart';

class AiAutomationsView extends BaseView<AiAutomationsController> {
  AiAutomationsView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => null;

  @override
  Widget body(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 16),
                  Text(
                    'AI Automations',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textColorPrimary,
                      fontFamily: 'Times New Roman',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _automationCard(
                    title: 'Auto-reply to inquiries',
                    subtitle:
                        'Automatically respond to common guest questions instantly using your property data.',
                    value: controller.autoReplyEnabled,
                    onChanged: controller.setAutoReply,
                  ),
                  const SizedBox(height: 10),
                  _automationCard(
                    title: 'Smart pricing adjustment',
                    subtitle:
                        'Optimize your rates dynamically based on real-time local market demand and events.',
                    value: controller.smartPricingEnabled,
                    onChanged: controller.setSmartPricing,
                  ),
                  const SizedBox(height: 10),
                  _automationCard(
                    title: 'Auto-assign cleaning tasks',
                    subtitle: 'Instantly notify and schedule your cleaning team once a booking is confirmed.',
                    value: controller.autoAssignCleaningEnabled,
                    onChanged: controller.setAutoAssignCleaning,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Configure Voice',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _voiceConfigCard(),
                  const SizedBox(height: 14),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF32C45A),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'AI Assistant is Active & Learning',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textColorSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _circleIcon(Icons.arrow_back_ios_new_rounded, onTap: Get.back),
        const Spacer(),
        _circleIcon(Icons.help_outline_rounded, onTap: () {}),
      ],
    );
  }

  Widget _circleIcon(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: AppColors.colorWhite,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20, color: AppColors.textColorPrimary),
        ),
      ),
    );
  }

  Widget _automationCard({
    required String title,
    required String subtitle,
    required RxBool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(color: AppColors.designInputBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textColorPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: AppColors.textColorSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Obx(
            () => Switch(
              value: value.value,
              onChanged: onChanged,
              activeColor: AppColors.colorWhite,
              activeTrackColor: AppColors.colorPrimary,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFE9EDF1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _voiceConfigCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(color: AppColors.designInputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tone & Personality',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textColorPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => Row(
              children: [
                _toneChip('Friendly', VoiceTone.friendly),
                const SizedBox(width: 8),
                _toneChip('Professional', VoiceTone.professional),
                const SizedBox(width: 8),
                _toneChip('Casual', VoiceTone.casual),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'AI Persona Vibe',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textColorPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller.personaController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Describe how you want your AI to sound (e.g., "A helpful concierge at a 5-star mountain resort").',
              hintStyle: TextStyle(
                color: AppColors.textColorSecondary,
                fontSize: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.designInputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.designInputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.colorPrimary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.previewVoice,
              icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
              label: const Text('Preview AI Voice', style: TextStyle(
                color: Color(0xFF0D6D6D),
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                height: 1.50,
              )),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE9F3F3),
                foregroundColor: AppColors.colorPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toneChip(String label, VoiceTone tone) {
    final selected = controller.selectedTone.value == tone;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setTone(tone),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.colorPrimary : AppColors.pageBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.colorPrimary : AppColors.designInputBorder),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textColorPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
