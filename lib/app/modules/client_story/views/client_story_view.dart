import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/local/db/client_event_local_data_source.dart';
import '../controllers/client_story_controller.dart';

class ClientStoryView extends GetView<ClientStoryController> {
  const ClientStoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF121212) : const Color(0xFFF6F8FA);
    final surface = dark ? const Color(0xFF1E1E2E) : Colors.white;
    final onSurface = dark ? Colors.white : const Color(0xFF1A1A2E);
    final muted = dark ? Colors.white54 : Colors.black45;
    const teal = Color(0xFF0E6666);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: dark ? const Color(0xFF1A1A2A) : teal,
        foregroundColor: Colors.white,
        title: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.tenantName.value.isEmpty
                    ? 'Client Story'
                    : controller.tenantName.value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (controller.phoneNumber.value.isNotEmpty)
                Text(
                  controller.phoneNumber.value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: controller.refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _SummaryHeader(
                controller: controller,
                surface: surface,
                onSurface: onSurface,
                muted: muted,
                teal: teal,
              ),
            ),
            if (controller.rating.value != null)
              SliverToBoxAdapter(
                child: _RatingCard(
                  rating: controller.rating.value!,
                  surface: surface,
                  onSurface: onSurface,
                  muted: muted,
                  teal: teal,
                ),
              ),
            if (controller.events.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timeline_outlined,
                        size: 56,
                        color: muted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No story events yet',
                        style: TextStyle(color: muted, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Events are recorded as payments,\nreminders and activities happen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final event = controller.events[index];
                      final isLast = index == controller.events.length - 1;
                      return _TimelineItem(
                        event: event,
                        isLast: isLast,
                        surface: surface,
                        onSurface: onSurface,
                        muted: muted,
                        teal: teal,
                      );
                    },
                    childCount: controller.events.length,
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary header
// ---------------------------------------------------------------------------
class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.controller,
    required this.surface,
    required this.onSurface,
    required this.muted,
    required this.teal,
  });

  final ClientStoryController controller;
  final Color surface;
  final Color onSurface;
  final Color muted;
  final Color teal;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.payments_outlined,
            label: 'Total paid',
            value: controller.totalPaid.value,
            teal: teal,
          ),
          const SizedBox(width: 10),
          _StatChip(
            icon: Icons.home_outlined,
            label: 'Stays/tenancies',
            value: controller.totalStays.value.toString(),
            teal: teal,
          ),
          const SizedBox(width: 10),
          _StatChip(
            icon: Icons.schedule_outlined,
            label: 'Duration',
            value: controller.durationLabel.value.isEmpty
                ? '—'
                : controller.durationLabel.value,
            teal: teal,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.teal,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color teal;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: teal.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: teal, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: teal,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: teal.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rating card
// ---------------------------------------------------------------------------
class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.rating,
    required this.surface,
    required this.onSurface,
    required this.muted,
    required this.teal,
  });

  final dynamic rating;
  final Color surface;
  final Color onSurface;
  final Color muted;
  final Color teal;

  @override
  Widget build(BuildContext context) {
    final r = rating;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: teal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 6),
              Text(
                'Landlord Rating',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: onSurface,
                ),
              ),
              const Spacer(),
              _StarDisplay(stars: r.overallStars),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniStat(
                label: 'Payment',
                stars: r.paymentStars,
                muted: muted,
              ),
              const SizedBox(width: 12),
              _MiniStat(
                label: 'Care',
                stars: r.propertyCareStars,
                muted: muted,
              ),
              const SizedBox(width: 12),
              _MiniStat(
                label: 'Comms',
                stars: r.communicationStars,
                muted: muted,
              ),
              const Spacer(),
              _RentAgainChip(value: r.rentAgain),
            ],
          ),
          if ((r.comment as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"${r.comment}"',
              style: TextStyle(
                color: muted,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StarDisplay extends StatelessWidget {
  const _StarDisplay({required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        return Icon(
          i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.stars,
    required this.muted,
  });
  final String label;
  final int stars;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: muted),
        ),
        const SizedBox(height: 2),
                      Text(
                        '$stars/5',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Colors.amber,
          ),
        ),
      ],
    );
  }
}

class _RentAgainChip extends StatelessWidget {
  const _RentAgainChip({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (value) {
      case 'yes':
        color = Colors.green;
        label = 'Would rent again';
        break;
      case 'no':
        color = Colors.red.shade400;
        label = 'Would not rent again';
        break;
      default:
        color = Colors.amber.shade700;
        label = 'Maybe rent again';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline item
// ---------------------------------------------------------------------------
class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.event,
    required this.isLast,
    required this.surface,
    required this.onSurface,
    required this.muted,
    required this.teal,
  });

  final StoryEventVm event;
  final bool isLast;
  final Color surface;
  final Color onSurface;
  final Color muted;
  final Color teal;

  static final _dateFmt = DateFormat('dd/MM/yyyy');
  static final _timeFmt = DateFormat('hh:mm a');

  Color _dotColor() {
    if (event.isStart) return teal;
    if (event.isEnd) return Colors.red.shade400;
    if (event.eventType == ClientEventType.balanceCleared) {
      return Colors.green;
    }
    if (event.isPayment) return Colors.blue.shade600;
    if (event.isReminder) return Colors.orange;
    return Colors.grey;
  }

  IconData _icon() {
    switch (event.eventType) {
      case ClientEventType.tenantAdded:
        return Icons.person_add_outlined;
      case ClientEventType.bookingCreated:
        return Icons.hotel_outlined;
      case ClientEventType.checkIn:
        return Icons.login_outlined;
      case ClientEventType.leaseStarted:
        return Icons.assignment_outlined;
      case ClientEventType.paymentPartial:
        return Icons.payments_outlined;
      case ClientEventType.paymentFull:
        return Icons.paid_outlined;
      case ClientEventType.balanceCleared:
        return Icons.check_circle_outlined;
      case ClientEventType.reminderSent:
        return Icons.notifications_outlined;
      case ClientEventType.leaseEnded:
        return Icons.assignment_turned_in_outlined;
      case ClientEventType.checkOut:
        return Icons.logout_outlined;
      case ClientEventType.leaseRenewed:
        return Icons.autorenew_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.fromMillisecondsSinceEpoch(event.createdAtMs);
    final dotColor = _dotColor();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: dotColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 1.5),
                  ),
                  child: Icon(_icon(), size: 15, color: dotColor),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            dotColor.withValues(alpha: 0.5),
                            Colors.grey.withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: dotColor.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: onSurface,
                          ),
                        ),
                      ),
                      if (event.amountLabel.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.amountLabel,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (event.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      event.subtitle,
                      style: TextStyle(
                        color: muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (event.balanceLabel.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      event.balanceLabel,
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_outlined,
                        size: 11,
                        color: muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_dateFmt.format(dt)} · ${_timeFmt.format(dt)}',
                        style: TextStyle(
                          color: muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
