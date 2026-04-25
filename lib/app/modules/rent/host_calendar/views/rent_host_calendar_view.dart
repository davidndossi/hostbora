import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';


import '../../../../core/base/base_view.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/values/app_values.dart';
import '../../../../core/widget/custom_app_bar.dart';
import '../controllers/rent_host_calendar_controller.dart';
import '../enum/day_type.dart';

const _hostCalendarManualRateBg = Color(0xFFE07A5F);

class RentHostCalendarView extends BaseView<RentHostCalendarController> {
  RentHostCalendarView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';
  String _t(String en, String sw) => _isSw ? sw : en;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.calendar,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    return Obx(
      () => SafeArea(
        child: Column(
          children: [
            if (controller.loading.value)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    // _buildDynamicPricingRow(context),
                    // const SizedBox(height: 20),
                    _buildPropertySelector(context),
                    const SizedBox(height: 20),
                    _buildCalendarGrid(context),
                    // const SizedBox(height: 12),
                    // _buildLegend(context),
                    const SizedBox(height: 24),
                    _buildEventsSection(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Obx(
          () => Text(
            _monthYear(controller.currentMonth.value),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.textColorPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Material(
          color: AppColors.colorPrimary,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: controller.goToToday,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                appLocalization.today,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _monthYear(DateTime m) {
    final months = _isSw
        ? const [
            'Januari',
            'Februari',
            'Machi',
            'Aprili',
            'Mei',
            'Juni',
            'Julai',
            'Agosti',
            'Septemba',
            'Oktoba',
            'Novemba',
            'Desemba',
          ]
        : const [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December',
          ];
    return '${months[m.month - 1]} ${m.year}';
  }

  Widget _buildDynamicPricingRow(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.colorWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.designInputBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, size: 20, color: AppColors.colorPrimary),
            const SizedBox(width: 10),
            Text(
              appLocalization.dynamicPricing,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textColorPrimary,
              ),
            ),
            const Spacer(),
            Switch(
              value: controller.dynamicPricingOn.value,
              onChanged: (_) => controller.toggleDynamicPricing(),
              activeTrackColor: AppColors.colorPrimaryLight,
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return AppColors.colorPrimary;
                return AppColors.designInputBorder;
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertySelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appLocalization.activeProperty,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: AppColors.textColorSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Material(
            color: AppColors.colorWhite,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _showPropertySheet(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.designInputBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.home_rounded, size: 24, color: AppColors.colorPrimary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        controller.selectedPropertyName.value.isEmpty
                            ? appLocalization.myProperties
                            : controller.selectedPropertyName.value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textColorPrimary,
                        ),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: AppColors.textColorSecondary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPropertySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.colorWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: controller.properties.isEmpty
              ? [
                  ListTile(
                    title: Text(
                      _t('No properties', 'Hakuna mali'),
                      style: TextStyle(color: AppColors.textColorSecondary),
                    ),
                  ),
                ]
              : controller.properties
                  .map(
                    (p) => ListTile(
                      title: Text(p, style: TextStyle(color: AppColors.textColorPrimary)),
                      onTap: () {
                        controller.selectProperty(p);
                        Navigator.pop(ctx);
                      },
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    return Obx(() {
      final focused = controller.currentMonth.value;
      final selected = controller.selectedDate.value;
      final firstDay = DateTime(focused.year - 2, 1);
      final lastDay = DateTime(focused.year + 2, 12, 31);
      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);
      return TableCalendar(
        firstDay: firstDay,
        lastDay: lastDay,
        focusedDay: focused,
        currentDay: today,
        selectedDayPredicate: (day) =>
            day.year == selected.year &&
            day.month == selected.month &&
            day.day == selected.day,
        enabledDayPredicate: (day) {
          final d = DateTime(day.year, day.month, day.day);
          return !d.isBefore(startOfToday);
        },
        onDaySelected: (day, _) {
          if (!controller.isDayEnabled(day)) return;
          controller.selectDate(day);
          controller.setMonth(DateTime(day.year, day.month));
        },
        onPageChanged: (focusedDay) =>
            controller.setMonth(DateTime(focusedDay.year, focusedDay.month)),
        headerVisible: false,
        startingDayOfWeek: StartingDayOfWeek.sunday,
        rowHeight: 52,
        daysOfWeekHeight: 36,
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textColorSecondary,
          ),
          weekendStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textColorSecondary,
          ),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: true,
          defaultTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textColorPrimary,
          ),
          outsideTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textColorSecondary,
          ),
          selectedDecoration: BoxDecoration(
            color: AppColors.colorPrimaryLight.withOpacity(0.4),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.colorPrimaryLight.withOpacity(0.3),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          cellMargin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          cellPadding: EdgeInsets.zero,
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) => _dayCell(
            day,
            isCurrentMonth: day.month == focusedDay.month,
            // price: controller.priceForDay(day),
            isSelected: day.year == selected.year &&
                day.month == selected.month &&
                day.day == selected.day,
            dayType: controller.typeForDay(day),
            isBlocked: controller.isDateBlocked(day),
            isDisabled: !controller.isDayEnabled(day),
          ),
          outsideBuilder: (context, day, focusedDay) => _dayCell(
            day,
            isCurrentMonth: false,
            price: null,
            isSelected: false,
            dayType: DayType.standard,
            isBlocked: false,
            isDisabled: true,
          ),
        ),
      );
    });
  }

  Widget _dayCell(
    DateTime d, {
    required bool isCurrentMonth,
    String? price,
    bool isSelected = false,
    DayType dayType = DayType.standard,
    bool isBlocked = false,
    bool isDisabled = false,
  }) {
    Color? bg;
    if (isCurrentMonth) {
      if (isBlocked) {
        bg = Colors.grey.shade300;
      } else if (dayType == DayType.aiOptimized) {
        bg = AppColors.colorPrimaryLight.withOpacity(0.6);
      } else if (dayType == DayType.manualRate) {
        bg = _hostCalendarManualRateBg.withOpacity(0.5);
      }
    }
    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              controller.selectDate(d);
              controller.setMonth(DateTime(d.year, d.month));
            },
      child: Opacity(
        opacity: isDisabled ? 0.45 : 1,
        child: Container(
        width: 44,
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: AppColors.colorPrimary, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${d.day}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isCurrentMonth
                    ? (isBlocked ? AppColors.textColorSecondary : AppColors.textColorPrimary)
                    : AppColors.textColorSecondary,
                decoration: isBlocked ? TextDecoration.lineThrough : null,
              ),
            ),
            if (price != null && !isBlocked) ...[
              const SizedBox(height: 2),
              Text(
                price,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isCurrentMonth
                      ? (dayType == DayType.standard
                          ? AppColors.colorPrimary
                          : AppColors.textColorPrimary)
                      : AppColors.textColorSecondary,
                ),
              ),
            ],
            if (isBlocked && isCurrentMonth)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _t('Blocked', 'Imefungwa'),
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.colorPrimary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          appLocalization.aiOptimized,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textColorSecondary,
          ),
        ),
        const SizedBox(width: 20),
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: _hostCalendarManualRateBg,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          appLocalization.manualRate,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textColorSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEventsSection(BuildContext context) {
    return Obx(() {
      final events = controller.eventsForSelectedDay;
      final selected = controller.selectedDate.value;
      final isBlocked = controller.isDateBlocked(selected);
      final canBlock = controller.isDayEnabled(selected);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                controller.selectedDayHeader,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textColorPrimary,
                ),
              ),
              Text(
                '${events.length} ${appLocalization.events.toUpperCase()}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textColorSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (canBlock)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => controller.toggleBlockDate(selected),
                  icon: Icon(
                    isBlocked ? Icons.lock_open_outlined : Icons.block_outlined,
                    size: 20,
                    color: isBlocked ? AppColors.colorPrimary : AppColors.paaYanguAlert,
                  ),
                  label: Text(
                    isBlocked
                        ? _t('Unblock date', 'Fungua tarehe')
                        : _t('Block date', 'Zuia tarehe'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isBlocked ? AppColors.colorPrimary : AppColors.paaYanguAlert,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: isBlocked ? AppColors.colorPrimary : AppColors.paaYanguAlert,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppValues.radius_6),
                    ),
                  ),
                ),
              ),
            ),
          ...events.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _EventCard(event: e),
              )),
        ],
      );
    });
  }
}

