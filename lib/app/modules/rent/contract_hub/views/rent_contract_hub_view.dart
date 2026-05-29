import 'package:flutter/material.dart';
import 'package:paa_yangu/app/core/widget/skeleton_presets.dart';

import 'package:paa_yangu/app/core/theme/app_theme_tokens.dart';

import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_contract_hub_controller.dart';

class _HubUi {
  _HubUi(this.context);

  final BuildContext context;
  ThemeData get _t => Theme.of(context);
  bool get dark => _t.brightness == Brightness.dark;

  Color get canvas =>
      dark ? _t.scaffoldBackgroundColor : const Color(0xFFF9F8F4);

  Color get card => dark ? _t.cardColor : Colors.white;

  Color get onSurface =>
      dark ? const Color(0xFFF2F2F7) : const Color(0xFF111827);

  Color get muted =>
      dark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280);

  static const Color forest = Color(0xFF004D40);
  static const Color lightTeal = Color(0xFF149C95);
  static const Color urgentRed = Color(0xFFB71C1C);
  static const Color renewUrgentBg = Color(0xFF6D2E2E);
  static const Color peachCard = Color(0xFFFFF3ED);
  static const Color badgeRose = Color(0xFFFFCDD2);

  Color get forestAccent => dark ? lightTeal : forest;

  List<BoxShadow> cardShadow(bool strong) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.35 : (strong ? 0.08 : 0.05)),
          blurRadius: strong ? 14 : 10,
          offset: const Offset(0, 4),
        ),
      ];
}

/// Contract Hub — Evergreen / Concierge layout (cream, teal hero, contract cards).
class RentContractHubView extends RentBaseView<RentContractHubController> {
  RentContractHubView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  Color pageBackgroundColor(BuildContext context) => _HubUi(context).canvas;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar(
    _isSw ? 'Mikataba' : 'Contracts',
  );

