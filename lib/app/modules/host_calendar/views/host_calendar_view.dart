import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/host_calendar_controller.dart';
import '../enum/day_type.dart';

const _hostCalendarManualRateBg = Color(0xFFE07A5F);

class HostCalendarView extends BaseView<HostCalendarController> {
  HostCalendarView({super.key});

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  String _t(BuildContext context, {required String en, required String sw}) {
    final code =
        Get.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    return code == 'sw' ? sw : en;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.calendar,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
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
                  const SizedBox(height: 12),
                  _buildLegend(context),
                  const SizedBox(height: 24),
                  _buildEventsSection(context),
                ],
              ),
            ),
          ),
        ],
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
            _monthYear(context, controller.currentMonth.value),
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

  String _monthYear(BuildContext context, DateTime m) {
    const monthsEn = [
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
    const monthsSw = [
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
    ];
    final isSw =
        (Get.locale?.languageCode ??
            Localizations.localeOf(context).languageCode) ==
        'sw';
    return '${(isSw ? monthsSw : monthsEn)[m.month - 1]} ${m.year}';
  }

  Widget _buildDynamicPricingRow(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isDark(context)
              ? theme.colorScheme.surfaceContainerHigh
              : AppColors.colorWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isDark(context)
                ? theme.colorScheme.outlineVariant
                : AppColors.designInputBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
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
                if (states.contains(WidgetState.selected)) {
                  return AppColors.colorPrimary;
                }
                return AppColors.designInputBorder;
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertySelector(BuildContext context) {
    final theme = Theme.of(context);
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
            color: _isDark(context)
                ? theme.colorScheme.surfaceContainerHigh
                : AppColors.colorWhite,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _showPropertySheet(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isDark(context)
                        ? theme.colorScheme.outlineVariant
                        : AppColors.designInputBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.home_rounded,
                      size: 24,
                      color: AppColors.colorPrimary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        controller.selectedPropertyName.value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textColorPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textColorSecondary,
                    ),
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
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: _isDark(context)
          ? theme.colorScheme.surfaceContainerHigh
          : AppColors.colorWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: controller.properties
              .map(
                (p) => ListTile(
                  title: Text(
                    p,
                    style: TextStyle(color: AppColors.textColorPrimary),
                  ),
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
      controller.calendarRevision.value;
      controller.properties.length;
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
            color: AppColors.colorPrimaryLight.withValues(alpha: 0.4),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.colorPrimaryLight.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          cellMargin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          cellPadding: EdgeInsets.zero,
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) => _dayCell(
            context,
            day,
            isCurrentMonth: day.month == focusedDay.month,
            price: controller.priceForDay(day),
            isSelected:
                day.year == selected.year &&
                day.month == selected.month &&
                day.day == selected.day,
            dayType: controller.typeForDay(day),
            isBlocked: controller.isDateBlocked(day),
            isDisabled: !controller.isDayEnabled(day),
          ),
          outsideBuilder: (context, day, focusedDay) => _dayCell(
            context,
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
    BuildContext context,
    DateTime d, {
    required bool isCurrentMonth,
    String? price,
    bool isSelected = false,
    DayType dayType = DayType.standard,
    bool isBlocked = false,
    bool isDisabled = false,
  }) {
    final theme = Theme.of(context);
    Color? bg;
    if (isCurrentMonth) {
      if (isBlocked) {
        bg = _isDark(context)
            ? theme.colorScheme.surfaceContainerHighest
            : Colors.grey.shade300;
      } else if (dayType == DayType.aiOptimized) {
        bg = AppColors.colorPrimaryLight.withValues(alpha: 0.6);
      } else if (dayType == DayType.manualRate) {
        bg = _hostCalendarManualRateBg.withValues(alpha: 0.5);
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
                      ? (isBlocked
                            ? AppColors.textColorSecondary
                            : AppColors.textColorPrimary)
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
                    _t(context, en: 'Blocked', sw: 'Imefungwa'),
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
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
          appLocalization.today,
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
          appLocalization.events,
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
      controller.calendarRevision.value;
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
                '${events.length} ${_t(context, en: 'EVENTS', sw: 'MATUKIO')}',
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
                    color: isBlocked
                        ? AppColors.colorPrimary
                        : AppColors.paaYanguAlert,
                  ),
                  label: Text(
                    isBlocked
                        ? _t(context, en: 'Unblock date', sw: 'Fungua tarehe')
                        : _t(context, en: 'Block date', sw: 'Funga tarehe'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isBlocked
                          ? AppColors.colorPrimary
                          : AppColors.paaYanguAlert,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: isBlocked
                          ? AppColors.colorPrimary
                          : AppColors.paaYanguAlert,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppValues.radius_6),
                    ),
                  ),
                ),
              ),
            ),
          ...events.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _EventCard(event: e, t: _t),
            ),
          ),
        ],
      );
    });
  }
}

class _EventCard extends StatelessWidget {
  final CalendarEvent event;
  final String Function(
    BuildContext context, {
    required String en,
    required String sw,
  })
  t;

  const _EventCard({required this.event, required this.t});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMaintenance = event.type == CalendarEventType.maintenance;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outlineVariant
              : AppColors.designInputBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
                isMaintenance
                    ? t(context, en: 'MAINTENANCE', sw: 'MATENGENEZO')
                    : (event.type == CalendarEventType.checkOut
                        ? t(context, en: 'CHECK-OUT', sw: 'KUONDOKA')
                        : t(context, en: 'CHECK-IN', sw: 'KUINGIA')),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: isMaintenance
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
          if (isMaintenance) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.home_work_outlined,
                  size: 16,
                  color: AppColors.textColorSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.propertyName.isEmpty ? '—' : event.propertyName,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textColorSecondary,
                    ),
                  ),
                ),
              ],
            ),
            if (event.subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notes_outlined,
                    size: 16,
                    color: AppColors.textColorSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      event.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textColorSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ] else ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 16,
                  color: AppColors.textColorSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${event.guests} ${t(context, en: 'Guests', sw: 'Wageni')}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textColorSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  event.subtitleHighlight
                      ? Icons.cleaning_services
                      : Icons.key_outlined,
                  size: 16,
                  color: event.subtitleHighlight
                      ? AppColors.colorOrange
                      : AppColors.textColorSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: event.subtitleHighlight
                          ? AppColors.colorOrange
                          : AppColors.textColorSecondary,
                      fontWeight: event.subtitleHighlight
                          ? FontWeight.w500
                          : FontWeight.normal,
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
