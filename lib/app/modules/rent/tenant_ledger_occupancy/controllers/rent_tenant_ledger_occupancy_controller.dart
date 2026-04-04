import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../routes/app_pages.dart';

class RentTenantLedgerOccupancyController extends BaseController {
  final tenantName = ''.obs;
  final propertyLine = ''.obs;

  @override
  void onInit() {
    super.onInit();
    tenantName.value = Get.parameters['name'] ?? '';
    propertyLine.value = Get.parameters['property'] ?? '';
  }

  String get displayTenantName =>
      tenantName.value.isEmpty ? 'Amara Okafor' : tenantName.value;

  /// Full line for residence card / subtitles.
  String get displayPropertyFull {
    final p = propertyLine.value;
    return p.isEmpty ? 'Sea View Apartment, Unit 402' : p;
  }

  /// Bold fragment in overview copy (text before first comma if present).
  String get propertyShortPhrase {
    final full = displayPropertyFull;
    final i = full.indexOf(',');
    if (i > 0) return full.substring(0, i).trim();
    return full;
  }

  static const residencyCity = 'Dar es Salaam';

  /// Demo figures — replace with API.
  static const remainingBalanceTsh = 400000;
  static const totalDueTsh = 1200000;
  static const totalPaidTsh = 800000;

  static const currentStayMonths = 4;
  static const currentLeaseMonths = 6;
  static const tenancyRangeLabel = 'May 2024 - Present';

  void openPaymentReminder() {
    Get.toNamed(
      Routes.RENT_SCHEDULE_PAYMENT_REMINDER,
      parameters: {
        'name': displayTenantName,
        'property': displayPropertyFull,
        'balance': '$remainingBalanceTsh',
      },
    );
  }
}
