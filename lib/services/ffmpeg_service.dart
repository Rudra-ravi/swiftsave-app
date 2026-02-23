import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'flutter_ffmpeg_service.dart';

/// Service for managing FFmpeg availability and configuration
/// Supports Android (via FFmpegKit), Windows, and Linux (system binary)
class FFmpegService {
  static FFmpegService? _instance;
  static FFmpegService get instance => _instance ??= FFmpegService._();

  FFmpegService._();

  bool _isAvailable = false;
  String? _ffmpegPath;
  String? _ffmpegVersion;
  bool _initialized = false;
  bool _useFlutterFFmpeg = false; // True when using FFmpegKit on Android

  /// Whether FFmpeg is available on this platform
  bool get isAvailable => _isAvailable;

  /// Path to FFmpeg binary (null for bundled Android FFmpeg)
  String? get ffmpegPath => _ffmpegPath;

  /// FFmpeg version string
  String? get version => _ffmpegVersion;

  /// Whether using FFmpegKit (Flutter-based merging on Android)
  bool get useFlutterFFmpeg => _useFlutterFFmpeg;

  /// Initialize FFmpeg availability check
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (Platform.isAndroid) {
        // On Android, yt-dlp typically uses bundled FFmpeg from Chaquopy
        // or we can check if ffmpeg is available in the python environment
        _isAvailable = await _checkAndroidFFmpeg();
      } else if (Platform.isWindows) {
        _isAvailable = await _checkWindowsFFmpeg();
      } else if (Platform.isLinux) {
        _isAvailable = await _checkLinuxFFmpeg();
      } else if (Platform.isMacOS) {
        _isAvailable = await _checkMacOSFFmpeg();
      }