class _EventCard extends StatelessWidget {
  final CalendarEvent event;

  const _EventCard({required this.event});

  bool get _isSw => Get.locale?.languageCode == 'sw';
  String _t(String en, String sw) => _isSw ? sw : en;

  String _typeHeader() {
    switch (event.type) {
      case CalendarEventType.maintenance:
        return _t('MAINTENANCE', 'MATENGENEZO');
      case CalendarEventType.paymentReminder:
        return _t('PAYMENT REMINDER', 'UKUMBUSHO WA MALIPO');
      case CalendarEventType.leaseEnd:
        return _t('LEASE END', 'MWISHO WA MKATABA');
      case CalendarEventType.leaseStart:
        return _t('LEASE START', 'MWANZO WA MKATABA');
      case CalendarEventType.checkOut:
        return _t('CHECK-OUT', 'TOKA');
      case CalendarEventType.checkIn:
        return _t('CHECK-IN', 'INGIA');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(color: AppColors.designInputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _typeHeader(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: event.type == CalendarEventType.maintenance
                      ? AppColors.colorOrange
                      : AppColors.colorPrimary,
                ),
              ),
              const Spacer(),
              Text(
                event.time,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textColorSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            event.guestName,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textColorPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (event.type == CalendarEventType.maintenance ||
              event.type == CalendarEventType.paymentReminder)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.home_work_outlined, size: 16, color: AppColors.textColorSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.propertyName.isEmpty ? '—' : event.propertyName,
                    style: TextStyle(fontSize: 13, color: AppColors.textColorSecondary),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(Icons.people_outline, size: 16, color: AppColors.textColorSecondary),
                const SizedBox(width: 6),
                Text(
                  '${event.guests} ${_t('Guests', 'Wageni')}',
                  style: TextStyle(fontSize: 13, color: AppColors.textColorSecondary),
                ),
                const SizedBox(width: 16),
                Icon(
                  event.subtitleHighlight ? Icons.cleaning_services : Icons.key_outlined,
                  size: 16,
                  color: event.subtitleHighlight ? AppColors.colorOrange : AppColors.textColorSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: event.subtitleHighlight ? AppColors.colorOrange : AppColors.textColorSecondary,
                      fontWeight: event.subtitleHighlight ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          if (event.type == CalendarEventType.maintenance && event.subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notes_outlined, size: 16, color: AppColors.textColorSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.subtitle,
                    style: TextStyle(fontSize: 13, color: AppColors.textColorSecondary),
                  ),
                ),
              ],
            ),
          ],
          if (event.type == CalendarEventType.paymentReminder && event.subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.payments_outlined, size: 16, color: AppColors.textColorSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColorSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
