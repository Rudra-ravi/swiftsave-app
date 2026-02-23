import 'package:flutter/material.dart';

abstract class ISettingsRepository {
  /// Initialize settings
  Future<void> initialize();

  // --- Theme & Locale ---

  ThemeMode get themeMode;
  Future<void> setThemeMode(ThemeMode mode);

  Locale? get locale;
  Future<void> setLocale(Locale? locale);

  // --- Download Settings ---

  bool get wifiOnlyDownloads;
  Future<void> setWifiOnlyDownloads(bool value);

  int get maxConcurrentDownloads;
  Future<void> setMaxConcurrentDownloads(int value);

  bool get saveToGallery;
  Future<void> setSaveToGallery(bool value);

  String? get downloadPathValue;
  Future<String?> getDownloadPath();
  Future<void> setDownloadPath(String path);

  bool get queuePaused;
  Future<void> setQueuePaused(bool value);

  // --- Quality Settings ---

  int get maxQualityWifi;
  Future<void> setMaxQualityWifi(int value);

  int get maxQualityMobile;
  Future<void> setMaxQualityMobile(int value);

  // --- Advanced Settings ---

  int get sleepInterval;
  Future<void> setSleepInterval(int value);

  bool get autoRetryFailed;
  Future<void> setAutoRetryFailed(bool value);

  bool get skipDuplicates;
  Future<void> setSkipDuplicates(bool value);

  bool get embedSubtitles;
  Future<void> setEmbedSubtitles(bool value);

  String get subtitleLanguage;
  Future<void> setSubtitleLanguage(String value);

  bool get showAdvancedSettings;
  Future<void> setShowAdvancedSettings(bool value);

  String? get customUserAgent;
  Future<void> setCustomUserAgent(String? value);

  String? get proxyUrl;
  Future<void> setProxyUrl(String? value);

  int get concurrentFragments;
  Future<void> setConcurrentFragments(int value);
}
