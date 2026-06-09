import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/bnb_stay_billing.dart';
import '../../../core/utils/booking_api_response.dart';
import '../../../data/local/bnb_booking_merge.dart';
import '../../../data/local/bnb_booking_pending_loader.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/guest_access_codes_store.dart';
import '../../../data/local/pending_bookings_store.dart';
import '../../../data/model/check_in_item.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';

enum AccessStatus { active, scheduled }

class GuestAccessItem {
  const GuestAccessItem({
    required this.id,
    required this.guestName,
    required this.status,
    required this.pinVisible,
    required this.pinFull,
    required this.dateRange,
    this.booking,
    this.isCustom = false,
  });

  final String id;
  final String guestName;
  final AccessStatus status;
  final String pinVisible;
  final String pinFull;
  final String dateRange;
  final CheckInItem? booking;
  final bool isCustom;
}

class GuestAccessCodesController extends BaseController {
  GuestAccessCodesController()
      : _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _propertyLocal = Get.find<PropertyLocalDataSource>(),
        _codesStore = GuestAccessCodesStore(),
        _pendingBookings = PendingBookingsStore();

  final AppRepository _repository;
  final PropertyLocalDataSource _propertyLocal;
  final GuestAccessCodesStore _codesStore;
  final PendingBookingsStore _pendingBookings;

  late final BnbBookingPendingLoader _pendingLoader = BnbBookingPendingLoader(
    syncQueue: Get.find<OfflineSyncQueueLocalDataSource>(),
  );

  final loading = true.obs;
  final lastSynced = '—'.obs;
  final revealedId = RxnString();
  final activeAccess = <GuestAccessItem>[].obs;
  final upcomingAccess = <GuestAccessItem>[].obs;

  static final _dateRangeFmt = DateFormat('MMM d, h:mm a');

  @override
  void onInit() {
    super.onInit();
    loadAccessCodes();
  }

  static Future<void> refreshIfRegistered() async {
    if (Get.isRegistered<GuestAccessCodesController>()) {
      await Get.find<GuestAccessCodesController>().loadAccessCodes(quiet: true);
    }
  }

  Future<void> loadAccessCodes({bool quiet = false}) async {
    if (!quiet) loading.value = true;
    try {
      final merge = BnbBookingMerge(pending: _pendingBookings);
      final merged = <String, CheckInItem>{};

      try {
        final res = await _repository.getAllBookings();
        if (BookingApiResponse.isSuccess(res.responseCode)) {
          for (final row in BookingApiResponse.parseBookingsList(res.data)) {
            final item = merge.fromApiMap(row);
            merged[item.bookingKey] = item;
          }
        }
      } catch (_) {}

      try {
        final properties = await _propertyLocal.getAllVisibleNewestFirst(
          userId: '',
          workspaceType: 'bnb',
        );
        await mergePendingBnbBookings(
          merge: merge,
          merged: merged,
          properties: properties,
          loader: _pendingLoader,
        );
      } catch (_) {}

      final now = DateTime.now();
      final active = <GuestAccessItem>[];
      final upcoming = <GuestAccessItem>[];

      for (final booking in merged.values) {
        if (booking.isInactive) continue;
        final ci = _parseDate(booking.checkInIso);
        final co = _parseDate(booking.checkOutIso);
        if (ci == null || co == null) continue;
        if (!BnbStayBilling.isValidStayRange(ci, co)) continue;

        final stored = _codesStore.get(booking.bookingKey);
        if (stored?.revoked == true) continue;

        final pin = await _codesStore.pinForBooking(
          bookingKey: booking.bookingKey,
          guestName: booking.guestName,
          checkInIso: booking.checkInIso,
          checkOutIso: booking.checkOutIso,
        );

        final item = _toUiItem(
          id: booking.bookingKey,
          guestName: booking.guestName,
          pin: pin,
          checkIn: ci,
          checkOut: co,
          booking: booking,
        );

        if (BnbStayBilling.dayInStay(now, ci, co)) {
          active.add(item.copyWithStatus(AccessStatus.active));
        } else if (BnbStayBilling.dateOnly(now).isBefore(BnbStayBilling.dateOnly(ci))) {
          upcoming.add(item.copyWithStatus(AccessStatus.scheduled));
        }
      }

      for (final custom in _codesStore.listActiveCustom()) {
        final ci = _parseDate(custom.checkInIso);
        final co = _parseDate(custom.checkOutIso);
        if (ci == null || co == null) continue;

        final item = _toUiItem(
          id: custom.id,
          guestName: custom.guestName,
          pin: custom.pin,
          checkIn: ci,
          checkOut: co,
          isCustom: true,
        );

        if (BnbStayBilling.dayInStay(now, ci, co)) {
          active.add(item.copyWithStatus(AccessStatus.active));
        } else if (BnbStayBilling.dateOnly(now).isBefore(BnbStayBilling.dateOnly(ci))) {
          upcoming.add(item.copyWithStatus(AccessStatus.scheduled));
        }
      }

      int sortKey(GuestAccessItem a) {
        final b = a.booking;
        if (b == null) return 0;
        return DateTime.tryParse(b.checkInIso)?.millisecondsSinceEpoch ?? 0;
      }

      active.sort((a, b) => sortKey(a).compareTo(sortKey(b)));
      upcoming.sort((a, b) => sortKey(a).compareTo(sortKey(b)));

      activeAccess.assignAll(active);
      upcomingAccess.assignAll(upcoming);
      lastSynced.value = _formatLastSynced(DateTime.now());
    } catch (_) {
      // Keep previous lists on error.
    } finally {
      if (!quiet) loading.value = false;
    }
  }