      _initialized = true;
      debugPrint(
        '[FFmpegService] FFmpeg available: $_isAvailable, path: $_ffmpegPath, version: $_ffmpegVersion',
      );
    } catch (e) {
      debugPrint('[FFmpegService] Error checking FFmpeg: $e');
      _isAvailable = false;
      _initialized = true;
    }
  }

  /// Check FFmpeg on Android via FFmpegKit
  Future<bool> _checkAndroidFFmpeg() async {
    try {
      // Initialize FlutterFFmpegService (uses ffmpeg_kit_flutter)
      final flutterFFmpeg = FlutterFFmpegService.instance;
      await flutterFFmpeg.initialize();

      if (flutterFFmpeg.isAvailable) {
        _useFlutterFFmpeg = true;
        _ffmpegVersion = flutterFFmpeg.version;
        debugPrint('[FFmpegService] FFmpegKit available: $_ffmpegVersion');
        return true;
      }
    } catch (e) {
      debugPrint('[FFmpegService] FFmpegKit check failed: $e');
    }

    // FFmpegKit not available
    _useFlutterFFmpeg = false;
    return false;
  }

  /// Check FFmpeg on Windows
  Future<bool> _checkWindowsFFmpeg() async {
    // Check common Windows FFmpeg locations
    final possiblePaths = [
      'ffmpeg.exe', // In PATH
      r'C:\ffmpeg\bin\ffmpeg.exe',
      r'C:\Program Files\ffmpeg\bin\ffmpeg.exe',
      r'C:\Program Files (x86)\ffmpeg\bin\ffmpeg.exe',
    ];

    // Also check in app's bundled location
    try {
      final appDir = await getApplicationSupportDirectory();
      possiblePaths.add('${appDir.path}\\ffmpeg\\ffmpeg.exe');
    } catch (_) {}

    for (final path in possiblePaths) {
      if (await _testFFmpegPath(path)) {
        _ffmpegPath = path;
        return true;
      }
    }

    return false;
  }

  /// Check FFmpeg on Linux
  Future<bool> _checkLinuxFFmpeg() async {
    // Check common Linux FFmpeg locations
    final possiblePaths = [
      'ffmpeg', // In PATH
      '/usr/bin/ffmpeg',
      '/usr/local/bin/ffmpeg',
      '/snap/bin/ffmpeg',
    ];

    // Also check in app's bundled location
    try {
      final appDir = await getApplicationSupportDirectory();
      possiblePaths.add('${appDir.path}/ffmpeg/ffmpeg');
    } catch (_) {}

    for (final path in possiblePaths) {
      if (await _testFFmpegPath(path)) {
        _ffmpegPath = path;
        return true;
      }
    }

    return false;
  }

  /// Check FFmpeg on macOS
  Future<bool> _checkMacOSFFmpeg() async {
    final possiblePaths = [
      'ffmpeg', // In PATH
      '/usr/local/bin/ffmpeg',
      '/opt/homebrew/bin/ffmpeg',
    ];

    for (final path in possiblePaths) {
      if (await _testFFmpegPath(path)) {
        _ffmpegPath = path;
        return true;
      }
    }

    return false;
  }

  /// Validate if the FFmpeg path is in a trusted location
  bool _isTrustedPath(String ffmpegPath) {
    if (Platform.isWindows) {
      final trusted = [
        r'C:\Program Files\',
        r'C:\Program Files (x86)\',
        r'C:\Windows\System32\',
      ];
      return trusted.any(
            (p) => ffmpegPath.toLowerCase().startsWith(p.toLowerCase()),
          ) ||
          ffmpegPath == 'ffmpeg.exe';
    } else if (Platform.isLinux || Platform.isMacOS) {
      final trusted = [
        '/usr/bin/',
        '/usr/local/bin/',
        '/opt/homebrew/bin/',
        '/snap/bin/',
      ];
      return trusted.any((p) => ffmpegPath.startsWith(p)) ||
          ffmpegPath == 'ffmpeg';
    }
    return false;
  }

  /// Test if FFmpeg is available at the given path
  Future<bool> _testFFmpegPath(String path) async {
    if (!_isTrustedPath(path)) return false;

    try {
      final result = await Process.run(path, ['-version']);
      if (result.exitCode == 0) {
        // Extract version from output
        final versionLine = result.stdout.toString().split('\n').first;
        _ffmpegVersion = _parseVersion(versionLine);
        return true;
      }
    } catch (_) {
      // Path not found or not executable
    }
    return false;
  }

  /// Parse version from FFmpeg output
  String? _parseVersion(String versionLine) {
    // ffmpeg version 6.0 Copyright ...
    final match = RegExp(r'ffmpeg version (\S+)').firstMatch(versionLine);
    return match?.group(1);
  }

  /// Get FFmpeg capabilities description
  String getCapabilitiesDescription() {
    if (!_isAvailable) {
      return 'FFmpeg not available - limited format support';
    }

    return 'FFmpeg ${_ffmpegVersion ?? ""} available - full format merging enabled';
  }

  /// Get format selection recommendation based on FFmpeg availability
  String getRecommendedFormat({int? maxHeight}) {
    final heightLimit = maxHeight ?? 2160;

    if (_isAvailable) {
      // With FFmpeg, we can merge video + audio for best quality
      return 'bestvideo[height<=$heightLimit]+bestaudio/best[height<=$heightLimit]/best';
    } else {
      // Without FFmpeg, prefer pre-merged formats
      return 'best[ext=mp4][height<=$heightLimit]/best[height<=$heightLimit]/best';
    }
  }

  /// Instructions for installing FFmpeg on the current platform
  String getInstallInstructions() {
    if (Platform.isWindows) {
      return '''
To install FFmpeg on Windows:
1. Download from https://ffmpeg.org/download.html
2. Extract to C:\\ffmpeg
3. Add C:\\ffmpeg\\bin to your PATH
4. Restart the app
''';
    } else if (Platform.isLinux) {
      return '''
To install FFmpeg on Linux:
  Ubuntu/Debian: apt install ffmpeg
  Fedora: dnf install ffmpeg
  Arch: pacman -S ffmpeg
''';
    } else if (Platform.isMacOS) {
      return '''
To install FFmpeg on macOS:
  brew install ffmpeg
''';
    } else if (Platform.isAndroid) {
      if (_useFlutterFFmpeg) {
        return 'FFmpeg is bundled with the app. Best quality merging enabled.';
      }
      return 'FFmpeg bundled via FFmpegKit. If issues persist, reinstall the app.';
    }

    return 'Please install FFmpeg for your platform.';
  }

  /// Refresh FFmpeg availability (e.g., after user installs it)
  Future<void> refresh() async {
    _initialized = false;
    _isAvailable = false;
    _ffmpegPath = null;
    _ffmpegVersion = null;
    await initialize();
  }
}
