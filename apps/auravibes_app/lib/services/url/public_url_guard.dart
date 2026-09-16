import 'dart:io';

import 'package:auravibes_engine/auravibes_engine.dart';

typedef PublicUrlLookup = Future<List<InternetAddress>> Function(String host);
typedef PublicUrlResolution = ({Uri uri, List<String>? addresses});

// Shared default used by the public URL guard API.
// ignore: prefer-static-class
const publicUrlDnsTimeout = Duration(seconds: 5);

abstract final class PublicUrlGuard {
  static Future<PublicUrlResolution> resolvePublicUri(
    String url, {
    required bool requireHttps,
    PublicUrlLookup lookup = InternetAddress.lookup,
    Duration dnsTimeout = publicUrlDnsTimeout,
  }) async {
    final uri = requirePublicUriSyntax(url, requireHttps: requireHttps);
    final addresses = await _resolveAddresses(
      uri.host,
      lookup: lookup,
      dnsTimeout: dnsTimeout,
    );

    final addressesForPinning = _addressesForPinning(uri.host, addresses);

    return (uri: uri, addresses: addressesForPinning);
  }

  static Future<PublicUrlResolution> resolveHttpsUri(
    String url, {
    PublicUrlLookup lookup = InternetAddress.lookup,
    Duration dnsTimeout = publicUrlDnsTimeout,
  }) => resolvePublicUri(
    url,
    requireHttps: true,
    lookup: lookup,
    dnsTimeout: dnsTimeout,
  );

  static Future<Uri> requireHttpsUri(String url) async {
    return (await resolveHttpsUri(url)).uri;
  }

  static Future<InternetAddress> requirePublicAddress(
    String host, {
    PublicUrlLookup lookup = InternetAddress.lookup,
    Duration dnsTimeout = publicUrlDnsTimeout,
  }) async {
    final addresses = await _resolveAddresses(
      host,
      lookup: lookup,
      dnsTimeout: dnsTimeout,
    );

    final address = addresses.firstOrNull;
    if (address == null) {
      throw const FormatException(publicUrlError);
    }

    return address;
  }

  static Future<void> ensureHost(
    String host, {
    Duration dnsTimeout = publicUrlDnsTimeout,
  }) async {
    final _ = await requirePublicAddress(host, dnsTimeout: dnsTimeout);
  }

  static Future<List<InternetAddress>> _resolveAddresses(
    String host, {
    required PublicUrlLookup lookup,
    required Duration dnsTimeout,
  }) async {
    if (isBlockedHostLabel(host)) {
      throw const FormatException(publicUrlError);
    }

    final literalAddress = InternetAddress.tryParse(host);
    if (literalAddress != null) {
      return _validatedLiteralAddress(literalAddress);
    }

    return _validatedLookup(await lookup(host).timeout(dnsTimeout));
  }

  static List<InternetAddress> _validatedLiteralAddress(
    InternetAddress address,
  ) {
    if (_isPrivateAddress(address)) throw const FormatException(publicUrlError);

    return [address];
  }

  static List<InternetAddress> _validatedLookup(
    List<InternetAddress> addresses,
  ) {
    if (addresses.isEmpty || addresses.any(_isPrivateAddress)) {
      throw const FormatException(publicUrlError);
    }

    return addresses;
  }
}

List<String>? _addressesForPinning(
  String host,
  List<InternetAddress> addresses,
) => InternetAddress.tryParse(host) == null
    ? addresses.map((address) => address.address).toList(growable: false)
    : null;

bool _isPrivateAddress(InternetAddress address) =>
    address.isLoopback ||
    address.isLinkLocal ||
    isPrivateIpAddress(
      address.rawAddress,
      isIpv6: address.type == InternetAddressType.IPv6,
    );
