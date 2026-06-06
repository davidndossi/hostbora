import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../core/base/feedback_extensions.dart';
import '../../../../data/local/db/expense_local_data_source.dart';
import '../../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../../routes/app_pages.dart';
import '../../../listing_details/services/listing_activity_loader.dart';
import '../../../listing_details/models/listing_activity_vm.dart';

class RentListingActivityLogController extends BaseController {
  RentListingActivityLogController()
    : _loader = ListingActivityLoader(),
      _expenseLocal = Get.find<ExpenseLocalDataSource>(),
      _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>();

  final ListingActivityLoader _loader;
  final ExpenseLocalDataSource _expenseLocal;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  late final ListingActivityScope scope =
      ListingActivityScope.fromRoute();

  final activities = <ListingActivityVm>[].obs;
  final loading = true.obs;

  String get screenTitle {
    final name = scope.propertyName.trim();
    if (name.isEmpty) return appLocalization.rentListingActivityLogTitle;
    return name;
  }

  @override
  void onReady() {
    super.onReady();
    loadActivities();
  }

  Future<void> loadActivities() async {
    loading.value = true;
    try {
      activities.assignAll(await _loader.load(scope: scope));
    } finally {
      loading.value = false;
    }
  }

  Future<void> editExpenseActivity(ListingActivityVm activity) async {
    final id = activity.expenseId;
    if (id == null) return;
    await Get.toNamed(
      Routes.ADD_EXPENSE,
      arguments: {'mode': 'edit', 'expenseId': id},
    );
    await loadActivities();
  }

  Future<void> deleteExpenseActivity(ListingActivityVm activity) async {
    final id = activity.expenseId;
    if (id == null) return;
    final confirmed = await confirmDestructive(
      title: scope.isSw ? 'Futa gharama?' : 'Delete expense?',
      message: scope.isSw
          ? 'Gharama hii itaondolewa kwenye shughuli na hesabu za mwezi.'
          : 'This expense will be removed from activity and monthly totals.',
      confirmLabel: scope.isSw ? 'Futa' : 'Delete',
      cancelLabel: scope.isSw ? 'Ghairi' : 'Cancel',
    );
    if (!confirmed) return;
    await _expenseLocal.deleteById(id);
    await _syncQueue.deleteByDedupeKey('expense:create:$id');
    showSuccessWithHaptic(scope.isSw ? 'Gharama imefutwa' : 'Expense deleted');
    await loadActivities();
  }

  static Future<void> refreshIfRegistered() async {
    if (!Get.isRegistered<RentListingActivityLogController>()) return;
    await Get.find<RentListingActivityLogController>().loadActivities();
  }
}