  GuestAccessItem _toUiItem({
    required String id,
    required String guestName,
    required String pin,
    required DateTime checkIn,
    required DateTime checkOut,
    CheckInItem? booking,
    bool isCustom = false,
  }) {
    final visible = pin.length >= 3 ? pin.substring(0, 3) : pin;
    return GuestAccessItem(
      id: id,
      guestName: guestName.isNotEmpty ? guestName : 'Guest',
      status: AccessStatus.scheduled,
      pinVisible: visible,
      pinFull: pin,
      dateRange: _formatStayRange(checkIn, checkOut),
      booking: booking,
      isCustom: isCustom,
    );
  }

  String _formatStayRange(DateTime checkIn, DateTime checkOut) {
    final ci = DateTime(checkIn.year, checkIn.month, checkIn.day, 10);
    final co = DateTime(checkOut.year, checkOut.month, checkOut.day, 10);
    return '${_dateRangeFmt.format(ci)} — ${_dateRangeFmt.format(co)}';
  }

  DateTime? _parseDate(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    return DateTime.tryParse(t);
  }

  String _formatLastSynced(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inSeconds < 60) {
      return Get.locale?.languageCode == 'sw' ? 'Sasa hivi' : 'Just now';
    }
    if (diff.inMinutes < 60) {
      return Get.locale?.languageCode == 'sw'
          ? 'Dakika ${diff.inMinutes} zilizopita'
          : '${diff.inMinutes} min ago';
    }
    return DateFormat('h:mm a').format(when);
  }

  void goBack() => Get.back();

  void openCalendar() {
  }

  void toggleReveal(GuestAccessItem item) {
    revealedId.value = revealedId.value == item.id ? null : item.id;
  }

  void shareCode(GuestAccessItem item) {
    final text = [
      'Your access code: ${item.pinFull}',
      if (item.guestName.isNotEmpty) 'Guest: ${item.guestName}',
      'Valid: ${item.dateRange}',
    ].join('\n');
    Share.share(text, subject: 'Access code');
  }

  Future<void> copyCode(GuestAccessItem item) async {
    await Clipboard.setData(ClipboardData(text: item.pinFull));
    showSuccessMessage(
      Get.locale?.languageCode == 'sw'
          ? 'Msimbo umenakiliwa'
          : 'Code copied to clipboard',
    );
  }

  void openOptions(GuestAccessItem item) {
    final isSw = Get.locale?.languageCode == 'sw';
    Get.bottomSheet<void>(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: Text(isSw ? 'Shiriki msimbo' : 'Share code'),
              onTap: () {
                Get.back();
                shareCode(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: Text(isSw ? 'Nakili msimbo' : 'Copy code'),
              onTap: () {
                Get.back();
                copyCode(item);
              },
            ),
            if (item.booking != null)
              ListTile(
                leading: const Icon(Icons.event_note_outlined),
                title: Text(isSw ? 'Angalia uhifadhi' : 'View booking'),
                onTap: () {
                  Get.back();
                  Get.toNamed(
                    Routes.BOOKING_DETAILS,
                    arguments: item.booking,
                  )?.then((_) => loadAccessCodes(quiet: true));
                },
              ),
            ListTile(
              leading: Icon(Icons.block, color: Get.theme.colorScheme.error),
              title: Text(
                isSw ? 'Batilisha ufikiaji' : 'Revoke access',
                style: TextStyle(color: Get.theme.colorScheme.error),
              ),
              onTap: () async {
                Get.back();
                await _codesStore.revoke(item.id);
                if (revealedId.value == item.id) revealedId.value = null;
                showSuccessMessage(
                  isSw ? 'Ufikiaji umebatilishwa' : 'Access revoked',
                );
                await loadAccessCodes(quiet: true);
              },
            ),
          ],
        ),
      ),
      backgroundColor: Get.theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  Future<void> createCustomCode() async {
    final isSw = Get.locale?.languageCode == 'sw';
    final guestController = TextEditingController();
    final pinController = TextEditingController();
    DateTime? checkIn;
    DateTime? checkOut;

    await Get.dialog<void>(
      StatefulBuilder(
        builder: (context, setState) {
          Future<void> pickDate({required bool isCheckIn}) async {
            final initial = isCheckIn
                ? (checkIn ?? DateTime.now())
                : (checkOut ??
                    checkIn?.add(const Duration(days: 1)) ??
                    DateTime.now().add(const Duration(days: 1)));
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 730)),
              locale: const Locale('en', 'GB'),
            );
            
            if (picked == null) return;
            setState(() {
              if (isCheckIn) {
                checkIn = picked;
              } else {
                checkOut = picked;
              }
            });
          }

          return AlertDialog(
            title: Text(isSw ? 'Msimbo maalum' : 'Custom access code'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: guestController,
                    decoration: InputDecoration(
                      labelText: isSw ? 'Jina la mgeni' : 'Guest name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: isSw ? 'PIN (hiari)' : 'PIN (optional)',
                      hintText: isSw
                          ? 'Tengeneza kiotomatiki'
                          : 'Auto-generated if empty',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(isSw ? 'Tarehe ya kuingia' : 'Check-in date'),
                    subtitle: Text(
                      checkIn != null
                          ? DateFormat('yyyy-MM-dd').format(checkIn!)
                          : (isSw ? 'Chagua' : 'Select'),
                    ),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () => pickDate(isCheckIn: true),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(isSw ? 'Tarehe ya kutoka' : 'Check-out date'),
                    subtitle: Text(
                      checkOut != null
                          ? DateFormat('yyyy-MM-dd').format(checkOut!)
                          : (isSw ? 'Chagua' : 'Select'),
                    ),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () => pickDate(isCheckIn: false),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text(isSw ? 'Ghairi' : 'Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final name = guestController.text.trim();
                  if (name.isEmpty) {
                    showErrorMessage(
                      isSw ? 'Weka jina la mgeni' : 'Enter guest name',
                    );
                    return;
                  }
                  if (checkIn == null || checkOut == null) {
                    showErrorMessage(
                      isSw
                          ? 'Chagua tarehe za kuingia na kutoka'
                          : 'Select check-in and check-out dates',
                    );
                    return;
                  }
                  if (!BnbStayBilling.isValidStayRange(checkIn!, checkOut!)) {
                    showErrorMessage(
                      isSw
                          ? 'Tarehe ya kutoka lazima iwe baada ya kuingia'
                          : 'Check-out must be after check-in',
                    );
                    return;
                  }
                  await _codesStore.saveCustom(
                    guestName: name,
                    checkInIso: DateFormat('yyyy-MM-dd').format(checkIn!),
                    checkOutIso: DateFormat('yyyy-MM-dd').format(checkOut!),
                    pin: pinController.text.trim(),
                  );
                  Get.back();
                  showSuccessMessage(
                    isSw ? 'Msimbo umehifadhiwa' : 'Access code created',
                  );
                  await loadAccessCodes(quiet: true);
                },
                child: Text(isSw ? 'Hifadhi' : 'Save'),
              ),
            ],
          );
        },
      ),
    );

    guestController.dispose();
    pinController.dispose();
  }
}

extension on GuestAccessItem {
  GuestAccessItem copyWithStatus(AccessStatus status) {
    return GuestAccessItem(
      id: id,
      guestName: guestName,
      status: status,
      pinVisible: pinVisible,
      pinFull: pinFull,
      dateRange: dateRange,
      booking: booking,
      isCustom: isCustom,
    );
  }
}
