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
      endpoint: Uri(
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
}
