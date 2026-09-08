import 'dart:io';

import 'package:auravibes_engine/auravibes_engine.dart';

abstract final class PublicUrlGuard {
  static Future<Uri> requireHttpsUri(String url) async {
    final uri = requirePublicUriSyntax(url, requireHttps: true);

    await ensureHost(uri.host);

    return uri;
  }

  static Future<InternetAddress> requirePublicAddress(String host) async {
    if (isBlockedHostLabel(host)) {
      throw const FormatException(publicUrlError);
    }

    final literalAddress = InternetAddress.tryParse(host);
    if (literalAddress != null) {
      if (_isPrivateAddress(literalAddress)) {
        throw const FormatException(publicUrlError);
      }

      return literalAddress;
    }

    final addresses = await InternetAddress.lookup(host);
    final address = addresses.firstOrNull;
    if (address == null || addresses.any(_isPrivateAddress)) {
      throw const FormatException(publicUrlError);
    }

    return address;
  }

  static Future<void> ensureHost(String host) async {
    final _ = await requirePublicAddress(host);
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
