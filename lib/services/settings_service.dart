import '../core/interfaces/i_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier implements ISettingsRepository {
  static final SettingsService _instance = SettingsService._internal();
  static SettingsService get instance => _instance;
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _themeKey = 'theme_mode';
  static const String _localeKey = 'locale';
  static const String _wifiOnlyKey = 'wifi_only_downloads';
  static const String _maxConcurrentKey = 'max_concurrent_downloads';
  static const String _saveToGalleryKey = 'save_to_gallery';
  static const String _downloadPathKey = 'download_path';
  static const String _queuePausedKey = 'queue_paused';

  // New settings for enhanced yt-dlp features
  static const String _maxQualityWifiKey = 'max_quality_wifi';
  static const String _maxQualityMobileKey = 'max_quality_mobile';
  static const String _sleepIntervalKey = 'sleep_interval';
  static const String _autoRetryKey = 'auto_retry_failed';
  static const String _skipDuplicatesKey = 'skip_duplicates';
  static const String _embedSubtitlesKey = 'embed_subtitles';
  static const String _subtitleLanguageKey = 'subtitle_language';
  static const String _showAdvancedKey = 'show_advanced_settings';
  static const String _customUserAgentKey = 'custom_user_agent';
  static const String _proxyUrlKey = 'proxy_url';
  static const String _concurrentFragmentsKey = 'concurrent_fragments';

  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;
  bool _wifiOnlyDownloads = false;
  int _maxConcurrentDownloads = 3;
  bool _saveToGallery = true;
  String? _downloadPath;
  bool _queuePaused = false;

  // New settings
  int _maxQualityWifi = 2160; // 4K
  int _maxQualityMobile = 720; // 720p
  int _sleepInterval = 3; // seconds between downloads
  bool _autoRetryFailed = true;
  bool _skipDuplicates = true;
  bool _embedSubtitles = false;
  String _subtitleLanguage = 'en';
  bool _showAdvancedSettings = false;
  String? _customUserAgent;
  String? _proxyUrl;
  int _concurrentFragments = 4;

  @override
  ThemeMode get themeMode => _themeMode;
  @override
  Locale? get locale => _locale;
  @override
  bool get wifiOnlyDownloads => _wifiOnlyDownloads;
  @override
  int get maxConcurrentDownloads => _maxConcurrentDownloads;
  @override
  bool get saveToGallery => _saveToGallery;
  @override
  String? get downloadPathValue => _downloadPath;
  @override
  bool get queuePaused => _queuePaused;

  // New getters
  @override
  int get maxQualityWifi => _maxQualityWifi;
  @override
  int get maxQualityMobile => _maxQualityMobile;
  @override
  int get sleepInterval => _sleepInterval;
  @override
  bool get autoRetryFailed => _autoRetryFailed;
  @override
  bool get skipDuplicates => _skipDuplicates;
  @override
  bool get embedSubtitles => _embedSubtitles;
  @override
  String get subtitleLanguage => _subtitleLanguage;
  @override
  bool get showAdvancedSettings => _showAdvancedSettings;
  @override
  String? get customUserAgent => _customUserAgent;
  @override
  String? get proxyUrl => _proxyUrl;
  @override
  int get concurrentFragments => _concurrentFragments;

  /// Get max quality based on current network type
  int getMaxQualityForNetwork(bool isWifi) {
    return isWifi ? _maxQualityWifi : _maxQualityMobile;
  }

  @override
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    // Load theme
    final themeString = prefs.getString(_themeKey);
    if (themeString == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    // Load locale
    final localeString = prefs.getString(_localeKey);
    if (localeString != null) {
      _locale = Locale(localeString);
    }

    _wifiOnlyDownloads = prefs.getBool(_wifiOnlyKey) ?? false;
    _maxConcurrentDownloads = prefs.getInt(_maxConcurrentKey) ?? 3;
    _saveToGallery = prefs.getBool(_saveToGalleryKey) ?? true;
    _downloadPath = prefs.getString(_downloadPathKey);
    _queuePaused = prefs.getBool(_queuePausedKey) ?? false;

    // Load new settings
    _maxQualityWifi = prefs.getInt(_maxQualityWifiKey) ?? 2160;
    _maxQualityMobile = prefs.getInt(_maxQualityMobileKey) ?? 720;
    _sleepInterval = prefs.getInt(_sleepIntervalKey) ?? 3;
    _autoRetryFailed = prefs.getBool(_autoRetryKey) ?? true;
    _skipDuplicates = prefs.getBool(_skipDuplicatesKey) ?? true;
    _embedSubtitles = prefs.getBool(_embedSubtitlesKey) ?? false;
    _subtitleLanguage = prefs.getString(_subtitleLanguageKey) ?? 'en';
    _showAdvancedSettings = prefs.getBool(_showAdvancedKey) ?? false;
    _customUserAgent = prefs.getString(_customUserAgentKey);
    _proxyUrl = prefs.getString(_proxyUrlKey);
    _concurrentFragments = prefs.getInt(_concurrentFragmentsKey) ?? 4;

    notifyListeners();
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.system:
        value = 'system';
        break;
    }
    await prefs.setString(_themeKey, value);
  }

  @override
  Future<void> setLocale(Locale? locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (locale != null) {
      await prefs.setString(_localeKey, locale.languageCode);
    } else {
      await prefs.remove(_localeKey);
    }
  }

  @override
  Future<void> setWifiOnlyDownloads(bool value) async {
    if (_wifiOnlyDownloads == value) return;
    _wifiOnlyDownloads = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wifiOnlyKey, value);
    await _notifyBackgroundService();
  }

  @override
  Future<void> setMaxConcurrentDownloads(int value) async {
    final clamped = value.clamp(1, 6).toInt();
    if (_maxConcurrentDownloads == clamped) return;
    _maxConcurrentDownloads = clamped;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxConcurrentKey, clamped);
    await _notifyBackgroundService();
  }

  @override
  Future<void> setSaveToGallery(bool value) async {
    if (_saveToGallery == value) return;
    _saveToGallery = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_saveToGalleryKey, value);
    await _notifyBackgroundService();
  }

  @override
  Future<String?> getDownloadPath() async {
    return _downloadPath;
  }

  @override
  Future<void> setDownloadPath(String path) async {
    final normalized = path.trim();
    final nextPath = normalized.isEmpty ? null : normalized;
    if (_downloadPath == nextPath) return;
    _downloadPath = nextPath;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (_downloadPath == null) {
      await prefs.remove(_downloadPathKey);
    } else {
      await prefs.setString(_downloadPathKey, _downloadPath!);
    }
    await _notifyBackgroundService();
  }

  @override
  Future<void> setQueuePaused(bool value) async {
    if (_queuePaused == value) return;
    _queuePaused = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_queuePausedKey, value);
    await _notifyBackgroundService();
  }

  // New setters for enhanced settings

  @override
  Future<void> setMaxQualityWifi(int value) async {
    final clamped = value.clamp(360, 4320).toInt();
    if (_maxQualityWifi == clamped) return;
    _maxQualityWifi = clamped;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxQualityWifiKey, clamped);
    await _notifyBackgroundService();
  }

  @override
  Future<void> setMaxQualityMobile(int value) async {
    final clamped = value.clamp(360, 2160).toInt();
    if (_maxQualityMobile == clamped) return;
    _maxQualityMobile = clamped;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxQualityMobileKey, clamped);
    await _notifyBackgroundService();
  }

  @override
  Future<void> setSleepInterval(int value) async {
    final clamped = value.clamp(0, 30).toInt();
    if (_sleepInterval == clamped) return;
    _sleepInterval = clamped;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sleepIntervalKey, clamped);
    await _notifyBackgroundService();
  }

  @override
  Future<void> setAutoRetryFailed(bool value) async {
    if (_autoRetryFailed == value) return;
    _autoRetryFailed = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoRetryKey, value);
    await _notifyBackgroundService();
  }

  @override
  Future<void> setSkipDuplicates(bool value) async {
    if (_skipDuplicates == value) return;
    _skipDuplicates = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skipDuplicatesKey, value);
    await _notifyBackgroundService();
  }

  @override
  Future<void> setEmbedSubtitles(bool value) async {
    if (_embedSubtitles == value) return;
    _embedSubtitles = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_embedSubtitlesKey, value);
    await _notifyBackgroundService();
  }

  @override
  Future<void> setSubtitleLanguage(String value) async {
    if (_subtitleLanguage == value) return;
    _subtitleLanguage = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subtitleLanguageKey, value);
    await _notifyBackgroundService();
  }

  @override
  Future<void> setShowAdvancedSettings(bool value) async {
    if (_showAdvancedSettings == value) return;
    _showAdvancedSettings = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showAdvancedKey, value);
  }

  @override
  Future<void> setCustomUserAgent(String? value) async {
    if (_customUserAgent == value) return;
    _customUserAgent = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (value != null && value.isNotEmpty) {
      await prefs.setString(_customUserAgentKey, value);
    } else {
      await prefs.remove(_customUserAgentKey);
    }
    await _notifyBackgroundService();
  }

  @override
  Future<void> setProxyUrl(String? value) async {
    if (_proxyUrl == value) return;
    _proxyUrl = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (value != null && value.isNotEmpty) {
      await prefs.setString(_proxyUrlKey, value);
    } else {
      await prefs.remove(_proxyUrlKey);
    }
    await _notifyBackgroundService();
  }

  @override
  Future<void> setConcurrentFragments(int value) async {
    final clamped = value.clamp(1, 16).toInt();
    if (_concurrentFragments == clamped) return;
    _concurrentFragments = clamped;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_concurrentFragmentsKey, clamped);
    await _notifyBackgroundService();
  }

  /// Get quality label for a height value
  static String getQualityLabel(int height) {
    switch (height) {
      case 360:
        return '360p (Low)';
      case 480:
        return '480p (SD)';
      case 720:
        return '720p (HD)';
      case 1080:
        return '1080p (Full HD)';
      case 1440:
        return '1440p (2K)';
      case 2160:
        return '2160p (4K)';
      case 4320:
        return '4320p (8K)';
      default:
        return '${height}p';
    }
  }

  /// Available quality options
  static const List<int> qualityOptions = [
    360,
    480,
    720,
    1080,
    1440,
    2160,
    4320,
  ];

  /// Available subtitle languages
  static const Map<String, String> subtitleLanguages = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'pt': 'Portuguese',
    'it': 'Italian',
    'ja': 'Japanese',
    'ko': 'Korean',
    'zh': 'Chinese',
    'ar': 'Arabic',
    'hi': 'Hindi',
    'ru': 'Russian',
    'auto': 'Auto-generated',
  };

  Future<void> _notifyBackgroundService() async {
    try {
      final service = FlutterBackgroundService();
      if (await service.isRunning()) {
        service.invoke('updateSettings', {
          'wifiOnlyDownloads': _wifiOnlyDownloads,
          'maxConcurrentDownloads': _maxConcurrentDownloads,
          'saveToGallery': _saveToGallery,
          'maxQualityWifi': _maxQualityWifi,
          'maxQualityMobile': _maxQualityMobile,
          'sleepInterval': _sleepInterval,
          'concurrentFragments': _concurrentFragments,
          'skipDuplicates': _skipDuplicates,
          'embedSubtitles': _embedSubtitles,
          'subtitleLanguage': _subtitleLanguage,
          'customUserAgent': _customUserAgent,
          'proxyUrl': _proxyUrl,
          'queuePaused': _queuePaused,
        });
      }
    } on MissingPluginException {
      // Background service channel may be unavailable in secondary isolates.
    }
  }
}
