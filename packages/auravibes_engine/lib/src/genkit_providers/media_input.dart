import 'dart:convert';

import 'package:genkit/plugin.dart';

String? dataUrlPayload(String url) {
  final comma = url.indexOf(',');
  if (!url.startsWith('data:') || comma < 0) return null;
  final header = url.replaceRange(comma, url.length, '');
  if (!header.contains(';base64')) return null;

  final payload = url.replaceRange(0, comma + 1, '');
  try {
    final _ = base64Decode(payload);
  } on FormatException {
    return null;
  }

  return payload;
}

String audioFormat(String contentType, String providerName) {
  if (contentType == 'audio/mpeg' || contentType == 'audio/mp3') return 'mp3';
  if (contentType == 'audio/wav' || contentType == 'audio/x-wav') return 'wav';

  throw GenkitException(
    '$providerName audio input supports only mp3 and wav.',
    status: .INVALID_ARGUMENT,
  );
}
