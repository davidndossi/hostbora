import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/service/currency_service.dart';

class GuestHistoryItem {
  const GuestHistoryItem({
    required this.tenantId,
    required this.guestName,
    required this.propertyLabel,
    required this.unitLabel,
    required this.checkInIso,
    required this.checkOutIso,
    required this.checkInDisplay,
    required this.checkOutDisplay,
    required this.nights,
    required this.amountDue,
    required this.amountPaid,
    required this.paymentStatus,
    required this.phoneNumber,
  });

  final int tenantId;
  final String guestName;
  final String propertyLabel;
  final String unitLabel;
  final String checkInIso;
  final String checkOutIso;
  final String checkInDisplay;
  final String checkOutDisplay;
  final int nights;
  final int amountDue;
  final int amountPaid;
  final String paymentStatus;
  final String phoneNumber;

  bool get isFullyPaid => amountPaid >= amountDue && amountDue > 0;
  bool get isPartial => amountPaid > 0 && amountPaid < amountDue;
  bool get isUnpaid => amountPaid <= 0;
}

class GuestHistoryController extends BaseController {
  GuestHistoryController()
      : _tenantLocal = Get.find<TenantLocalDataSource>(),
        _incomeLocal = Get.find<IncomeLocalDataSource>();

  final TenantLocalDataSource _tenantLocal;
  final IncomeLocalDataSource _incomeLocal;

  final allGuests = <GuestHistoryItem>[].obs;
  final filteredGuests = <GuestHistoryItem>[].obs;
  final searchQuery = ''.obs;
  final isLoading = false.obs;

  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void onInit() {
    super.onInit();
    loadGuestHistory();
  }

  Future<void> loadGuestHistory() async {
    isLoading.value = true;
    try {
      final bnbTenants = await _tenantLocal.getAllForBnbWorkspaceByPropertyRefJoin();
      final allIncome = <IncomeRecord>[];
      allIncome.addAll(await _incomeLocal.getAllNewestFirst(workspaceType: 'bnb'));
      allIncome.addAll(await _incomeLocal.getAllNewestFirst(workspaceType: 'rent'));

      final items = <GuestHistoryItem>[];
      for (final t in bnbTenants) {
        final checkIn = _parseDate(t.leaseStartIso);
        final checkOut = _parseDate(t.leaseEndIso);
        final nights = checkIn != null && checkOut != null
            ? checkOut.difference(checkIn).inDays.clamp(0, 99999)
            : 0;

        var paid = 0.0;
        for (final r in allIncome) {
          if (_incomeMatchesTenant(r, t)) {
            paid += r.amountValue;
          }
        }

        final amountDue = t.rentAmountValue.round();
        final amountPaid = paid.round();
        final status = amountPaid >= amountDue && amountDue > 0
            ? 'paid'
            : amountPaid > 0
                ? 'partial'
                : 'pending';

        items.add(
          GuestHistoryItem(
            tenantId: t.id,
            guestName: t.tenantName.trim(),
            propertyLabel: t.propertyLabel.trim(),
            unitLabel: t.unitLabel.trim(),
            checkInIso: t.leaseStartIso,
            checkOutIso: t.leaseEndIso,
            checkInDisplay: checkIn != null ? _dateFmt.format(checkIn) : '—',
            checkOutDisplay: checkOut != null ? _dateFmt.format(checkOut) : '—',
            nights: nights,
            amountDue: amountDue,
            amountPaid: amountPaid,
            paymentStatus: status,
            phoneNumber: t.phoneNumber,
          ),
        );
      }

      // Newest stay first (by check-in date descending).
      items.sort((a, b) => b.checkInIso.compareTo(a.checkInIso));
      allGuests.assignAll(items);
      _applyFilter();
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String value) {
    searchQuery.value = value.trim();
    _applyFilter();
  }

  void _applyFilter() {
    final q = searchQuery.value.toLowerCase();
    if (q.isEmpty) {
      filteredGuests.assignAll(allGuests);
      return;
    }
    filteredGuests.assignAll(
      allGuests.where(
        (g) =>
            g.guestName.toLowerCase().contains(q) ||
            g.propertyLabel.toLowerCase().contains(q) ||
            g.unitLabel.toLowerCase().contains(q),
      ),
    );
  }

  String formatAmount(int amount) =>
      Get.find<CurrencyService>().formatBase(amount);

  static DateTime? _parseDate(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw.trim());
    } catch (_) {
      return null;
    }
  }

  static bool _incomeMatchesTenant(IncomeRecord r, TenantRecord t) {
    final nameLower = t.tenantName.trim().toLowerCase();
    final rName = r.tenantName.trim().toLowerCase();
    if (nameLower.isNotEmpty && rName.contains(nameLower)) return true;
    if (t.id > 0) {
      final idTag = 'tenantid:${t.id}';
      if (r.notes.toLowerCase().contains(idTag)) return true;
    }
    return false;
  }
}
