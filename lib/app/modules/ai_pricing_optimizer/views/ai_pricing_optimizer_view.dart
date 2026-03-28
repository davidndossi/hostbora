import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../controllers/ai_pricing_optimizer_controller.dart';

class AiPricingOptimizerView extends BaseView<AiPricingOptimizerController> {
  AiPricingOptimizerView({super.key});

  static const _teal = Color(0xFF0D6D6D);
  static const _softTeal = Color(0x190D6D6D);
  static const _muted = Color(0xFF6B7280);

  @override
  PreferredSizeWidget? appBar(BuildContext context) => null;

  @override
  Widget body(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _circleIcon(Icons.arrow_back_ios_new_rounded, onTap: Get.back),
            _recommendationCard(),
            const SizedBox(height: 14),
            _autoApplyCard(),
            const SizedBox(height: 18),
            Text(
              'Pricing Forecast',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _forecastCard(Icon(Icons.event_note_outlined, color: const Color(0xFFEA580C)), const Color(0xFFFFEDD5), 'WEEKEND', 'Tsh 150k', '+25% Increase', true)),
                const SizedBox(width: 10),
                Expanded(child: _forecastCard(Icon(Icons.ac_unit_outlined, color: const Color(0xFF2563EB)), const Color(0xFFDBEAFE),'LOW SEASON', 'Tsh 90k', '-25% Decrease', false)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x0C0D6D6D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x190D6D6D)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: const Color(0xFF0D6D6D), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AI predicts a 15% surge in booking probability if you maintain this price for the next 48 hours.',
                      style: TextStyle(
                        color: const Color(0xFF0D6D6D),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleIcon(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20, color: Colors.black),
        ),
      ),
    );
  }

  Widget _recommendationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Current Recommendation',
                style: TextStyle(fontSize: 14, color: _muted, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _softTeal,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC7DDD8)),
                ),
                child: const Text(
                  '✧ AI OPTIMIZED',
                  style: TextStyle(fontSize: 10, color: _teal, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Tsh 120,000',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
          ),
          Text(
            'Based on high local demand & seasonal trends',
            style: TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Image.asset('images/luxury_room_view.png', height: 192, width: double.infinity, fit: BoxFit.cover),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.50)],
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 14,
                  bottom: 12,
                  child: Text(
                    'Property: Ocean View Penthouse',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _autoApplyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _softTeal,
              borderRadius: BorderRadius.circular(21),
            ),
            child: const Icon(Icons.bolt, color: _teal),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enable Auto-Apply', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('Let AI update your rates instantly', style: TextStyle(fontSize: 12, color: _muted)),
              ],
            ),
          ),
          Obx(
            () => Switch(
              value: controller.autoApplyEnabled.value,
              onChanged: controller.setAutoApply,
              activeTrackColor: _teal,
              activeColor: Colors.white,
              inactiveTrackColor: const Color(0xFFDCE3EA),
              inactiveThumbColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _forecastCard(Icon icon, Color iconBg, String label, String value, String delta, bool up) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon(emoji, style: const TextStyle(fontSize: 20)),
          CircleAvatar(
            radius: 16,
            backgroundColor: iconBg,
            child: icon,
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            delta,
            style: TextStyle(fontSize: 10, color: up ? const Color(0xFF0D8F62) : const Color(0xFFC07038), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
