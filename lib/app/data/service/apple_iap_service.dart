import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import '../../core/config/subscription_payment_config.dart';
import '../repository/app_repository.dart';

/// Outcome of an App Store subscription purchase attempt.
class ApplePurchaseResult {
  const ApplePurchaseResult._({
    required this.success,
    required this.canceled,
    this.message,
  });

  final bool success;
  final bool canceled;
  final String? message;

  factory ApplePurchaseResult.ok() =>
      const ApplePurchaseResult._(success: true, canceled: false);

  factory ApplePurchaseResult.canceled() => const ApplePurchaseResult._(
        success: false,
        canceled: true,
        message: 'Purchase canceled.',
      );

  factory ApplePurchaseResult.failed(String message) => ApplePurchaseResult._(
        success: false,
        canceled: false,
        message: message,
      );
}

/// Handles App Store auto-renewable subscriptions on iOS.
class AppleIapService extends GetxService {
  AppleIapService()
      : _repository = Get.find(tag: (AppRepository).toString());

  final AppRepository _repository;
  InAppPurchasePlatform get _iap => InAppPurchasePlatform.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Completer<ApplePurchaseResult>? _activePurchase;
  String? _activeProductId;

  final products = <String, ProductDetails>{}.obs;
  final storeAvailable = false.obs;
  final loadingProducts = false.obs;
  String? _lastProductQueryError;
  List<String> _lastNotFoundIds = const [];

