import 'dart:async';
import 'dart:io';

import 'package:auravibes_server/src/features/objects/object_store.dart';
import 'package:test/test.dart';

void main() {
  final registrationId = 'a' * 64;
  final objectKey = '7/${'b' * 48}';

  for (final operation in ['register', 'head']) {
    test('$operation times out when response headers stall', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final subscription = server.listen((_) {});
      addTearDown(subscription.cancel);
      final store = _store(server, timeout: const Duration(milliseconds: 250));

      await expectLater(
        operation == 'register'
            ? store.registerFreshKey(
                key: objectKey,
                registrationId: registrationId,
              )
            : store.head(objectKey, registrationId: registrationId),
        throwsA(isA<TimeoutException>()),
      );
    });
  }

  test('registration times out when response body stalls', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final subscription = server.listen((request) {
      request.response.statusCode = HttpStatus.conflict;
      request.response.write('conflict');
      unawaited(request.response.flush().catchError((Object _) {}));
    });
    addTearDown(subscription.cancel);
    final store = _store(server, timeout: const Duration(milliseconds: 250));

    await expectLater(
      store.registerFreshKey(key: objectKey, registrationId: registrationId),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('registration rejects an oversized conflict response', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final subscription = server.listen((request) {
      request.response.statusCode = HttpStatus.conflict;
      request.response.write('x' * 8193);
      unawaited(request.response.close());
    });
    addTearDown(subscription.cancel);

    await expectLater(
      _store(server).registerFreshKey(
        key: objectKey,
        registrationId: registrationId,
      ),
      throwsA(isA<StateError>()),
    );
  });

  for (final operation in ['quiesce', 'delete']) {
    test('$operation times out when response headers stall', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final subscription = server.listen((_) {});
      addTearDown(subscription.cancel);
      final store = _store(server, timeout: const Duration(milliseconds: 250));

      await expectLater(
        operation == 'quiesce'
            ? store.confirmsUploadQuiescence(
                key: objectKey,
                expiresAt: DateTime.now(),
                registrationId: registrationId,
              )
            : store.delete(objectKey, registrationId: registrationId),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('$operation times out when response body stalls', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final subscription = server.listen((request) {
        request.response.statusCode = HttpStatus.conflict;
        request.response.write('pending');
        unawaited(request.response.flush().catchError((Object _) {}));
      });
      addTearDown(subscription.cancel);
      final store = _store(server, timeout: const Duration(milliseconds: 250));

      await expectLater(
        operation == 'quiesce'
            ? store.confirmsUploadQuiescence(
                key: objectKey,
                expiresAt: DateTime.now(),
                registrationId: registrationId,
              )
            : store.delete(objectKey, registrationId: registrationId),
        throwsA(isA<TimeoutException>()),
      );
    });
  }

  for (final scenario in [
    (operation: 'quiesce', status: HttpStatus.conflict),
    (operation: 'delete', status: HttpStatus.conflict),
    (operation: 'delete', status: HttpStatus.unprocessableEntity),
  ]) {
    test(
      '${scenario.operation} rejects oversized ${scenario.status} body',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => server.close(force: true));
        final subscription = server.listen((request) {
          request.response.statusCode = scenario.status;
          request.response.write('x' * 8193);
          unawaited(request.response.close());
        });
        addTearDown(subscription.cancel);
        final store = _store(server);

        await expectLater(
          scenario.operation == 'quiesce'
              ? store.confirmsUploadQuiescence(
                  key: objectKey,
                  expiresAt: DateTime.now(),
                  registrationId: registrationId,
                )
              : store.delete(objectKey, registrationId: registrationId),
          throwsA(isA<StateError>()),
        );
      },
    );
  }

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

  test('treats a registration conflict as unverified provenance', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final observed = server.first.then((request) async {
      request.response.statusCode = HttpStatus.conflict;
      request.response.write('conflict\n');
      await request.response.close();
      return _ObservedRequest.from(request);
    });

    await expectLater(
      _store(server).registerFreshKey(
        key: objectKey,
        registrationId: registrationId,
      ),
      throwsA(isA<ObjectStoreRegistrationConflictException>()),
    );

    final request = await observed;
    expect(request.query['register'], '1');
  });

  test(
    'rejects insecure gateway endpoints without exposing credentials',
    () async {
      final store = HttpObjectStore(
        gatewayEndpoint: Uri.parse('http://gateway.invalid/objects'),
        gatewayBearerToken: 'gateway-secret',
      );

      await expectLater(
        store.registerFreshKey(key: objectKey, registrationId: registrationId),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(
              isNot(contains('gateway.invalid')),
              isNot(contains('gateway-secret')),
            ),
          ),
        ),
      );
    },
  );

  test(
    'rejects insecure legacy endpoints without exposing credentials',
    () async {
      final store = HttpObjectStore(
        legacyEndpoint: Uri.parse('http://legacy.invalid/objects'),
        legacyBearerToken: 'legacy-secret',
      );

      await expectLater(
        store.delete(objectKey),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(
              isNot(contains('legacy.invalid')),
              isNot(contains('legacy-secret')),
            ),
          ),
        ),
      );
    },
  );

  test('reports gateway delete quiescence as pending', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final observed = server.first.then((request) async {
      request.response.statusCode = HttpStatus.conflict;
      request.response.write('pending\n');
      await request.response.close();
      return _ObservedRequest.from(request);
    });

    await expectLater(
      _store(server).delete(objectKey, registrationId: registrationId),
      throwsA(isA<ObjectStoreDeletePendingException>()),
    );

    final request = await observed;
    expect(request.method, 'DELETE');
    expect(request.registrationId, registrationId);
  });

  test('decodes the explicit provider deletion blocker response', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final observed = server.first.then((request) async {
      request.response.statusCode = HttpStatus.unprocessableEntity;
      request.response.write('{"code":"replica_provenance_unavailable"}');
      await request.response.close();
      return _ObservedRequest.from(request);
    });

    await expectLater(
      _store(server).delete(objectKey, registrationId: registrationId),
      throwsA(
        isA<ObjectStoreDeleteBlockedException>().having(
          (error) => error.code,
          'code',
          'replica_provenance_unavailable',
        ),
      ),
    );

    final request = await observed;
    expect(request.method, 'DELETE');
    expect(request.registrationId, registrationId);
  });

  test('fails closed on an unrecognized gateway 422 response', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final observed = server.first.then((request) async {
      request.response.statusCode = HttpStatus.unprocessableEntity;
      request.response.write('{"code":"unknown_blocker"}');
      await request.response.close();
      return _ObservedRequest.from(request);
    });

    await expectLater(
      _store(server).delete(objectKey, registrationId: registrationId),
      throwsStateError,
    );

    final request = await observed;
    expect(request.method, 'DELETE');
    expect(request.registrationId, registrationId);
  });

  test('keeps an untyped gateway 502 as a transient error', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final observed = server.first.then((request) async {
      request.response.statusCode = HttpStatus.badGateway;
      request.response.write('storage unavailable');
      await request.response.close();
      return _ObservedRequest.from(request);
    });

    await expectLater(
      _store(server).delete(objectKey, registrationId: registrationId),
      throwsStateError,
    );
    expect((await observed).method, 'DELETE');
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
        if (quiesceCount == 1) request.response.write('pending\n');
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
      ['1', '1'],
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

  test(
    'distinguishes unknown gateway registration from pending quiescence',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final observed = server.first.then((request) async {
        request.response.statusCode = HttpStatus.conflict;
        request.response.write('conflict\n');
        await request.response.close();
        return _ObservedRequest.from(request);
      });

      await expectLater(
        _store(server).confirmsUploadQuiescence(
          key: objectKey,
          expiresAt: DateTime.utc(2026, 10, 26),
          registrationId: registrationId,
        ),
        throwsA(isA<ObjectStoreRegistrationConflictException>()),
      );

      final request = await observed;
      expect(request.query, {'quiesce': '1'});
    },
  );

  test('fails closed on an unknown 409 quiescence body', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final observed = server.first.then((request) async {
      request.response.statusCode = HttpStatus.conflict;
      request.response.write('unexpected\n');
      await request.response.close();
      return _ObservedRequest.from(request);
    });

    await expectLater(
      _store(server).confirmsUploadQuiescence(
        key: objectKey,
        expiresAt: DateTime.utc(2026, 10, 26),
        registrationId: registrationId,
      ),
      throwsStateError,
    );
    expect((await observed).query, {'quiesce': '1'});
  });

  test(
    'does not register unknown keys during head, get signing or quiesce',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final requests = <_ObservedRequest>[];
      final serving = () async {
        await for (final request in server) {
          final observed = _ObservedRequest.from(request);
          requests.add(observed);
          request.response.statusCode = HttpStatus.conflict;
          request.response.write('conflict\n');
          await request.response.close();
          if (requests.length == 3) break;
        }
      }();
      final store = _store(server);

      await expectLater(
        store.head(objectKey, registrationId: registrationId),
        throwsStateError,
      );
      await expectLater(
        store.signGet(
          key: objectKey,
          contentDisposition: 'attachment; filename="file.txt"',
          expiresIn: const Duration(minutes: 1),
          registrationId: registrationId,
        ),
        throwsStateError,
      );
      await expectLater(
        store.confirmsUploadQuiescence(
          key: objectKey,
          expiresAt: DateTime.utc(2026, 10, 26),
          registrationId: registrationId,
        ),
        throwsA(isA<ObjectStoreRegistrationConflictException>()),
      );
      await serving;

      expect(requests.map((request) => request.method), [
        'HEAD',
        'POST',
        'POST',
      ]);
      expect(requests.map((request) => request.query['sign']), [
        null,
        'GET',
        null,
      ]);
      expect(
        requests.every((request) => !request.query.containsKey('register')),
        isTrue,
      );
    },
  );

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
        if (requests.length == 6) break;
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

    expect(requests, hasLength(6));
    expect(
      requests.map((request) => request.registrationId),
      everyElement(registrationId),
    );
    expect(
      requests.map((request) => request.authorization),
      everyElement('Bearer gateway-secret'),
    );
    expect(requests[1].query['sign'], 'PUT');
    expect(requests[2].method, 'HEAD');
    expect(requests[3].query['sign'], 'GET');
    expect(requests[3].query['response-cache-control'], 'no-store');
    expect(requests[4].query['quiesce'], '1');
    expect(requests[5].method, 'DELETE');
  });

  test(
    'requires gateway DELETE to positively confirm object removal',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final observed = server.first.then((request) async {
        final result = _ObservedRequest.from(request);
        request.response.statusCode = HttpStatus.conflict;
        request.response.write('pending\n');
        await request.response.close();
        return result;
      });

      await expectLater(
        _store(server).delete(objectKey, registrationId: registrationId),
        throwsA(isA<ObjectStoreDeletePendingException>()),
      );

      final request = await observed;
      expect(request.method, 'DELETE');
      expect(request.registrationId, registrationId);
    },
  );

  test(
    'delete treats a gateway registration conflict as a permanent blocker',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final observed = server.first.then((request) async {
        request.response.statusCode = HttpStatus.conflict;
        request.response.write('conflict\n');
        await request.response.close();
        return _ObservedRequest.from(request);
      });

      await expectLater(
        _store(server).delete(objectKey, registrationId: registrationId),
        throwsA(isA<ObjectStoreRegistrationConflictException>()),
      );
      expect((await observed).method, 'DELETE');
    },
  );

  test('allows legacy DELETE 404 for an already absent object', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final observed = server.first.then((request) async {
      final result = _ObservedRequest.from(request);
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return result;
    });
    final store = HttpObjectStore(
      legacyEndpoint: _endpoint(server),
      legacyBearerToken: 'legacy-secret',
    );

    await store.delete(objectKey);

    final request = await observed;
    expect(request.method, 'DELETE');
    expect(request.registrationId, isNull);
    expect(request.authorization, 'Bearer legacy-secret');
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

HttpObjectStore _store(
  HttpServer server, {
  Duration timeout = const Duration(seconds: 30),
}) => HttpObjectStore(
  gatewayEndpoint: _endpoint(server),
  gatewayBearerToken: 'gateway-secret',
  requestTimeout: timeout,
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
