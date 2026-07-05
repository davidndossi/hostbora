import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

import '../../../core/utils/util.dart';
import '../db/offline_sync_queue_local_data_source.dart';

typedef OfflineSyncHandler = Future<void> Function(OfflineSyncQueueItem item);

/// Background worker for processing queued offline operations when online.
///
/// Handlers are registered per `entityType:operation`.
class OfflineSyncWorkerService extends GetxService {
  OfflineSyncWorkerService({
    required OfflineSyncQueueLocalDataSource queue,
  }) : _queue = queue;

  final OfflineSyncQueueLocalDataSource _queue;
  final _connectivity = Connectivity();
  final Map<String, OfflineSyncHandler> _handlers = <String, OfflineSyncHandler>{};

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _pollTimer;
  bool _isRunning = false;
  bool _started = false;
  final List<void Function()> _onDrainListeners = [];

  void addOnDrainListener(void Function() listener) {
    if (!_onDrainListeners.contains(listener)) {
      _onDrainListeners.add(listener);
    }
  }

  void removeOnDrainListener(void Function() listener) {
    _onDrainListeners.remove(listener);
  }

  /// Start listening for connectivity and processing pending sync queue items.
  void start() {
    if (_started) return;
    _started = true;

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      if (_hasConnectivity(results)) {
        unawaited(_drainQueue());
      }
    });

    // Safety poller in case connectivity stream misses events.
    _pollTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(_drainQueue());
    });

    unawaited(_drainQueue());
  }

  /// Register a handler for a queued operation.
  ///
  /// Example key under the hood: `booking:create`.
  void registerHandler({
    required String entityType,
    required String operation,
    required OfflineSyncHandler handler,
  }) {
    _handlers[_key(entityType, operation)] = handler;
  }

  /// Unregister one operation handler.
  void unregisterHandler({
    required String entityType,
    required String operation,
  }) {
    _handlers.remove(_key(entityType, operation));
  }

  /// Runs one sync pass (up to [maxItems]).
  Future<void> runNow({int maxItems = 20}) => _drainQueue(maxItems: maxItems);

  Future<void> _drainQueue({int maxItems = 20}) async {
    if (_isRunning) return;
    if (!await _isOnline()) return;

    _isRunning = true;
    try {
      await _queue.requeueFailed();
      for (var i = 0; i < maxItems; i++) {
        final item = await _queue.nextPending();
        if (item == null) break;

        final handler = _handlers[_key(item.entityType, item.operation)];
        if (handler == null) {
          await _queue.markFailed(
            item.id,
            errorMessage: 'No sync handler for ${item.entityType}:${item.operation}',
          );
          continue;
        }

        await _queue.markInProgress(item.id);
        try {
          await handler(item);
          await _queue.markDone(item.id);
        } catch (e) {
          await _queue.markFailed(item.id, errorMessage: e.toString());
        }
      }

      await _queue.deleteDone();
      _notifyDrainListeners();
    } finally {
      _isRunning = false;
    }
  }

  void _notifyDrainListeners() {
    for (final listener in List<void Function()>.from(_onDrainListeners)) {
      try {
        listener();
      } catch (_) {}
    }
  }

  String _key(String entityType, String operation) => '$entityType:$operation';

  bool _hasConnectivity(List<ConnectivityResult> results) {
    return Util.hasNetworkConnectivity(results);
  }

  Future<bool> _isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnectivity(results);
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.onClose();
  }
}
