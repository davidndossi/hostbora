import 'package:flutter/material.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_values.dart';
import '../controllers/password_updated_controller.dart';

// Figma design colors for this screen
const _colorBackground = Color(0xFFF8F7F4);
const _colorSuccessGreen = Color(0xFF1E885B);
const _colorHeadline = Color(0xFF2E3331);
const _colorBodyText = Color(0xFF7C8281);
const _colorPlaceholderBox = Color(0xFFE3F2F1);
const _colorButtonTeal = Color(0xFF1E6E66);

class PasswordUpdatedView extends BaseView<PasswordUpdatedController> {
  PasswordUpdatedView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'sw' ? sw : en;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return null;
  }

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      color: isDark ? theme.colorScheme.surface : _colorBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildSuccessIcon(),
              const SizedBox(height: 24),
              Text(
                _t(
                  context,
                  en: 'Password Updated',
                  sw: 'Nenosiri Limesasishwa',
                ),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: isDark ? theme.colorScheme.onSurface : _colorHeadline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _t(
                  context,
                  en: 'Your password has been changed successfully. You can now log in to your account.',
                  sw: 'Nenosiri lako limebadilishwa kwa mafanikio. Sasa unaweza kuingia kwenye akaunti yako.',
                ),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? theme.colorScheme.onSurfaceVariant
                      : _colorBodyText,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildPlaceholderBox(context),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: AppValues.formButtonHeight,
                child: ElevatedButton(
                  onPressed: controller.backToLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? theme.colorScheme.primary
                        : _colorButtonTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _t(context, en: 'Back to Login', sw: 'Rudi Kuingia'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _t(context, en: 'Need help? ', sw: 'Unahitaji msaada? '),
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark
                          ? theme.colorScheme.onSurfaceVariant
                          : _colorBodyText,
                    ),
                  ),
                  GestureDetector(
                    onTap: controller.contactSupport,
                    child: Text(
                      _t(
                        context,
                        en: 'Contact support',
                        sw: 'Wasiliana na msaada',
                      ),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? theme.colorScheme.primary
                            : _colorButtonTeal,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer subtle circles (glow effect)
        Positioned(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _colorSuccessGreen.withValues(alpha: 0.15),
            ),
          ),
        ),
        Positioned(
          left: 20,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _colorSuccessGreen.withValues(alpha: 0.2),
            ),
          ),
        ),
        // Main circle with checkmark
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _colorSuccessGreen,
            boxShadow: [
              BoxShadow(
                color: Color(0x301E885B),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.check_rounded, size: 48, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildPlaceholderBox(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : _colorPlaceholderBox,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.lock_rounded,
          size: 56,
          color: (isDark ? theme.colorScheme.primary : _colorSuccessGreen)
              .withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
