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

  return normalizedHost == 'localhost' || normalizedHost.endsWith('.localhost');
}

bool isPrivateIpAddress(List<int> bytes, {required bool isIpv6}) {
  if (!isIpv6) return _isPrivateIpv4(bytes);
  if (bytes.length != 16) return false;

  final isMapped =
      bytes.take(10).every((byte) => byte == 0) &&
      bytes[10] == 0xff &&
      bytes[11] == 0xff;
  if (isMapped) return _isPrivateIpv4(bytes.sublist(12));

  final isUnspecified = bytes.every((byte) => byte == 0);

  return isUnspecified ||
      bytes.first == 0xfc ||
      bytes.first == 0xfd ||
      bytes.first == 0xff ||
      (bytes.first == 0xfe && (bytes[1] & 0xc0) == 0x80) ||
      bytes.sublist(0, 15).every((byte) => byte == 0) && bytes.last == 1;
}

bool _isPrivateIpv4(List<int> bytes) {
  if (bytes.length != 4) return false;
  final first = bytes.first;

  return first == 10 ||
      (first == 172 && bytes[1] >= 16 && bytes[1] <= 31) ||
      (first == 192 && bytes[1] == 168) ||
      (first == 169 && bytes[1] == 254) ||
      first == 127 ||
      first == 0 ||
      (first == 100 && bytes[1] >= 64 && bytes[1] <= 127) ||
      (first == 192 && bytes[1] == 0 && bytes[2] == 2) ||
      (first == 198 && (bytes[1] == 18 || bytes[1] == 19)) ||
      (first == 198 && bytes[1] == 51 && bytes[2] == 100) ||
      (first == 203 && bytes[1] == 0 && bytes[2] == 113) ||
      (first >= 224 && first <= 239) ||
      first >= 240;
}

bool _isHttpScheme(String scheme) => scheme == 'http' || scheme == 'https';
