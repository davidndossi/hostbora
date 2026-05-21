import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/bnb_booking_actions.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/offline_sync_worker_service.dart';
import '../../../data/model/check_in_item.dart';
import '../../../routes/app_pages.dart';
import '../../../../l10n/app_localizations.dart';

class BookingDetailsController extends BaseController {
  BookingDetailsController()
      : _actions = BnbBookingActions(
          syncQueue: Get.find<OfflineSyncQueueLocalDataSource>(),
          syncWorker: Get.find<OfflineSyncWorkerService>(),
        ),
        _incomeLocal = Get.find<IncomeLocalDataSource>(),
        _propertyLocal = Get.find<PropertyLocalDataSource>(),
        _preferenceManager = Get.find<PreferenceManager>(
          tag: (PreferenceManager).toString(),
        );

  final BnbBookingActions _actions;
  final IncomeLocalDataSource _incomeLocal;
  final PropertyLocalDataSource _propertyLocal;
  final PreferenceManager _preferenceManager;

  static final _money = NumberFormat('#,###', 'en_US');

  /// True when opened from My Properties (select listing) to check availability.
  late final bool isListingMode;

  late CheckInItem _item;

  final propertyTitle = ''.obs;
  final propertyLocation = ''.obs;
  final propertyImageUrl = ''.obs;

  final guestName = ''.obs;
  final guestAvatarUrl = ''.obs;
  final guestRating = 0.0;
  final guestReviewCount = 0;

  final checkInDate = ''.obs;
  final checkInTime = 'After 3:00 PM';
  final checkOutDate = ''.obs;
  final checkOutTime = 'By 11:00 AM';

  final isPaid = false.obs;
  final totalPayout = '—'.obs;
  final paymentSummaryLoading = false.obs;

  String _propertyRef = '';
  String _propertyLabel = '';

  final isCheckedOut = false.obs;
  final isCancelled = false.obs;
  final processing = false.obs;

  DateTime? _checkOutDateTime;

  static const _displayDateFormat = 'MMM d, yyyy';

