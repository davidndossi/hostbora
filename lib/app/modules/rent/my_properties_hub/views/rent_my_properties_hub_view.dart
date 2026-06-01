import 'package:flutter/material.dart';
import 'package:host_bora/app/core/widget/skeleton_presets.dart';

import 'package:host_bora/app/core/theme/app_theme_tokens.dart';

import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/widget/app_skeleton.dart';
import '../../../../core/widget/custom_app_bar.dart';
import '../../../../routes/app_pages.dart';
import '../../../../core/widget/property_listing_image.dart';
import '../controllers/rent_my_properties_hub_controller.dart';

class RentMyPropertiesHubView extends RentBaseView<RentMyPropertiesHubController> {
  RentMyPropertiesHubView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) => CustomAppBar(
    appBarTitleText: _isSw ? 'Mijengo Yangu' : 'My Properties'
  );

  @override
  Widget body(BuildContext context) {
    return Obx(() {
      if (controller.loading.value) {
        final tokens = context.tokens;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            for (var i = 0; i < 4; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                height: 220,
                decoration: BoxDecoration(
                  color: tokens.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: AppSkeleton(width: 160, height: 18, borderRadius: 6),
                ),
              ),
          ],
        );
      }
      if (controller.properties.isEmpty) {
        return _emptyState();
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSw ? 'Kitovu cha usimamizi' : 'Management hub',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                // color: _HubTheme.hubRed.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 16),
            _newPropertyButton(),
            const SizedBox(height: 22),
            ...controller.properties.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _ManagementPropertyCard(
                  row: p,
                  isSw: _isSw,
                  onEditProperty:
                      p.isLocal ? () => controller.editProperty(p.id) : null,
                  onTenantForUnit: p.unitSlots.isEmpty
                      ? null
                      : (slot) => controller.addTenantForUnit(
                            propertyHubId: p.id,
                            propertyTitle: p.title,
                            slot: slot,
                          ),
                  onOpenListing: () => Get.toNamed(
                    Routes.RENT_LISTING_DETAILS,
                    parameters: {'id': p.id, 'title': p.title},
                    arguments: {
                      'property_id': p.id,
                      'property_name': p.title,
                      'property_image': p.imageUrl,
                    },
                  ),
                  onAddEstimate: () => Get.toNamed(
                    Routes.RENT_PROPERTY_ROI_ESTIMATE_FORM,
                    parameters: {
                      'propertyRef': p.id,
                      'propertyLabel': p.title,
                    },
                  ),
                  onAddIncome: () => Get.toNamed(Routes.RENT_ADD_INCOME_FORM),
                  onAddExpense: () => Get.toNamed(Routes.RENT_ADD_NEW_EXPENSE),
                  onNewTenant: () => Get.toNamed(Routes.RENT_ADD_TENANT_FORM,
                      parameters: {'property': p.title, 'propertyRef': p.id}),
                  onAnalytics: () => Get.toNamed(Routes.RENT_LISTING_ANALYTICS_DASHBOARD),
                  onAddCoHost: () => _openAddCoHostDialog(
                    propertyRef: p.id,
                    propertyTitle: p.title,
                  ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: controller.addProperty,
              icon: const Icon(Icons.add_circle_outline, size: 72, color: Colors.grey),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 72, minHeight: 72),
              alignment: Alignment.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: controller.addProperty,
              child: Text(
                _isSw ? 'Ongeza mjengo' : 'Add property',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _newPropertyButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: controller.addProperty,
        style: FilledButton.styleFrom(
          // backgroundColor: _HubTheme.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.add, size: 22),
        label: Text(
          _isSw ? 'Mjengo Mpya' : 'New Property',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }

  void _openAddCoHostDialog({
    required String propertyRef,
    required String propertyTitle,
  }) {
    final idController = TextEditingController();
    Future<List<dynamic>> loadMembers() async {
      final rows = await controller.listCoHosts(propertyRef: propertyRef);
      return rows;
    }
    Future<List<dynamic>> membersFuture = loadMembers();
    Get.dialog(
      StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(_isSw ? 'Ongeza Mwenzangu' : 'Add Co-host'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSw
                      ? 'Weka kitambulisho cha mtumiaji wa co-host kwa "$propertyTitle".'
                      : 'Enter the co-host user ID for "$propertyTitle".',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: idController,
                  decoration: InputDecoration(
                    hintText: _isSw ? 'Mfano: user_123' : 'e.g. user_123',
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _isSw ? 'Wenzangu' : 'Current co-hosts',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: FutureBuilder<List<dynamic>>(
                    future: membersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: const DefaultScreenSkeleton(),
                        );
                      }
                      final items = snapshot.data ?? const [];
                      if (items.isEmpty) {
                        return Text(
                          _isSw ? 'Sina mwenzangu bado.' : 'No co-hosts yet.',
                          style: const TextStyle(color: Colors.grey),
                        );
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: items.map((m) {
                          final userId = (m.userId ?? '').toString();
                          final role = (m.role ?? '').toString();
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(userId),
                            subtitle: Text(role),
                            trailing: IconButton(
                              tooltip: _isSw ? 'Ondoa mwenzangu' : 'Remove co-host',
                              onPressed: () async {
                                await controller.removeCoHost(
                                  propertyRef: propertyRef,
                                  coHostUserId: userId,
                                );
                                setStateDialog(() {
                                  membersFuture = loadMembers();
                                });
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(_isSw ? 'Funga' : 'Close'),
            ),
            FilledButton(
              onPressed: () async {
                await controller.addCoHost(
                  propertyRef: propertyRef,
                  coHostUserId: idController.text,
                );
                idController.clear();
                setStateDialog(() {
                  membersFuture = loadMembers();
                });
              },
              child: Text(_isSw ? 'Ongeza' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}

void _showMultiUnitPropertySheet(
  BuildContext context, {
  required RentHubPropertyRow row,
  required bool isSw,
  required VoidCallback onOpenListing,
  required void Function(RentHubUnitSlot slot)? onTenantForUnit,
}) {
  final tokens = context.tokens;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: tokens.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final maxListHeight = MediaQuery.sizeOf(ctx).height * 0.42;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 16 + MediaQuery.of(ctx).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? tokens.border : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                row.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isSw
                    ? '${row.unitSlots.length} vitengo'
                    : '${row.unitSlots.length} units',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? tokens.textMuted : const Color(0xFF6B7280),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxListHeight),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: row.unitSlots.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final slot = row.unitSlots[i];
                    return Material(
                      color: isDark ? tokens.elevatedSurface : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    slot.unitName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${slot.tenantCount} ${isSw ? 'wapangaji' : 'tenants'}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? const Color(0xFF8E8E93)
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                Get.toNamed(
                                  Routes.RENT_LISTING_DETAILS,
                                  parameters: {
                                    'id': row.id,
                                    'title': row.title,
                                    if (slot.unitId.trim().isNotEmpty) 'unitId': slot.unitId.trim(),
                                    'unitName': slot.unitName.trim(),
                                  },
                                  arguments: {
                                    'property_id': row.id,
                                    'property_name': row.title,
                                    'property_image': row.imageUrl,
                                  },
                                );
                              },
                              child: Text(isSw ? 'Maelezo' : 'View details', style: TextStyle(fontSize: 16)),
                            ),
                            if (onTenantForUnit != null)
                              IconButton(
                                tooltip: isSw ? 'Ongeza mpangaji' : 'Add tenant',
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  onTenantForUnit(slot);
                                },
                                icon: Icon(
                                  Icons.person_add_alt_1_outlined,
                                  color: isDark
                                      ? const Color(0xFF5EC9C3)
                                      : const Color(0xFF0D9488),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onOpenListing();
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isSw ? 'Angalia maelezo ya mjengo' : 'View property details',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ManagementPropertyCard extends StatelessWidget {
  const _ManagementPropertyCard({
    required this.row,
    required this.isSw,
    this.onEditProperty,
    this.onTenantForUnit,
    required this.onOpenListing,
    required this.onAddEstimate,
    required this.onAddIncome,
    required this.onAddExpense,
    required this.onNewTenant,
    required this.onAnalytics,
    required this.onAddCoHost,
  });

  final RentHubPropertyRow row;
  final bool isSw;
  /// Local SQLite property only — opens rent add/edit form.
  final VoidCallback? onEditProperty;
  /// Per apartment unit — add tenant scoped to that unit.
  final void Function(RentHubUnitSlot slot)? onTenantForUnit;
  final VoidCallback onOpenListing;
  final VoidCallback onAddEstimate;
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;
  final VoidCallback onNewTenant;
  final VoidCallback onAnalytics;
  final VoidCallback onAddCoHost;

  bool get _hasMultipleUnits => row.unitSlots.length > 1;

  void _onCardTap(BuildContext context) {
    if (_hasMultipleUnits) {
      _showMultiUnitPropertySheet(
        context,
        row: row,
        isSw: isSw,
        onOpenListing: onOpenListing,
        onTenantForUnit: onTenantForUnit,
      );
    } else {
      onOpenListing();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: tokens.cardBackground,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: () => _onCardTap(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _imageBlock(isDark: isDark),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  style: const TextStyle(
                    // fontFamily: _HubTheme.serif,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    // color: _HubTheme.navy,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                        Icons.person_outline_rounded, size: 18,
                        // color: _HubTheme.muted.withValues(alpha: 0.9)
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${row.activeTenants} ${isSw ? 'Wapangaji' : 'Tenants'}',
                      style: TextStyle(
                        fontSize: 13,
                        // color: _HubTheme.muted.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
                // Single unit only on-card; multiple units open from card tap (bottom sheet).
                if (row.unitSlots.length == 1 && onTenantForUnit != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    isSw ? 'Kitengo' : 'Unit',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTenantForUnit!(row.unitSlots.first),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? tokens.border : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row.unitSlots.first.unitName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${row.unitSlots.first.tenantCount} ${isSw ? 'wapangaji' : 'tenants'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? tokens.textMuted
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (row.unitSlots.first.tenantCount != 1)
                            Icon(
                              Icons.person_add_alt_1_outlined,
                              size: 22,
                              color: isDark ? tokens.accent : const Color(0xFF0D9488),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_hasMultipleUnits) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        size: 16,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isSw
                              ? 'Gusa kadi kuona vitengo na maelezo'
                              : 'Tap card to see units & view details',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  isSw ? 'Vitendo vya haraka' : 'Quick actions',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    // color: _HubTheme.muted.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 10),
                _quickGrid(),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _imageBlock({required bool isDark}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: PropertyListingImage(
            imagePath: row.imageUrl,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1F2937).withValues(alpha: 0.92)
                  : Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              row.propertyTypeLabel.replaceAll('_', ' '),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: isDark ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickGrid() {
    Widget cell(String label, IconData icon, Color iconColor, VoidCallback onTap) {
      return Material(
        // color: _HubTheme.actionBg,
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
                      // color: _HubTheme.navy,
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
        if (onEditProperty != null) ...[
          Row(
            children: [
              Expanded(
                child: cell(
                  isSw ? 'Hariri mjengo' : 'Edit property',
                  Icons.edit_outlined,
                  const Color(0xFF0D9488),
                  onEditProperty!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(child: cell(isSw ? 'Ongeza Mapato' : 'Add Income', Icons.add_circle_outline, const Color(0xFF15803D), onAddIncome)),
            const SizedBox(width: 10),
            Expanded(child: cell(isSw ? 'Ongeza Gharama' : 'Add Expense', Icons.remove_circle_outline, const Color(0xFF9B1C1C), onAddExpense)),
          ],
        ),
        // const SizedBox(height: 10),
        // Row(
        //   children: [
        //     if (!_isApartmentProperty) ...[
        //       Expanded(
        //         child: cell(
        //           isSw ? 'Mpangaji Mpya' : 'New Tenant',
        //           Icons.person_add_alt_1_outlined,
        //           const Color(0xFF6B7280),
        //           onNewTenant,
        //         ),
        //       ),
        //       const SizedBox(width: 10),
        //     ],
        //     Expanded(
        //       child: cell(
        //         isSw ? 'Uchanganuzi' : 'Analytics',
        //         Icons.bar_chart_rounded,
        //         const Color(0xFF6B7280),
        //         onAnalytics,
        //       ),
        //     ),
        //   ],
        // ),
        // const SizedBox(height: 10),
        // Row(
        //   children: [
        //     Expanded(
        //       child: cell(
        //         isSw ? 'Ongeza Co-host' : 'Add Co-host',
        //         Icons.group_add_outlined,
        //         const Color(0xFF0F766E),
        //         onAddCoHost,
        //       ),
        //     ),
        //   ],
        // ),
        // const SizedBox(height: 10),
        // Row(
        //   children: [
        //     Expanded(
        //       child: cell(
        //         isSw ? 'Ongeza Makadirio ya ROI' : 'Add ROI Estimates',
        //         Icons.calculate_outlined,
        //         const Color(0xFF4C1D95),
        //         onAddEstimate,
        //       ),
        //     ),
        //   ],
        // ),
      ],
    );
  }
}
