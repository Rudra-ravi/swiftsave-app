import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftsave/core/interfaces/i_settings_repository.dart';
import 'package:swiftsave/viewmodels/settings_view_model.dart';

class _FakeSettingsRepository implements ISettingsRepository {
  @override
  ThemeMode themeMode = ThemeMode.system;
  @override
  Locale? locale;
  @override
  bool wifiOnlyDownloads = false;
  @override
  int maxConcurrentDownloads = 3;
  @override
  bool saveToGallery = true;
  String? _downloadPath;
  @override
  String? get downloadPathValue => _downloadPath;
  @override
  bool queuePaused = false;
  @override
  int maxQualityWifi = 2160;
  @override
  int maxQualityMobile = 720;
  @override
  int sleepInterval = 3;
  @override
  bool autoRetryFailed = true;
  @override
  bool skipDuplicates = true;
  @override
  bool embedSubtitles = false;
  @override
  String subtitleLanguage = 'en';
  @override
  bool showAdvancedSettings = false;
  @override
  String? customUserAgent;
  @override
  String? proxyUrl;
  @override
  int concurrentFragments = 4;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
  }

  @override
  Future<void> setLocale(Locale? locale) async {
    this.locale = locale;
  }

  @override
  Future<void> setWifiOnlyDownloads(bool value) async {
    wifiOnlyDownloads = value;
  }

  @override
  Future<void> setMaxConcurrentDownloads(int value) async {
    maxConcurrentDownloads = value;
  }

  @override
  Future<void> setSaveToGallery(bool value) async {
    saveToGallery = value;
  }

  @override
  Future<String?> getDownloadPath() async {
    return _downloadPath;
  }

  @override
  Future<void> setDownloadPath(String path) async {
    _downloadPath = path;
  }

  @override
  Future<void> setQueuePaused(bool value) async {
    queuePaused = value;
  }

  @override
  Future<void> setMaxQualityWifi(int value) async {
    maxQualityWifi = value;
  }

  @override
  Future<void> setMaxQualityMobile(int value) async {
    maxQualityMobile = value;
  }

  @override
  Future<void> setSleepInterval(int value) async {
    sleepInterval = value;
  }

  @override
  Future<void> setAutoRetryFailed(bool value) async {
    autoRetryFailed = value;
  }

  @override
  Future<void> setSkipDuplicates(bool value) async {
    skipDuplicates = value;
  }

  @override
  Future<void> setEmbedSubtitles(bool value) async {
    embedSubtitles = value;
  }

  @override
  Future<void> setSubtitleLanguage(String value) async {
    subtitleLanguage = value;
  }

  @override
  Future<void> setShowAdvancedSettings(bool value) async {
    showAdvancedSettings = value;
  }

  @override
  Future<void> setCustomUserAgent(String? value) async {
    customUserAgent = value;
  }

  @override
  Future<void> setProxyUrl(String? value) async {
    proxyUrl = value;
  }

  @override
  Future<void> setConcurrentFragments(int value) async {
    concurrentFragments = value;
  }
}

void main() {
  group('SettingsViewModel advanced yt-dlp wiring', () {
    test(
      'exposes and updates proxy/user-agent/fragments/subtitles settings',
      () async {
        final repo = _FakeSettingsRepository();
        final vm = SettingsViewModel(repo);

        expect(vm.concurrentFragments, 4);
        expect(vm.embedSubtitles, false);
        expect(vm.subtitleLanguage, 'en');
        expect(vm.customUserAgent, isNull);
        expect(vm.proxyUrl, isNull);

        await vm.setConcurrentFragments(8);
        await vm.setEmbedSubtitles(true);
        await vm.setSubtitleLanguage('es');
        await vm.setCustomUserAgent('Mozilla/5.0 Test');
        await vm.setProxyUrl('http://127.0.0.1:8080');

        expect(vm.concurrentFragments, 8);
        expect(vm.embedSubtitles, true);
        expect(vm.subtitleLanguage, 'es');
        expect(vm.customUserAgent, 'Mozilla/5.0 Test');
        expect(vm.proxyUrl, 'http://127.0.0.1:8080');
      },
    );
  });
}
