import 'dart:io';

import 'package:auravibes_server/src/features/objects/object_store.dart';
import 'package:test/test.dart';

void main() {
  test('signed private downloads request a no-store response', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final requestUri = server.first.then((request) async {
      final uri = request.uri;
      request.response.write('https://private.invalid/signed');
      await request.response.close();

      return uri;
    });
    final store = HttpObjectStore(
      legacyEndpoint: Uri(
        scheme: 'http',
        host: server.address.address,
        port: server.port,
        path: '/objects',
      ),
    );
    final signed = await store.signGet(
      key: 'opaque-asset',
      contentDisposition: 'attachment; filename="notes.txt"',
      expiresIn: const Duration(minutes: 5),
    );
    final query = (await requestUri).queryParameters;

    expect(query['sign'], 'GET');
    expect(query['response-cache-control'], 'no-store');
    expect(
      query['response-content-disposition'],
      'attachment; filename="notes.txt"',
    );
    expect(signed.url, Uri.https('private.invalid', '/signed'));
    expect(signed.headers, isEmpty);
  });

  test('upload signing uses an absolute persisted deadline', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final requestUri = server.first.then((request) async {
      final uri = request.uri;
      request.response.write('https://private.invalid/upload');
      await request.response.close();
      return uri;
    });
    final store = HttpObjectStore(
      legacyEndpoint: Uri(
        scheme: 'http',
        host: server.address.address,
        port: server.port,
        path: '/objects',
      ),
    );
    final persistedExpiry = DateTime.utc(2026, 10, 26, 20, 10, 0, 900);
    final signed = await store.signPut(
      key: 'workspace/object',
      mimeType: 'text/plain',
      sizeBytes: 4,
      checksumSha256: 'a' * 64,
      expiresAt: persistedExpiry,
    );
    final query = (await requestUri).queryParameters;
    final gatewayExpirySeconds = persistedExpiry.millisecondsSinceEpoch ~/ 1000;
    final gatewayExpiry = DateTime.fromMillisecondsSinceEpoch(
      gatewayExpirySeconds * 1000,
      isUtc: true,
    );

    expect(query['sign'], 'PUT');
    expect(query['expires'], '$gatewayExpirySeconds');
    expect(signed.expiresAt, gatewayExpiry);
    expect(persistedExpiry.isAfter(signed.expiresAt), isTrue);
    expect(
      await store.confirmsUploadQuiescence(
        key: 'workspace/object',
        expiresAt: persistedExpiry,
      ),
      isFalse,
    );
  });
}
