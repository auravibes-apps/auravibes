const publicUrlError = 'URL must use a public HTTPS host.';
const publicHttpUrlError = 'URL must use a public HTTP or HTTPS host.';

Uri requirePublicUriSyntax(String url, {required bool requireHttps}) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    throw FormatException(_urlError(requireHttps));
  }
  if ((requireHttps ? uri.scheme != 'https' : !_isHttpScheme(uri.scheme)) ||
      uri.userInfo.isNotEmpty ||
      isBlockedHostLabel(uri.host)) {
    throw FormatException(_urlError(requireHttps));
  }

  return uri;
}

String _urlError(bool requireHttps) =>
    requireHttps ? publicUrlError : publicHttpUrlError;

bool isBlockedHostLabel(String host) {
  final normalizedHost = host.toLowerCase();
  final literalAddress = _literalAddressBytes(normalizedHost);

  return normalizedHost == 'localhost' ||
      normalizedHost.endsWith('.localhost') ||
      (literalAddress != null &&
          isPrivateIpAddress(literalAddress.$1, isIpv6: literalAddress.$2));
}

(List<int>, bool)? _literalAddressBytes(String host) {
  if (host.contains(':')) {
    try {
      return (Uri.parseIPv6Address(host), true);
    } on FormatException catch (_) {
      return null;
    }
  }
  final parts = host.split('.');
  if (parts.length != 4) return null;
  final bytes = parts.map(int.tryParse).toList();
  if (bytes.any((byte) => byte == null || byte < 0 || byte > 255)) return null;
  return (bytes.cast<int>(), false);
}

bool isPrivateIpAddress(List<int> bytes, {required bool isIpv6}) {
  if (!isIpv6) return _isPrivateIpv4(bytes);
  if (bytes.length != 16) return false;

  if (_isMappedIpv4(bytes)) return _isPrivateIpv4(bytes.sublist(12));
  return _isPrivateIpv6(bytes);
}

bool _isMappedIpv4(List<int> bytes) =>
    bytes.take(10).every((byte) => byte == 0) &&
    bytes[10] == 0xff &&
    bytes[11] == 0xff;

bool _isPrivateIpv6(List<int> bytes) {
  if (bytes.every((byte) => byte == 0)) return true;
  if (const {0xfc, 0xfd, 0xff}.contains(bytes.first)) return true;
  if (bytes.first == 0xfe && (bytes[1] & 0xc0) == 0x80) return true;
  return bytes.sublist(0, 15).every((byte) => byte == 0) && bytes.last == 1;
}

bool _isPrivateIpv4(List<int> bytes) {
  if (bytes.length != 4) return false;
  final first = bytes.first;

  return _isLocalIpv4(first, bytes[1]) ||
      _isDocumentationIpv4(first, bytes[1], bytes[2]) ||
      first >= 224;
}

bool _isLocalIpv4(int first, int second) {
  if (const {0, 10, 127}.contains(first)) return true;
  if (first == 172) return second >= 16 && second <= 31;
  if (first == 192 && second == 168) return true;
  if (first == 169 && second == 254) return true;
  return first == 100 && second >= 64 && second <= 127;
}

bool _isDocumentationIpv4(int first, int second, int third) {
  if (first == 192) return second == 0 && third == 2;
  if (first != 198) {
    return first == 203 && second == 0 && third == 113;
  }
  if (const {18, 19}.contains(second)) return true;
  return second == 51 && third == 100;
}

bool _isHttpScheme(String scheme) => scheme == 'http' || scheme == 'https';
