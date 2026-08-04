import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widget/base_currency_picker.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingView extends BaseView<OnboardingController> {
  OnboardingView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => null;

  @override
  Color pageBackgroundColor(BuildContext context) => const Color(0xFF0A1628);

  @override
  Widget body(BuildContext context) {
    final isSw = Get.locale?.languageCode == 'sw';
    final size = MediaQuery.sizeOf(context);

    return Stack(
      children: [
        // ── decorative background blobs ──────────────────────────────────
        Positioned(
          top: -60,
          right: -60,
          child: _Blob(size: 260, color: AppColors.colorPrimary.withValues(alpha: 0.18)),
        ),
        Positioned(
          top: size.height * 0.28,
          left: -80,
          child: _Blob(size: 200, color: const Color(0xFF1E88E5).withValues(alpha: 0.12)),
        ),
        Positioned(
          bottom: 160,
          right: -40,
          child: _Blob(size: 180, color: AppColors.colorPrimary.withValues(alpha: 0.10)),
        ),

        // ── main content ─────────────────────────────────────────────────
        // Fill the viewport: content on top, CTA at the bottom when space
        // allows. Scroll only on overflow — no empty band above the footer.
        LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: size.height < 700 ? 20 : 40),

                          // ── logo badge ────────────────────────────────
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                              border: Border.all(
                                color: AppColors.colorPrimary
                                    .withValues(alpha: 0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.colorPrimary
                                      .withValues(alpha: 0.35),
                                  blurRadius: 32,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'images/host_bora_logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.home_work_rounded,
                                  size: 48,
                                  color: AppColors.colorPrimary,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── headline ──────────────────────────────────
                          Text(
                            isSw ? 'Karibu HostBora' : 'Welcome to HostBora',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ── sub-headline ──────────────────────────────
                          Text(
                            isSw
                                ? 'Simamia BnB na upangishaji wa muda mrefu kutoka mahali pamoja'
                                : 'Manage BnB stays & long-term rentals\nfrom one powerful app',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.7),
                              height: 1.55,
                            ),
                          ),

                          SizedBox(height: size.height < 700 ? 24 : 40),

                          // ── feature cards ─────────────────────────────
                          _FeatureRow(
                            icon: Icons.payments_rounded,
                            color: const Color(0xFF4CAF50),
                            title: isSw ? 'Fuatilia Malipo' : 'Track Payments',
                            subtitle: isSw
                                ? 'Malipo ya kodi, bili na michango'
                                : 'Rent, bills & tenant contributions',
                          ),
                          const SizedBox(height: 12),
                          _FeatureRow(
                            icon: Icons.hotel_rounded,
                            color: const Color(0xFF42A5F5),
                            title: isSw ? 'BnB & Upangishaji' : 'BnB & Rentals',
                            subtitle: isSw
                                ? 'Wageni wa muda mfupi na mpangaji wa muda mrefu'
                                : 'Short-term guests & long-term tenants',
                          ),
                          const SizedBox(height: 12),
                          _FeatureRow(
                            icon: Icons.message_rounded,
                            color: const Color(0xFF26C6DA),
                            title: isSw ? 'WhatsApp & SMS' : 'WhatsApp & SMS',
                            subtitle: isSw
                                ? 'Tuma ukumbusho wa kodi kiotomatiki'
                                : 'Auto-send rent reminders to tenants',
                          ),
                          const SizedBox(height: 12),
                          _FeatureRow(
                            icon: Icons.cloud_off_rounded,
                            color: const Color(0xFFFFA726),
                            title: isSw
                                ? 'Hifadhi Nje ya Mtandao'
                                : 'Offline Storage',
                            subtitle: isSw
                                ? 'Data salama hata bila intaneti'
                                : 'Secure data even without internet',
                          ),

                          const SizedBox(height: 28),

                          // ── base currency (static list, no network)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: BaseCurrencyPicker(
                              forDarkBackground: true,
                              title: isSw
                                  ? 'Sarafu yako ya msingi'
                                  : 'Your base currency',
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    // ── bottom CTA (viewport-bottom when content fits)
                    _BottomCta(isSw: isSw),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── Feature row ──────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.55),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom CTA panel ─────────────────────────────────────────────────────────

class _BottomCta extends StatelessWidget {
  const _BottomCta({required this.isSw});

  final bool isSw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary CTA
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5A4), Color(0xFF0D8F8E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.colorPrimary.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () =>
                      Get.find<OnboardingController>().completeOnboarding(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isSw ? 'Anza Sasa' : 'Get Started',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Already have account link
          GestureDetector(
            onTap: () => Get.find<OnboardingController>().goToLogin(),
            child: Text(
              isSw ? 'Nina akaunti tayari' : 'Already have an account?',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.5),
                decoration: TextDecoration.underline,
                decorationColor: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Decorative blob ──────────────────────────────────────────────────────────

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _BlobPainter(color: color),
    );
  }
}

class _BlobPainter extends CustomPainter {
  const _BlobPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final r = size.width / 2;
    final path = Path();
    final pts = <Offset>[];
    const n = 8;
    for (var i = 0; i < n; i++) {
      final angle = (i / n) * 2 * math.pi;
      final rand = 0.75 + 0.25 * math.sin(i * 2.3);
      pts.add(Offset(
        r + r * rand * math.cos(angle),
        r + r * rand * math.sin(angle),
      ));
    }
    path.moveTo(pts[0].dx, pts[0].dy);
    for (var i = 0; i < n; i++) {
      final next = pts[(i + 1) % n];
      final ctrl = pts[i];
      path.quadraticBezierTo(ctrl.dx, ctrl.dy, next.dx, next.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.color != color;
}
