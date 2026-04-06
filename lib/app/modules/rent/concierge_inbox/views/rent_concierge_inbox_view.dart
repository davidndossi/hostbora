import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_concierge_inbox_controller.dart';

/// Evergreen Concierge Inbox — cream bg, deep teal accents, serif headings.
abstract class _InboxPalette {
  static const Color bg = Color(0xFFF9F9F7);
  static const Color primaryTeal = Color(0xFF005F5F);
  static const Color navy = Color(0xFF1B2838);
  static const Color muted = Color(0xFF6B7280);
  static const Color border = Color(0xFFE8E6E1);
  static const Color card = Colors.white;
  static const String serif = 'Georgia';
}

class RentConciergeInboxView extends BaseView<RentConciergeInboxController> {
  RentConciergeInboxView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => _InboxPalette.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Inbox');

  @override
  Widget body(BuildContext context) {
    return Obx(() {
      if (!controller.hasNotifications) {
        return _ConciergeInboxEmptyBody(onReturn: controller.returnToDashboard);
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          const Text(
            'Evergreen Estate Management Dashboard',
            style: TextStyle(
              fontSize: 13,
              color: _InboxPalette.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: controller.markAllAsRead,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.done_all, color: _InboxPalette.primaryTeal, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Mark all as read',
                    style: TextStyle(
                      color: _InboxPalette.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'All (${controller.allCount})',
                  selected: controller.selectedFilter.value == 'all',
                  onTap: () => controller.setFilter('all'),
                ),
                _FilterChip(
                  label: 'Urgent (${controller.urgentCount})',
                  selected: controller.selectedFilter.value == 'urgent',
                  onTap: () => controller.setFilter('urgent'),
                ),
                _FilterChip(
                  label: 'Maintenance (${controller.maintenanceCount})',
                  selected: controller.selectedFilter.value == 'maintenance',
                  onTap: () => controller.setFilter('maintenance'),
                ),
                _FilterChip(
                  label: 'Unread (${controller.unreadCount})',
                  selected: controller.selectedFilter.value == 'unread',
                  onTap: () => controller.setFilter('unread'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (controller.filteredUrgentItems.isNotEmpty) ...[
            _urgentSectionHeader(criticalCount: controller.filteredUrgentItems.length),
            const SizedBox(height: 12),
            ...controller.filteredUrgentItems.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _UrgentCard(
                  item: e,
                  onAction: () => controller.onUrgentAction(e),
                ),
              ),
            ),
          ],
          if (controller.renewalItems.isNotEmpty) ...[
            _sectionTitle(icon: Icons.sync_alt_rounded, label: 'Upcoming Renewals'),
            const SizedBox(height: 12),
            ...controller.renewalItems.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RenewalCard(
                  item: e,
                  onRenew: () => controller.onRenewalAction(e),
                ),
              ),
            ),
          ],
          if (controller.filteredMaintenanceItems.isNotEmpty) ...[
            _sectionTitle(icon: Icons.build_circle_outlined, label: 'Scheduled Maintenance'),
            const SizedBox(height: 12),
            ...controller.filteredMaintenanceItems.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MaintenanceCard(
                  item: e,
                  onAction: () => controller.onMaintenanceAction(e),
                ),
              ),
            ),
          ],
          if (controller.generalItems.isNotEmpty) ...[
            _sectionTitle(icon: Icons.notifications_outlined, label: 'General Updates'),
            const SizedBox(height: 12),
            ...controller.generalItems.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _GeneralCard(
                  item: e,
                  onAction: () => controller.onGeneralAction(e),
                ),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _urgentSectionHeader({required int criticalCount}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Urgent Action',
            style: TextStyle(
              fontFamily: _InboxPalette.serif,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _InboxPalette.navy,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFBE9EA),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$criticalCount CRITICAL',
            style: const TextStyle(
              color: Color(0xFFB24148),
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle({required IconData icon, required String label}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _InboxPalette.primaryTeal),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: _InboxPalette.serif,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: _InboxPalette.navy,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty inbox: illustration, headline, CTA, Evergreen identity footer.
class _ConciergeInboxEmptyBody extends StatelessWidget {
  const _ConciergeInboxEmptyBody({required this.onReturn});

  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _emptyGraphic(),
                const SizedBox(height: 28),
                const Text(
                  'All Quiet Here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _InboxPalette.serif,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: _InboxPalette.primaryTeal,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "You're all caught up. We'll let you know when something important needs your attention.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: _InboxPalette.navy.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: onReturn,
                  style: FilledButton.styleFrom(
                    backgroundColor: _InboxPalette.primaryTeal,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.black26,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'RETURN TO DASHBOARD',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: _InboxPalette.border),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
          child: Column(
            children: [
              Text(
                'EVERGREEN ESTATE IDENTITY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.4,
                  color: _InboxPalette.muted.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 2,
                height: 14,
                decoration: BoxDecoration(
                  color: _InboxPalette.muted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyGraphic() {
    return SizedBox(
      height: 210,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 188,
            height: 188,
            decoration: const BoxDecoration(
              color: Color(0xFFEAEAE8),
              shape: BoxShape.circle,
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.notifications_off_outlined,
                    size: 46,
                    color: Color(0xFF9AA8B8),
                  ),
                ),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8D4CC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.spa_rounded,
                    size: 20,
                    color: Color(0xFF5C3D32),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UrgentCard extends StatelessWidget {
  const _UrgentCard({required this.item, required this.onAction});

  final ConciergeUrgentItem item;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final teal = item.isPrimaryAction;
    return Container(
      decoration: BoxDecoration(
        color: _InboxPalette.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SquareIcon(
                icon: item.tag == 'PAYROLL' ? Icons.payments_outlined : Icons.request_quote_outlined,
                background: teal
                    ? const Color(0xFFE8F5F4)
                    : const Color(0xFFF5E6E0),
                iconColor: teal ? _InboxPalette.primaryTeal : const Color(0xFF98604A),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.tag,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: _InboxPalette.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontFamily: _InboxPalette.serif,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _InboxPalette.navy,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _InboxPalette.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor:
                    teal ? _InboxPalette.primaryTeal : const Color(0xFFECEAE4),
                foregroundColor: teal ? Colors.white : _InboxPalette.navy,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              ),
              child: Text(
                item.actionLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: teal ? Colors.white : _InboxPalette.navy,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RenewalCard extends StatelessWidget {
  const _RenewalCard({required this.item, required this.onRenew});

  final ConciergeRenewalItem item;
  final VoidCallback onRenew;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _InboxPalette.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: item.imageAsset != null
                    ? Image.asset(
                        item.imageAsset!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _placeholderThumb(),
                      )
                    : _placeholderThumb(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.unit,
                      style: const TextStyle(
                        fontFamily: _InboxPalette.serif,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _InboxPalette.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.propertyLine,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: _InboxPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.body,
            style: const TextStyle(
              fontSize: 12,
              color: _InboxPalette.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F6F3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _InboxPalette.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.dueLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                          color: _InboxPalette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onRenew,
                  style: TextButton.styleFrom(
                    foregroundColor: _InboxPalette.primaryTeal,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  child: Text(item.actionLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderThumb() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFF122331), Color(0xFF061015)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({required this.item, required this.onAction});

  final ConciergeMaintenanceItem item;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _InboxPalette.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5E9E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.categoryPill,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Color(0xFF6A473A),
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.calendar_month_outlined, size: 20, color: _InboxPalette.muted),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: const TextStyle(
              fontFamily: _InboxPalette.serif,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _InboxPalette.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            style: const TextStyle(fontSize: 12, color: _InboxPalette.muted),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.scheduledCaption,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: _InboxPalette.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.dateLine,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _InboxPalette.navy,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _InboxPalette.primaryTeal,
                  side: const BorderSide(color: _InboxPalette.primaryTeal),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: Text(item.actionLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GeneralCard extends StatelessWidget {
  const _GeneralCard({required this.item, required this.onAction});

  final ConciergeGeneralItem item;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _InboxPalette.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.meeting_room_outlined, color: _InboxPalette.primaryTeal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontFamily: _InboxPalette.serif,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _InboxPalette.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: const TextStyle(fontSize: 12, color: _InboxPalette.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: _InboxPalette.primaryTeal,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: Text(item.actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareIcon extends StatelessWidget {
  const _SquareIcon({
    required this.icon,
    required this.background,
    required this.iconColor,
  });

  final IconData icon;
  final Color background;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: iconColor),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _InboxPalette.primaryTeal : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? _InboxPalette.primaryTeal : _InboxPalette.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : _InboxPalette.navy,
            ),
          ),
        ),
      ),
    );
  }
}
