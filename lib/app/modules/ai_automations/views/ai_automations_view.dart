import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../controllers/ai_automations_controller.dart';

class AiAutomationsView extends BaseView<AiAutomationsController> {
  AiAutomationsView({super.key});

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  String _t(BuildContext context, {required String en, required String sw}) {
    final code =
        Get.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    return code == 'sw' ? sw : en;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) => null;

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _isDark(context);
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 16),
                  Text(
                    _t(context, en: 'AI Automations', sw: 'Otomesheni za AI'),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? theme.colorScheme.onSurface
                          : AppColors.textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _automationCard(
                    context: context,
                    title: 'Auto-reply to inquiries',
                    subtitle:
                        'Automatically respond to common guest questions instantly using your property data.',
                    value: controller.autoReplyEnabled,
                    onChanged: controller.setAutoReply,
                  ),
                  const SizedBox(height: 10),
                  _automationCard(
                    context: context,
                    title: 'Smart pricing adjustment',
                    subtitle:
                        'Optimize your rates dynamically based on real-time local market demand and events.',
                    value: controller.smartPricingEnabled,
                    onChanged: controller.setSmartPricing,
                  ),
                  const SizedBox(height: 10),
                  _automationCard(
                    context: context,
                    title: 'Auto-assign cleaning tasks',
                    subtitle:
                        'Instantly notify and schedule your cleaning team once a booking is confirmed.',
                    value: controller.autoAssignCleaningEnabled,
                    onChanged: controller.setAutoAssignCleaning,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _t(context, en: 'Configure Voice', sw: 'Sanidi Sauti'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? theme.colorScheme.onSurface
                          : AppColors.textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _voiceConfigCard(context),
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
                          _t(
                            context,
                            en: 'AI Assistant is Active & Learning',
                            sw: 'Msaidizi wa AI yuko hai na anajifunza',
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        _circleIcon(context, Icons.arrow_back_ios_new_rounded, onTap: Get.back),
        const Spacer(),
        _circleIcon(context, Icons.help_outline_rounded, onTap: () {}),
      ],
    );
  }

  Widget _circleIcon(
    BuildContext context,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: _isDark(context)
          ? theme.colorScheme.surfaceContainerHigh
          : AppColors.colorWhite,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 20,
            color: _isDark(context)
                ? theme.colorScheme.onSurface
                : AppColors.textColorPrimary,
          ),
        ),
      ),
    );
  }

  Widget _automationCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required RxBool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = _isDark(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outlineVariant
              : AppColors.designInputBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t(
                    context,
                    en: title,
                    sw: title == 'Auto-reply to inquiries'
                        ? 'Jibu kiotomatiki kwa maswali'
                        : title == 'Smart pricing adjustment'
                        ? 'Marekebisho mahiri ya bei'
                        : 'Pangia kiotomatiki kazi za usafi',
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? theme.colorScheme.onSurface
                        : AppColors.textColorPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _t(
                    context,
                    en: subtitle,
                    sw: title == 'Auto-reply to inquiries'
                        ? 'Jibu maswali ya kawaida ya wageni papo hapo kwa kutumia data ya mali yako.'
                        : title == 'Smart pricing adjustment'
                        ? 'Boresha bei zako kwa mabadiliko ya soko la eneo husika kwa wakati halisi.'
                        : 'Arifu na panga timu yako ya usafi mara moja baada ya uhifadhi kuthibitishwa.',
                  ),
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: theme.colorScheme.onSurfaceVariant,
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
              activeThumbColor: isDark
                  ? theme.colorScheme.onPrimary
                  : AppColors.colorWhite,
              activeTrackColor: AppColors.colorPrimary,
              inactiveThumbColor: isDark
                  ? theme.colorScheme.surface
                  : Colors.white,
              inactiveTrackColor: isDark
                  ? theme.colorScheme.surfaceContainerHighest
                  : const Color(0xFFE9EDF1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _voiceConfigCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _isDark(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outlineVariant
              : AppColors.designInputBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(context, en: 'Tone & Personality', sw: 'Mtindo na Haiba'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? theme.colorScheme.onSurface
                  : AppColors.textColorPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => Row(
              children: [
                _toneChip(
                  context,
                  _t(context, en: 'Friendly', sw: 'Rafiki'),
                  VoiceTone.friendly,
                ),
                const SizedBox(width: 8),
                _toneChip(
                  context,
                  _t(context, en: 'Professional', sw: 'Kitaalamu'),
                  VoiceTone.professional,
                ),
                const SizedBox(width: 8),
                _toneChip(
                  context,
                  _t(context, en: 'Casual', sw: 'Kawaida'),
                  VoiceTone.casual,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _t(context, en: 'AI Persona Vibe', sw: 'Hisia ya Utu wa AI'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? theme.colorScheme.onSurface
                  : AppColors.textColorPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller.personaController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: _t(
                context,
                en: 'Describe how you want your AI to sound (e.g., "A helpful concierge at a 5-star mountain resort").',
                sw: 'Eleza unavyotaka AI yako isikike (mf. "Mhudumu msaidizi katika hoteli ya nyota 5 mlimani").',
              ),
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? theme.colorScheme.outlineVariant
                      : AppColors.designInputBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? theme.colorScheme.outlineVariant
                      : AppColors.designInputBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? theme.colorScheme.primary
                      : AppColors.colorPrimary,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.previewVoice,
              icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
              label: Text(
                _t(context, en: 'Preview AI Voice', sw: 'Sikiliza Sauti ya AI'),
                style: TextStyle(
                  color: isDark
                      ? theme.colorScheme.primary
                      : const Color(0xFF0D6D6D),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.50,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? theme.colorScheme.surfaceContainerHighest
                    : const Color(0xFFE9F3F3),
                foregroundColor: AppColors.colorPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toneChip(BuildContext context, String label, VoiceTone tone) {
    final theme = Theme.of(context);
    final selected = controller.selectedTone.value == tone;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setTone(tone),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.colorPrimary
                : (_isDark(context)
                      ? theme.colorScheme.surface
                      : AppColors.pageBackground),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.colorPrimary
                  : (_isDark(context)
                        ? theme.colorScheme.outlineVariant
                        : AppColors.designInputBorder),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : (_isDark(context)
                          ? theme.colorScheme.onSurface
                          : AppColors.textColorPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
