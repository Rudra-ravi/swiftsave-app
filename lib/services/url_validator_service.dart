import 'dart:io';

/// Secure URL validation with SSRF protection
class UrlValidatorService {
  static const Set<String> _blockedHostLiterals = {
    'localhost',
    'localhost.localdomain',
    'ip6-localhost',
    '0.0.0.0',
    '::',
    '::1',
  };

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
    final host = _normalizeHost(uri.host);
    if (host.isEmpty) {
      return const ValidationResult.invalid('URL host is empty');
    }

    if (_isBlockedHost(host)) {
      return const ValidationResult.invalid('URL points to restricted network');
    }

    final ipAddress = InternetAddress.tryParse(host);
    if (ipAddress != null && _isRestrictedAddress(ipAddress)) {
      return const ValidationResult.invalid('URL points to restricted network');
    }

    final isKnown = _knownDomains.any((d) => host == d || host.endsWith('.$d'));
    return ValidationResult.valid(isKnownSite: isKnown);
  }

  static String _normalizeHost(String host) {
    var normalized = host.trim().toLowerCase();
    if (normalized.startsWith('[') && normalized.endsWith(']')) {
      normalized = normalized.substring(1, normalized.length - 1);
    }
    if (normalized.endsWith('.')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  static bool _isBlockedHost(String host) {
    if (_blockedHostLiterals.contains(host)) {
      return true;
    }
    if (host.endsWith('.localhost') || host.endsWith('.local')) {
      return true;
    }
    return false;
  }

  static bool _isRestrictedAddress(InternetAddress address) {
    final raw = address.rawAddress;

    if (address.type == InternetAddressType.IPv4) {
      return _isRestrictedIpv4(raw[0], raw[1]);
    }

    if (address.isLoopback || address.isLinkLocal || address.isMulticast) {
      return true;
    }

    final isUnspecified = raw.every((b) => b == 0);
    if (isUnspecified) {
      return true;
    }

    // Unique local addresses fc00::/7
    if ((raw[0] & 0xfe) == 0xfc) {
      return true;
    }

    // Deprecated site-local addresses fec0::/10
    if (raw[0] == 0xfe && (raw[1] & 0xc0) == 0xc0) {
      return true;
    }

    // IPv4-mapped IPv6 addresses ::ffff:w.x.y.z
    final isIpv4Mapped =
        raw.length == 16 &&
        raw.sublist(0, 10).every((b) => b == 0) &&
        raw[10] == 0xff &&
        raw[11] == 0xff;
    if (isIpv4Mapped) {
      return _isRestrictedIpv4(raw[12], raw[13]);
    }

    return false;
  }

  static bool _isRestrictedIpv4(int first, int second) {
    if (first == 0 ||
        first == 10 ||
        first == 127 ||
        first >= 224 ||
        (first == 100 && second >= 64 && second <= 127) ||
        (first == 169 && second == 254) ||
        (first == 172 && second >= 16 && second <= 31) ||
        (first == 192 && second == 168) ||
        (first == 198 && (second == 18 || second == 19))) {
      return true;
    }
    return false;
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
