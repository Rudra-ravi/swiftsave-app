import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../utils/app_logger.dart';
import 'notification_manager.dart';

class ConnectivityMonitor {
  final Connectivity _connectivity = Connectivity();
  final NotificationManager _notifications;

  bool _networkAvailable = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool get isNetworkAvailable => _networkAvailable;

  ConnectivityMonitor(this._notifications);

  /// Start monitoring network connectivity
  void startMonitoring({void Function()? onConnectionRestored}) {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final wasAvailable = _networkAvailable;
        _networkAvailable =
            results.isNotEmpty && !results.contains(ConnectivityResult.none);

        if (wasAvailable && !_networkAvailable) {
          // Connection lost
          AppLogger.debug('[ConnectivityMonitor] Network connection lost');
          _notifications.show(
            'Connection lost',
            'Downloads will resume when connected',
          );
        } else if (!wasAvailable && _networkAvailable) {
          // Connection restored
          AppLogger.debug('[ConnectivityMonitor] Network connection restored');
          _notifications.show('Connection restored', 'Resuming downloads...');

          if (onConnectionRestored != null) {
            onConnectionRestored();
          }
        }
      },
      onError: (Object error) {
        AppLogger.error('[ConnectivityMonitor] Monitoring error', error: error);
      },
    );
  }

  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Check if the preferred network (WiFi/Ethernet) is available
  Future<bool> isPreferredNetworkAvailable() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);
    } catch (e) {
      AppLogger.error(
        '[ConnectivityMonitor] Connectivity check failed',
        error: e,
      );
      return true; // Fail open to avoid blocking downloads
    }
  }

  /// Wait for preferred network if wifi-only mode is enabled
  Future<void> waitForPreferredNetwork({
    required bool wifiOnlyDownloads,
  }) async {
    if (!wifiOnlyDownloads) return;

    await _notifications.show(
      'Waiting for Wi-Fi',
      'Connect to Wi-Fi to resume downloads',
    );

    final completer = Completer<void>();
    StreamSubscription<List<ConnectivityResult>>? subscription;

    subscription = _connectivity.onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet)) {
        subscription?.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    await completer.future;
  }
}
