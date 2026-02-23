import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'engine/download_engine_provider.dart';
import 'secure_storage_service.dart';
import '../utils/app_logger.dart';

class CookieService {
  static const String _cookieFileKey =
      'browser_cookie_file'; // Kept for backward compat/migration
  static const String _lastBrowserKey = 'last_browser';

  /// Get stored cookie file path
  static Future<String?> getCookieFile() async {
    // Initialize secure storage service to ensure migration happens
    await SecureStorageService.instance.initialize();

    // Try getting from secure storage first
    final securePath = await SecureStorageService.instance.getCookiePath();
    if (securePath != null) return securePath;

    // Fallback to shared prefs (should have been migrated, but just in case)
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cookieFileKey);
  }

  /// Extract and save cookies from browser
  static Future<bool> extractAndSaveCookies(String browser) async {
    try {
      final cookieFile = await DownloadEngineProvider.instance
          .extractCookiesFromBrowser(browser);

      if (cookieFile != null) {
        // Save to secure storage
        await SecureStorageService.instance.saveCookiePath(cookieFile);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastBrowserKey, browser);
        // We don't save to _cookieFileKey anymore in prefs
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Cookie extraction failed', error: e);
      return false;
    }
  }

  /// Check if cookies are available and the file actually exists
  static Future<bool> hasCookies() async {
    final cookieFile = await getCookieFile();
    if (cookieFile == null || cookieFile.isEmpty) {
      return false;
    }
    // Verify the file actually exists on disk
    try {
      return await File(cookieFile).exists();
    } catch (e) {
      AppLogger.error('Error checking cookie file existence', error: e);
      return false;
    }
  }

  /// Clear stored cookies
  static Future<void> clearCookies() async {
    await SecureStorageService.instance.deleteCookiePath();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cookieFileKey);
    await prefs.remove(_lastBrowserKey);
  }

  /// Get last used browser
  static Future<String?> getLastBrowser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastBrowserKey);
  }
}
