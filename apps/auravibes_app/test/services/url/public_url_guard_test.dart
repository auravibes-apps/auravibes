import 'dart:async';
import 'dart:io';

import 'package:auravibes_app/services/url/public_url_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final url in [
    'https://127.0.0.1/path',
    'https://10.0.0.1/path',
    'https://169.254.1.1/path',
    'https://[::1]/path',
    'https://[::ffff:127.0.0.1]/path',
  ]) {
    test('rejects blocked address literal $url before DNS lookup', () async {
      var lookupCalled = false;

      await expectLater(
        PublicUrlGuard.resolveHttpsUri(
          url,
          lookup: (_) async {
            lookupCalled = true;

            return [InternetAddress('8.8.8.8')];
          },
        ),
        throwsA(isA<FormatException>()),
      );
      expect(lookupCalled, isFalse);
    });
  }

  for (final blockedAddress in [
    InternetAddress.loopbackIPv4,
    InternetAddress('10.0.0.1'),
    InternetAddress('169.254.1.1'),
    InternetAddress('::1'),
    InternetAddress('::ffff:127.0.0.1'),
  ]) {
    test('rejects DNS answers containing $blockedAddress', () async {
      await expectLater(
        PublicUrlGuard.resolveHttpsUri(
          'https://mixed-answer.example/path',
          lookup: (_) async => [InternetAddress('8.8.8.8'), blockedAddress],
        ),
        throwsA(isA<FormatException>()),
      );
    });
  }

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