  /// Must run once before any IAP calls (StoreKit plugin is not auto-registered
  /// when using `in_app_purchase_storekit` without the umbrella package).
  static void registerPlatform() {
    if (kIsWeb) return;
    try {
      InAppPurchaseStoreKitPlatform.registerPlatform();
    } catch (_) {
      // Already registered / unsupported platform.
    }
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    if (!SubscriptionPaymentConfig.usesAppleIap) return;

    try {
      registerPlatform();
      storeAvailable.value = await _iap.isAvailable();
      if (!storeAvailable.value) return;

      _purchaseSub = _iap.purchaseStream.listen(
        _onPurchaseUpdates,
        onError: (Object e) {
          _completeActivePurchase(
            ApplePurchaseResult.failed(
              'App Store error: $e. Please try again.',
            ),
          );
        },
      );
      await loadProducts();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppleIAP] init failed: $e');
      }
      storeAvailable.value = false;
    }
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
      _lastProductQueryError = response.error?.message;
      _lastNotFoundIds = List<String>.from(response.notFoundIDs);
      if (response.error != null) {
        if (kDebugMode) {
          debugPrint('[AppleIAP] queryProductDetails error: ${response.error}');
        }
      }
      if (response.notFoundIDs.isNotEmpty && kDebugMode) {
        debugPrint('[AppleIAP] products not found: ${response.notFoundIDs}');
      }
      if (response.productDetails.isNotEmpty) {
        products.assignAll({
          for (final p in response.productDetails) p.id: p,
        });
      }
      if (kDebugMode) {
        debugPrint(
          '[AppleIAP] loaded ${response.productDetails.length}/'
          '${AppleIapProducts.all.length} products '
          '(ids=${response.productDetails.map((p) => p.id).toList()})',
        );
      }
    } finally {
      loadingProducts.value = false;
    }
  }

  String? storePriceForPlan(String plan) {
    final id = AppleIapProducts.productIdForPlan(plan);
    return products[id]?.price;
  }

  /// Starts an App Store purchase for [plan] and verifies it with the backend.
  Future<ApplePurchaseResult> purchasePlan(String plan) async {
    if (!SubscriptionPaymentConfig.usesAppleIap) {
      return ApplePurchaseResult.failed(
        'In-app purchases are only available on iOS.',
      );
    }
    registerPlatform();
    if (!storeAvailable.value) {
      storeAvailable.value = await _iap.isAvailable();
    }
    if (!storeAvailable.value) {
      return ApplePurchaseResult.failed(
        'App Store is unavailable on this device. Check your connection and Apple ID, then try again.',
      );
    }

    final normalizedPlan = plan.trim().toLowerCase();
    final productId = AppleIapProducts.productIdForPlan(normalizedPlan);
    ProductDetails? details = products[productId];
    details ??= await _fetchProduct(productId);
    if (details == null) {
      await loadProducts();
      details = products[productId] ?? await _fetchProduct(productId);
    }
    if (details == null) {
      return ApplePurchaseResult.failed(_productMissingMessage(productId));
    }

    if (_activePurchase != null && !_activePurchase!.isCompleted) {
      return ApplePurchaseResult.failed(
        'A purchase is already in progress. Please wait, then try again.',
      );
    }
    _activePurchase = Completer<ApplePurchaseResult>();
    _activeProductId = productId;

    try {
      final param = PurchaseParam(productDetails: details);
      final started = await _iap.buyNonConsumable(purchaseParam: param);
      if (!started) {
        final result = ApplePurchaseResult.failed(
          'Could not start the App Store purchase. Please try again.',
        );
        _completeActivePurchase(result);
        return result;
      }

      return await _activePurchase!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          final result = ApplePurchaseResult.failed(
            'Purchase timed out. If you were charged, tap Restore Purchases, otherwise try again.',
          );
          _completeActivePurchase(result);
          return result;
        },
      );
    } catch (e) {
      final result = ApplePurchaseResult.failed(
        'Purchase failed: $e. Please try again.',
      );
      _completeActivePurchase(result);
      return result;
    }
  }

  String _productMissingMessage(String productId) {
    if (kDebugMode) {
      debugPrint(
        '[AppleIAP] missing product=$productId '
        'notFound=$_lastNotFoundIds error=$_lastProductQueryError',
      );
    }
    final err = (_lastProductQueryError ?? '').trim();
    if (err.isNotEmpty) {
      return 'Could not load "$productId" from the App Store ($err). '
          'Confirm the Product ID in App Store Connect, then try again.';
    }
    return 'Could not load "$productId" from the App Store. '
        'For local debug, select HostBoraProducts.storekit in the Xcode scheme. '
        'For TestFlight, confirm that Product ID exists and Paid Apps is Active.';
  }

  Future<void> restorePurchases() async {
    if (!SubscriptionPaymentConfig.usesAppleIap) return;
    registerPlatform();
    if (!storeAvailable.value) {
      storeAvailable.value = await _iap.isAvailable();
    }
    if (!storeAvailable.value) return;
    await _iap.restorePurchases();
  }

  Future<ProductDetails?> _fetchProduct(String productId) async {
    final response = await _iap.queryProductDetails({productId});
    _lastProductQueryError = response.error?.message ?? _lastProductQueryError;
    if (response.notFoundIDs.isNotEmpty) {
      _lastNotFoundIds = List<String>.from(response.notFoundIDs);
    }
    if (response.error != null && kDebugMode) {
      debugPrint('[AppleIAP] fetch "$productId" error: ${response.error}');
    }
    if (response.productDetails.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[AppleIAP] fetch "$productId" returned empty '
          '(notFound=${response.notFoundIDs})',
        );
      }
      return null;
    }
    final details = response.productDetails.first;
    products[productId] = details;
    return details;
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      // Ignore updates for other products while a specific purchase is active.
      if (_activeProductId != null &&
          purchase.productID != _activeProductId &&
          purchase.status != PurchaseStatus.restored) {
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.error:
          final err = purchase.error;
          final msg = err == null ? '' : err.message.trim();
          _completeActivePurchase(
            ApplePurchaseResult.failed(
              msg.isNotEmpty
                  ? '$msg Please try again.'
                  : 'App Store purchase failed. Please try again.',
            ),
          );
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.canceled:
          _completeActivePurchase(ApplePurchaseResult.canceled());
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final verify = await _verifyWithServer(purchase);
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          if (verify.success) {
            _completeActivePurchase(ApplePurchaseResult.ok());
          } else {
            _completeActivePurchase(
              ApplePurchaseResult.failed(
                verify.message ??
                    'Purchase succeeded in App Store but could not activate the plan. Please try again or restore purchases.',
              ),
            );
          }
          break;
      }
    }
  }

  Future<({bool success, String? message})> _verifyWithServer(
    PurchaseDetails purchase,
  ) async {
    final productId = purchase.productID;
    final signedInfo = purchase.verificationData.serverVerificationData;
    final transactionId = _resolveTransactionId(purchase, signedInfo);
    if (transactionId == null || transactionId.isEmpty) {
      return (
        success: false,
        message:
            'Missing App Store transaction id. Please try again or restore purchases.',
      );
    }

    try {
      final resp = await _repository.verifyAppleSubscription(
        productId: productId,
        transactionId: transactionId,
        signedTransactionInfo: signedInfo,
      );
      final ok = resp.responseCode == '201' ||
          resp.responseCode == '0' ||
          resp.responseCode == '200';
      if (ok) return (success: true, message: null);
      final serverMsg = (resp.message ?? '').trim();
      return (
        success: false,
        message: serverMsg.isNotEmpty
            ? '$serverMsg Please try again.'
            : 'Server could not activate the plan (code ${resp.responseCode}). Please try again.',
      );
    } catch (e) {
      return (
        success: false,
        message:
            'Could not reach the server to activate your plan. Check your connection and try again.',
      );
    }
  }

  /// Prefer StoreKit purchaseID; fall back to transactionId inside the JWS.
  String? _resolveTransactionId(PurchaseDetails purchase, String signedInfo) {
    final direct = purchase.purchaseID?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    return _transactionIdFromJws(signedInfo);
  }

  String? _transactionIdFromJws(String jws) {
    if (jws.trim().isEmpty) return null;
    try {
      final parts = jws.split('.');
      if (parts.length < 2) return null;
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      final mod = payload.length % 4;
      if (mod > 0) payload += '=' * (4 - mod);
      final decoded = utf8.decode(base64.decode(payload));
      final map = jsonDecode(decoded);
      if (map is! Map) return null;
      final tx = (map['transactionId'] ?? map['originalTransactionId'] ?? '')
          .toString()
          .trim();
      return tx.isEmpty ? null : tx;
    } catch (_) {
      return null;
    }
  }

  void _completeActivePurchase(ApplePurchaseResult value) {
    if (_activePurchase != null && !_activePurchase!.isCompleted) {
      _activePurchase!.complete(value);
    }
    _activePurchase = null;
    _activeProductId = null;
  }
}
