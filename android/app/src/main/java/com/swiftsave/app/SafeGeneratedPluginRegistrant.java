package com.swiftsave.app;

import androidx.annotation.NonNull;
import io.flutter.Log;
import io.flutter.embedding.engine.FlutterEngine;

/**
 * Registers plugins defensively so one native plugin failure does not block
 * all other plugins from being available at runtime.
 */
public final class SafeGeneratedPluginRegistrant {
  private static final String TAG = "SafePluginRegistrant";

  private SafeGeneratedPluginRegistrant() {}

  public static void registerWith(@NonNull FlutterEngine flutterEngine) {
    try {
      flutterEngine.getPlugins().add(new dev.fluttercommunity.plus.connectivity.ConnectivityPlugin());
    } catch (Throwable e) {
      Log.e(TAG, "Error registering plugin connectivity_plus", e);
    }
    try {
      flutterEngine.getPlugins().add(new dev.fluttercommunity.plus.device_info.DeviceInfoPlusPlugin());
    } catch (Throwable e) {
      Log.e(TAG, "Error registering plugin device_info_plus", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.antonkarpenko.ffmpegkit.FFmpegKitFlutterPlugin());
    } catch (Throwable e) {
      Log.e(TAG, "Error registering plugin ffmpeg_kit_flutter_new_min_gpl", e);
    }
    try {
      flutterEngine.getPlugins().add(new id.flutter.flutter_background_service.FlutterBackgroundServicePlugin());
    } catch (Throwable e) {
      Log.e(TAG, "Error registering plugin flutter_background_service_android", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin());
    } catch (Throwable e) {
      Log.e(TAG, "Error registering plugin flutter_local_notifications", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.it_nomads.fluttersecurestorage.FlutterSecureStoragePlugin());
    } catch (Throwable e) {
      Log.e(TAG, "Error registering plugin flutter_secure_storage", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.lazycatlabs.media_scanner.MediaScannerPlugin());
    } catch (Throwable e) {
      Log.e(TAG, "Error registering plugin media_scanner", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.crazecoder.openfile.OpenFilePlugin());
    } catch (Throwable e) {
      Log.e(TAG, "Error registering plugin open_filex", e);
    }
    try {
      flutterEngine.getPlugins().add(new dev.fluttercommunity.plus.packageinfo.PackageInfoPlugin());
    } catch (Throwable e) {
      Log.e(TAG, "Error registering plugin package_info_plus", e);
    }
    try {
      flutterEngine.getPlugins().add(new io.flutter.plugins.pathprovider.PathProviderPlugin());
    } catch (Throwable e) {
      Log.e(TAG, "Error registering plugin path_provider_android", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.baseflow.permissionhandler.PermissionHandlerPlugin());
    } catch (Throwable e) {
      Log.e(TAG, "Error registering plugin permission_handler_android", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.kasem.receive_sharing_intent.ReceiveSharingIntentPlugin());
    } catch (Throwable e) {
      Log.e(TAG, "Error registering plugin receive_sharing_intent", e);
    }
    try {
      flutterEngine.getPlugins().add(new io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin());
    } catch (Throwable e) {
      Log.e(TAG, "Error registering plugin shared_preferences_android", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.tekartik.sqflite.SqflitePlugin());
    } catch (Throwable e) {
      Log.e(TAG, "Error registering plugin sqflite_android", e);
    }
    try {
      flutterEngine.getPlugins().add(new dev.fluttercommunity.plus.wakelock.WakelockPlusPlugin());
    } catch (Throwable e) {
      Log.e(TAG, "Error registering plugin wakelock_plus", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.example.ytdlp_bridge.YtdlpBridgePlugin());
    } catch (Throwable e) {
      Log.e(TAG, "Error registering plugin ytdlp_bridge", e);
    }
  }
}
