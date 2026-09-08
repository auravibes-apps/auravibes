import 'dart:io';

import 'package:auravibes_engine/auravibes_engine.dart';

typedef PublicUrlLookup = Future<List<InternetAddress>> Function(String host);
typedef PublicUrlResolution = ({Uri uri, List<String> addresses});

abstract final class PublicUrlGuard {
  static Future<PublicUrlResolution> resolvePublicUri(
    String url, {
    required bool requireHttps,
    PublicUrlLookup lookup = InternetAddress.lookup,
  }) async {
    final uri = requirePublicUriSyntax(url, requireHttps: requireHttps);
    final addresses = await _resolveAddresses(uri.host, lookup: lookup);

    return (
      uri: uri,
      addresses: addresses
          .map((address) => address.address)
          .toList(growable: false),
    );
  }

  static Future<PublicUrlResolution> resolveHttpsUri(String url) =>
      resolvePublicUri(url, requireHttps: true);

  static Future<Uri> requireHttpsUri(String url) async {
    return (await resolveHttpsUri(url)).uri;
  }

  static Future<InternetAddress> requirePublicAddress(
    String host, {
    PublicUrlLookup lookup = InternetAddress.lookup,
  }) async {
    final addresses = await _resolveAddresses(host, lookup: lookup);

    final address = addresses.firstOrNull;
    if (address == null) {
      throw const FormatException(publicUrlError);
    }

    return address;
  }

  static Future<void> ensureHost(String host) async {
    final _ = await requirePublicAddress(host);
  }

  static Future<List<InternetAddress>> _resolveAddresses(
    String host, {
    required PublicUrlLookup lookup,
  }) async {
    if (isBlockedHostLabel(host)) {
      throw const FormatException(publicUrlError);
    }

    final literalAddress = InternetAddress.tryParse(host);
    if (literalAddress != null) {
      if (_isPrivateAddress(literalAddress)) {
        throw const FormatException(publicUrlError);
      }

      return [literalAddress];
    }

    final addresses = await lookup(host);
    if (addresses.isEmpty || addresses.any(_isPrivateAddress)) {
      throw const FormatException(publicUrlError);
    }

    return addresses;
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
