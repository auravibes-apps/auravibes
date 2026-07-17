import 'dart:convert';
import 'dart:io';

import 'package:auravibes_engine/auravibes_engine.dart';

abstract final class McpServerPolicy {
  static const maxResponseBytes = 1024 * 1024;
  static const maxTools = 100;
  static const maxSchemaBytes = 64 * 1024;
  static const maxSchemaDepth = 16;

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

  static String boundedSchema(Object? schema) {
    _validateJson(schema, 0);
    final encoded = jsonEncode(schema);
    if (utf8.encode(encoded).length > maxSchemaBytes) {
      throw const FormatException('MCP tool schema is too large.');
    }
    return encoded;
  }

  static void _validateJson(Object? value, int depth) {
    if (depth > maxSchemaDepth) {
      throw const FormatException('MCP tool schema is too deep.');
    }
    switch (value) {
      case Map<Object?, Object?>():
        for (final entry in value.entries) {
          if (entry.key is! String) {
            throw const FormatException(
              'MCP tool schema has a non-string key.',
            );
          }
          _validateJson(entry.value, depth + 1);
        }
      case List<Object?>():
        for (final item in value) {
          _validateJson(item, depth + 1);
        }
      case null || String() || num() || bool():
        return;
      default:
        throw const FormatException('MCP tool schema is not JSON.');
    }
  }
}
