import 'package:flutter/material.dart';
import 'package:host_bora/app/core/theme/app_theme_tokens.dart';

import 'package:get/get.dart';
import 'package:host_bora/app/core/widget/custom_app_bar.dart';

import '../../../../core/base/rent_base_view.dart';
import '../controllers/rent_share_renewed_lease_controller.dart';

/// Design: dark teal accent (~#005F59), cream bg #F9F8F4, serif headlines.
class _ShareUi {
  _ShareUi(this.context);

  final BuildContext context;
  ThemeData get _t => Theme.of(context);
  bool get dark => _t.brightness == Brightness.dark;

  Color get canvas =>
      dark ? _t.scaffoldBackgroundColor : const Color(0xFFF9F8F4);

  static const Color teal = Color(0xFF005F59);
  static const Color tealDark = Color(0xFF004D40);

  Color get onSurface =>
      dark ? const Color(0xFFF2F2F7) : const Color(0xFF1A1A1A);

  Color get muted =>
      dark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280);

  Color get card => dark ? context.tokens.cardBackground : Colors.white;

  Color get successCircleBg =>
      dark ? teal.withValues(alpha: 0.28) : const Color(0xFFB2DFDB);

  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.35 : 0.08),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}

class RentShareRenewedLeaseView extends RentBaseView<RentShareRenewedLeaseController> {
  RentShareRenewedLeaseView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) => CustomAppBar(
    appBarTitleText: ''
  );

  @override
  Widget body(BuildContext context) {
    final u = _ShareUi(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: u.successCircleBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              size: 40,
              color: u.dark ? const Color(0xFF80CBC4) : _ShareUi.tealDark,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            _isSw ? 'Mkataba Umehuishwa kwa Mafanikio' : 'Lease Renewed Successfully',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: u.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isSw
                ? 'Hati iko tayari kusainiwa na kushirikiwa na mpangaji wako.'
                : 'The document is ready for signing and sharing with your tenant.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: u.muted,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 28),
          _documentPreviewCard(context),
          const SizedBox(height: 10),
          InkWell(
            onTap: controller.onPreviewTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility_outlined, size: 18, color: u.muted),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _isSw
                          ? 'Kuangalia: ${controller.previewFileName}'
                          : 'Previewing: ${controller.previewFileName}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: u.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _isSw ? 'Tuma kwa Mpangaji' : 'Send to Tenant',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: u.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _whatsappCard(context),
          const SizedBox(height: 12),
          _emailCard(context),
          const SizedBox(height: 18),
          Obx(
            () => Theme(
              data: Theme.of(context).copyWith(
                checkboxTheme: CheckboxThemeData(
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return _ShareUi.teal;
                    }
                    return null;
                  }),
                ),
              ),
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: controller.sendCopyToMyEmail.value,
                onChanged: controller.toggleSendCopy,
                title: Text(
                  _isSw ? 'Tuma nakili kwa barua pepe yangu' : 'Send Copy to My Email',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: u.onSurface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: controller.onDone,
              style: FilledButton.styleFrom(
                backgroundColor:
                    u.dark ? context.tokens.elevatedSurface : const Color(0xFFE5E5E0),
                foregroundColor: u.onSurface,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                _isSw ? 'Imekamilika' : 'Done',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: controller.returnToContractHub,
            child: Text(
              _isSw ? 'RUDI KWENYE KITOVU CHA MIKATABA' : 'RETURN TO CONTRACT HUB',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: u.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentPreviewCard(BuildContext context) {
    final u = _ShareUi(context);
    final barColor = u.dark ? const Color(0xFF5C5C5E) : const Color(0xFFD0D0CC);
    final faint = u.muted.withValues(alpha: 0.85);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: u.cardShadow,
        border: u.dark ? Border.all(color: context.tokens.elevatedSurface) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'CONFIDENTIAL',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: faint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _bar(barColor, 1.0),
          const SizedBox(height: 8),
          _bar(barColor, 0.92),
          const SizedBox(height: 8),
          _bar(barColor, 0.75),
          const SizedBox(height: 8),
          _bar(barColor, 0.88),
          const SizedBox(height: 8),
          _bar(barColor, 0.5),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 1,
                      color: barColor,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'LESSOR SIGNATURE',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: faint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 36,
                height: 44,
                decoration: BoxDecoration(
                  color: u.dark ? const Color(0xFF48484A) : const Color(0xFFE8E8E4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.description_outlined,
                  size: 20,
                  color: faint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bar(Color color, double widthFactor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: constraints.maxWidth * widthFactor,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }

  Widget _whatsappCard(BuildContext context) {
    return Material(
      color: _ShareUi.teal,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => controller.shareViaWhatsApp(),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSw ? 'Shiriki kupitia WhatsApp' : 'Share via WhatsApp',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isSw
                          ? 'Tuma kiungo salama moja kwa moja'
                          : 'Send a secure link directly',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emailCard(BuildContext context) {
    final u = _ShareUi(context);
    final bg = u.dark ? context.tokens.elevatedSurface : const Color(0xFFF0EFEB);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => controller.sendViaEmail(),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: u.dark ? const Color(0xFF48484A) : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.mail_outline_rounded, color: _ShareUi.teal, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSw ? 'Tuma kwa barua pepe' : 'Send via Email',
                      style: TextStyle(
                        color: u.dark ? const Color(0xFF80CBC4) : _ShareUi.tealDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isSw
                          ? 'Utumaji rasmi wa hati'
                          : 'Official document delivery',
                      style: TextStyle(
                        color: u.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
