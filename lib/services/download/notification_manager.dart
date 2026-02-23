import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../file_opener_service.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  NotificationManager.handleNotificationResponse(response);
}

class NotificationManager {
  static const String channelId = 'ytdlp_download_channel';
  static const String completionChannelId = 'ytdlp_download_complete_channel';
  static const String openActionId = 'open_download';
  static const int notificationId = 888;
  static const int _openErrorNotificationId = 889;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ServiceInstance? _service;

  NotificationManager(this._service);

  /// Show a foreground notification if running on Android
  Future<void> show(String title, String content) async {
    if (_service is AndroidServiceInstance) {
      await (_service).setForegroundNotificationInfo(
        title: title,
        content: content,
      );
    }
  }

  /// Check and request notification permissions (Android 13+)
  static Future<bool> checkPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ requires notification permission
        final status = await Permission.notification.request();
        return status.isGranted;
      }
    }
    return true;
  }

  /// Initialize the notification channel
  static Future<void> initializeChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      'Downloads',
      description: 'Progress of active downloads',
      importance: Importance.low,
    );
    const AndroidNotificationChannel completionChannel =
        AndroidNotificationChannel(
          completionChannelId,
          'Download Completed',
          description: 'Completed downloads with open action',
          importance: Importance.high,
        );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(completionChannel);
  }

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: iOS);

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await initializeChannel();
  }

  static Future<void> showCompletionNotification({
    required String title,
    required String body,
    required String filePath,
  }) async {
    if (filePath.trim().isEmpty) return;
    final id = filePath.hashCode & 0x7fffffff;
    final payload = jsonEncode({'filePath': filePath});

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        completionChannelId,
        'Download Completed',
        channelDescription: 'Completed downloads with open action',
        importance: Importance.high,
        priority: Priority.high,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(openActionId, 'Open'),
        ],
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  static Future<void> handleNotificationResponse(
    NotificationResponse response,
  ) async {
    if (response.payload == null || response.payload!.isEmpty) {
      return;
    }

    final payload = response.payload!;
    String? filePath;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        filePath = decoded['filePath'] as String?;
      }
    } catch (_) {
      filePath = payload;
    }

    if (filePath == null || filePath.trim().isEmpty) {
      await _showOpenFailedNotification('Unable to open file');
      return;
    }

    final result = await FileOpenerService.openAndScan(filePath);
    if (!FileOpenerService.isSuccess(result)) {
      await _showOpenFailedNotification(
        FileOpenerService.getErrorMessage(result),
      );
    }
  }

  static Future<void> _showOpenFailedNotification(String message) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        completionChannelId,
        'Download Completed',
        channelDescription: 'Completed downloads with open action',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _localNotifications.show(
      id: _openErrorNotificationId,
      title: 'Unable to open download',
      body: message,
      notificationDetails: details,
    );
  }

  /// Helper to create Android configuration for the background service
  static AndroidConfiguration createAndroidConfiguration({
    required void Function(ServiceInstance) onStart,
    required bool isForegroundMode,
    bool autoStart = false,
  }) {
    return AndroidConfiguration(
      onStart: onStart,
      autoStart: autoStart,
      isForegroundMode: isForegroundMode,
      notificationChannelId: channelId,
      initialNotificationTitle: 'SwiftSave',
      initialNotificationContent: 'Initializing...',
      foregroundServiceNotificationId: notificationId,
    );
  }
}
