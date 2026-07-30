import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../core/base/feedback_extensions.dart';
import '../../../../data/local/db/rent_loyalty_offer_local_data_source.dart';
import '../../../../data/local/service/currency_service.dart';
import '../../../../routes/app_pages.dart';

class ActiveLoyaltyProgramItem {
  const ActiveLoyaltyProgramItem({
    required this.id,
    required this.title,
    required this.thresholdLabel,
    required this.rewardLabel,
    required this.terms,
    required this.createdAtMs,
    required this.minStayMonths,
    required this.revenueThresholdTsh,
  });

  final int id;
  final String title;
  final String thresholdLabel;
  final String rewardLabel;
  final String terms;
  final int createdAtMs;
  final int minStayMonths;
  final double revenueThresholdTsh;
}

class RentActiveLoyaltyProgramsController extends BaseController {
  RentActiveLoyaltyProgramsController()
      : _loyaltyLocal = Get.find<RentLoyaltyOfferLocalDataSource>();

  final RentLoyaltyOfferLocalDataSource _loyaltyLocal;
  final offers = <ActiveLoyaltyProgramItem>[].obs;
  final loading = true.obs;

  int get activeProgramsCount => offers.length;
  int get activeClaimsCount => offers.length;
  String get retentionRateLabel => offers.isEmpty ? '0%' : '100%';
  String get valueDistributedLabel {
    final total = offers.fold<double>(0, (sum, e) {
      final raw = e.rewardLabel.replaceAll(RegExp(r'[^0-9.]'), '');
      final parsed = double.tryParse(raw) ?? 0;
      return sum + parsed;
    });
    if (total <= 0) return '0';
    return NumberFormat.compact().format(total);
  }

  @override
  void onReady() {
    super.onReady();
    loadOffers();
  }

  Future<void> loadOffers() async {
    loading.value = true;
    try {
      final rows = await _loyaltyLocal.getAllNewestFirst();
      offers.assignAll(
        rows.map(
          (r) => ActiveLoyaltyProgramItem(
            id: r.id,
            title: r.offerType.trim().isEmpty ? 'Loyalty Offer #${r.id}' : r.offerType.trim(),
            thresholdLabel: '${r.minStayMonths} month(s) stay',
            rewardLabel: Get.find<CurrencyService>()
                .formatBase(r.revenueThresholdTsh.round()),
            terms: r.terms.trim(),
            createdAtMs: r.createdAtMs,
            minStayMonths: r.minStayMonths,
            revenueThresholdTsh: r.revenueThresholdTsh,
          ),
        ),
      );
    } finally {
      loading.value = false;
    }
  }

  void onCreateNewOffer() {
    Get.toNamed(Routes.RENT_DEFINE_LOYALTY_OFFERS);
  }

  void onViewAnalytics() {}

  void onEditReferralProgram() {}

  void onOpenMenu() {}

  void onOpenNotifications() {}

  void onOpenProfile() {}

  Future<void> deleteOffer(int id) async {
    ActiveLoyaltyProgramItem? offer;
    for (final o in offers) {
      if (o.id == id) {
        offer = o;
        break;
      }
    }
    final offerCopy = offer;
    if (offerCopy == null) return;

    final confirmed = await confirmDestructive(
      title: 'Delete loyalty offer?',
      message: 'Remove "${offerCopy.title}"?',
      confirmLabel: 'Delete',
    );
    if (!confirmed) return;

    await runDestructiveWithUndo(
      message: 'Offer deleted',
      action: () async {
        await _loyaltyLocal.deleteById(id);
        await loadOffers();
      },
      onUndo: () async {
        await _loyaltyLocal.insert(
          minStayMonths: offerCopy.minStayMonths,
          revenueThresholdTsh: offerCopy.revenueThresholdTsh,
          offerType: offerCopy.title,
          terms: offerCopy.terms,
        );
        await loadOffers();
      },
    );
  }

  Future<void> openEditOfferDialog(ActiveLoyaltyProgramItem offer) async {
    final minStayController = TextEditingController(text: offer.minStayMonths.toString());
    final revenueController = TextEditingController(
      text: offer.revenueThresholdTsh.toStringAsFixed(0),
    );
    final typeController = TextEditingController(text: offer.title);
    final termsController = TextEditingController(text: offer.terms);

    await Get.dialog(
      AlertDialog(
        title: const Text('Edit loyalty offer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minStayController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Min stay months',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: revenueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText:
                      'Revenue threshold (${Get.find<CurrencyService>().inputSuffix})',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: typeController,
                decoration: const InputDecoration(
                  labelText: 'Offer type',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: termsController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Terms',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final minStay = int.tryParse(minStayController.text.trim());
              final revenue = double.tryParse(revenueController.text.trim().replaceAll(',', ''));
              final type = typeController.text.trim();
              final terms = termsController.text.trim();
              if (minStay == null || minStay <= 0) {
                showErrorMessage('Enter valid minimum stay');
                return;
              }
              if (revenue == null || revenue < 0) {
                showErrorMessage('Enter valid revenue threshold');
                return;
              }
              if (type.isEmpty || terms.isEmpty) {
                showErrorMessage('Offer type and terms are required');
                return;
              }
              await _loyaltyLocal.update(
                id: offer.id,
                minStayMonths: minStay,
                revenueThresholdTsh: revenue,
                offerType: type,
                terms: terms,
              );
              Get.back();
              await loadOffers();
              showSuccessMessage('Offer updated');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
