import 'dart:io';

import 'package:auravibes_server/src/features/objects/object_store.dart';
import 'package:test/test.dart';

void main() {
  final registrationId = 'a' * 64;
  final objectKey = '7/${'b' * 48}';

  test('registers a fresh key with its durable identity', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final observed = server.first.then((request) async {
      final result = _ObservedRequest.from(request);
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return result;
    });
    final store = _store(server);

    await store.registerFreshKey(
      key: objectKey,
      registrationId: registrationId,
    );

    final request = await observed;
    expect(request.method, 'POST');
    expect(request.path, '/objects/$objectKey');
    expect(request.query['register'], '1');
    expect(request.registrationId, registrationId);
    expect(request.authorization, 'Bearer gateway-secret');
  });

  test('quiesces by registration and treats pending as unverified', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final requests = <_ObservedRequest>[];
    var quiesceCount = 0;
    final serving = () async {
      await for (final request in server) {
        final observed = _ObservedRequest.from(request);
        requests.add(observed);
        if (observed.query.containsKey('quiesce')) quiesceCount++;
        request.response.statusCode = observed.query.containsKey('register')
            ? HttpStatus.noContent
            : quiesceCount == 1
            ? HttpStatus.conflict
            : HttpStatus.noContent;
        await request.response.close();
        if (quiesceCount == 2) break;
      }
    }();
    final store = _store(server);

    final first = await store.confirmsUploadQuiescence(
      key: objectKey,
      expiresAt: DateTime.utc(2026, 10, 26),
      registrationId: registrationId,
    );
    final second = await store.confirmsUploadQuiescence(
      key: objectKey,
      expiresAt: DateTime.utc(2026, 10, 26),
      registrationId: registrationId,
    );
    await serving;

    expect(first, isFalse);
    expect(second, isTrue);
    expect(
      requests.map(
        (request) => request.query['register'] ?? request.query['quiesce'],
      ),
      ['1', '1', '1', '1'],
    );
    expect(
      requests.every((request) => request.registrationId == registrationId),
      isTrue,
    );
    expect(
      requests.every(
        (request) => request.authorization == 'Bearer gateway-secret',
      ),
      isTrue,
    );
  });

  test('uses one registration identity for every gateway operation', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final requests = <_ObservedRequest>[];
    final serving = () async {
      await for (final request in server) {
        final observed = _ObservedRequest.from(request);
        requests.add(observed);
        request.response.statusCode = request.method == 'HEAD'
            ? HttpStatus.ok
            : request.method == 'DELETE' ||
                  observed.query.containsKey('register') ||
                  observed.query.containsKey('quiesce')
            ? HttpStatus.noContent
            : HttpStatus.ok;
        if (request.method == 'HEAD') {
          request.response.headers.contentLength = 4;
          request.response.headers.contentType = ContentType.text;
          request.response.headers.set('x-checksum-sha256', 'b' * 64);
        } else if (observed.query.containsKey('sign')) {
          request.response.write('https://gateway.invalid/signed');
        }
        await request.response.close();
        if (requests.length == 9) break;
      }
    }();
    final store = _store(server);
    final expiresAt = DateTime.now().toUtc().add(const Duration(minutes: 5));

    await store.registerFreshKey(
      key: objectKey,
      registrationId: registrationId,
    );
    await store.signPut(
      key: objectKey,
      mimeType: 'text/plain',
      sizeBytes: 4,
      checksumSha256: 'b' * 64,
      expiresAt: expiresAt,
      registrationId: registrationId,
    );
    expect(
      await store.head(objectKey, registrationId: registrationId),
      isNotNull,
    );
    await store.signGet(
      key: objectKey,
      contentDisposition: 'attachment; filename="file.txt"',
      expiresIn: const Duration(minutes: 1),
      registrationId: registrationId,
    );
    expect(
      await store.confirmsUploadQuiescence(
        key: objectKey,
        expiresAt: expiresAt,
        registrationId: registrationId,
      ),
      isTrue,
    );
    await store.delete(objectKey, registrationId: registrationId);
    await serving;

    expect(requests, hasLength(9));
    expect(
      requests.map((request) => request.registrationId),
      everyElement(registrationId),
    );
    expect(
      requests.map((request) => request.authorization),
      everyElement('Bearer gateway-secret'),
    );
    expect(requests[1].query['sign'], 'PUT');
    expect(requests[3].method, 'HEAD');
    expect(requests[5].query['sign'], 'GET');
    expect(requests[5].query['response-cache-control'], 'no-store');
    expect(requests[7].query['quiesce'], '1');
    expect(requests[8].method, 'DELETE');
  });

  test('legacy operations use only the explicit legacy endpoint', () async {
    final gateway = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final legacy = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => gateway.close(force: true));
    addTearDown(() => legacy.close(force: true));
    var gatewayRequests = 0;
    gateway.listen((request) {
      gatewayRequests++;
      request.response.close();
    });
    final legacyRequests = <_ObservedRequest>[];
    final legacyServing = () async {
      await for (final request in legacy) {
        legacyRequests.add(_ObservedRequest.from(request));
        if (request.method == 'HEAD') {
          request.response.statusCode = HttpStatus.notFound;
        } else if (request.uri.queryParameters['sign'] == 'GET') {
          request.response.write('https://legacy.invalid/signed');
        }
        await request.response.close();
        if (legacyRequests.length == 2) break;
      }
    }();
    final store = HttpObjectStore(
      gatewayEndpoint: _endpoint(gateway),
      gatewayBearerToken: 'gateway-secret',
      legacyEndpoint: _endpoint(legacy),
      legacyBearerToken: 'legacy-secret',
    );

    expect(await store.head(objectKey), isNull);
    await store.signGet(
      key: objectKey,
      contentDisposition: 'attachment; filename="legacy.txt"',
      expiresIn: const Duration(minutes: 1),
    );
    await legacyServing;

    expect(gatewayRequests, 0);
    expect(legacyRequests.map((request) => request.method), ['HEAD', 'POST']);
    expect(
      legacyRequests.every((request) => request.registrationId == null),
      isTrue,
    );
    expect(legacyRequests.map((request) => request.authorization), [
      'Bearer legacy-secret',
      'Bearer legacy-secret',
    ]);
  });

  test(
    'does not route missing legacy configuration to the new gateway',
    () async {
      final gateway = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => gateway.close(force: true));
      var gatewayRequests = 0;
      gateway.listen((request) {
        gatewayRequests++;
        request.response.close();
      });
      final store = HttpObjectStore(
        gatewayEndpoint: _endpoint(gateway),
        gatewayBearerToken: 'gateway-secret',
      );

      await expectLater(store.head(objectKey), throwsStateError);
      expect(gatewayRequests, 0);
    },
  );
}

HttpObjectStore _store(HttpServer server) => HttpObjectStore(
  gatewayEndpoint: _endpoint(server),
  gatewayBearerToken: 'gateway-secret',
);

Uri _endpoint(HttpServer server) => Uri(
  scheme: 'http',
  host: server.address.address,
  port: server.port,
  path: '/objects',
);

class _ObservedRequest {
  const _ObservedRequest({
    required this.method,
    required this.path,
    required this.query,
    required this.authorization,
    required this.registrationId,
  });

  factory _ObservedRequest.from(HttpRequest request) => _ObservedRequest(
    method: request.method,
    path: request.uri.path,
    query: request.uri.queryParameters,
    authorization: request.headers.value(HttpHeaders.authorizationHeader),
    registrationId: request.headers.value('x-registration-id'),
  );

  final String method;
  final String path;
  final Map<String, String> query;
  final String? authorization;
  final String? registrationId;
}
