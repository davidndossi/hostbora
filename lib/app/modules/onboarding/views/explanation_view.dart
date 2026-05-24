import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:paa_yangu/app/core/values/text_styles.dart';

import '../../../core/values/app_colors.dart';
import '../../../core/widget/base_currency_picker.dart';
import '../../../data/local/service/workspace_context_service.dart';
import '../controllers/onboarding_controller.dart';

class ExplanationView extends StatelessWidget {
  const ExplanationView({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLang = Get.locale?.languageCode == 'sw' ? 'sw' : 'en';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppColors.textColorPrimary;
    final bodyColor = isDark ? Colors.white70 : AppColors.textColorSecondary;
    final cardBg = isDark
        ? const Color(0xFF2C2C2E)
        : Colors.white.withValues(alpha: 0.9);
    final workspaceLabelColor = isDark
        ? Colors.white
        : AppColors.textColorPrimary;

    return SingleChildScrollView(
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
          // Text(
          //   (currentLang == 'sw'
          //       ? 'HostBora ni programu kwa ajili ya watu wanaoendesha '
          //             'makaazi ya muda mfupi (mtindo wa BnB) na kodi za muda mrefu. '
          //             'Inakusaidia kufuatilia malipo ya wapangaji na faida au hasara '
          //             'zinazotokana na mali zako. Kwa kodi za muda mrefu unaweza '
          //             'kuona jinsi kila mpangaji alivyochangia na kama kodi ya upangaji '
          //             'wake imekuwa na faida. Inatuma taarifa kiotomatiki kwa '
          //             'wapangaji kupitia whatsapp/text ikiwa kodi yao inakaribia kuisha '
          //             'na unaweza kuweka ukumbusho katika kalenda iliyojengwa ndani. '
          //             'Hatimaye hauhitaji kuwa mtandaoni kwani data huhifadhiwa kwa '
          //             'usalama kwenye simu yako.'
          //       : 'HostBora is an app for people who run short-term stays (BnB-style) '
          //             'and long-term rentals. It helps you track tenant payments and '
          //             'see profits or losses derived from your properties. For long term '
          //             'rentals you can visualize how each tenant has contributed and if '
          //             'the tenancy has been profitable. It sends automatic notifications '
          //             'to tenants via whatsapp/text if their rent is due and you can '
          //             'set reminders in inbuilt calendar. Finally you don\'t have to '
          //             'be online as data is saved offline securely in your phone.'),
          //   style: TextStyle(
          //     fontSize: 16,
          //     fontWeight: FontWeight.w400,
          //     color: bodyColor,
          //     height: 1.5,
          //   ),
          // ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: BaseCurrencyPicker(
              title: currentLang == 'sw'
                  ? 'Sarafu ya msingi (chaguo-msingi TZS)'
                  : 'Base currency (default TZS)',
            ),
          ),
          SizedBox(
            height: Get.width - 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: () async {
                    await Get.find<WorkspaceContextService>().switchWorkspace(
                      'rent',
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: isDark
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
                  onTap: () async {
                    await Get.find<WorkspaceContextService>().switchWorkspace(
                      'bnb',
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: isDark
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
          // Center(
          //   child: Container(
          //     padding: const EdgeInsets.all(24),
          //     margin: const EdgeInsets.symmetric(horizontal: 24),
          //     decoration: BoxDecoration(
          //       color: cardBg,
          //       borderRadius: BorderRadius.circular(16),
          //       border: Border.all(
          //         color: isDark
          //             ? const Color(0xFF3A3A3C)
          //             : AppColors.designInputBorder,
          //       ),
          //     ),
          //     child: Column(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Text(
          //           currentLang == 'sw' ? 'Anza Sasa' : 'Get Started',
          //           style: TextStyle(
          //             fontSize: 24,
          //             fontWeight: FontWeight.bold,
          //             color: titleColor,
          //           ),
          //         ),
          //         SizedBox(height: 12),
          //         Text(
          //           currentLang == 'sw'
          //               ? 'Uko tayari kuanza kutumia programu.'
          //               : 'Ready to explore the app experience.',
          //           textAlign: TextAlign.center,
          //           style: TextStyle(color: bodyColor),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
