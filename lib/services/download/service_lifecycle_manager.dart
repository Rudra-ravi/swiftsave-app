import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../../utils/app_logger.dart';
import 'notification_manager.dart';

class ServiceLifecycleManager {
  final ServiceInstance _service;
  final NotificationManager _notifications;

  DateTime? _serviceStartTime;
  Timer? _idleTimer;

  static const Duration _idleTimeout = Duration(minutes: 5);
  // Android 14+ requires services to stop after 6 hours roughly
  // We leave a 15 min buffer (5h 45m)
  static const Duration _maxServiceRuntime = Duration(hours: 5, minutes: 45);

  ServiceLifecycleManager(this._service, this._notifications);

  void start() {
    _serviceStartTime = DateTime.now();
    AppLogger.debug(
      '[ServiceLifecycleManager] Service started at $_serviceStartTime',
    );
  }

  /// Check if service has exceeded runtime limits (Android 14+)
  /// Returns true if the service should stop/restart
  Future<bool> checkRuntime({
    required Future<void> Function() onRestartRequired,
  }) async {
    if (_serviceStartTime == null) return false;

    final runningTime = DateTime.now().difference(_serviceStartTime!);

    if (runningTime >= _maxServiceRuntime) {
      AppLogger.debug(
        '[ServiceLifecycleManager] Service runtime limit reached (${runningTime.inMinutes} minutes), restarting...',
      );

      await _notifications.show(
        'Restarting download service',
        'Long-running service limit reached',
      );

      // Call the cleanup/save callback provided by the caller
      await onRestartRequired();

      await _service.stopSelf();
      return true;
    } else if (runningTime.inMinutes >= 330) {
      // 5.5 hours warning
      await _notifications.show(
        'Service will restart soon',
        'Long-running download limit approaching',
      );
    }

    return false;
  }

  /// Start the idle timer to stop service if no activity
  void startIdleTimer({
    required bool Function() isIdle,
    required Future<void> Function() onStop,
  }) {
    _idleTimer?.cancel();
    AppLogger.debug('[ServiceLifecycleManager] Starting idle timer');

    _idleTimer = Timer(_idleTimeout, () async {
      if (isIdle()) {
        AppLogger.debug(
          '[ServiceLifecycleManager] No activity for ${_idleTimeout.inMinutes} minutes, stopping service',
        );

        await _notifications.show(
          'Stopping download service',
          'No active downloads',
        );

        await onStop();
        await _service.stopSelf();
      }
    });
  }

  void cancelIdleTimer() {
    if (_idleTimer != null) {
      // Only log if we are actually cancelling an active timer
      if (_idleTimer!.isActive) {
        // AppLogger.debug('[ServiceLifecycleManager] Idle timer cancelled');
      }
      _idleTimer?.cancel();
      _idleTimer = null;
    }
  }
}
