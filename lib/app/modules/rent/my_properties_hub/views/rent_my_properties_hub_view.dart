import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/widget/custom_app_bar.dart';
import '../../../../routes/app_pages.dart';
import '../controllers/rent_my_properties_hub_controller.dart';

/// Concierge management hub — property cards with quick actions, or empty add state.
abstract class _HubTheme {
  static const Color bg = Color(0xFFF9F8F4);
  static const Color card = Colors.white;
  static const Color teal = Color(0xFF004D4D);
  static const Color hubRed = Color(0xFFB42318);
  static const Color muted = Color(0xFF6B7280);
  static const Color actionBg = Color(0xFFF5F5F3);
  static const Color navy = Color(0xFF1A1A1A);
  static const String serif = 'Georgia';
}

class RentMyPropertiesHubView extends BaseView<RentMyPropertiesHubController> {
  RentMyPropertiesHubView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => CustomAppBar(
    appBarTitleText: 'My Properties'
  );

  @override
  Widget body(BuildContext context) {
    return Obx(() {
      if (controller.loading.value) {
        return const Center(child: CircularProgressIndicator(color: _HubTheme.teal));
      }
      if (controller.properties.isEmpty) {
        return _emptyState();
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _hubHeader(),
            const SizedBox(height: 16),
            _newPropertyButton(),
            const SizedBox(height: 22),
            ...controller.properties.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _ManagementPropertyCard(
                  row: p,
                  onAddIncome: () => Get.toNamed(Routes.RENT_ADD_INCOME_FORM),
                  onAddExpense: () => Get.toNamed(Routes.RENT_ADD_NEW_EXPENSE),
                  onNewTenant: () => Get.toNamed(Routes.RENT_ADD_TENANT_FORM),
                  onAnalytics: () => Get.toNamed(Routes.RENT_LISTING_ANALYTICS_DASHBOARD),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: controller.addProperty,
              icon: const Icon(Icons.add_circle_outline, size: 72, color: Colors.grey),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: controller.addProperty,
                child: const Text(
                  'Add property',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hubHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MANAGEMENT HUB',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: _HubTheme.hubRed.withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Curated Estates & Asset Intelligence.',
          style: TextStyle(
            fontFamily: _HubTheme.serif,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1.15,
            color: Color(0xFF0D3D2E),
          ),
        ),
      ],
    );
  }

  Widget _newPropertyButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: controller.addProperty,
        style: FilledButton.styleFrom(
          backgroundColor: _HubTheme.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.add, size: 22),
        label: const Text(
          'New Property',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}

class _ManagementPropertyCard extends StatelessWidget {
  const _ManagementPropertyCard({
    required this.row,
    required this.onAddIncome,
    required this.onAddExpense,
    required this.onNewTenant,
    required this.onAnalytics,
  });

  final RentHubPropertyRow row;
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;
  final VoidCallback onNewTenant;
  final VoidCallback onAnalytics;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _HubTheme.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _imageBlock(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  style: const TextStyle(
                    fontFamily: _HubTheme.serif,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _HubTheme.navy,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 18, color: _HubTheme.muted.withValues(alpha: 0.9)),
                    const SizedBox(width: 6),
                    Text(
                      '${row.activeTenants} Active Tenants',
                      style: TextStyle(
                        fontSize: 13,
                        color: _HubTheme.muted.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'QUICK ACTIONS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: _HubTheme.muted.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 10),
                _quickGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageBlock() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: row.imageUrl.isNotEmpty
              ? Image.network(
                  row.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _fallbackImage(),
                )
              : _fallbackImage(),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              row.propertyTypeLabel.replaceAll('_', ' '),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: _HubTheme.muted.withValues(alpha: 0.95),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallbackImage() {
    return Image.asset(
      'images/luxury_room_view.png',
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        height: 180,
        color: _HubTheme.actionBg,
        child: const Icon(Icons.home_work_outlined, size: 48, color: _HubTheme.muted),
      ),
    );
  }

  Widget _quickGrid() {
    Widget cell(String label, IconData icon, Color iconColor, VoidCallback onTap) {
      return Material(
        color: _HubTheme.actionBg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _HubTheme.navy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cell('Add Income', Icons.add_circle_outline, _HubTheme.teal, onAddIncome)),
            const SizedBox(width: 10),
            Expanded(child: cell('Add Expense', Icons.remove_circle_outline, const Color(0xFF9B1C1C), onAddExpense)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: cell('New Tenant', Icons.person_add_alt_1_outlined, _HubTheme.muted, onNewTenant)),
            const SizedBox(width: 10),
            Expanded(child: cell('Analytics', Icons.bar_chart_rounded, _HubTheme.muted, onAnalytics)),
          ],
        ),
      ],
    );
  }
}