  AppLocalizations get _l10n => appLocalization;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      final id = args['listingId'];
      if (id != null && id.toString().isNotEmpty) {
        isListingMode = true;
        propertyTitle.value = args['listingTitle']?.toString() ?? '';
        propertyLocation.value = args['listingLocation']?.toString() ?? '';
        propertyImageUrl.value = args['listingImageUrl']?.toString() ?? '';
        return;
      }
    }
    isListingMode = false;
    if (args is CheckInItem) {
      _bindBooking(args);
      unawaited(_resolvePropertyContext());
      unawaited(_loadPaymentSummary());
    } else {
      _bindBooking(
        const CheckInItem(
          imageUrl: '',
          guestName: 'Guest',
          guestAvatarUrl: '',
          propertyType: 'Property',
          dates: '',
          isConfirmed: false,
        ),
      );
    }
  }

  void _bindBooking(CheckInItem item) {
    _item = item;
    _propertyLabel = item.propertyType.trim();
    guestName.value = item.guestName;
    guestAvatarUrl.value = item.guestAvatarUrl;
    propertyTitle.value = item.propertyType;
    propertyLocation.value = '';
    propertyImageUrl.value = item.imageUrl;
    isCheckedOut.value = item.isCheckedOut;
    isCancelled.value = item.isCancelled;

    final ci = DateTime.tryParse(item.checkInIso);
    final co = DateTime.tryParse(item.checkOutIso);
    _checkOutDateTime = co;
    checkInDate.value =
        ci != null ? DateFormat(_displayDateFormat).format(ci) : item.checkInIso;
    checkOutDate.value =
        co != null ? DateFormat(_displayDateFormat).format(co) : item.checkOutIso;
  }

  /// Availability: 'today' (default), 'month', 'month_date'
  final availabilityMode = 'today'.obs;
  final selectedMonth = Rxn<DateTime>();
  final selectedDate = Rxn<DateTime>();

  void setAvailabilityMode(String mode) {
    availabilityMode.value = mode;
    if (mode == 'today') {
      selectedMonth.value = null;
      selectedDate.value = null;
    } else if (mode == 'month') {
      selectedDate.value = null;
      if (selectedMonth.value == null) {
        selectedMonth.value = DateTime(DateTime.now().year, DateTime.now().month);
      }
    } else if (mode == 'month_date') {
      if (selectedMonth.value == null) {
        selectedMonth.value = DateTime(DateTime.now().year, DateTime.now().month);
      }
      if (selectedDate.value == null) {
        selectedDate.value = DateTime.now();
      }
    }
  }

  void pickMonth(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth.value ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2, 12),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      selectedMonth.value = DateTime(picked.year, picked.month);
    }
  }

  void pickDate(BuildContext context) async {
    final now = DateTime.now();
    final month = selectedMonth.value ?? now;
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0);
    final firstDate = (month.year == now.year && month.month == now.month)
        ? DateTime(now.year, now.month, now.day)
        : monthStart;
    final initial = selectedDate.value ?? month;
    final initialDate = initial.isBefore(firstDate) ? firstDate : initial;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: monthEnd,
    );
    if (picked != null) {
      selectedDate.value = picked;
    }
  }

  String get availabilitySummary {
    if (availabilityMode.value == 'today') {
      final t = DateTime.now();
      return DateFormat('EEEE, MMM d').format(t);
    }
    if (availabilityMode.value == 'month') {
      final m = selectedMonth.value;
      if (m == null) return 'Select month';
      return DateFormat('MMMM yyyy').format(m);
    }
    final d = selectedDate.value;
    if (d == null) return 'Select date';
    return DateFormat('EEEE, MMM d').format(d);
  }

  String get availabilityStatus {
    if (availabilityMode.value == 'today') {
      return 'Available';
    }
    if (availabilityMode.value == 'month') {
      return '22 days available';
    }
    return 'Available';
  }

  void goBack() => Get.back(result: true);

  Future<void> _resolvePropertyContext() async {
    final listingId = (_item.listingId ?? '').trim();
    if (listingId.isNotEmpty) {
      _propertyRef = listingId;
    }
    try {
      final userId = (await _preferenceManager.getUser()).id ?? '';
      final rows = await _propertyLocal.getAllVisibleNewestFirst(
        userId: userId,
        workspaceType: 'bnb',
      );
      for (final p in rows) {
        final ref = p.propertyRef.trim();
        final legacy = 'legacy_${p.id}';
        final local = 'local_${p.id}';
        if (listingId.isNotEmpty &&
            (listingId == ref || listingId == legacy || listingId == local)) {
          _propertyRef = ref.isNotEmpty ? ref : legacy;
          final label = p.propertyName.trim().isNotEmpty
              ? p.propertyName.trim()
              : p.propertyLocation.trim();
          if (label.isNotEmpty) _propertyLabel = label;
          return;
        }
        final label = p.propertyName.trim().isNotEmpty
            ? p.propertyName.trim()
            : p.propertyLocation.trim();
        if (label.isNotEmpty && label == _propertyLabel) {
          _propertyRef = ref.isNotEmpty ? ref : legacy;
          return;
        }
      }
    } catch (_) {}
  }

  Future<void> _loadPaymentSummary() async {
    if (isListingMode) return;
    paymentSummaryLoading.value = true;
    try {
      final rows = await _incomeLocal.getAllByBookingId(
        _item.bookingKey,
        workspaceType: 'bnb',
      );
      final total = rows.fold<double>(0, (sum, r) => sum + r.amountValue);
      isPaid.value = total > 0;
      totalPayout.value =
          total > 0 ? 'TZS ${_money.format(total.round())}' : '—';
    } finally {
      paymentSummaryLoading.value = false;
    }
  }

  Future<void> recordPayment() async {
    if (isListingMode) return;
    final property = _propertyLabel.isNotEmpty
        ? _propertyLabel
        : propertyTitle.value.trim();
    final saved = await Get.toNamed(
      Routes.RECORD_PAYMENT,
      parameters: {
        'bookingId': _item.bookingKey,
        if (_propertyRef.isNotEmpty) 'propertyRef': _propertyRef,
        if (property.isNotEmpty) 'property': property,
      },
      arguments: {
        'bookingId': _item.bookingKey,
        if (_propertyRef.isNotEmpty) 'propertyRef': _propertyRef,
        if (property.isNotEmpty) 'property': property,
      },
    );
    if (saved == true) {
      await _loadPaymentSummary();
    }
  }

  void share() {
    final text = [
      '${_l10n.bookingDetails} – ${propertyTitle.value}',
      if (propertyLocation.value.isNotEmpty) propertyLocation.value,
      'Check-in: ${checkInDate.value} $checkInTime',
      'Check-out: ${checkOutDate.value} $checkOutTime',
      '${_l10n.guestName}: ${guestName.value}',
      if (totalPayout.value.isNotEmpty && totalPayout.value != '—')
        '${_l10n.totalPayout}: ${totalPayout.value}',
    ].join('\n');
    Share.share(text, subject: '${_l10n.bookingDetails} – ${propertyTitle.value}');
  }

  void moreOptions() {}

  void messageGuest() {}

  bool get _isInactive =>
      isCheckedOut.value || isCancelled.value;

  Future<void> confirmCancelBooking() async {
    if (_isInactive || processing.value) return;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(_l10n.cancelBookingTitle),
        content: Text(_l10n.cancelBookingMessage),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(_l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(Get.context!).colorScheme.error,
            ),
            child: Text(_l10n.cancelBooking),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await cancelBooking();
  }

  Future<void> cancelBooking() async {
    if (_isInactive || processing.value) return;
    processing.value = true;
    try {
      await _actions.cancelBooking(
        bookingKey: _item.bookingKey,
        isLocalPending: _item.isLocalPending,
      );
      isCancelled.value = true;
      Get.snackbar(_l10n.cancelBooking, _l10n.bookingCancelledSuccess);
      Get.back(result: true);
    } catch (e) {
      Get.snackbar(_l10n.error, e.toString());
    } finally {
      processing.value = false;
    }
  }

  Future<void> confirmCheckOut() async {
    if (_isInactive || processing.value) return;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(_l10n.checkOutGuestTitle),
        content: Text(_l10n.checkOutGuestMessage),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(_l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text(_l10n.checkOutGuest),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await checkOutGuest();
  }

  Future<void> checkOutGuest() async {
    if (_isInactive || processing.value) return;
    processing.value = true;
    try {
      await _actions.checkOut(
        bookingKey: _item.bookingKey,
        isLocalPending: _item.isLocalPending,
      );
      isCheckedOut.value = true;
      Get.snackbar(_l10n.checkOutGuest, _l10n.guestCheckedOut);
      Get.back(result: true);
    } catch (e) {
      Get.snackbar(_l10n.error, e.toString());
    } finally {
      processing.value = false;
    }
  }

  Future<void> showExtendStayDialog() async {
    if (_isInactive || processing.value) return;
    final currentOut = _checkOutDateTime ??
        DateTime.tryParse(_item.checkOutIso) ??
        DateTime.now().add(const Duration(days: 1));
    var extraNights = 1;

    final result = await Get.dialog<int>(
      AlertDialog(
        title: Text(_l10n.extendStayTitle),
        content: StatefulBuilder(
          builder: (context, setState) {
            final newOut = currentOut.add(Duration(days: extraNights));
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_l10n.extendStayDays),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: extraNights > 1
                          ? () => setState(() => extraNights--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$extraNights',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: extraNights < 90
                          ? () => setState(() => extraNights++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_l10n.newCheckOutDate}: ${DateFormat(_displayDateFormat).format(newOut)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(_l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Get.back(result: extraNights),
            child: Text(_l10n.extendStayConfirm),
          ),
        ],
      ),
    );

    if (result == null || result < 1) return;
    await extendStay(extraNights: result);
  }

  Future<void> extendStay({required int extraNights}) async {
    if (_isInactive || processing.value) return;
    final currentOut = _checkOutDateTime ??
        DateTime.tryParse(_item.checkOutIso) ??
        DateTime.now();
    final newOut = DateTime(currentOut.year, currentOut.month, currentOut.day)
        .add(Duration(days: extraNights));

    processing.value = true;
    try {
      await _actions.extendStay(
        bookingKey: _item.bookingKey,
        isLocalPending: _item.isLocalPending,
        newCheckOut: newOut,
      );
      _checkOutDateTime = newOut;
      checkOutDate.value = DateFormat(_displayDateFormat).format(newOut);
      Get.snackbar(_l10n.extendStayTitle, _l10n.stayExtended);
      Get.back(result: true);
    } catch (e) {
      Get.snackbar(_l10n.error, e.toString());
    } finally {
      processing.value = false;
    }
  }

  void modifyBooking() => showExtendStayDialog();
}
