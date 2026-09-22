import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

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
  final loadError = RxnString();
  String? _lastProductQueryError;
  List<String> _lastNotFoundIds = const [];
  Future<void>? _loadInFlight;

  static bool _platformRegistered = false;

  /// StoreKit 2 often returns an empty list (reported as
  /// "Failed to get response from platform") on the first request.
  static const _catalogRetryDelays = <Duration>[
    Duration(milliseconds: 600),
    Duration(milliseconds: 1200),
  ];

  /// Must run once before any IAP calls (StoreKit plugin is not auto-registered
  /// when using `in_app_purchase_storekit` without the umbrella package).
  ///
  /// Calling this again replaces the platform instance and drops an in-flight
  /// product query, so registration is idempotent.
  static void registerPlatform() {
    if (kIsWeb || _platformRegistered) return;
    try {
      InAppPurchaseStoreKitPlatform.registerPlatform();
      _platformRegistered = true;
    } catch (_) {
      // Unsupported platform, or the engine is not ready yet.
    }
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    if (!SubscriptionPaymentConfig.usesAppleIap) return;

    try {
      registerPlatform();
      storeAvailable.value = await _waitUntilStoreAvailable();
      _ensurePurchaseListener();
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

  Future<void> loadProducts() {
    final inFlight = _loadInFlight;
    if (inFlight != null) return inFlight;
    final run = _loadProducts();
    _loadInFlight = run;
    return run.whenComplete(() {
      if (identical(_loadInFlight, run)) _loadInFlight = null;
    });
  }

  Future<void> _loadProducts() async {
    if (!SubscriptionPaymentConfig.usesAppleIap) return;
    loadingProducts.value = true;
    try {
      registerPlatform();
      if (!storeAvailable.value) {
        storeAvailable.value = await _waitUntilStoreAvailable();
      }
      _ensurePurchaseListener();
      await _waitUntilStoreReadyToQuery();

      final ids = AppleIapProducts.all;
      final response = await _queryCatalog(ids);
      _rememberResponse(response);
      if (response.productDetails.isNotEmpty) {
        products.assignAll({
          for (final p in response.productDetails)
            AppleIapProducts.canonicalizeProductId(p.id): p,
        });
        loadError.value = null;
        if ((response.error?.message ?? '').trim().isEmpty) {
          _lastProductQueryError = null;
        }
      } else if (products.isEmpty) {
        loadError.value = _catalogUnavailableMessage();
      }
      if (kDebugMode) {
        debugPrint(
          '[AppleIAP] loaded ${response.productDetails.length}/'
          '${ids.length} products queried=$ids '
          'returned=${response.productDetails.map((p) => p.id).toList()} '
          'notFound=$_lastNotFoundIds error=$_lastProductQueryError',
        );
      }
    } catch (e) {
      _lastProductQueryError = e.toString();
      if (products.isEmpty) {
        loadError.value = _catalogUnavailableMessage();
      }
      if (kDebugMode) {
        debugPrint('[AppleIAP] loadProducts failed: $e');
      }
    } finally {
      loadingProducts.value = false;
    }
  }

  void _ensurePurchaseListener() {
    if (_purchaseSub != null || !storeAvailable.value) return;
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
  }

  Future<bool> _waitUntilStoreAvailable() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        if (await _iap.isAvailable()) return true;
      } catch (e) {
        _lastProductQueryError = e.toString();
        if (kDebugMode) {
          debugPrint('[AppleIAP] isAvailable failed: $e');
        }
      }
      if (attempt < 2) {
        await Future<void>.delayed(_catalogRetryDelays[attempt]);
      }
    }
    return false;
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
    _ensurePurchaseListener();
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

  String _planLabelForProductId(String productId) {
    final plan = AppleIapProducts.planForProductId(productId);
    return AppleIapProducts.displayNameForPlan(plan ?? '');
  }

  bool _isStoreKitPlatformFailure(String? error) {
    final err = (error ?? '').toLowerCase();
    return err.contains('failed to get response from platform') ||
        err.contains('storekit_no_response') ||
        err.contains('storekit:');
  }

  String _catalogUnavailableMessage() {
    return 'The App Store could not load HostBora plans right now. '
        'Check your connection and Apple ID, then try again.';
  }

  String _productMissingMessage(String productId) {
    if (kDebugMode) {
      debugPrint(
        '[AppleIAP] missing product=$productId '
        'canonical=${AppleIapProducts.canonicalizeProductId(productId)} '
        'notFound=$_lastNotFoundIds error=$_lastProductQueryError',
      );
    }
    final planLabel = _planLabelForProductId(productId);
    if (_isStoreKitPlatformFailure(_lastProductQueryError)) {
      return 'The $planLabel plan could not be loaded from the App Store. '
          'Check your connection and Apple ID, then try again.';
    }
    final err = (_lastProductQueryError ?? '').trim();
    if (err.isNotEmpty) {
      return 'The $planLabel plan could not be loaded from the App Store. '
          'Please try again in a moment.';
    }
    return 'The $planLabel plan is not available from the App Store right now. '
        'Try again, or tap Restore Purchases if you already subscribed.';
  }

  /// StoreKit returns an empty catalog when queried before the scene is active.
  /// `in_app_purchase_storekit` reports that empty list as `storekit_no_response`.
  Future<void> _waitUntilStoreReadyToQuery() async {
    final binding = WidgetsBinding.instance;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase != SchedulerPhase.idle) {
      try {
        await binding.endOfFrame;
      } catch (_) {}
    }
    if (binding.lifecycleState == null ||
        binding.lifecycleState == AppLifecycleState.resumed) {
      return;
    }
    final completer = Completer<void>();
    final observer = _StoreReadyObserver(() {
      if (!completer.isCompleted) completer.complete();
    });
    binding.addObserver(observer);
    try {
      await completer.future.timeout(const Duration(seconds: 3));
    } on TimeoutException {
      // Still query; the catalog retries cover a late resume.
    } finally {
      binding.removeObserver(observer);
    }
  }

  /// Queries the approved App Store Connect IDs in [AppleIapProducts.all].
  ///
  /// StoreKit 2 reports an empty catalog as `storekit_no_response` /
  /// "Failed to get response from platform" even when the IDs are valid.
  /// Retry that transient failure, then ask for each product, then StoreKit 1.
  Future<ProductDetailsResponse> _queryCatalog(Set<String> productIds) async {
    final ids = productIds
        .map(AppleIapProducts.canonicalizeProductId)
        .where((id) => id.isNotEmpty)
        .toSet();
    var response = await _queryWithRetries(ids);
    if (_returnedEveryId(ids, response)) return response;

    if (ids.length > 1) {
      final byId = await _queryEachProduct(ids, response);
      if (byId.productDetails.isNotEmpty) {
        response = byId;
        if (_returnedEveryId(ids, response)) return response;
      }
    }

    final sk1 = await _queryViaStoreKit1(ids);
    if (sk1.isEmpty) return response;
    final merged = <String, ProductDetails>{
      for (final product in response.productDetails)
        AppleIapProducts.canonicalizeProductId(product.id): product,
      for (final product in sk1)
        AppleIapProducts.canonicalizeProductId(product.id): product,
    };
    return ProductDetailsResponse(
      productDetails: merged.values.toList(),
      notFoundIDs: ids.difference(merged.keys.toSet()).toList(),
    );
  }

  bool _returnedEveryId(Set<String> ids, ProductDetailsResponse response) {
    if (response.productDetails.isEmpty) return false;
    final found = response.productDetails
        .map((product) => AppleIapProducts.canonicalizeProductId(product.id))
        .toSet();
    return ids.difference(found).isEmpty;
  }

  /// Initial request plus up to [extraRetries] repeats when StoreKit returns
  /// no products. The plugin maps that empty list to
  /// "Failed to get response from platform".
  Future<ProductDetailsResponse> _queryWithRetries(
    Set<String> ids, {
    int extraRetries = 2,
  }) async {
    final retries = extraRetries.clamp(0, _catalogRetryDelays.length);
    ProductDetailsResponse? last;
    for (var attempt = 0; attempt <= retries; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(_catalogRetryDelays[attempt - 1]);
      }
      try {
        last = await _queryProducts(ids);
      } catch (e) {
        _lastProductQueryError = e.toString();
        if (kDebugMode) {
          debugPrint('[AppleIAP] query $ids attempt ${attempt + 1} threw: $e');
        }
        if (!_isTransientCatalogFailure(_lastProductQueryError)) rethrow;
        continue;
      }
      _rememberResponse(last);
      if (last.productDetails.isNotEmpty) return last;
      if (kDebugMode) {
        debugPrint(
          '[AppleIAP] query $ids attempt ${attempt + 1} empty '
          'error=${last.error} notFound=${last.notFoundIDs}',
        );
      }
    }
    return last ??
        ProductDetailsResponse(
          productDetails: const <ProductDetails>[],
          notFoundIDs: ids.toList(),
        );
  }

  Future<ProductDetailsResponse> _queryEachProduct(
    Set<String> ids,
    ProductDetailsResponse batch,
  ) async {
    final merged = <String, ProductDetails>{
      for (final product in batch.productDetails)
        AppleIapProducts.canonicalizeProductId(product.id): product,
    };
    final missing = ids.difference(merged.keys.toSet());
    for (final id in missing) {
      final one = await _queryWithRetries({id}, extraRetries: 1);
      for (final product in one.productDetails) {
        merged[AppleIapProducts.canonicalizeProductId(product.id)] = product;
      }
    }
    return ProductDetailsResponse(
      productDetails: merged.values.toList(),
      notFoundIDs: ids.difference(merged.keys.toSet()).toList(),
    );
  }

  /// StoreKit 1 product request. Used when StoreKit 2 returns
  /// `storekit_no_response` for IDs that are present in the local catalog.
  Future<List<ProductDetails>> _queryViaStoreKit1(Set<String> ids) async {
    try {
      final response = await SKRequestMaker().startProductRequest(ids.toList());
      if (response.invalidProductIdentifiers.isNotEmpty) {
        _lastNotFoundIds = response.invalidProductIdentifiers
            .map(AppleIapProducts.canonicalizeProductId)
            .toList();
      }
      if (kDebugMode) {
        debugPrint(
          '[AppleIAP] StoreKit 1 returned ${response.products.length}/'
          '${ids.length} invalid=${response.invalidProductIdentifiers}',
        );
      }
      return response.products
          .map(AppStoreProductDetails.fromSKProduct)
          .toList();
    } on PlatformException catch (e) {
      _lastProductQueryError = e.message ?? e.toString();
      if (kDebugMode) {
        debugPrint('[AppleIAP] StoreKit 1 query failed: $e');
      }
      return const [];
    }
  }

  void _rememberResponse(ProductDetailsResponse response) {
    final message = response.error?.message;
    if (message != null && message.trim().isNotEmpty) {
      _lastProductQueryError = message;
    }
    if (response.notFoundIDs.isNotEmpty) {
      _lastNotFoundIds = response.notFoundIDs
          .map(AppleIapProducts.canonicalizeProductId)
          .toList();
    }
    if (response.error != null && kDebugMode) {
      debugPrint('[AppleIAP] queryProductDetails error: ${response.error}');
    }
    if (response.notFoundIDs.isNotEmpty && kDebugMode) {
      debugPrint('[AppleIAP] products not found: ${response.notFoundIDs}');
    }
  }

  bool _isTransientCatalogFailure(String? error) {
    if (_isStoreKitPlatformFailure(error)) return true;
    final err = (error ?? '').toLowerCase();
    return err.contains('missingpluginexception') ||
        err.contains('storekit2_products_error') ||
        err.contains('storekit2_failed_to_fetch');
  }

  Future<ProductDetailsResponse> _queryProducts(Set<String> productIds) {
    final ids = productIds
        .map(AppleIapProducts.canonicalizeProductId)
        .where((id) => id.isNotEmpty)
        .toSet();
    return _iap.queryProductDetails(ids);
  }

  Future<void> restorePurchases() async {
    if (!SubscriptionPaymentConfig.usesAppleIap) return;
    registerPlatform();
    if (!storeAvailable.value) {
      storeAvailable.value = await _iap.isAvailable();
    }
    _ensurePurchaseListener();
    if (!storeAvailable.value) return;
    await _iap.restorePurchases();
  }

  Future<ProductDetails?> _fetchProduct(String productId) async {
    final canonical = AppleIapProducts.canonicalizeProductId(productId);
    final response = await _queryCatalog({canonical});
    _lastProductQueryError = response.error?.message ?? _lastProductQueryError;
    if (response.notFoundIDs.isNotEmpty) {
      _lastNotFoundIds = List<String>.from(response.notFoundIDs)
          .map(AppleIapProducts.canonicalizeProductId)
          .toList();
    }
    if (response.error != null && kDebugMode) {
      debugPrint('[AppleIAP] fetch "$canonical" error: ${response.error}');
    }
    if (response.productDetails.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[AppleIAP] fetch "$canonical" returned empty '
          '(notFound=${response.notFoundIDs})',
        );
      }
      return null;
    }
    final details = response.productDetails.first;
    products[canonical] = details;
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

class _StoreReadyObserver extends WidgetsBindingObserver {
  _StoreReadyObserver(this._onResumed);

  final VoidCallback _onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onResumed();
  }
}
