/// Sanitizes filenames to prevent path traversal
class PathSanitizer {
  static final RegExp _unsafeChars = RegExp(r'[<>:"/\\|?*\x00-\x1F]');
  static final RegExp _pathTraversal = RegExp(r'\.\.[\\/]|[\\/]\.\.|\.\.');
  static const int _maxLength = 200;

  static String sanitizeFilename(String filename) {
    if (filename.isEmpty) {
      return 'untitled_${DateTime.now().millisecondsSinceEpoch}';
    }
    var safe = filename
        .replaceAll(_pathTraversal, '_')
        .replaceAll(_unsafeChars, '_');
    safe = safe
        .trim()
        .replaceAll(RegExp(r'^\\.+|\\.+$'), '')
        .replaceAll(RegExp(r'_+'), '_');
    if (safe.length > _maxLength) {
      safe = safe.substring(0, _maxLength);
    }
    return safe.isEmpty
        ? 'download_${DateTime.now().millisecondsSinceEpoch}'
        : safe;
  }
}
