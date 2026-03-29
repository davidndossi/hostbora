import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../controllers/rent_add_new_listing_controller.dart';

/// Concierge “Add New Listing” — cream background, teal primary (#005D5D).
abstract class _AddListingTheme {
  static const Color bg = Color(0xFFF9F8F6);
  static const Color teal = Color(0xFF005D5D);
  static const Color card = Colors.white;
  static const Color inputBg = Color(0xFFF1F1F1);
  static const Color label = Color(0xFF3D3D3D);
  static const Color body = Color(0xFF5C5C5C);
  static const Color charcoal = Color(0xFF1A1A1A);
  static const String serif = 'Georgia';
}

class RentAddNewListingView extends BaseView<RentAddNewListingController> {
  RentAddNewListingView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => _AddListingTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => AppBar(
        backgroundColor: _AddListingTheme.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 48,
        leading: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.menu, color: _AddListingTheme.charcoal, size: 26),
        ),
        centerTitle: true,
        title: const Text(
          'The Concierge',
          style: TextStyle(
            fontFamily: _AddListingTheme.serif,
            fontWeight: FontWeight.w700,
            fontSize: 19,
            color: _AddListingTheme.teal,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFFE5E3DD),
              child: Icon(Icons.person, size: 18, color: Color(0xFF2F2F2F)),
            ),
          ),
        ],
      );

  @override
  Widget body(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURATING EXCELLENCE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w600,
                    color: _AddListingTheme.body,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Add New Listing',
                  style: TextStyle(
                    fontFamily: _AddListingTheme.serif,
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                    height: 1.12,
                    color: _AddListingTheme.charcoal,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Expand your portfolio by detailing your new premium space. We\'ve simplified the onboarding to let you focus on what matters: the guest experience.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: _AddListingTheme.body,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3A3A3A),
                          backgroundColor: const Color(0xFFECEBE8),
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: _AddListingTheme.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Property', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _whiteCard(
                  children: [
                    _fieldLabel('PROPERTY LOCATION'),
                    _inputRow(
                      icon: Icons.location_on_outlined,
                      child: const Text(
                        'Enter full street address or district',
                        style: TextStyle(fontSize: 14, color: Color(0xFF7A7A7A)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel('PROPERTY TYPE'),
                    Obx(() => _dropdownTile(controller.propertyType.value)),
                    const SizedBox(height: 16),
                    _fieldLabel('APARTMENT/SUITE NUMBER'),
                    _plainInput(hint: 'e.g. 4B or Penthouse 1'),
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Color(0xFFEDEDED)),
                    const SizedBox(height: 18),
                    _fieldLabel('RENT AMOUNT'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: _AddListingTheme.inputBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Text('\$', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A))),
                                SizedBox(width: 6),
                                Text('0.00', style: TextStyle(fontSize: 16, color: Color(0xFF7A7A7A))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Obx(() => _dropdownTile(controller.rentFrequency.value, compact: true)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel('MINIMUM RENTAL DURATION'),
                    Obx(() => _dropdownTile(controller.minRentalDuration.value)),
                  ],
                ),
                const SizedBox(height: 16),
                _whiteCard(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              'images/luxury_room_view.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: const Color(0xFF1C1C1C),
                                alignment: Alignment.center,
                                child: Icon(Icons.photo_library_outlined, color: Colors.white.withValues(alpha: 0.4), size: 48),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.15),
                                    Colors.black.withValues(alpha: 0.55),
                                  ],
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'VISUAL IDENTITY',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Curated Spaces',
                                    style: TextStyle(
                                      fontFamily: _AddListingTheme.serif,
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Upload professional photography to increase your booking rate by up to 40%. Highlight natural light and unique architectural details.',
                      style: TextStyle(fontSize: 13, height: 1.4, color: _AddListingTheme.body),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _AddListingTheme.teal,
                          side: const BorderSide(color: _AddListingTheme.teal, width: 1.4),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('ADD GALLERY', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _AddListingTheme.teal,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.lightbulb_outline, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MARKET INSIGHTS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                letterSpacing: 1.6,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Long-term contracts in this district rent for 12% higher on average. Consider highlighting lease flexibility in your description.',
                              style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        _listingBottomNav(),
      ],
    );
  }

  Widget _whiteCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _AddListingTheme.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: _AddListingTheme.label,
        ),
      ),
    );
  }

  Widget _inputRow({required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _AddListingTheme.inputBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6B6B6B)),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _plainInput({required String hint}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _AddListingTheme.inputBg,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerLeft,
      child: Text(hint, style: const TextStyle(fontSize: 14, color: Color(0xFF7A7A7A))),
    );
  }

  Widget _dropdownTile(String value, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 12 : 14),
      decoration: BoxDecoration(
        color: _AddListingTheme.inputBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2E2E2E)),
            ),
          ),
          const Icon(Icons.expand_more, color: Color(0xFF3D3D3D)),
        ],
      ),
    );
  }

  Widget _listingBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8E6E1))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(icon: Icons.apartment_rounded, label: 'Properties', selected: true),
            _navItem(icon: Icons.calendar_month_outlined, label: 'Bookings', selected: false),
            _navItem(icon: Icons.chat_bubble_outline_outlined, label: 'Inbox', selected: false),
            _navItem(icon: Icons.bar_chart_rounded, label: 'Insights', selected: false),
          ],
        ),
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required bool selected}) {
    final c = selected ? Colors.white : const Color(0xFF7A7A7A);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _AddListingTheme.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: c),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.2, color: c),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
