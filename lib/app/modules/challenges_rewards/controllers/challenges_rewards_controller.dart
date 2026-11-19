import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/month_rent_collection.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/model/rewards_dashboard.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';

class ChallengesRewardsController extends BaseController {
  final AppRepository _repository = Get.find(tag: (AppRepository).toString());

  final dashboard = Rxn<RewardsDashboard>();
  final loading = false.obs;
  final saving = false.obs;

  bool get isSw => Get.locale?.languageCode == 'sw';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading(true);
    try {
      final response = await _repository.getRewards();
      final data = response.data;
      if (response.isSuccess && data is Map) {
        dashboard(await _withLocalCollection(
          RewardsDashboard.fromJson(Map<String, dynamic>.from(data)),
        ));
      }
    } catch (e) {
      showErrorMessage(
        isSw ? 'Imeshindikana kupakia changamoto.' : 'Could not load challenges.',
      );
    } finally {
      loading(false);
    }
  }

  Future<void> completeAcademy() async {
    saving(true);
    try {
      final response = await _repository.completeAcademy();
      final data = response.data;
      if (response.isSuccess && data is Map) {
        dashboard(await _withLocalCollection(
          RewardsDashboard.fromJson(Map<String, dynamic>.from(data)),
        ));
        showSuccessMessage(
          isSw ? 'Academy imekamilika. +HB Points' : 'Academy completed. HB Points added.',
        );
      }
    } catch (e) {
      showErrorMessage(e.toString());
    } finally {
      saving(false);
    }
  }

  Future<void> redeem(RewardCatalogItem item) async {
    final current = dashboard.value;
    if (current == null) return;
    if (current.balance < item.cost) {
      showErrorMessage(
        isSw
            ? 'HB Points hazitoshi. Unahitaji ${item.cost}.'
            : 'Not enough HB Points. You need ${item.cost}.',
      );
      return;
    }
    saving(true);
    try {
      final response = await _repository.redeemReward(item.key);
      final data = response.data;
      if (response.isSuccess && data is Map) {
        final nested = data['dashboard'];
        if (nested is Map) {
          dashboard(await _withLocalCollection(
            RewardsDashboard.fromJson(Map<String, dynamic>.from(nested)),
          ));
        } else {
          await load();
        }
        final detail = (data['redemption'] is Map)
            ? (data['redemption'] as Map)['detail']?.toString()
            : null;
        showSuccessMessage(detail ?? (isSw ? 'Zawadi imechukuliwa.' : 'Reward redeemed.'));
      }
    } catch (e) {
      showErrorMessage(e.toString());
    } finally {
      saving(false);
    }
  }

  void openAcademy() {
    Get.toNamed(Routes.HELP_CENTER);
  }

  Future<RewardsDashboard> _withLocalCollection(RewardsDashboard data) async {
    try {
      if (!Get.isRegistered<TenantLocalDataSource>() ||
          !Get.isRegistered<IncomeLocalDataSource>()) {
        return data;
      }
      final tenants = await Get.find<TenantLocalDataSource>().getAllNewestFirst();
      final incomes = await Get.find<IncomeLocalDataSource>().getAllNewestFirst();
      return MonthRentCollection.fromRecords(
        tenants: tenants,
        incomes: incomes,
      ).applyTo(data);
    } catch (_) {
      return data;
    }
  }
}
