import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/values/app_values.dart';
import '../controllers/create_host_account_controller.dart';
import 'signup_wizard_chrome.dart';

/// Sign-up as a one-question-per-screen wizard.
///
/// The progress bar is the point: each answer visibly shortens the distance to
/// a finished account, which is what keeps people moving through a form they
/// would abandon if it arrived as a single wall of fields.
class CreateHostAccountView extends BaseView<CreateHostAccountController> {
  CreateHostAccountView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => null;

  @override
  Widget body(BuildContext context) {
    return Form(
      key: controller.formKey,
      // Never pops directly: controller.back() already decides between
      // stepping back a question, popping, and leaving for the login screen.
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.back();
        },
        child: Obx(() {
          final step = controller.step.value;
          return SignupWizardScaffold(
            progress: controller.progress,
            stepLabel: _t(
              context,
              en: 'Step ${controller.stepIndex + 1} of ${controller.totalSteps}',
              sw: 'Hatua ${controller.stepIndex + 1} ya ${controller.totalSteps}',
            ),
            onBack: controller.back,
            primaryLabel: _primaryLabel(context, step),
            onPrimary: controller.next,
            stepKey: step,
            isBusy: controller.isLoading.value,
            footer: step == SignupStep.email
                ? _legalFooter(context)
                : step == SignupStep.name
                    ? _loginFooter(context)
                    : null,
            child: _stepContent(context, step),
          );
        }),
      ),
    );
  }

  String _primaryLabel(BuildContext context, SignupStep step) {
    switch (step) {
      case SignupStep.email:
        return _t(context, en: 'Create my account', sw: 'Fungua akaunti yangu');
      case SignupStep.code:
        return _t(context, en: 'Verify', sw: 'Thibitisha');
      default:
        return _t(context, en: 'Continue', sw: 'Endelea');
    }
  }

  Widget _stepContent(BuildContext context, SignupStep step) {
    switch (step) {
      case SignupStep.name:
        return _nameStep(context);
      case SignupStep.phone:
        return _phoneStep(context);
      case SignupStep.email:
        return _emailStep(context);
      case SignupStep.code:
        return _codeStep(context);
    }
  }

  // ── Steps ─────────────────────────────────────────────────────────────────

  Widget _nameStep(BuildContext context) {
    return SignupStepBody(
      question: _t(context, en: "What's your name?", sw: 'Jina lako ni nani?'),
      helper: _t(
        context,
        en: 'This is how your tenants and guests will see you.',
        sw: 'Hivi ndivyo wapangaji na wageni wako watakuona.',
      ),
      children: [
        signupField(
          context,
          label: _t(context, en: 'FIRST NAME', sw: 'JINA LA KWANZA'),
          controller: controller.firstNameController,
          hint: _t(context, en: 'Juma', sw: 'Juma'),
          validator: controller.validateFirstName,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 18),
        signupField(
          context,
          label: _t(context, en: 'LAST NAME', sw: 'JINA LA FAMILIA'),
          controller: controller.lastNameController,
          hint: _t(context, en: 'Mwinyi', sw: 'Mwinyi'),
          validator: controller.validateLastName,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => controller.next(),
        ),
      ],
    );
  }

  Widget _phoneStep(BuildContext context) {
    final name = controller.firstName;
    return SignupStepBody(
      question: name.isEmpty
          ? _t(context, en: 'Your phone number', sw: 'Namba yako ya simu')
          : _t(
              context,
              en: 'Your phone number, $name',
              sw: 'Namba yako ya simu, $name',
            ),
      helper: _t(
        context,
        en: 'We send your verification code here. It is also how you sign in later.',
        sw: 'Tunatuma msimbo wa uthibitisho hapa. Pia ndiyo njia yako ya kuingia baadaye.',
      ),
      children: [
        signupField(
          context,
          label: _t(context, en: 'PHONE NUMBER', sw: 'NAMBA YA SIMU'),
          controller: controller.phoneController,
          hint: '0712345678',
          validator: controller.validatePhone,
          autofocus: true,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => controller.next(),
        ),
      ],
    );
  }

  Widget _emailStep(BuildContext context) {
    return SignupStepBody(
      question: _t(
        context,
        en: 'Do you have an email?',
        sw: 'Unayo barua pepe?',
      ),
      helper: _t(
        context,
        en: 'Optional. It is only used for receipts, exported reports, and getting back into your account.',
        sw: 'Si lazima. Hutumika kwa risiti, ripoti unazopakua, na kurejesha akaunti yako.',
      ),
      children: [
        Obx(() {
          final answer = controller.hasEmail.value;
          return Row(
            children: [
              Expanded(
                child: SignupChoiceTile(
                  label: _t(context, en: 'Yes', sw: 'Ndiyo'),
                  selected: answer == true,
                  onTap: () => controller.setHasEmail(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SignupChoiceTile(
                  label: _t(context, en: 'No', sw: 'Hapana'),
                  selected: answer == false,
                  onTap: () => controller.setHasEmail(false),
                ),
              ),
            ],
          );
        }),
        Obx(() {
          if (controller.hasEmail.value != true) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 22),
            child: signupField(
              context,
              label: _t(context, en: 'EMAIL', sw: 'BARUA PEPE'),
              controller: controller.emailController,
              hint: 'juma@example.com',
              validator: controller.validateEmail,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => controller.next(),
            ),
          );
        }),
        Obx(() {
          if (controller.hasEmail.value != false) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Text(
              _t(
                context,
                en: 'No problem — your code comes by SMS, and you sign in with your phone number. You can add an email later in Settings.',
                sw: 'Hakuna shida — msimbo wako unakuja kwa SMS, na unaingia kwa namba yako ya simu. Unaweza kuongeza barua pepe baadaye kwenye Mipangilio.',
              ),
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: FormSurfaceColors.of(context).secondary,
              ),
            ),
          );
        }),
        _referralApplied(context),
      ],
    );
  }

  /// Confirms a referral code that arrived on a deep link.
  ///
  /// Replaces a whole wizard step that asked "were you referred?". A host
  /// without a code could only answer No, and a host with one arrived holding
  /// it already — [ReferralLinks.pendingCode] carries it, and the server
  /// attaches it after verification. So this states the outcome instead of
  /// collecting an answer, and renders nothing when there is no code.
  Widget _referralApplied(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Obx(() {
      if (controller.wasReferred.value != true) {
        return const SizedBox.shrink();
      }
      final code = controller.referralCodeController.text.trim();
      if (code.isEmpty) return const SizedBox.shrink();
      final agent = controller.referralAgentName.value ?? '';
      return Container(
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.tokens.accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppValues.radius_12),
          border: Border.all(color: c.tokens.accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.redeem_outlined, size: 20, color: c.tokens.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                agent.isEmpty
                    ? _t(
                        context,
                        en: 'Referral code $code applied',
                        sw: 'Msimbo wa mrejeleo $code umetumika',
                      )
                    : _t(
                        context,
                        en: 'Referred by $agent · $code',
                        sw: 'Umeletwa na $agent · $code',
                      ),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: c.headline,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _codeStep(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Obx(() {
      final onEmail = controller.channel.value.toUpperCase() == 'EMAIL';
      final target = onEmail ? controller.email.value : controller.msisdn.value;
      return SignupStepBody(
        question: _t(
          context,
          en: 'Enter the code we sent',
          sw: 'Weka msimbo tuliotuma',
        ),
        helper: _t(
          context,
          en: 'A 4-digit code is on its way to $target.',
          sw: 'Msimbo wa tarakimu 4 unakuja kwa $target.',
        ),
        children: [
          signupField(
            context,
            label: _t(context, en: '4-DIGIT CODE', sw: 'MSIMBO WA TARAKIMU 4'),
            controller: controller.otpController,
            hint: '••••',
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            onChanged: controller.onCodeChanged,
            letterSpacing: 10,
            textAlign: TextAlign.center,
            fontSize: 24,
          ),
          const SizedBox(height: 20),
          Obx(
            () => TextButton(
              onPressed: controller.canResend
                  ? () => controller.resendCode()
                  : null,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                controller.canResend
                    ? _t(context, en: 'Send a new code', sw: 'Tuma msimbo mpya')
                    : _t(
                        context,
                        en: 'Send a new code in ${controller.resendCooldownLabel}',
                        sw: 'Tuma msimbo mpya baada ya ${controller.resendCooldownLabel}',
                      ),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: controller.canResend ? c.tokens.accent : c.hint,
                ),
              ),
            ),
          ),
          // Only offered when there is actually a second place to send to.
          if (controller.canUseEmailChannel)
            TextButton(
              onPressed: () => controller.resendCode(
                onChannel: onEmail ? 'SMS' : 'EMAIL',
              ),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                onEmail
                    ? _t(
                        context,
                        en: 'Send by SMS instead',
                        sw: 'Tuma kwa SMS badala yake',
                      )
                    : _t(
                        context,
                        en: 'Send to my email instead',
                        sw: 'Tuma kwenye barua pepe yangu badala yake',
                      ),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.secondary,
                ),
              ),
            ),
        ],
      );
    });
  }

  // ── Footers ───────────────────────────────────────────────────────────────

  Widget _legalFooter(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final linkStyle = TextStyle(
      fontSize: 13,
      color: c.tokens.accent,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );

    // WidgetSpan rather than TextSpan + recognizer: a GestureRecognizer built
    // here would need disposing, and this footer rebuilds on every keystroke.
    WidgetSpan link(String text, VoidCallback onTap) => WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: onTap,
            child: Text(text, style: linkStyle),
          ),
        );

    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 13, color: c.secondary, height: 1.4),
        children: [
          TextSpan(
            text: _t(
              context,
              en: 'By creating an account you agree to our ',
              sw: 'Kwa kufungua akaunti unakubali ',
            ),
          ),
          link(
            _t(context, en: 'Terms of Service', sw: 'Masharti ya Huduma'),
            controller.goToTerms,
          ),
          TextSpan(text: _t(context, en: ' and ', sw: ' na ')),
          link(
            _t(context, en: 'Privacy Policy', sw: 'Sera ya Faragha'),
            controller.goToPrivacy,
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _loginFooter(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Center(
      child: TextButton(
        onPressed: controller.goToLogin,
        child: Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 14, color: c.secondary),
            children: [
              TextSpan(
                text: _t(
                  context,
                  en: 'Already have an account? ',
                  sw: 'Una akaunti tayari? ',
                ),
              ),
              TextSpan(
                text: _t(context, en: 'Sign in', sw: 'Ingia'),
                style: TextStyle(
                  color: c.tokens.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _t(BuildContext context, {required String en, required String sw}) {
    final code = Get.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    return code == 'sw' ? sw : en;
  }
}

/// Shared input used by every wizard step.
Widget signupField(
  BuildContext context, {
  required String label,
  required TextEditingController controller,
  required String hint,
  String? Function(String?)? validator,
  bool autofocus = false,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  TextCapitalization textCapitalization = TextCapitalization.none,
  TextInputAction? textInputAction,
  ValueChanged<String>? onChanged,
  ValueChanged<String>? onSubmitted,
  Widget? suffix,
  double? letterSpacing,
  TextAlign textAlign = TextAlign.start,
  double fontSize = 16,
}) {
  final c = FormSurfaceColors.of(context);
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        borderSide: BorderSide(color: color, width: width),
      );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: c.secondary,
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        autofocus: autofocus,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        validator: validator,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: letterSpacing,
          color: c.headline,
          height: 1.3,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: c.hint,
            fontWeight: FontWeight.w400,
            letterSpacing: letterSpacing,
          ),
          filled: true,
          fillColor: c.inputFill,
          suffixIcon: suffix,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: border(c.inputBorder),
          enabledBorder: border(c.inputBorder),
          focusedBorder: border(c.tokens.accent, 1.5),
        ),
      ),
    ],
  );
}
