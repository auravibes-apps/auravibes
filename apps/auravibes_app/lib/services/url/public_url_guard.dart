import 'dart:io';

import 'package:auravibes_engine/auravibes_engine.dart';

abstract final class PublicUrlGuard {
  static Future<Uri> requireHttpsUri(String url) async {
    final uri = requirePublicUriSyntax(url, requireHttps: true);

    await ensureHost(uri.host);

    return uri;
  }

  static Future<void> ensureHost(String host) async {
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

  static bool _isPrivateAddress(InternetAddress address) {
    return address.isLoopback ||
        address.isLinkLocal ||
        isPrivateIpAddress(
          address.rawAddress,
          isIpv6: address.type == InternetAddressType.IPv6,
        );
  }
}
