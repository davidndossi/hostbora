import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/locale/app_locale_controller.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../routes/app_pages.dart';
import '../controllers/auth_controller.dart';

class AuthView extends BaseView<AuthController> {
  AuthView({super.key});

  String _t(BuildContext context, String en, String sw) {
    return Localizations.localeOf(context).languageCode == 'sw' ? sw : en;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) => null;

  @override
  Color pageBackgroundColor(BuildContext context) =>
      FormSurfaceColors.of(context).scaffold;

  @override
  Widget body(BuildContext context) {
    final tokens = context.tokens;
    final surface = FormSurfaceColors.of(context);

    return SafeArea(
      child: Column(
        children: [
          _TopBar(tokens: tokens),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: constraints.maxHeight < 640 ? 8 : 20),
                        _LogoMark(tokens: tokens, surface: surface),
                        const SizedBox(height: 28),
                        Text(
                          _t(context, 'Welcome back', 'Karibu tena'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            height: 1.15,
                            color: tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _t(
                            context,
                            'Enter your phone number. We’ll send a one-time code — no password needed.',
                            'Weka namba yako ya simu. Tutakutumia msimbo wa mara moja — hakuna nenosiri.',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _PhoneCard(controller: controller, t: _t),
                        const SizedBox(height: 28),
                        _OrDivider(tokens: tokens, label: appLocalization.orLabel),
                        const SizedBox(height: 20),
                        _PinEntry(controller: controller),
                        const SizedBox(height: 28),
                        _CreateAccountRow(t: _t),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.tokens});

  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          const Spacer(),
          if (Get.isRegistered<ThemeController>())
            Obx(() {
              final theme = Get.find<ThemeController>();
              return IconButton(
                tooltip: theme.isDarkMode.value
                    ? 'Light theme'
                    : 'Dark theme',
                onPressed: theme.toggleTheme,
                icon: Icon(
                  theme.isDarkMode.value
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  color: tokens.textPrimary,
                ),
              );
            }),
          if (Get.isRegistered<AppLocaleController>())
            IconButton(
              tooltip: Get.locale?.languageCode == 'sw'
                  ? 'Badili lugha'
                  : 'Change language',
              onPressed: () => Get.find<AppLocaleController>().toggle(),
              icon: Icon(Icons.language, color: tokens.textPrimary),
            ),
        ],
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.tokens, required this.surface});

  final AppThemeTokens tokens;
  final FormSurfaceColors surface;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: tokens.accent.withValues(alpha: surface.isDark ? 0.18 : 0.10),
          border: Border.all(
            color: tokens.accent.withValues(alpha: 0.28),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: tokens.accent.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Image.asset(
              'images/host_bora_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.home_work_outlined,
                size: 40,
                color: tokens.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneCard extends StatelessWidget {
  const _PhoneCard({required this.controller, required this.t});

  final AuthController controller;
  final String Function(BuildContext context, String en, String sw) t;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final surface = FormSurfaceColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: surface.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: surface.isDark ? 0.22 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Form(
          key: AuthController.authFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t(context, 'Phone number', 'Namba ya simu'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: tokens.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              Obx(
                () => TextFormField(
                  key: ValueKey(identityHashCode(controller.msisdnController)),
                  controller: controller.msisdnController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: t(context, 'e.g. 0712345678', 'mf. 0712345678'),
                    errorText: controller.errorText.value,
                    filled: true,
                    fillColor: surface.inputFill,
                    hintStyle: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: tokens.textMuted,
                    ),
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: tokens.accent,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: surface.inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: tokens.accent, width: 1.6),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.colorAlert),
                    ),
                  ),
                  validator: controller.validator,
                ),
              ),
              const SizedBox(height: 18),
              Obx(
                () => SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: controller.isLoading.isTrue
                        ? null
                        : controller.continueWithOtp,
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.accent,
                      disabledBackgroundColor:
                          tokens.accent.withValues(alpha: 0.45),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppValues.roundedButtonRadius,
                        ),
                      ),
                    ),
                    child: controller.isLoading.isTrue
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          )
                        : Text(
                            t(context, 'Continue', 'Endelea'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.tokens, required this.label});

  final AppThemeTokens tokens;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: tokens.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: tokens.textMuted,
            ),
          ),
        ),
        Expanded(child: Divider(color: tokens.border)),
      ],
    );
  }
}

class _PinEntry extends StatelessWidget {
  const _PinEntry({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = controller.appLocalization;

    return Obx(() {
      if (controller.isPinStatusLoading.value) {
        return Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: tokens.accent,
            ),
          ),
        );
      }

      if (!controller.hasPinEnabled.value) {
        return Text(
          l10n.authPinAvailableAfterFirstLogin,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: tokens.textMuted,
          ),
        );
      }

      return OutlinedButton.icon(
        onPressed: () => Get.toNamed(Routes.WELCOME_BACK),
        icon: Icon(Icons.pin_outlined, size: 20, color: tokens.accent),
        label: Text(
          l10n.authUsePinToSignIn,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: tokens.accent,
          ),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(color: tokens.accent.withValues(alpha: 0.45)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppValues.roundedButtonRadius),
          ),
        ),
      );
    });
  }
}

class _CreateAccountRow extends StatelessWidget {
  const _CreateAccountRow({required this.t});

  final String Function(BuildContext context, String en, String sw) t;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          t(context, 'New to Host Bora?', 'Huna akaunti?'),
          style: TextStyle(fontSize: 14, color: tokens.textSecondary),
        ),
        TextButton(
          onPressed: () => Get.toNamed(Routes.CREATE_HOST_ACCOUNT),
          child: Text(
            t(context, 'Create an account', 'Fungua akaunti'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: tokens.accent,
            ),
          ),
        ),
      ],
    );
  }
}
