import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/sticky_form_actions.dart';
import '../controllers/first_property_controller.dart';

class FirstPropertyView extends BaseView<FirstPropertyController> {
  FirstPropertyView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => null;

  /// One screen, where there used to be two.
  ///
  /// The first was an "account is ready" page whose only job was to soften the
  /// form behind it: a headline, three reassurances and a button that revealed
  /// the actual ask. With the form down to two fields there is nothing left to
  /// soften, so the reassurances collapse into one line above the fields and
  /// the extra tap is gone.
  @override
  Widget body(BuildContext context) {
    // System back is the same promise as the Skip button: leave without
    // adding anything. Without this the step is a trap, because it is reached
    // by offAllNamed and so has nothing to pop back to.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        controller.skip();
      },
      child: _form(context),
    );
  }

  Widget _form(BuildContext context) {
    final c = FormSurfaceColors.of(context);

    final content = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: c.tokens.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.check_outlined,
              color: c.tokens.accent,
              size: 30,
            ),
          ),
          const SizedBox(height: 24),
          Obx(() {
            final name = controller.hostFirstName.value;
            return Text(
              name.isEmpty
                  ? _t(
                      context,
                      en: 'Your account is ready',
                      sw: 'Akaunti yako iko tayari',
                    )
                  : _t(
                      context,
                      en: 'Your account is ready, $name',
                      sw: 'Akaunti yako iko tayari, $name',
                    ),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -0.5,
                color: c.headline,
              ),
            );
          }),
          const SizedBox(height: 10),
          Text(
            _t(
              context,
              en: 'Add your first property and you are done. Two answers — units, photos and rent come later.',
              sw: 'Ongeza mali yako ya kwanza na umemaliza. Majibu mawili — uniti, picha na kodi zinafuata baadaye.',
            ),
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: c.secondary,
            ),
          ),
          const SizedBox(height: 22),
          _reassurances(context),
          const SizedBox(height: 26),
          _textField(
            context,
            label: _t(context, en: 'PROPERTY NAME', sw: 'JINA LA MALI'),
            controller: controller.nameController,
            hint: _t(
              context,
              en: "Juma's Apartment",
              sw: 'Apartment ya Juma',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),
          _textField(
            context,
            label: _t(context, en: 'LOCATION', sw: 'MAHALI'),
            controller: controller.locationController,
            hint: _t(
              context,
              en: 'e.g. Sinza Madukani',
              sw: 'mf. Sinza Madukani',
            ),
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
    );

    return Column(
      children: [
        Expanded(child: content),
        StickyFormActions(
          primary: Obx(
            () => FilledButton(
              onPressed: controller.isSaving.value ? null : controller.complete,
              style: FilledButton.styleFrom(
                backgroundColor: c.tokens.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    c.tokens.accent.withValues(alpha: 0.5),
                minimumSize: Size.fromHeight(AppValues.formButtonHeight + 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppValues.radius_12),
                ),
              ),
              child: controller.isSaving.value
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _t(
                        context,
                        en: 'Add property',
                        sw: 'Ongeza mali',
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          secondary: TextButton(
            onPressed: controller.skip,
            child: Text(
              _t(context, en: 'Skip for now', sw: 'Ruka kwa sasa'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.secondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The three promises from the deleted offer screen, on one line.
  ///
  /// They were a 2-line block each, which is more weight than a reassurance
  /// needs when it sits above the thing it is reassuring about. Compressed to
  /// icon-and-label they still answer "what am I signing up for" at a glance
  /// without pushing the fields off the first screen.
  Widget _reassurances(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final items = <(IconData, String)>[
      (
        Icons.workspace_premium_outlined,
        _t(context, en: 'Free plan', sw: 'Mpango wa bure'),
      ),
      (
        Icons.cloud_off_outlined,
        _t(context, en: 'Works offline', sw: 'Bila mtandao'),
      ),
      (
        Icons.notifications_active_outlined,
        _t(context, en: 'Rent reminders', sw: 'Vikumbusho'),
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: c.tileBg,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          for (final (icon, label) in items)
            Expanded(
              child: Column(
                children: [
                  Icon(icon, size: 20, color: c.tokens.accent),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: c.secondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Field builders ────────────────────────────────────────────────────────

  Widget _textField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String hint,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final c = FormSurfaceColors.of(context);
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
        TextField(
          controller: controller,
          textCapitalization: textCapitalization,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: c.headline,
          ),
          decoration: _decoration(context, hint: hint),
        ),
      ],
    );
  }

  InputDecoration _decoration(BuildContext context, {required String hint}) {
    final c = FormSurfaceColors.of(context);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppValues.radius_12),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: hint.isEmpty ? null : hint,
      hintStyle: TextStyle(color: c.hint, fontWeight: FontWeight.w400),
      filled: true,
      fillColor: c.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(c.inputBorder),
      enabledBorder: border(c.inputBorder),
      focusedBorder: border(c.tokens.accent, 1.5),
    );
  }

  String _t(BuildContext context, {required String en, required String sw}) {
    final code = Get.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    return code == 'sw' ? sw : en;
  }
}
