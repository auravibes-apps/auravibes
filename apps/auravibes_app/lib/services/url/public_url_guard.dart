import 'dart:io';

const _publicUrlError = 'URL must use a public HTTPS host.';

Future<Uri> requirePublicHttpsUri(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    throw const FormatException(_publicUrlError);
  }
  if (uri.scheme != 'https' || uri.userInfo.isNotEmpty) {
    throw const FormatException(_publicUrlError);
  }

  await ensurePublicHost(uri.host);

  return uri;
}

Future<void> ensurePublicHost(String host) async {
  if (_isBlockedHostLabel(host)) {
    throw const FormatException(_publicUrlError);
  }

  final literalAddress = InternetAddress.tryParse(host);
  if (literalAddress != null) {
    if (_isPrivateAddress(literalAddress)) {
      throw const FormatException(_publicUrlError);
    }

    return;
  }

  final addresses = await InternetAddress.lookup(host);
  if (addresses.isEmpty || addresses.any(_isPrivateAddress)) {
    throw const FormatException(_publicUrlError);
  }
}

bool _isBlockedHostLabel(String host) {
  final normalizedHost = host.toLowerCase();

  return normalizedHost == 'localhost' || normalizedHost.endsWith('.localhost');
}

bool _isPrivateAddress(InternetAddress address) {
  if (address.isLoopback || address.isLinkLocal) return true;

  final raw = address.rawAddress;
  if (address.type == InternetAddressType.IPv4) {
    return _isPrivateIPv4(raw);
  }

  if (address.type == InternetAddressType.IPv6 && raw.length == 16) {
    final isMapped =
        raw.take(10).every((byte) => byte == 0) &&
        raw[10] == 0xff &&
        raw[11] == 0xff;
    if (isMapped) return _isPrivateIPv4(raw.sublist(12));
  }

  final isUnspecified = raw.every((b) => b == 0);

  return isUnspecified ||
      raw.firstOrNull == 0xfc ||
      raw.firstOrNull == 0xfd ||
      raw.firstOrNull == 0xff ||
      (raw.firstOrNull == 0xfe && (raw[1] & 0xc0) == 0x80);
}

bool _isPrivateIPv4(List<int> b) {
  final firstByte = b.firstOrNull;
  if (firstByte == null) return false;

  return firstByte == 10 ||
      (firstByte == 172 && b[1] >= 16 && b[1] <= 31) ||
      (firstByte == 192 && b[1] == 168) ||
      (firstByte == 169 && b[1] == 254) ||
      firstByte == 127 ||
      firstByte == 0 ||
      (firstByte == 100 && b[1] >= 64 && b[1] <= 127) ||
      (firstByte == 192 && b[1] == 0 && b[2] == 2) ||
      (firstByte == 198 && (b[1] == 18 || b[1] == 19)) ||
      (firstByte == 198 && b[1] == 51 && b[2] == 100) ||
      (firstByte == 203 && b[1] == 0 && b[2] == 113) ||
      (firstByte >= 224 && firstByte <= 239) ||
      firstByte >= 240;
}
