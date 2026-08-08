import 'dart:convert';

import 'package:crypto/crypto.dart';

String appStorageNamespaceFor(String? hashSource) {
  if (hashSource == null || hashSource.isEmpty) return 'auravibes_app';

  final digest = sha256.convert(utf8.encode(hashSource));
  final hashPrefix = digest.bytes
      .take(8)
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();

  return 'auravibes_app_$hashPrefix';
}
