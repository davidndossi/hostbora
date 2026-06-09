import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/db/client_event_local_data_source.dart';
import '../../../data/local/db/tenant_rating_local_data_source.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/db/tenant_local_data_source.dart';

/// Represents one node in the story timeline.
class StoryEventVm {
  const StoryEventVm({
    required this.id,
    required this.eventType,
    required this.title,
    required this.subtitle,
    required this.amountLabel,
    required this.balanceLabel,
    required this.createdAtMs,
    this.metadata = const {},
  });

  final int id;
  final ClientEventType eventType;
  final String title;
  final String subtitle;
  final String amountLabel;
  final String balanceLabel;
  final int createdAtMs;
  final Map<String, dynamic> metadata;

  bool get isPayment =>
      eventType == ClientEventType.paymentPartial ||
      eventType == ClientEventType.paymentFull ||
      eventType == ClientEventType.balanceCleared;

  bool get isReminder => eventType == ClientEventType.reminderSent;
  bool get isStart =>
      eventType == ClientEventType.tenantAdded ||
      eventType == ClientEventType.leaseStarted ||
      eventType == ClientEventType.bookingCreated ||
      eventType == ClientEventType.checkIn;
  bool get isEnd =>
      eventType == ClientEventType.leaseEnded ||
      eventType == ClientEventType.checkOut;
}

class ClientStoryController extends BaseController {
  ClientStoryController()
    : _eventLocal = Get.find<ClientEventLocalDataSource>(),
      _ratingLocal = Get.find<TenantRatingLocalDataSource>(),
      _incomeLocal = Get.find<IncomeLocalDataSource>(),
      _tenantLocal = Get.find<TenantLocalDataSource>();

  final ClientEventLocalDataSource _eventLocal;
  final TenantRatingLocalDataSource _ratingLocal;
  final IncomeLocalDataSource _incomeLocal;
  final TenantLocalDataSource _tenantLocal;

  final events = <StoryEventVm>[].obs;
  final tenantName = ''.obs;
  final phoneNumber = ''.obs;
  final rating = Rxn<TenantRatingRecord>();
  final totalPaid = ''.obs;
  final totalStays = 0.obs;
  final durationLabel = ''.obs;
  final isLoading = true.obs;

  int _tenantId = 0;
  String _workspace = 'rent';

