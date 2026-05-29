import 'package:flutter/material.dart';
import 'package:paa_yangu/app/core/theme/app_theme_tokens.dart';
import '../../../core/theme/form_surface_colors.dart';

import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/values/text_styles.dart';
import '../../../data/local/service/workspace_context_service.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingView extends BaseView<OnboardingController> {
  OnboardingView({super.key});

  

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return null;
  }

  @override
  Widget body(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final currentLang = Get.locale?.languageCode == 'sw' ? 'sw' : 'en';
    final titleColor = c.headline;
    final workspaceLabelColor = c.isDark
        ? Colors.white
        : AppColors.textColorPrimary;
    final bodyColor = c.secondary;
    final cardBg = c.isDark
        ? context.tokens.cardBackground
        : Colors.white.withValues(alpha: 0.9);
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppValues.largePadding,
                vertical: AppValues.largePadding,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Center(
                      child: Image.asset(
                        'images/paa_yangu_logo.png',
                        width: 100,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.home_work_rounded,
                          size: 80,
                          color: AppColors.colorPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        (currentLang == 'sw' ? 'Karibu HostBora' : 'Welcome to HostBora'),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 16,
                          color: titleColor,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(
                            text: 'HostBora',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: (currentLang == 'sw'
                                ? ' ni programu ya kusimamia upangishaji wa muda mfupi na wa muda mrefu. '
                                : ' is an app for managing both short-term stays and long-term rentals. '),
                          ),
                          TextSpan(
                            text: (currentLang == 'sw'
                                ? 'Fuatilia malipo'
                                : 'Track payments'),
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: (currentLang == 'sw'
                              ? ', fuatilia '
                              : ', monitor ')),
                          TextSpan(
                            text: (currentLang == 'sw'
                                ? 'faida na hasara'
                                : 'profits or losses'),
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: (currentLang == 'sw'
                              ? ', na kuona michango ya wapangaji. '
                              : ', and view tenant contributions. ')),
                          TextSpan(
                            text: (currentLang == 'sw'
                                ? 'Tuma ukumbusho wa kulipa kodi'
                                : 'Send rent reminders'),
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: (currentLang == 'sw'
                                ? ' kupitia WhatsApp au SMS, simamia ratiba, na hifadhi data kwa usalama bila mtandao kwenye simu yako.'
                                : ' via WhatsApp or SMS, manage schedules, and securely store data offline on your phone.'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      (currentLang == 'sw'
                          ? 'Hii ni programu ya mwenye nyumba au mpangishaji yenye sehemu mbili '
                          '— uhifadhi wa taarifa za wageni wa BnB shughuli za upangishaji '
                          'na umiliki, ikiwa na uhifadhi imara wa data nje ya mtandao.'
                          : 'This is a dual-purpose property app that combines BnB booking '
                          'and guest management with rental and landlord operations, '
                          'backed by strong offline data storage'
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        (currentLang == 'sw'
                            ? 'Chagua upande upi utatumia zaidi.'
                            : 'Choose your preferred workspace.'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        (currentLang == 'sw'
                            ? 'Utaweza kubadilisha muda wowote ukiwa ndani ya programu.'
                            : 'You can change any time once inside the app.'),
                        style: subTitleTextStyle
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: Get.width - 200,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          InkWell(
                            onTap: () {
                              Get.find<WorkspaceContextService>().switchWorkspace(
                                'rent',
                              );
                              controller.completeOnboarding();
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: c.isDark
                                        ? AppColors.colorPrimary.withValues(alpha: 0.25)
                                        : AppColors.colorPrimaryLight,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.colorPrimary.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: SvgPicture.asset(
                                      'images/ic_rent_house.svg',
                                      height: 64,
                                      width: 64,
                                      colorFilter: const ColorFilter.mode(
                                        AppColors.colorPrimary,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'RENT',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: workspaceLabelColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Get.find<WorkspaceContextService>().switchWorkspace(
                                'bnb',
                              );
                              controller.completeOnboarding();
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: c.isDark
                                        ? AppColors.colorPrimary.withValues(alpha: 0.25)
                                        : AppColors.colorPrimaryLight,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.colorPrimary.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'images/bed-and-breakfast.png',
                                    height: 64,
                                    width: 64,
                                    color: AppColors.colorPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'BnB',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: workspaceLabelColor,
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
              ),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: c.isDark
                      ? context.tokens.elevatedSurface
                      : AppColors.designInputBorder,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentLang == 'sw' ? 'Anza Sasa' : 'Get Started',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    currentLang == 'sw'
                        ? 'Uko tayari kuanza kutumia programu.'
                        : 'Ready to explore the app experience.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: bodyColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
