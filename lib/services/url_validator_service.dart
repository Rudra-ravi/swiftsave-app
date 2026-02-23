/// Secure URL validation with SSRF protection
class UrlValidatorService {
  static final List<String> _blockedPatterns = [
    r'^localhost$',
    r'^127\.',
    r'^10\.',
    r'^172\.(1[6-9]|2[0-9]|3[01])\.',
    r'^192\.168\.',
    r'^169\.254\.',
    r'^0\.0\.0\.0$',
    r'^\[::1\]$',
  ];

  static final Set<String> _knownDomains = {
    'youtube.com',
    'youtu.be',
    'vimeo.com',
    'twitter.com',
    'x.com',
    'instagram.com',
    'tiktok.com',
    'reddit.com',
    'twitch.tv',
  };

  static ValidationResult validate(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return const ValidationResult.invalid('Invalid URL format');
    }
    if (!{'http', 'https'}.contains(uri.scheme.toLowerCase())) {
      return const ValidationResult.invalid('Only HTTP/HTTPS allowed');
    }
    final host = uri.host.toLowerCase();
    for (final pattern in _blockedPatterns) {
      if (RegExp(pattern).hasMatch(host)) {
        return const ValidationResult.invalid(
          'URL points to restricted network',
        );
      }
    }
    final isKnown = _knownDomains.any((d) => host == d || host.endsWith('.$d'));
    return ValidationResult.valid(isKnownSite: isKnown);
  }
}

class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final bool isKnownSite;
  const ValidationResult.valid({this.isKnownSite = false})
    : isValid = true,
      errorMessage = null;
  const ValidationResult.invalid(this.errorMessage)
    : isValid = false,
      isKnownSite = false;
}
