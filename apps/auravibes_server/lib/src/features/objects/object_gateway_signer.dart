import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'object_gateway_config.dart';

class ObjectGatewayClaims {
  const ObjectGatewayClaims({
    required this.method,
    required this.key,
    required this.expiresAtSeconds,
    required this.nonce,
    this.contentType,
    this.length,
    this.checksumSha256,
    this.contentDisposition,
    this.registrationId,
  });

  final String method;
  final String key;
  final int expiresAtSeconds;
  final String nonce;
  final String? contentType;
  final int? length;
  final String? checksumSha256;
  final String? contentDisposition;
  final String? registrationId;

  bool get isLegacy => registrationId == null;

  Map<String, Object?> toJson() => {
    'm': method,
    'k': key,
    'e': expiresAtSeconds,
    if (contentType != null) 't': contentType,
    if (length != null) 'l': length,
    if (checksumSha256 != null) 'c': checksumSha256,
    if (contentDisposition != null) 'd': contentDisposition,
    'n': nonce,
    'r': registrationId ?? '',
  };

  static ObjectGatewayClaims? tryParse(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final method = value['m'];
    final key = value['k'];
    final expires = value['e'];
    final nonce = value['n'];
    final registrationId = value['r'];
    if (method is! String ||
        key is! String ||
        expires is! int ||
        nonce is! String ||
        (registrationId != null && registrationId is! String)) {
      return null;
    }
    final contentType = value['t'];
    final length = value['l'];
    final checksum = value['c'];
    final disposition = value['d'];
    if ((contentType != null && contentType is! String) ||
        (length != null && length is! int) ||
        (checksum != null && checksum is! String) ||
        (disposition != null && disposition is! String)) {
      return null;
    }
    return ObjectGatewayClaims(
      method: method,
      key: key,
      expiresAtSeconds: expires,
      nonce: nonce,
      contentType: contentType as String?,
      length: length as int?,
      checksumSha256: checksum as String?,
      contentDisposition: disposition as String?,
      registrationId: (registrationId as String?)?.isEmpty == true
          ? null
          : registrationId,
    );
  }
}

class ObjectGatewaySigner {
  ObjectGatewaySigner(this.config);

  final ObjectGatewayConfig config;
  final Random _random = Random.secure();

  String sign(ObjectGatewayClaims claims) {
    final payload = _base64UrlWithoutPadding(
      utf8.encode(jsonEncode(claims.toJson())),
    );
    final signature = Hmac(
      sha256,
      config.signingKey,
    ).convert(utf8.encode(payload)).bytes;
    return '$payload.${_base64UrlWithoutPadding(signature)}';
  }

  ObjectGatewayClaims? verify(String token) {
    if (token.length > 8192) return null;
    final parts = token.split('.');
    if (parts.length != 2) return null;
    final expected = Hmac(
      sha256,
      config.signingKey,
    ).convert(utf8.encode(parts.first)).bytes;
    final actual = _decodeBase64Url(parts.last);
    if (actual == null || !_constantTimeEquals(expected, actual)) return null;
    final payload = _decodeBase64Url(parts.first);
    if (payload == null) return null;
    try {
      return ObjectGatewayClaims.tryParse(jsonDecode(utf8.decode(payload)));
    } on FormatException {
      return null;
    }
  }

  Uri url(String key, ObjectGatewayClaims claims) =>
      config.publicBaseUrl.replace(
        path: '${config.publicBaseUrl.path}/$key',
        queryParameters: {'token': sign(claims)},
      );

  String nonce() => List<int>.generate(
    24,
    (_) => _random.nextInt(256),
  ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

  static String _base64UrlWithoutPadding(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  static List<int>? _decodeBase64Url(String value) {
    if (!RegExp(r'^[A-Za-z0-9_-]*$').hasMatch(value)) return null;
    final normalized = value.padRight(
      value.length + (4 - value.length % 4) % 4,
      '=',
    );
    try {
      return base64Url.decode(normalized);
    } on FormatException {
      return null;
    }
  }

  static bool _constantTimeEquals(List<int> left, List<int> right) {
    var difference = left.length ^ right.length;
    final length = max(left.length, right.length);
    for (var index = 0; index < length; index++) {
      final a = index < left.length ? left[index] : 0;
      final b = index < right.length ? right[index] : 0;
      difference |= a ^ b;
    }
    return difference == 0;
  }
}
