import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:paa_yangu/app/core/values/app_values.dart';
import 'package:paa_yangu/app/core/widget/custom_app_bar.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/values/app_colors.dart';
import '../controllers/rent_listing_details_controller.dart';

class _ListingUi {
  _ListingUi(this.context);

  final BuildContext context;
  ThemeData get _t => Theme.of(context);
  bool get dark => _t.brightness == Brightness.dark;

  static const Color forest = Color(0xFF0A5C5C);
  static const Color cream = Color(0xFFFBFAF6);

  Color get bg => dark ? _t.scaffoldBackgroundColor : cream;
  Color get card => dark ? const Color(0xFF2C2C2E) : Colors.white;
  Color get soft => dark ? const Color(0xFF3A3A3C) : const Color(0xFFF4F1EA);
  Color get line => dark ? const Color(0xFF4A4A4C) : const Color(0xFFE6E1D7);
  Color get text => dark ? const Color(0xFFF2F2F7) : const Color(0xFF111827);
  Color get muted => dark ? const Color(0xFFAEAEB2) : const Color(0xFF6B7280);
}

class RentListingDetailsView extends BaseView<RentListingDetailsController> {
  RentListingDetailsView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) => CustomAppBar(
    appBarTitleText: controller.listingTitle.value.isEmpty
        ? (_isSw ? 'Maelezo ya Mali' : 'Listing Details')
        : controller.listingTitle.value,
    isCentered: true,
  );

  @override
  Widget body(BuildContext context) {
    final u = _ListingUi(context);
    return Obx(() {
      if (controller.loadingListing.value) {
        return const Center(
          child: CircularProgressIndicator(color: _ListingUi.forest),
        );
      }
      return RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            controller.loadListingDetail(),
            controller.loadRealDataSnapshot(),
          ]);
        },
        child: ListView(
          controller: controller.listingScrollController,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
          children: [
            const SizedBox(height: 14),
            _hero(u),
            const SizedBox(height: 12),
            _kpiMinimal(
              u,
              label: _isSw ? 'UKAAJI WA SASA' : 'CURRENT OCCUPANCY',
              value: '${controller.occupancyPercent.value.clamp(0, 100)}',
              suffix: '%',
              progress: controller.occupancyPercent.value.clamp(0, 100) / 100,
            ),
            const SizedBox(height: 10),
            _kpiMinimal(
              u,
              label: _isSw ? 'MAPATO YA MWEZI' : 'MONTHLY REVENUE',
              value: controller.monthlyRevenueLabel.value,
              prefix: 'TZS',
              progress: controller.monthlyRevenueProgress.value,
            ),
            const SizedBox(height: 14),
            _quickManagement(u),
            const SizedBox(height: 14),
            _units(u),
            const SizedBox(height: 12),
            _activity(u),
            const SizedBox(height: 12),
            _staff(u),
            const SizedBox(height: 12),
            _warning(u),
          ],
        ),
      );
    });
  }

  Widget _hero(_ListingUi u) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 158,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'images/bedroom.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: u.soft,
                child: Icon(Icons.apartment_rounded, color: u.muted, size: 36),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.66),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    controller.heroOverlayTitle.value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      height: 0.95,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 24,
                    child: OutlinedButton(
                      onPressed: controller.onEditListing,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.16),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _isSw ? 'Hariri listing' : 'Edit Listing',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
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

  Widget _kpiMinimal(
      _ListingUi u, {
        required String label,
        required String value,
        String prefix = '',
        String suffix = '',
        double? progress,
      }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: u.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: u.muted,
            ),
          ),
          const SizedBox(height: 3),
          if (prefix.isNotEmpty)
            Text(
              prefix,
              style: TextStyle(fontSize: 12, color: u.muted, fontWeight: FontWeight.w700),
            ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: u.text,
                  ),
                ),
                if (suffix.isNotEmpty)
                  TextSpan(
                    text: suffix,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: u.text,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 2,
            color: u.line,
            child: progress == null
                ? null
                : FractionallySizedBox(
              widthFactor: progress.clamp(0, 1),
              alignment: Alignment.centerLeft,
              child: const ColoredBox(color: AppColors.colorPrimaryDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickManagement(_ListingUi u) {
    final items = <(IconData, String, int)>[
      (Icons.person_add_alt_1_outlined, _isSw ? 'ADD TENANT' : 'ADD TENANT', 0),
      (Icons.payments_outlined, _isSw ? 'ADD INCOME' : 'ADD INCOME', 1),
      (Icons.receipt_long_outlined, _isSw ? 'ADD EXPENSE' : 'ADD EXPENSE', 2),
      (Icons.calendar_today_outlined, _isSw ? 'SCHEDULE\nMAINTENANCE' : 'SCHEDULE\nMAINTENANCE', 3),
      (Icons.lock_open, _isSw ? 'UNIT LOCK\nCONTROL' : 'UNIT LOCK\nCONTROL', 4),
      (Icons.bolt_outlined, _isSw ? 'UTILITY\nDASHBOARD' : 'UTILITY\nDASHBOARD', 5),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _isSw ? 'Quick Management' : 'Quick Management',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: u.text,
                ),
              ),
            ),
            Text(
              _isSw ? '6 ACTIVE\nMODULES' : '6 ACTIVE\nMODULES',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w700,
                letterSpacing: .8,
                color: u.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.95,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, i) {
            final item = items[i];
            return InkWell(
              onTap: () => controller.onQuickAction(item.$3),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: u.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.$1, size: 24, color: AppColors.colorPrimary),
                    const SizedBox(height: 6),
                    Text(
                      item.$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .45,
                        color: u.text,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _units(_ListingUi u) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _isSw ? 'Property Units' : 'Property Units',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: u.text,
                ),
              ),
            ),
            TextButton(
              onPressed: controller.onAddNewUnit,
              child: Text(
                _isSw ? 'ADD NEW UNIT' : 'ADD NEW UNIT',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Obx(() {
          final rows = controller.unitRows;
          if (rows.isEmpty) {
            return Text(
              _isSw ? 'Hakuna units.' : 'No units listed.',
              style: TextStyle(fontSize: 12, color: u.muted),
            );
          }
          return Column(
            children: rows
                .map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _unitCard(u, r),
            ))
                .toList(),
          );
        }),
      ],
    );
  }

  Widget _unitCard(_ListingUi u, ListingUnitRowVm row) {
    final due = row.status == ListingUnitStatus.dueDate;
    final occupied = row.status == ListingUnitStatus.occupied;

    final badgeBg = due
        ? const Color(0xFFFEEAEA)
        : occupied
        ? const Color(0xFFEAF6EC)
        : const Color(0xFFF2F2F2);
    final badgeFg = due
        ? const Color(0xFFB42318)
        : occupied
        ? const Color(0xFF1B6B3A)
        : const Color(0xFF6B7280);
    final badgeText = due ? 'DUE DATE' : occupied ? 'OCCUPIED' : 'SHORT';

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: u.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.name,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: u.text),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(fontSize: 12, letterSpacing: .45, fontWeight: FontWeight.w800, color: badgeFg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(row.subtitle, style: TextStyle(fontSize: 14, color: u.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () => controller.onUnitPrimaryAction(row),
              style: FilledButton.styleFrom(
                backgroundColor: due
                    ? const Color(0xFFFFF3F2)
                    : occupied
                    ? AppColors.colorPrimary
                    : u.soft,
                foregroundColor: due
                    ? const Color(0xFFB42318)
                    : occupied
                    ? Colors.white
                    : AppColors.colorPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                controller.primaryButtonLabel(row, _isSw),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activity(_ListingUi u) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _isSw ? 'Recent Activity' : 'Recent Activity',
                style: TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w700, color: u.text),
              ),
            ),
            TextButton(
              onPressed: controller.onViewAllLog,
              child: const Text(
                'VIEW ALL LOG',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        Obx(() {
          final rows = controller.recentActivity;
          if (rows.isEmpty) {
            return Text('No recent activity', style: TextStyle(fontSize: 14, color: u.muted));
          }
          return Column(
            children: rows
                .take(3)
                .map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: a.accentColor.withValues(alpha: .2),
                    child: Icon(Icons.circle, size: 8, color: a.accentColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: u.text)),
                        Text(a.subtitle, style: TextStyle(fontSize: 13, color: u.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(a.trailing, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: u.text)),
                      Text(a.timeLabel, style: TextStyle(fontSize: 12, color: u.muted)),
                    ],
                  ),
                ],
              ),
            ))
                .toList(),
          );
        }),
      ],
    );
  }

  Widget _staff(_ListingUi u) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _isSw ? 'Staff Assigned' : 'Staff Assigned',
                style: TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w700, color: u.text),
              ),
            ),
            TextButton(
              onPressed: controller.onManageStaff,
              child: const Text('ALL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        Obx(() {
          final staff = controller.staffPreview;
          if (staff.isEmpty) return Text('No staff', style: TextStyle(fontSize: 14, color: u.muted));
          return Column(
            children: staff
                .take(2)
                .map((s) => ListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: -3),
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 11,
                backgroundColor: u.soft,
                child: Text(
                  s.name.isEmpty ? '?' : s.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ListingUi.forest),
                ),
              ),
              title: Text(s.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: u.text)),
              subtitle: Text(
                s.jobTitle.isEmpty ? 'Staff' : s.jobTitle,
                style: TextStyle(fontSize: 12, color: u.muted),
              ),
            ))
                .toList(),
          );
        }),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: controller.onManageStaff,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.colorPrimary,
              side: BorderSide(color: AppColors.colorPrimaryDark.withValues(alpha: .55)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: EdgeInsets.all(AppValues.padding),
            ),
            child: Text(
              _isSw ? 'MANAGE STAFF' : 'MANAGE STAFF',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _warning(_ListingUi u) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5EB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF2D7B8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _isSw
                  ? 'Kumbukumbu za malipo zinahitaji ufuatiliaji wa karibu.'
                  : 'Payment records in this listing need close follow-up.',
              style: const TextStyle(fontSize: 13, height: 1.25, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }
}
