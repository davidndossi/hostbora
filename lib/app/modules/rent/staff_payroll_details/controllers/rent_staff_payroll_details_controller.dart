import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/rent_staff_local_data_source.dart';
import '../../../../data/local/service/currency_service.dart';
import '../../staff_management/utils/rent_staff_pay_format.dart';

/// One row for the payroll breakdown list.
class RentStaffPayrollUiRow {
  const RentStaffPayrollUiRow({
    required this.name,
    required this.jobTitle,
    required this.payLabel,
    this.payDayNote,
  });

  final String name;
  final String jobTitle;
  final String payLabel;
  final String? payDayNote;

  String get initial {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t[0].toUpperCase();
  }
}

class RentStaffPayrollDetailsController extends BaseController {
  RentStaffPayrollDetailsController()
      : _local = Get.find<RentStaffLocalDataSource>(),
        _currency = Get.find<CurrencyService>();

  final RentStaffLocalDataSource _local;
  final CurrencyService _currency;

  final rows = <RentStaffPayrollUiRow>[].obs;
  final payPeriodLabel = ''.obs;
  final totalMonthlySalaryPool = 0.0.obs;
  final monthlyContractCount = 0.obs;
  final loading = true.obs;

  @override
  void onInit() {
    super.onInit();
    payPeriodLabel.value = _buildPayPeriodLabel();
  }

  @override
  void onReady() {
    super.onReady();
    loadPayroll();
  }

  String _buildPayPeriodLabel() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    final locale = Get.locale?.toString() ?? 'en_US';
    final fmt = DateFormat.MMMd(locale);
    return '${fmt.format(start)} – ${fmt.format(end)}, ${now.year}';
  }

  String _formatPayLine(RentStaffRecord r) {
    if (r.amountValue > 0 && r.paymentType == RentStaffPayFormat.monthly) {
      return _currency.formatBase(r.amountValue.round());
    }
    return r.displayAmountLine;
  }

  String? _payDayNote(RentStaffRecord r) {
    final raw = r.payDayLabel.trim();
    if (raw.isEmpty) return null;
    return RentStaffPayFormat.payDayLine(raw);
  }

  Future<void> loadPayroll() async {
    loading.value = true;
    try {
      final records = await _local.getAllNewestFirst();
      payPeriodLabel.value = _buildPayPeriodLabel();

      var monthlyTotal = 0.0;
      var monthlyCount = 0;
      final out = <RentStaffPayrollUiRow>[];

      for (final r in records) {
        if (r.paymentType == RentStaffPayFormat.monthly && r.amountValue > 0) {
          monthlyTotal += r.amountValue;
          monthlyCount++;
        }
        out.add(
          RentStaffPayrollUiRow(
            name: r.name.trim().isEmpty ? '—' : r.name.trim(),
            jobTitle: r.jobTitle.trim().isEmpty ? '—' : r.jobTitle.trim(),
            payLabel: _formatPayLine(r),
            payDayNote: _payDayNote(r),
          ),
        );
      }

      rows.assignAll(out);
      totalMonthlySalaryPool.value = monthlyTotal;
      monthlyContractCount.value = monthlyCount;
    } catch (e, st) {
      logger.e('loadPayroll $e $st');
      rows.clear();
      totalMonthlySalaryPool.value = 0;
      monthlyContractCount.value = 0;
      showErrorMessage('Could not load payroll');
    } finally {
      loading.value = false;
    }
  }

  String get totalMonthlyFormatted =>
      _currency.formatBase(totalMonthlySalaryPool.value.round());
}
