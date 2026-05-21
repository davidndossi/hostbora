import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/model/calendar_subscription.dart';
import '../../../data/model/calendar_sync_request.dart';
import '../../../data/model/create_calendar_subscription_request.dart';
import '../../../data/model/general_response.dart';
import '../../../data/repository/app_repository.dart';
import '../../host_calendar/controllers/host_calendar_controller.dart';

class CalendarSyncController extends BaseController {
  CalendarSyncController()
      : _repository = Get.find<AppRepository>(tag: (AppRepository).toString());

  final AppRepository _repository;

  final loading = true.obs;
  final syncing = false.obs;
  final subscriptions = <CalendarSubscription>[].obs;

  final importUrlController = TextEditingController();
  final importLabelController = TextEditingController();

  String get listingId =>
      (Get.arguments is Map)
          ? ((Get.arguments as Map)['listing_id'] ?? '').toString().trim()
          : '';

  String get listingName =>
      (Get.arguments is Map)
          ? ((Get.arguments as Map)['listing_name'] ?? '').toString().trim()
          : '';

  List<CalendarSubscription> get importSubscriptions =>
      subscriptions.where((s) => s.isImport).toList();

  List<CalendarSubscription> get exportSubscriptions =>
      subscriptions.where((s) => s.isExport).toList();

  @override
  void onInit() {
    super.onInit();
    loadSubscriptions();
  }

  @override
  void onClose() {
    importUrlController.dispose();
    importLabelController.dispose();
    super.onClose();
  }

  Future<void> loadSubscriptions() async {
    if (listingId.isEmpty) {
      loading.value = false;
      return;
    }
    loading.value = true;
    await callDataService(
      _repository.getCalendarSubscriptions(listingId),
      onSuccess: (GeneralResponse res) {
        subscriptions.assignAll(_parseSubscriptions(res));
      },
    );
    loading.value = false;
  }

  List<CalendarSubscription> _parseSubscriptions(GeneralResponse res) {
    final data = res.data;
    if (data is! Map) return [];
    final raw = data['subscriptions'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => CalendarSubscription.fromJson(Map<String, dynamic>.from(e)))
        .where((s) => s.id.isNotEmpty)
        .toList();
  }

  CalendarSubscription? _parseSubscriptionData(GeneralResponse res) {
    final data = res.data;
    if (data is! Map) return null;
    return CalendarSubscription.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> addImportSubscription() async {
    final url = importUrlController.text.trim();
    if (url.isEmpty) {
      showErrorMessage('Paste your Airbnb (or other) calendar URL');
      return;
    }
    if (!url.startsWith('http')) {
      showErrorMessage('URL must start with http:// or https://');
      return;
    }
    final label = importLabelController.text.trim();
    await callDataService(
      _repository.createCalendarSubscription(
        CreateCalendarSubscriptionRequest(
          listingId: listingId,
          direction: 'IMPORT',
          sourceUrl: url,
          label: label.isEmpty ? null : label,
        ),
      ),
      onSuccess: (GeneralResponse res) {
        final sub = _parseSubscriptionData(res);
        if (sub != null) {
          subscriptions.insert(0, sub);
        }
        importUrlController.clear();
        importLabelController.clear();
        showSuccessMessage(res.message ?? 'Import calendar linked');
        loadSubscriptions();
      },
    );
  }

  Future<void> createExportSubscription() async {
    await callDataService(
      _repository.createCalendarSubscription(
        CreateCalendarSubscriptionRequest(
          listingId: listingId,
          direction: 'EXPORT',
          label: 'HostBora export',
        ),
      ),
      onSuccess: (GeneralResponse res) {
        final sub = _parseSubscriptionData(res);
        if (sub != null) {
          subscriptions.insert(0, sub);
        }
        showSuccessMessage(res.message ?? 'Export calendar created');
        loadSubscriptions();
      },
    );
  }

  Future<void> syncListing() async {
    if (listingId.isEmpty) return;
    syncing.value = true;
    await callDataService(
      _repository.syncCalendarImport(CalendarSyncRequest(listingId: listingId)),
      onSuccess: (GeneralResponse res) {
        _handleSyncResponse(res);
        loadSubscriptions();
        _notifyHostCalendarRefresh();
      },
    );
    syncing.value = false;
  }

  Future<void> syncSubscription(CalendarSubscription sub) async {
    syncing.value = true;
    await callDataService(
      _repository.syncCalendarImport(
        CalendarSyncRequest(subscriptionId: sub.id),
      ),
      onSuccess: (GeneralResponse res) {
        _handleSyncResponse(res);
        loadSubscriptions();
        _notifyHostCalendarRefresh();
      },
    );
    syncing.value = false;
  }

  void _handleSyncResponse(GeneralResponse res) {
    final results = _parseSyncResults(res);
    if (results.isEmpty) {
      showSuccessMessage(res.message ?? 'Sync completed');
      return;
    }
    final failed = results.where((r) => r.status == 'FAILED').length;
    final ok = results.length - failed;
    if (failed == 0) {
      final imported = results.fold<int>(0, (s, r) => s + r.importedCount);
      showSuccessMessage(
        imported > 0
            ? 'Synced $ok feed(s), $imported event(s) imported'
            : (res.message ?? 'Sync completed'),
      );
    } else {
      showErrorMessage('$ok succeeded, $failed failed. Check subscription status.');
    }
  }

  List<CalendarSyncResult> _parseSyncResults(GeneralResponse res) {
    final data = res.data;
    if (data is Map && data['results'] is List) {
      return (data['results'] as List)
          .whereType<Map>()
          .map((e) => CalendarSyncResult.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (data is Map && data['subscriptionId'] != null) {
      return [
        CalendarSyncResult.fromJson(Map<String, dynamic>.from(data)),
      ];
    }
    return [];
  }

  /// Refreshes host calendar bookings; imported iCal blocks are server-only until a blocks API exists.
  void _notifyHostCalendarRefresh() {
    if (Get.isRegistered<HostCalendarController>()) {
      Get.find<HostCalendarController>().loadCalendarData();
    }
  }

  Future<void> deleteSubscription(CalendarSubscription sub) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Remove calendar link?'),
        content: Text(
          sub.isExport
              ? 'Airbnb will stop receiving blocked dates from this export URL.'
              : 'Imported external blocks for this feed will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await callDataService(
      _repository.deleteCalendarSubscription(sub.id),
      onSuccess: (_) {
        subscriptions.removeWhere((s) => s.id == sub.id);
        showSuccessMessage('Calendar link removed');
      },
    );
  }

  Future<void> copyExportUrl(String url) async {
    if (url.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: url));
    showSuccessMessage('Export URL copied');
  }

  String formatLastSync(CalendarSubscription sub) {
    final ms = sub.lastSyncAtMs;
    if (ms == null) return 'Never synced';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final when = DateFormat.yMMMd().add_jm().format(dt);
    final status = (sub.lastSyncStatus ?? '').trim();
    if (status.isEmpty) return when;
    return '$when · $status';
  }
}