  @override
  void onInit() {
    super.onInit();
    _tenantId = int.tryParse(Get.parameters['tenantId'] ?? '') ?? 0;
    final args = Get.arguments;
    if (args is Map) {
      _tenantId = args['tenantId'] as int? ?? _tenantId;
      _workspace = (args['workspace'] ?? 'rent').toString();
    }
    tenantName.value = Get.parameters['name'] ?? '';
    phoneNumber.value = Get.parameters['phone'] ?? '';
    _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final phone = phoneNumber.value.trim();
      final rawEvents = _tenantId > 0
          ? await _eventLocal.getByTenantLocalId(_tenantId)
          : phone.isNotEmpty
          ? await _eventLocal.getByPhone(phone)
          : <ClientEventRecord>[];

      // If no recorded events, synthesize from existing tenant + income records
      final synthesized = await _synthesizeIfEmpty(rawEvents, phone);

      events.value = synthesized.map(_toVm).toList();

      // Rating
      if (_tenantId > 0) {
        rating.value = await _ratingLocal.findByTenantId(_tenantId);
      }

      // Summary stats
      int paidSum = 0;
      for (final e in synthesized) {
        if (e.eventType == ClientEventType.paymentPartial ||
            e.eventType == ClientEventType.paymentFull) {
          paidSum += e.amountTsh;
        }
      }
      final fmt = _formatCurrency(paidSum);
      totalPaid.value = fmt;
      totalStays.value = synthesized
          .where((e) => e.eventType == ClientEventType.leaseEnded ||
              e.eventType == ClientEventType.checkOut)
          .length;

      // Duration label from first to last event
      if (synthesized.isNotEmpty) {
        final first = DateTime.fromMillisecondsSinceEpoch(
          synthesized.first.createdAtMs,
        );
        final last = DateTime.fromMillisecondsSinceEpoch(
          synthesized.last.createdAtMs,
        );
        final days = last.difference(first).inDays.abs();
        durationLabel.value = days > 30
            ? '${(days / 30).floor()} months'
            : '$days days';
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  /// Build synthetic events from tenant + income records when client_event table is empty.
  Future<List<ClientEventRecord>> _synthesizeIfEmpty(
    List<ClientEventRecord> existing,
    String phone,
  ) async {
    if (existing.isNotEmpty) return existing;
    final synth = <ClientEventRecord>[];
    if (_tenantId > 0) {
      final tenant = await _tenantLocal.findById(_tenantId);
      if (tenant != null) {
        // tenant_added event
        synth.add(
          ClientEventRecord(
            id: 0,
            tenantLocalId: tenant.id,
            phoneNumber: tenant.phoneNumber,
            clientName: tenant.tenantName,
            propertyRef: tenant.propertyRef,
            propertyLabel: tenant.propertyLabel,
            unitLabel: tenant.unitLabel,
            workspace: _workspace,
            eventType: ClientEventType.tenantAdded,
            amountTsh: 0,
            balanceBefore: 0,
            balanceAfter: 0,
            metadataJson: '{}',
            syncStatus: 'local',
            createdAtMs: tenant.createdAtMs,
          ),
        );
      }
      // income payments
      final incomes = await _getIncomes(tenant?.propertyRef ?? '');
      final tenantIncomes = incomes
          .where(
            (i) =>
                i.tenantName.toLowerCase() ==
                (tenant?.tenantName ?? '').toLowerCase(),
          )
          .toList()
        ..sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));

      int runningBalance = tenant != null
          ? (tenant.rentAmountValue * 1).round()
          : 0;
      for (final inc in tenantIncomes) {
        final amt = inc.amountValue.round();
        final before = runningBalance;
        runningBalance = (runningBalance - amt).clamp(0, 999999999);
        synth.add(
          ClientEventRecord(
            id: 0,
            tenantLocalId: _tenantId,
            phoneNumber: phone,
            clientName: tenant?.tenantName ?? '',
            propertyRef: inc.propertyRef,
            propertyLabel: inc.apartment,
            unitLabel: inc.apartmentUnit,
            workspace: inc.workspaceType,
            eventType: runningBalance == 0
                ? ClientEventType.balanceCleared
                : ClientEventType.paymentPartial,
            amountTsh: amt,
            balanceBefore: before,
            balanceAfter: runningBalance,
            metadataJson: '{"category":"${inc.category}"}',
            syncStatus: 'local',
            createdAtMs: inc.createdAtMs,
          ),
        );
      }
    }
    return synth..sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));
  }

  StoryEventVm _toVm(ClientEventRecord e) {
    return StoryEventVm(
      id: e.id,
      eventType: e.eventType,
      title: _eventTitle(e.eventType),
      subtitle: _eventSubtitle(e),
      amountLabel: e.amountTsh > 0 ? _formatCurrency(e.amountTsh) : '',
      balanceLabel: e.balanceAfter > 0
          ? 'Balance: ${_formatCurrency(e.balanceAfter)}'
          : '',
      createdAtMs: e.createdAtMs,
      metadata: e.metadata,
    );
  }

  String _eventTitle(ClientEventType t) {
    switch (t) {
      case ClientEventType.tenantAdded:
        return 'Tenant Added';
      case ClientEventType.bookingCreated:
        return 'Booking Created';
      case ClientEventType.checkIn:
        return 'Checked In';
      case ClientEventType.leaseStarted:
        return 'Lease Started';
      case ClientEventType.paymentPartial:
        return 'Partial Payment';
      case ClientEventType.paymentFull:
        return 'Full Payment';
      case ClientEventType.balanceCleared:
        return 'Balance Cleared';
      case ClientEventType.reminderSent:
        return 'Reminder Sent';
      case ClientEventType.leaseEnded:
        return 'Tenancy Ended';
      case ClientEventType.checkOut:
        return 'Checked Out';
      case ClientEventType.leaseRenewed:
        return 'Lease Renewed';
    }
  }

  String _eventSubtitle(ClientEventRecord e) {
    final meta = e.metadata;
    switch (e.eventType) {
      case ClientEventType.reminderSent:
        final channel = meta['channel'] as String? ?? 'app';
        return 'Via $channel';
      case ClientEventType.leaseEnded:
        final handling = meta['balanceHandling'] as String? ?? '';
        if (handling == 'written_off') return 'Balance written off';
        if (handling == 'cleared') return 'Balance cleared at exit';
        return '';
      case ClientEventType.paymentPartial:
      case ClientEventType.paymentFull:
      case ClientEventType.balanceCleared:
        final cat = meta['category'] as String? ?? '';
        return cat.isNotEmpty ? cat : '';
      default:
        final notes = meta['notes'] as String? ?? '';
        return notes;
    }
  }

  String _formatCurrency(int tsh) {
    if (tsh >= 1000000) {
      return 'Tsh ${(tsh / 1000000).toStringAsFixed(1)}M';
    }
    if (tsh >= 1000) {
      return 'Tsh ${(tsh / 1000).toStringAsFixed(0)}K';
    }
    return 'Tsh $tsh';
  }

  Future<List<IncomeRecord>> _getIncomes(String propertyRef) async {
    if (propertyRef.isEmpty) return [];
    return _incomeLocal.getAllByPropertyRefAndWorkspace(
      propertyRef: propertyRef,
      workspaceType: _workspace,
    );
  }

  @override
  void refresh() => _load();
}
