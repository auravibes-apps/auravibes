import 'dart:convert';

import 'package:crypto/crypto.dart';

String sha256Utf8(String value) {
  final digestSink = _DigestSink();
  final bytes = sha256.startChunkedConversion(digestSink);
  utf8.encoder.startChunkedConversion(bytes)
    ..add(value)
    ..close();

  return (digestSink.digest ?? (throw StateError('Digest is missing')))
      .toString();
}

class _DigestSink implements Sink<Digest> {
  Digest? digest;

  @override
  void add(Digest value) {
    digest = value;
  }

  @override
  void close() {}
}
