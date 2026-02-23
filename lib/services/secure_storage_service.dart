import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

/// Service for securely storing sensitive data like cookies and credentials
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._();
  static SecureStorageService get instance => _instance;

  final FlutterSecureStorage _storage;

  // Keys
  static const String _kCookiePath = 'cookie_path';
  static const String _kCookiesMigrated = 'cookies_migrated_v1';

  SecureStorageService._()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );

  /// Initialize and migrate data if necessary
  Future<void> initialize() async {
    try {
      await _migrateFromSharedPreferences();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to initialize secure storage',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Migrate sensitive data from insecure SharedPreferences to SecureStorage
  Future<void> _migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool(_kCookiesMigrated) ?? false;

    if (!migrated) {
      AppLogger.info('Migrating cookies to secure storage...');

      // Migrate cookie path
      final cookiePath = prefs.getString(_kCookiePath);
      if (cookiePath != null && cookiePath.isNotEmpty) {
        await saveCookiePath(cookiePath);
        await prefs.remove(_kCookiePath); // Remove from insecure storage
      }

      await prefs.setBool(_kCookiesMigrated, true);
      AppLogger.info('Migration complete');
    }
  }

  /// Save cookie file path securely
  Future<void> saveCookiePath(String path) async {
    await _storage.write(key: _kCookiePath, value: path);
    AppLogger.debug('Cookie path saved securely');
  }

  /// Get cookie file path
  Future<String?> getCookiePath() async {
    return await _storage.read(key: _kCookiePath);
  }

  /// Delete cookie file path
  Future<void> deleteCookiePath() async {
    await _storage.delete(key: _kCookiePath);
    AppLogger.debug('Cookie path removed from secure storage');
  }

  // Generic methods for future use
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Clear all secure data
  Future<void> clearAll() async {
    await _storage.deleteAll();
    AppLogger.warning('All secure storage data cleared');
  }
}
