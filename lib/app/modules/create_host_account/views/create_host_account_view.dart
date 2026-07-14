import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../core/theme/form_surface_colors.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/create_host_account_controller.dart';

class CreateHostAccountView extends BaseView<CreateHostAccountController> {
  CreateHostAccountView({super.key});

  

  String _t(BuildContext context, {required String en, required String sw}) {
    final code =
        Get.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    return code == 'sw' ? sw : en;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(appBarTitleText: '');
  }

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    final c = FormSurfaceColors.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  _t(
                    context,
                    en: 'Create Host Account',
                    sw: 'Fungua Akaunti ya Mwenye Nyumba',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: c.isDark
                        ? theme.colorScheme.primary
                        : AppColors.designAccent,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _t(
                  context,
                  en: 'Join our community of premium property owners.',
                  sw: 'Jiunge na jamii yetu ya wamiliki wa mali bora.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: c.isDark
                      ? theme.colorScheme.onSurfaceVariant
                      : AppColors.designSecondaryText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              _buildLabel(
                context,
                _t(context, en: 'Full Name', sw: 'Jina Kamili'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.fullNameController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(
                  context,
                  hint: _t(context, en: 'John Doe', sw: 'Juma Juma'),
                ),
                validator: (v) => controller.validateRequired(
                  v,
                  _t(context, en: 'Full name', sw: 'Jina kamili'),
                ),
              ),
              const SizedBox(height: 20),
              _buildLabel(
                context,
                _t(context, en: 'Email Address', sw: 'Barua Pepe'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(context, hint: 'name@example.com'),
                validator: controller.validateEmail,
              ),
              const SizedBox(height: 20),
              _buildLabel(
                context,
                _t(context, en: 'Phone Number', sw: 'Namba ya Simu'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                  context,
                  hint: '0601000000',
                ),
                validator: (v) => controller.validateRequired(
                  v,
                  _t(context, en: 'Phone number', sw: 'Namba ya simu'),
                ),
              ),
              const SizedBox(height: 20),
              _buildLabel(
                context,
                _t(context, en: 'Referral code (optional)', sw: 'Msimbo wa mrejeleo (si lazima)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.referralCodeController,
                textCapitalization: TextCapitalization.characters,
                decoration: _inputDecoration(
                  context,
                  hint: _t(context, en: 'AGT-JOHN-001', sw: 'AGT-JOHN-001'),
                ).copyWith(
                  suffixIcon: Obx(() {
                    if (controller.isCheckingReferral.value) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final valid = controller.referralValid.value;
                    if (valid == true) {
                      return const Icon(Icons.check_circle, color: Colors.green);
                    }
                    if (valid == false) {
                      return const Icon(Icons.error_outline, color: Colors.red);
                    }
                    return const SizedBox.shrink();
                  }),
                ),
                onChanged: (_) => controller.validateReferralCode(),
                onFieldSubmitted: (_) => controller.validateReferralCode(),
              ),
              Obx(() {
                final name = controller.referralAgentName.value;
                if (name == null || name.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _t(
                      context,
                      en: 'Referred by $name',
                      sw: 'Umeletwa na $name',
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: c.isDark
                          ? theme.colorScheme.primary
                          : AppColors.designAccent,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              _buildLabel(context, _t(context, en: 'Password', sw: 'Nenosiri')),
              const SizedBox(height: 8),
              Obx(
                () => TextFormField(
                  controller: controller.passwordController,
                  obscureText: controller.obscurePassword.value,
                  decoration: _inputDecoration(context, hint: '••••••••')
                      .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.obscurePassword.value
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.designPlaceholder,
                            size: 22,
                          ),
                          onPressed: controller.togglePasswordVisibility,
                        ),
                      ),
                  validator: controller.validatePassword,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: c.isDark
                          ? theme.colorScheme.onSurfaceVariant
                          : AppColors.designSecondaryText,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: _t(
                          context,
                          en: 'By signing up, you agree to our ',
                          sw: 'Kwa kujisajili, unakubali ',
                        ),
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: controller.goToTerms,
                          child: Text(
                            _t(
                              context,
                              en: 'Terms of Service',
                              sw: 'Masharti ya Huduma',
                            ),
                            style: TextStyle(
                              color: c.isDark
                                  ? theme.colorScheme.primary
                                  : AppColors.designAccent,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      TextSpan(
                        text: _t(context, en: ' and ', sw: ' na '),
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: controller.goToPrivacy,
                          child: Text(
                            _t(
                              context,
                              en: 'Privacy Policy',
                              sw: 'Sera ya Faragha',
                            ),
                            style: TextStyle(
                              color: c.isDark
                                  ? theme.colorScheme.primary
                                  : AppColors.designAccent,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: AppValues.formButtonHeight,
                child: ElevatedButton(
                  onPressed: controller.signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.isDark
                        ? theme.colorScheme.primary
                        : AppColors.designAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppValues.radius_6),
                    ),
                  ),
                  child: Text(
                    _t(context, en: 'Sign Up', sw: 'Jisajili'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: controller.goToLogin,
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 15,
                        color: c.isDark
                            ? theme.colorScheme.onSurfaceVariant
                            : AppColors.designSecondaryText,
                      ),
                      children: [
                        TextSpan(
                          text: _t(
                            context,
                            en: 'Already have an account? ',
                            sw: 'Una akaunti tayari? ',
                          ),
                        ),
                        TextSpan(
                          text: _t(context, en: 'Login', sw: 'Ingia'),
                          style: TextStyle(
                            color: c.isDark
                                ? theme.colorScheme.primary
                                : AppColors.designAccent,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Center(
                child: Container(
                  width: 64,
                  height: 4,
                  decoration: ShapeDecoration(
                    color: c.isDark
                        ? theme.colorScheme.outlineVariant
                        : const Color(0xFFE2E8F0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildBottomBanner(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: FormSurfaceColors.of(context).isDark
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : AppColors.designSecondaryText,
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
  }) {
    final theme = Theme.of(context);
    final c = FormSurfaceColors.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: c.isDark
            ? theme.colorScheme.onSurfaceVariant
            : AppColors.designPlaceholder,
      ),
      filled: true,
      fillColor: c.isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: BorderSide(
          color: c.isDark
              ? theme.colorScheme.outlineVariant
              : AppColors.designInputBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: BorderSide(
          color: c.isDark
              ? theme.colorScheme.outlineVariant
              : AppColors.designInputBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: BorderSide(
          color: c.isDark ? theme.colorScheme.primary : AppColors.designAccent,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: const BorderSide(color: AppColors.errorColor),
      ),
    );
  }

  Widget _buildBottomBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      height: 120,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: AssetImage("images/create_host_account.png"),
          fit: BoxFit.fill,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.designAccent, AppColors.designAccentDark],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // const Icon(
          //   Icons.bed_rounded,
          //   size: 36,
          //   color: Colors.white,
          // ),
          SvgPicture.asset('images/ic_bed.svg'),
          Text(
            _t(
              context,
              en: 'Your journey as a host starts here.',
              sw: 'Safari yako ya kuwa mwenyeji inaanza hapa.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