  @override
  Widget body(BuildContext context) {
    final u = _HubUi(context);
    return RefreshIndicator(
      color: _HubUi.forest,
      onRefresh: controller.onRefresh,
      child: Obx(() {
        if (controller.loading.value) {
          return const DefaultScreenSkeleton();
        }
        controller.searchQuery.value;
        controller.filterExpiringSoon.value;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Text(
              _isSw ? 'Kitovu cha Mikataba' : 'Contract Hub',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                height: 1.1,
                color: u.forestAccent,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _isSw
                  ? 'Simamia na panga makubaliano ya wapangaji kwa uwazi na urahisi.'
                  : 'Manage and curate your tenant agreements with botanical precision and effortless clarity.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: u.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            _searchField(context),
            const SizedBox(height: 12),
            _filtersButton(context),
            const SizedBox(height: 22),
            _uploadCtaCard(context),
            const SizedBox(height: 26),
            _activeContractsHeader(context),
            const SizedBox(height: 14),
            ..._buildContractCards(context),
          ],
        );
      }),
    );
  }

  Widget _searchField(BuildContext context) {
    final u = _HubUi(context);
    final fill = u.dark ? context.tokens.elevatedSurface : const Color(0xFFEFEEE9);
    return TextField(
      controller: controller.searchController,
      onChanged: controller.setSearch,
      style: TextStyle(color: u.onSurface, fontSize: 15),
      decoration: InputDecoration(
        hintText: _isSw
            ? 'Tafuta wapangaji au mali…'
            : 'Search tenants or properties…',
        hintStyle: TextStyle(color: u.muted, fontSize: 15),
        prefixIcon: Icon(Icons.search_rounded, color: u.muted),
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }

  Widget _filtersButton(BuildContext context) {
    final u = _HubUi(context);
    return Material(
      color: u.card,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: u.cardShadow(false),
          border: u.dark
              ? Border.all(color: context.tokens.elevatedSurface)
              : null,
        ),
        child: InkWell(
          onTap: controller.openFiltersSheet,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.tune_rounded, size: 22, color: u.forestAccent),
                const SizedBox(width: 10),
                Text(
                  _isSw ? 'Vichujio' : 'Filters',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: u.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _uploadCtaCard(BuildContext context) {
    final u = _HubUi(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _HubUi.forest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: u.cardShadow(true),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_upload_outlined, color: Colors.white.withValues(alpha: 0.95), size: 36),
          const SizedBox(height: 14),
          Text(
            _isSw ? 'Hifadhi Mkataba Mpya' : 'Archive a New Agreement',
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _isSw
                ? 'Pakia haraka na uhifadhi mikataba iliyosainiwa katika vault salama.'
                : 'Swiftly digitize and store signed lease documents into our secure vault.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: controller.onUploadSignedLease,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _HubUi.forest,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _isSw ? 'PAKIA MKATABA ULIOSAINIWA' : 'UPLOAD SIGNED LEASE',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeContractsHeader(BuildContext context) {
    final u = _HubUi(context);
    final n = controller.filteredContracts.length;
    return Row(
      children: [
        Expanded(
          child: Text(
            _isSw ? 'MIKATABA HAI' : 'ACTIVE CONTRACTS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: u.muted,
            ),
          ),
        ),
        Text(
          _isSw ? '$n hati jumla' : '$n Documents Total',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: u.muted,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildContractCards(BuildContext context) {
    final list = controller.filteredContracts;
    if (list.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text(
              _isSw
                  ? 'Hakuna mikataba inayolingana. Badilisha utafutaji au vichujio.'
                  : 'No matching contracts. Adjust search or filters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _HubUi(context).muted, fontSize: 14),
            ),
          ),
        ),
      ];
    }
    return list
        .map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _contractCard(context, c),
          ),
        )
        .toList();
  }

  Widget _contractCard(BuildContext context, ContractCardVm c) {
    final u = _HubUi(context);
    final urgent = c.isUrgent || c.isExpiredOrDue;
    final cardBg = urgent
        ? (u.dark ? const Color(0xFF3D2A28) : _HubUi.peachCard)
        : u.card;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: u.cardShadow(false),
        border: u.dark
            ? Border.all(
                color: urgent
                    ? _HubUi.urgentRed.withValues(alpha: 0.35)
                    : context.tokens.elevatedSurface,
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'images/luxury_room_view.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 72,
                      height: 72,
                      color: RentTheme.sectionMist,
                      child: Icon(Icons.home_work_outlined, color: u.muted),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              c.propertyLineCaps,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: u.forestAccent,
                              ),
                            ),
                          ),
                          if (c.showDaysLeftBadge && !urgent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: u.dark
                                    ? _HubUi.badgeRose.withValues(alpha: 0.25)
                                    : _HubUi.badgeRose,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _isSw
                                    ? 'SIKU ${c.daysUntilExpiry}'
                                    : '${c.daysUntilExpiry} DAYS LEFT',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: u.dark ? const Color(0xFFFFAB91) : _HubUi.urgentRed,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c.tenantName,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: u.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            urgent ? Icons.warning_amber_rounded : Icons.calendar_today_outlined,
                            size: 15,
                            color: urgent ? _HubUi.urgentRed : u.muted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              c.isExpiredOrDue
                                  ? (_isSw
                                      ? 'Imeisha ${controller.formatExpiry(c, isSw: _isSw)}'
                                      : 'Expired ${controller.formatExpiry(c, isSw: _isSw)}')
                                  : (_isSw
                                      ? (urgent
                                          ? 'Inaisha kwa siku ${c.daysUntilExpiry}'
                                          : 'Inaisha ${controller.formatExpiry(c, isSw: _isSw)}')
                                      : (urgent
                                          ? 'Expires in ${c.daysUntilExpiry} days'
                                          : 'Expires ${controller.formatExpiry(c, isSw: _isSw)}')),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: urgent ? _HubUi.urgentRed : u.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                IconButton(
                  onPressed: () => controller.onViewContract(c),
                  icon: Icon(Icons.visibility_outlined, color: u.forestAccent),
                  tooltip: _isSw ? 'Angalia' : 'View',
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: urgent
                      ? FilledButton(
                          onPressed: () => controller.onRenewLease(c),
                          style: FilledButton.styleFrom(
                            backgroundColor: _HubUi.renewUrgentBg,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _isSw ? 'FANYA UHUISHAJI' : 'RENEW LEASE',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                      : OutlinedButton(
                          onPressed: () => controller.onRenewLease(c),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: u.forestAccent,
                            side: BorderSide(color: u.forestAccent.withValues(alpha: 0.45)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _isSw ? 'FANYA UHUISHAJI' : 'RENEW LEASE',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
