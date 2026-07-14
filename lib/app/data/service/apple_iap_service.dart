import 'dart:async';

import 'package:get/get.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

import '../../core/config/subscription_payment_config.dart';
import '../repository/app_repository.dart';

/// Handles App Store auto-renewable subscriptions on iOS.
class AppleIapService extends GetxService {
  AppleIapService()
      : _repository = Get.find(tag: (AppRepository).toString());

  final AppRepository _repository;
  InAppPurchasePlatform get _iap => InAppPurchasePlatform.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Completer<bool>? _activePurchase;

  final products = <String, ProductDetails>{}.obs;
  final storeAvailable = false.obs;
  final loadingProducts = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    if (!SubscriptionPaymentConfig.usesAppleIap) return;

    storeAvailable.value = await _iap.isAvailable();
    if (!storeAvailable.value) return;

    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (_) => _completeActivePurchase(false),
    );
    await loadProducts();
  }

  @override
  void onClose() {
    _purchaseSub?.cancel();
    super.onClose();
  }

  Future<void> loadProducts() async {
    if (!SubscriptionPaymentConfig.usesAppleIap) return;
    loadingProducts.value = true;
    try {
      final response = await _iap.queryProductDetails(AppleIapProducts.all);
      if (response.error != null) return;
      products.assignAll({for (final p in response.productDetails) p.id: p});
    } finally {
      loadingProducts.value = false;
    }
  }

  String? storePriceForPlan(String plan) {
    final id = AppleIapProducts.productIdForPlan(plan);
    return products[id]?.price;
  }

  /// Starts an App Store purchase for [plan]. Returns true when verified server-side.
  Future<bool> purchasePlan(String plan) async {
    if (!SubscriptionPaymentConfig.usesAppleIap) return false;
    if (!storeAvailable.value) return false;

    final productId = AppleIapProducts.productIdForPlan(plan);
    ProductDetails? details = products[productId];
    details ??= await _fetchProduct(productId);
    if (details == null) return false;

    if (_activePurchase != null && !_activePurchase!.isCompleted) {
      return false;
    }
    _activePurchase = Completer<bool>();

    final param = PurchaseParam(productDetails: details);
    final started = await _iap.buyNonConsumable(purchaseParam: param);
    if (!started) {
      _completeActivePurchase(false);
      return false;
    }

    return _activePurchase!.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        _completeActivePurchase(false);
        return false;
      },
    );
  }

  Future<void> restorePurchases() async {
    if (!SubscriptionPaymentConfig.usesAppleIap || !storeAvailable.value) return;
    await _iap.restorePurchases();
  }

  Future<ProductDetails?> _fetchProduct(String productId) async {
    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isEmpty) return null;
    final details = response.productDetails.first;
    products[productId] = details;
    return details;
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.error:
          _completeActivePurchase(false);
          break;
        case PurchaseStatus.canceled:
          _completeActivePurchase(false);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final ok = await _verifyWithServer(purchase);
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          _completeActivePurchase(ok);
          break;
      }
    }
  }

  Future<bool> _verifyWithServer(PurchaseDetails purchase) async {
    final productId = purchase.productID;
    final transactionId = purchase.purchaseID ?? '';
    if (transactionId.isEmpty) return false;

    final signedInfo = purchase.verificationData.serverVerificationData;
    try {
      final resp = await _repository.verifyAppleSubscription(
        productId: productId,
        transactionId: transactionId,
        signedTransactionInfo: signedInfo,
      );
      return resp.responseCode == '201' || resp.responseCode == '0';
    } catch (_) {
      return false;
    }
  }

  void _completeActivePurchase(bool value) {
    if (_activePurchase != null && !_activePurchase!.isCompleted) {
      _activePurchase!.complete(value);
    }
    _activePurchase = null;
  }
}
