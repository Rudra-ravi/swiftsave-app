import 'package:flutter/material.dart';
import '../core/interfaces/i_settings_repository.dart';
import '../services/settings_service.dart'; // Needed for static constants

class SettingsViewModel extends ChangeNotifier {
  final ISettingsRepository _repository;

  SettingsViewModel(this._repository);

  // --- Theme & Locale ---

  ThemeMode get themeMode => _repository.themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    await _repository.setThemeMode(mode);
    notifyListeners();
  }

  Locale? get locale => _repository.locale;

  Future<void> setLocale(Locale? locale) async {
    await _repository.setLocale(locale);
    notifyListeners();
  }

  // --- Download Settings ---

  bool get wifiOnlyDownloads => _repository.wifiOnlyDownloads;

  Future<void> setWifiOnlyDownloads(bool value) async {
    await _repository.setWifiOnlyDownloads(value);
    notifyListeners();
  }

  int get maxConcurrentDownloads => _repository.maxConcurrentDownloads;

  Future<void> setMaxConcurrentDownloads(int value) async {
    await _repository.setMaxConcurrentDownloads(value);
    notifyListeners();
  }

  bool get saveToGallery => _repository.saveToGallery;

  Future<void> setSaveToGallery(bool value) async {
    await _repository.setSaveToGallery(value);
    notifyListeners();
  }

  String? get downloadPathValue => _repository.downloadPathValue;

  Future<void> setDownloadPath(String path) async {
    await _repository.setDownloadPath(path);
    notifyListeners();
  }

  bool get queuePaused => _repository.queuePaused;

  Future<void> setQueuePaused(bool value) async {
    await _repository.setQueuePaused(value);
    notifyListeners();
  }

  // --- Quality Settings ---

  int get maxQualityWifi => _repository.maxQualityWifi;

  Future<void> setMaxQualityWifi(int value) async {
    await _repository.setMaxQualityWifi(value);
    notifyListeners();
  }

  int get maxQualityMobile => _repository.maxQualityMobile;

  Future<void> setMaxQualityMobile(int value) async {
    await _repository.setMaxQualityMobile(value);
    notifyListeners();
  }

  // --- Advanced Settings ---

  int get sleepInterval => _repository.sleepInterval;

  Future<void> setSleepInterval(int value) async {
    await _repository.setSleepInterval(value);
    notifyListeners();
  }

  bool get autoRetryFailed => _repository.autoRetryFailed;

  Future<void> setAutoRetryFailed(bool value) async {
    await _repository.setAutoRetryFailed(value);
    notifyListeners();
  }

  bool get skipDuplicates => _repository.skipDuplicates;

  Future<void> setSkipDuplicates(bool value) async {
    await _repository.setSkipDuplicates(value);
    notifyListeners();
  }

  bool get embedSubtitles => _repository.embedSubtitles;

  Future<void> setEmbedSubtitles(bool value) async {
    await _repository.setEmbedSubtitles(value);
    notifyListeners();
  }

  String get subtitleLanguage => _repository.subtitleLanguage;

  Future<void> setSubtitleLanguage(String value) async {
    await _repository.setSubtitleLanguage(value);
    notifyListeners();
  }

  bool get showAdvancedSettings => _repository.showAdvancedSettings;

  Future<void> setShowAdvancedSettings(bool value) async {
    await _repository.setShowAdvancedSettings(value);
    notifyListeners();
  }

  String? get customUserAgent => _repository.customUserAgent;

  Future<void> setCustomUserAgent(String? value) async {
    await _repository.setCustomUserAgent(value);
    notifyListeners();
  }

  String? get proxyUrl => _repository.proxyUrl;

  Future<void> setProxyUrl(String? value) async {
    await _repository.setProxyUrl(value);
    notifyListeners();
  }

  int get concurrentFragments => _repository.concurrentFragments;

  Future<void> setConcurrentFragments(int value) async {
    await _repository.setConcurrentFragments(value);
    notifyListeners();
  }

  // --- Helpers ---

  // Expose static helpers from Service as convenience or proxy them
  // In a pure MVVM, the VM should probably provide these, but reusing the Service static constants is practical
  List<int> get qualityOptions => SettingsService.qualityOptions;

  String getQualityLabel(int height) {
    return SettingsService.getQualityLabel(height);
  }

  Map<String, String> get subtitleLanguages =>
      SettingsService.subtitleLanguages;
}
