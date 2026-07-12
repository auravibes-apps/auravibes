import 'dart:io';

import 'package:auravibes_engine/auravibes_engine.dart';

Future<Uri> requirePublicHttpsUri(String url) async {
  final uri = requirePublicUriSyntax(url, requireHttps: true);

  await ensurePublicHost(uri.host);

  return uri;
}

Future<void> ensurePublicHost(String host) async {
  if (isBlockedHostLabel(host)) {
    throw const FormatException(publicUrlError);
  }

  final literalAddress = InternetAddress.tryParse(host);
  if (literalAddress != null) {
    if (_isPrivateAddress(literalAddress)) {
      throw const FormatException(publicUrlError);
    }

    return;
  }

  final addresses = await InternetAddress.lookup(host);
  if (addresses.isEmpty || addresses.any(_isPrivateAddress)) {
    throw const FormatException(publicUrlError);
  }
}

bool _isPrivateAddress(InternetAddress address) {
  return address.isLoopback ||
      address.isLinkLocal ||
      isPrivateIpAddress(
        address.rawAddress,
        isIpv6: address.type == InternetAddressType.IPv6,
      );
}
