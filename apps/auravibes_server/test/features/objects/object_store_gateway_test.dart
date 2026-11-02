import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:auravibes_server/src/features/objects/object_gateway_config.dart';
import 'package:auravibes_server/src/features/objects/object_gateway_service.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import 'object_gateway_test_support.dart';

void main() {
  test('rejects missing, forged, and expired signed requests', () async {
    final fixture = FakeObjectGatewayFixture();
    final claims = fixture.claims(method: 'GET', key: objectGatewayTestKey);
    final baseUrl = fixture.config.publicBaseUrl.replace(
      path: '${fixture.config.publicBaseUrl.path}/${claims.key}',
    );

    final missing = await fixture.service.handle(
      fixture.session,
      fixture.request(
        method: 'GET',
        claims: claims,
        url: baseUrl,
        queryParameters: const {},
      ),
    );
    final forged = await fixture.service.handle(
      fixture.session,
      fixture.request(
        method: 'GET',
        claims: claims,
        url: baseUrl.replace(queryParameters: {'token': 'forged'}),
      ),
    );
    final expired = await fixture.service.handle(
      fixture.session,
      fixture.request(
        method: 'GET',
        claims: fixture.claims(
          method: 'GET',
          key: objectGatewayTestKey,
          expiresAtSeconds:
              DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 - 1,
        ),
      ),
    );

    expect(missing.statusCode, 401);
    expect(forged.statusCode, 403);
    expect(expired.statusCode, 403);
    expect(fixture.bucket.ranges, isEmpty);
  });

  test('accepts one signed upload and rejects replay', () async {
    final fixture = FakeObjectGatewayFixture();
    final bytes = Uint8List.fromList(utf8.encode('object data'));
    final checksum = sha256.convert(bytes).toString();
    await fixture.register(objectGatewayTestKey);
    final claims = fixture.claims(
      method: 'PUT',
      key: objectGatewayTestKey,
      nonce: 'c' * 48,
      contentType: 'text/plain',
      length: bytes.length,
      checksumSha256: checksum,
    );
    final request = fixture.request(
      method: 'PUT',
      claims: claims,
      headers: {
        'content-length': '${bytes.length}',
        'content-type': 'text/plain',
        'x-checksum-sha256': checksum,
      },
      body: [bytes],
      contentLength: bytes.length,
    );

    final first = await fixture.service.handle(fixture.session, request);
    final replay = await fixture.service.handle(fixture.session, request);

    expect(first.statusCode, 204);
    expect(replay.statusCode, 409);
    expect(fixture.bucket.putCount, 1);
    expect(fixture.ledger.pendingFor(objectGatewayTestKey), 0);
  });

  test(
    'validates upload length, headers, checksum, and 25 MiB limit',
    () async {
      final fixture = FakeObjectGatewayFixture();
      final bytes = Uint8List.fromList(utf8.encode('object data'));
      final checksum = sha256.convert(bytes).toString();
      await fixture.register(objectGatewayTestKey);
      final validClaims = fixture.claims(
        method: 'PUT',
        key: objectGatewayTestKey,
        nonce: 'd' * 48,
        contentType: 'text/plain',
        length: bytes.length,
        checksumSha256: checksum,
      );
      final wrongLength = await fixture.service.handle(
        fixture.session,
        fixture.request(
          method: 'PUT',
          claims: validClaims,
          headers: {
            'content-length': '${bytes.length + 1}',
            'content-type': 'text/plain',
            'x-checksum-sha256': checksum,
          },
          body: [bytes],
          contentLength: bytes.length + 1,
        ),
      );
      final wrongContentType = await fixture.service.handle(
        fixture.session,
        fixture.request(
          method: 'PUT',
          claims: fixture.claims(
            method: 'PUT',
            key: objectGatewayTestKey,
            nonce: '2' * 48,
            contentType: 'text/plain',
            length: bytes.length,
            checksumSha256: checksum,
          ),
          headers: {
            'content-length': '${bytes.length}',
            'content-type': 'application/json',
            'x-checksum-sha256': checksum,
          },
          body: [bytes],
          contentLength: bytes.length,
        ),
      );
      final wrongChecksum = await fixture.service.handle(
        fixture.session,
        fixture.request(
          method: 'PUT',
          claims: fixture.claims(
            method: 'PUT',
            key: objectGatewayTestKey,
            nonce: 'e' * 48,
            contentType: 'text/plain',
            length: bytes.length,
            checksumSha256: checksum,
          ),
          headers: {
            'content-length': '${bytes.length}',
            'content-type': 'text/plain',
            'x-checksum-sha256': checksum,
          },
          body: [Uint8List.fromList(utf8.encode('other data'))],
          contentLength: bytes.length,
        ),
      );
      final tooLargeClaims = fixture.claims(
        method: 'PUT',
        key: objectGatewayTestKey,
        nonce: 'f' * 48,
        contentType: 'application/octet-stream',
        length: maxObjectUploadBytes + 1,
        checksumSha256: 'f' * 64,
      );
      var readOversizedBody = false;
      final tooLarge = await fixture.service.handle(
        fixture.session,
        fixture.request(
          method: 'PUT',
          claims: tooLargeClaims,
          headers: {
            'content-length': '${maxObjectUploadBytes + 1}',
            'content-type': 'application/octet-stream',
            'x-checksum-sha256': 'f' * 64,
          },
          readBody: (_) {
            readOversizedBody = true;
            return const Stream.empty();
          },
          contentLength: maxObjectUploadBytes + 1,
        ),
      );

      expect(wrongLength.statusCode, 400);
      expect(wrongContentType.statusCode, 400);
      expect(wrongChecksum.statusCode, 400);
      expect(tooLarge.statusCode, 403);
      expect(readOversizedBody, isFalse);
      expect(fixture.bucket.putCount, 0);
    },
  );

  test('allows exact configured CORS origins and answers preflight', () async {
    final fixture = FakeObjectGatewayFixture();
    final claims = fixture.claims(method: 'GET', key: objectGatewayTestKey);
    final options = await fixture.service.handle(
      fixture.session,
      fixture.request(
        method: 'OPTIONS',
        claims: claims,
        headers: {'origin': 'https://app.example'},
      ),
    );
    final denied = await fixture.service.handle(
      fixture.session,
      fixture.request(
        method: 'GET',
        claims: claims,
        headers: {'origin': 'https://evil.example'},
      ),
    );

    expect(options.statusCode, 204);
    expect(
      options.headers['access-control-allow-origin'],
      'https://app.example',
    );
    expect(options.headers['access-control-allow-methods'], contains('PUT'));
    expect(options.headers['cache-control'], 'no-store');
    expect(denied.statusCode, 403);
    expect(denied.headers['access-control-allow-origin'], isNull);
  });

  test(
    'limits concurrent uploads and releases capacity after completion',
    () async {
      final fixture = FakeObjectGatewayFixture(maxConcurrentUploads: 1);
      final gate = Completer<void>();
      fixture.bucket.putGate = gate;
      final bytes = Uint8List.fromList(utf8.encode('object data'));
      final checksum = sha256.convert(bytes).toString();
      await fixture.register(objectGatewayTestKey);
      ObjectGatewayRequest requestFor(String nonce) => fixture.request(
        method: 'PUT',
        claims: fixture.claims(
          method: 'PUT',
          key: objectGatewayTestKey,
          nonce: nonce,
          contentType: 'text/plain',
          length: bytes.length,
          checksumSha256: checksum,
        ),
        headers: {
          'content-length': '${bytes.length}',
          'content-type': 'text/plain',
          'x-checksum-sha256': checksum,
        },
        body: [bytes],
        contentLength: bytes.length,
      );

      final firstFuture = fixture.service.handle(
        fixture.session,
        requestFor('1' * 48),
      );
      await fixture.bucket.putStarted.future;
      final busy = await fixture.service.handle(
        fixture.session,
        requestFor('2' * 48),
      );
      gate.complete();
      final first = await firstFuture;

      expect(busy.statusCode, 503);
      expect(first.statusCode, 204);
      expect(fixture.bucket.putCount, 1);
    },
  );

  test('limits concurrent downloads until response stream completes', () async {
    final fixture = FakeObjectGatewayFixture(maxConcurrentDownloads: 1);
    await fixture.register(objectGatewayTestKey);
    fixture.bucket.seed(objectGatewayTestKey, Uint8List.fromList([1, 2, 3]));
    ObjectGatewayRequest downloadRequest(String nonce) => fixture.request(
      method: 'GET',
      claims: fixture.claims(
        method: 'GET',
        key: objectGatewayTestKey,
        nonce: nonce,
        contentDisposition: 'attachment',
      ),
    );

    final first = await fixture.service.handle(
      fixture.session,
      downloadRequest('1' * 48),
    );
    final busy = await fixture.service.handle(
      fixture.session,
      downloadRequest('2' * 48),
    );
    expect(busy.statusCode, 503);
    expect(await first.body.expand((chunk) => chunk).toList(), [1, 2, 3]);

    final afterDrain = await fixture.service.handle(
      fixture.session,
      downloadRequest('3' * 48),
    );
    expect(afterDrain.statusCode, 200);
    await afterDrain.body.drain<void>();
  });

  test(
    'times out a stalled upload body before creating a reservation',
    () async {
      final fixture = FakeObjectGatewayFixture(
        readTimeout: const Duration(milliseconds: 20),
      );
      final bytes = Uint8List.fromList(utf8.encode('object data'));
      final checksum = sha256.convert(bytes).toString();
      await fixture.register(objectGatewayTestKey);
      final response = await fixture.service.handle(
        fixture.session,
        fixture.request(
          method: 'PUT',
          claims: fixture.claims(
            method: 'PUT',
            key: objectGatewayTestKey,
            contentType: 'text/plain',
            length: bytes.length,
            checksumSha256: checksum,
          ),
          headers: {
            'content-length': '${bytes.length}',
            'content-type': 'text/plain',
            'x-checksum-sha256': checksum,
          },
          contentLength: bytes.length,
          readBody: (_) => Stream<Uint8List>.multi((_) {}),
        ),
      );

      expect(response.statusCode, 408);
      expect(fixture.ledger.pendingFor(objectGatewayTestKey), 0);
      expect(fixture.bucket.putCount, 0);
    },
  );

  test(
    'leaves failed storage uploads pending for fail-closed erasure',
    () async {
      final fixture = FakeObjectGatewayFixture();
      final bytes = Uint8List.fromList(utf8.encode('object data'));
      final checksum = sha256.convert(bytes).toString();
      await fixture.register(objectGatewayTestKey);
      fixture.bucket.putError = StateError('backend details');
      final response = await fixture.service.handle(
        fixture.session,
        fixture.request(
          method: 'PUT',
          claims: fixture.claims(
            method: 'PUT',
            key: objectGatewayTestKey,
            nonce: '3' * 48,
            contentType: 'text/plain',
            length: bytes.length,
            checksumSha256: checksum,
          ),
          headers: {
            'content-length': '${bytes.length}',
            'content-type': 'text/plain',
            'x-checksum-sha256': checksum,
          },
          body: [bytes],
          contentLength: bytes.length,
        ),
      );

      expect(response.statusCode, 502);
      expect(await utf8.decodeStream(response.body), 'storage unavailable');
      expect(fixture.ledger.pendingFor(objectGatewayTestKey), 1);
    },
  );

  test(
    'streams private downloads in bounded ranges and reserves reads',
    () async {
      final fixture = FakeObjectGatewayFixture();
      await fixture.register(objectGatewayTestKey);
      final bytes = Uint8List.fromList(
        List<int>.generate(4 * 1024 * 1024 + 17, (index) => index % 251),
      );
      fixture.bucket.seed(
        objectGatewayTestKey,
        bytes,
        mimeType: 'text/plain; charset=utf-8',
      );
      final response = await fixture.service.handle(
        fixture.session,
        fixture.request(
          method: 'GET',
          claims: fixture.claims(
            method: 'GET',
            key: objectGatewayTestKey,
            nonce: '7' * 48,
            contentDisposition: 'attachment; filename="private.txt"',
          ),
        ),
      );
      final chunks = <Uint8List>[];
      await for (final chunk in response.body) {
        chunks.add(chunk);
      }
      final output = BytesBuilder(copy: false);
      for (final chunk in chunks) {
        output.add(chunk);
      }

      expect(response.statusCode, 200);
      expect(response.headers['cache-control'], 'no-store');
      expect(response.headers['content-type'], 'text/plain; charset=utf-8');
      expect(
        response.headers['content-disposition'],
        'attachment; filename="private.txt"',
      );
      expect(response.contentLength, bytes.length);
      expect(fixture.bucket.ranges.map((range) => range.$2), [
        0,
        4 * 1024 * 1024,
      ]);
      expect(fixture.bucket.ranges.map((range) => range.$3), [
        4 * 1024 * 1024 - 1,
        bytes.length - 1,
      ]);
      expect(output.takeBytes(), bytes);
      expect(fixture.ledger.pendingFor(objectGatewayTestKey), 0);
    },
  );

  test(
    'serves legacy keys by signed GET without touching the ledger',
    () async {
      final fixture = FakeObjectGatewayFixture();
      final key = '7/${'a' * 48}';
      fixture.bucket.seed(key, Uint8List.fromList([1, 2, 3]));
      final response = await fixture.service.handle(
        fixture.session,
        fixture.request(
          method: 'GET',
          claims: fixture.claims(
            method: 'GET',
            key: key,
            registrationId: null,
            contentDisposition: 'attachment',
          ),
        ),
      );
      final contents = await response.body.expand((chunk) => chunk).toList();

      expect(response.statusCode, 200);
      expect(contents, [1, 2, 3]);
      expect(fixture.ledger.calls, isEmpty);
    },
  );

  test('legacy keys cannot upload, register, or be deleted', () async {
    final fixture = FakeObjectGatewayFixture();
    final key = '7/${'a' * 48}';
    final upload = await fixture.service.handle(
      fixture.session,
      fixture.request(
        method: 'PUT',
        claims: fixture.claims(
          method: 'PUT',
          key: key,
          registrationId: null,
          contentType: 'text/plain',
          length: 1,
          checksumSha256: 'a' * 64,
        ),
        headers: {
          'content-length': '1',
          'content-type': 'text/plain',
          'x-checksum-sha256': 'a' * 64,
        },
        body: [
          Uint8List.fromList([1]),
        ],
        contentLength: 1,
      ),
    );

    expect(upload.statusCode, 403);
    expect(fixture.bucket.putCount, 0);
    expect(fixture.ledger.calls, isEmpty);
  });

  test(
    'returns unavailable on bucket failure and cleans read reservations',
    () async {
      final fixture = FakeObjectGatewayFixture();
      await fixture.register(objectGatewayTestKey);
      fixture.bucket.headError = StateError('private backend detail');
      final response = await fixture.service.handle(
        fixture.session,
        fixture.request(
          method: 'GET',
          claims: fixture.claims(
            method: 'GET',
            key: objectGatewayTestKey,
            contentDisposition: 'attachment',
          ),
        ),
      );

      expect(response.statusCode, 503);
      expect(await utf8.decodeStream(response.body), 'unavailable');
      expect(fixture.ledger.pendingFor(objectGatewayTestKey), 0);
    },
  );

  test('finishes a settled failed object range', () async {
    final fixture = FakeObjectGatewayFixture();
    await fixture.register(objectGatewayTestKey);
    fixture.bucket.seed(objectGatewayTestKey, Uint8List.fromList([1, 2, 3]));
    fixture.bucket.rangeError = StateError('range failed');
    final response = await fixture.service.handle(
      fixture.session,
      fixture.request(
        method: 'GET',
        claims: fixture.claims(
          method: 'GET',
          key: objectGatewayTestKey,
          nonce: '8' * 48,
          contentDisposition: 'attachment',
        ),
      ),
    );

    await expectLater(response.body.drain<void>(), throwsStateError);
    expect(fixture.ledger.pendingFor(objectGatewayTestKey), 0);
  });

  test(
    'keeps timed out object streams pending for fail-closed erasure',
    () async {
      final fixture = FakeObjectGatewayFixture(
        requestTimeout: const Duration(milliseconds: 20),
      );
      await fixture.register(objectGatewayTestKey);
      fixture.bucket.seed(objectGatewayTestKey, Uint8List.fromList([1, 2, 3]));
      fixture.bucket.rangeDelay = const Duration(milliseconds: 50);
      final response = await fixture.service.handle(
        fixture.session,
        fixture.request(
          method: 'GET',
          claims: fixture.claims(
            method: 'GET',
            key: objectGatewayTestKey,
            nonce: '9' * 48,
            contentDisposition: 'attachment',
          ),
        ),
      );

      await expectLater(
        response.body.drain<void>(),
        throwsA(isA<TimeoutException>()),
      );
      expect(fixture.ledger.pendingFor(objectGatewayTestKey), 1);
    },
  );

  test('rejects malformed object paths before storage access', () async {
    final fixture = FakeObjectGatewayFixture();
    final claims = fixture.claims(method: 'GET', key: objectGatewayTestKey);
    final response = await fixture.service.handle(
      fixture.session,
      fixture.request(
        method: 'GET',
        claims: claims,
        url: fixture.config.publicBaseUrl.replace(
          path: '/objects/../$objectGatewayTestKey',
          queryParameters: {'token': fixture.signer.sign(claims)},
        ),
      ),
    );

    expect(response.statusCode, 400);
    expect(fixture.bucket.objects, isEmpty);
  });
}
