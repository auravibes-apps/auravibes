import 'dart:async';
import 'dart:io';

import 'package:auravibes_app/services/url/public_url_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns validated addresses for transport pinning', () async {
    final resolved = await PublicUrlGuard.resolvePublicUri(
      'https://public.example/path',
      requireHttps: true,
      lookup: (_) async => [InternetAddress('8.8.8.8')],
    );

    expect(resolved.uri.toString(), 'https://public.example/path');
    expect(resolved.addresses, ['8.8.8.8']);
  });

  test('bounds hanging DNS lookups', () async {
    final lookup = Completer<List<InternetAddress>>();

    await expectLater(
      PublicUrlGuard.resolvePublicUri(
        'https://public.example/path',
        requireHttps: true,
        lookup: (_) => lookup.future,
        dnsTimeout: const Duration(milliseconds: 1),
      ),
      throwsA(isA<TimeoutException>()),
    );
  });
}
