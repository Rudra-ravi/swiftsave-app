import '../../../models/download_progress_event.dart';

class YtDlpProgressParser {
  static const _prefix = 'progress:';

  /// Expected format:
  /// `progress:<taskId>|<percent>|<downloadedBytes>|<totalBytes>|<speed>|<eta>`
  DownloadProgressEvent? parse(String line) {
    final trimmed = line.trim();
    if (!trimmed.startsWith(_prefix)) return null;

    final payload = trimmed.substring(_prefix.length);
    final parts = payload.split('|');
    if (parts.length < 6) return null;

    final taskId = parts[0].trim();
    if (taskId.isEmpty) return null;

    final progress = _parsePercent(parts[1]);
    final downloadedBytes = _parseInt(parts[2]);
    final totalBytes = _parseInt(parts[3]);
    final speed = _normalize(parts[4]);
    final eta = _normalize(parts[5]);

    return DownloadProgressEvent(
      taskId: taskId,
      progress: progress,
      downloadedBytes: downloadedBytes,
      totalBytes: totalBytes,
      speed: speed,
      eta: eta,
    );
  }

  double? _parsePercent(String raw) {
    final value = raw.replaceAll('%', '').trim();
    if (value.isEmpty || value == 'NA') return null;
    final parsed = double.tryParse(value);
    if (parsed == null) return null;
    return (parsed / 100).clamp(0.0, 1.0);
  }

  int? _parseInt(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value == 'NA') return null;
    return int.tryParse(value);
  }

  String? _normalize(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value == 'NA') return null;
    return value;
  }
}
