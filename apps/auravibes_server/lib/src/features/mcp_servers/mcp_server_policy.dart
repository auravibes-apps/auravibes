import 'dart:io';

import 'package:auravibes_engine/auravibes_engine.dart';

abstract final class McpServerPolicy {
  static const maxResponseBytes = 1024 * 1024;
  static const maxTools = McpDiscoveryPolicy.maxTools;

  static Uri validateUri(String value) =>
      requirePublicUriSyntax(value, requireHttps: true);

  static void validateAddresses(List<InternetAddress> addresses) {
    if (addresses.isEmpty ||
        addresses.any(
          (address) => isPrivateIpAddress(
            address.rawAddress,
            isIpv6: address.type == InternetAddressType.IPv6,
          ),
        )) {
      throw const FormatException(publicUrlError);
    }
  }

  static String boundedSchema(Object? schema) =>
      McpDiscoveryPolicy.boundedSchema(schema);
}
