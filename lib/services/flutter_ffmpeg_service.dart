import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/statistics.dart';

/// FFmpeg service using ffmpeg_kit_flutter for Android
/// Handles video/audio merging that yt-dlp can't do without binary FFmpeg
class FlutterFFmpegService {
  static FlutterFFmpegService? _instance;
  static FlutterFFmpegService get instance =>
      _instance ??= FlutterFFmpegService._();

  FlutterFFmpegService._();

  bool _initialized = false;
  String? _version;

  /// Whether FFmpegKit is available (Android only)
  bool get isAvailable => Platform.isAndroid && _initialized;

  /// FFmpeg version from FFmpegKit
  String? get version => _version;

  /// Initialize FFmpegKit
  Future<void> initialize() async {
    if (_initialized) return;
    if (!Platform.isAndroid) {
      _initialized = false;
      return;
    }

    try {
      // Get FFmpeg version to verify it works
      final session = await FFmpegKit.execute('-version');
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final output = await session.getOutput();
        _version = _parseVersion(output ?? '');
        _initialized = true;
        debugPrint(
          '[FlutterFFmpegService] Initialized successfully. Version: $_version',
        );
      } else {
        debugPrint('[FlutterFFmpegService] FFmpeg -version failed');
        _initialized = false;
      }
    } catch (e) {
      debugPrint('[FlutterFFmpegService] Initialization error: $e');
      _initialized = false;
    }
  }

  /// Parse version from FFmpeg output
  String? _parseVersion(String output) {
    final match = RegExp(r'ffmpeg version (\S+)').firstMatch(output);
    return match?.group(1) ?? 'unknown';
  }

  /// Merge video and audio files into a single MP4
  /// Returns the output file path on success, throws on failure
  Future<String> mergeVideoAudio({
    required String videoPath,
    required String audioPath,
    required String outputPath,
    void Function(double progress)? onProgress,
    int? totalDurationMs,
  }) async {
    if (!isAvailable) {
      throw Exception('FFmpegKit not available on this platform');
    }

    // Ensure output directory exists
    final outputDir = Directory(outputPath).parent;
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    // Delete output file if it exists
    final outputFile = File(outputPath);
    if (await outputFile.exists()) {
      await outputFile.delete();
    }

    debugPrint('[FlutterFFmpegService] Merging:');
    debugPrint('  Video: $videoPath');
    debugPrint('  Audio: $audioPath');
    debugPrint('  Output: $outputPath');

    // Build FFmpeg command
    // -i: input files
    // -c:v copy: copy video codec (no re-encoding)
    // -c:a aac: encode audio as AAC for compatibility
    // -strict experimental: allow experimental codecs
    // -shortest: finish when shortest stream ends
    final command =
        '-i "$videoPath" -i "$audioPath" -c:v copy -c:a aac -strict experimental -shortest "$outputPath"';

    // Enable statistics callback for progress
    if (onProgress != null && totalDurationMs != null) {
      FFmpegKitConfig.enableStatisticsCallback((Statistics statistics) {
        final timeMs = statistics.getTime();
        if (timeMs > 0 && totalDurationMs > 0) {
          final progress = (timeMs / totalDurationMs).clamp(0.0, 1.0);
          onProgress(progress);
        }
      });
    }

    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        debugPrint('[FlutterFFmpegService] Merge successful: $outputPath');

        // Verify output file exists and has content
        if (!await outputFile.exists() || await outputFile.length() == 0) {
          throw Exception('Output file was not created or is empty');
        }

        return outputPath;
      } else if (ReturnCode.isCancel(returnCode)) {
        throw Exception('Merge was cancelled');
      } else {
        final logs = await session.getAllLogsAsString();
        debugPrint('[FlutterFFmpegService] Merge failed. Logs: $logs');
        throw Exception(
          'FFmpeg merge failed with code: ${returnCode?.getValue()}',
        );
      }
    } finally {
      // Disable statistics callback
      FFmpegKitConfig.enableStatisticsCallback(null);
    }
  }

  /// Cancel any running FFmpeg operation
  Future<void> cancel() async {
    await FFmpegKit.cancel();
  }

  /// Clean up temporary video/audio files after successful merge
  Future<void> cleanupTempFiles(String videoPath, String audioPath) async {
    try {
      final videoFile = File(videoPath);
      final audioFile = File(audioPath);

      if (await videoFile.exists()) {
        await videoFile.delete();
        debugPrint('[FlutterFFmpegService] Deleted temp video: $videoPath');
      }

      if (await audioFile.exists()) {
        await audioFile.delete();
        debugPrint('[FlutterFFmpegService] Deleted temp audio: $audioPath');
      }
    } catch (e) {
      debugPrint('[FlutterFFmpegService] Cleanup error: $e');
    }
  }

  /// Get recommended format string for yt-dlp based on FFmpegKit availability
  /// On Android with FFmpegKit, we can download video+audio separately and merge
  String getRecommendedFormat({int? maxHeight}) {
    final heightLimit = maxHeight ?? 2160;

    if (isAvailable) {
      // With FFmpegKit, we'll download separately and merge in Flutter
      // Return format that selects best video AND best audio separately
      return 'bestvideo[height<=$heightLimit]+bestaudio/best[height<=$heightLimit]/best';
    } else {
      // Without FFmpegKit, prefer pre-merged formats
      return 'best[ext=mp4][height<=$heightLimit]/best[height<=$heightLimit]/best';
    }
  }
}
