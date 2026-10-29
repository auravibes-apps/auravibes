import 'package:auravibes_server/src/features/objects/object_store.dart'
    show
        ObjectStoreDeleteBlockedException,
        ObjectStoreRegistrationConflictException,
        ServerpodObjectStore;
import 'package:test/test.dart';

import 'object_gateway_test_support.dart';

void main() {
  test('upload signing keeps the persisted absolute deadline', () async {
    final fixture = FakeObjectGatewayFixture();
    final store = ServerpodObjectStore(
      session: fixture.session,
      runtime: fixture.runtime,
    );
    final key = objectGatewayTestKey;
    await store.registerFreshKey(
      key: key,
      registrationId: objectGatewayTestRegistrationId,
    );
    final persistedExpiry = DateTime.now().toUtc().add(
      const Duration(minutes: 5, milliseconds: 900),
    );
    final checksum = 'd' * 64;

    final signed = await store.signPut(
      key: key,
      mimeType: 'text/plain',
      sizeBytes: 4,
      checksumSha256: checksum,
      expiresAt: persistedExpiry,
      registrationId: objectGatewayTestRegistrationId,
    );

    final claims = fixture.signer.verify(signed.url.queryParameters['token']!);
    final expirySeconds = persistedExpiry.millisecondsSinceEpoch ~/ 1000;
    expect(signed.url.path, '/objects/$key');
    expect(claims?.method, 'PUT');
    expect(claims?.length, 4);
    expect(claims?.checksumSha256, checksum);
    expect(claims?.registrationId, objectGatewayTestRegistrationId);
    expect(signed.headers, {
      'content-type': 'text/plain',
      'content-length': '4',
      'x-checksum-sha256': checksum,
    });
    expect(signed.expiresAt.millisecondsSinceEpoch ~/ 1000, expirySeconds);
    expect(persistedExpiry.isAfter(signed.expiresAt), isTrue);
  });

  test('download signing returns private URL without upload headers', () async {
    final fixture = FakeObjectGatewayFixture();
    final store = ServerpodObjectStore(
      session: fixture.session,
      runtime: fixture.runtime,
    );
    await fixture.register(objectGatewayTestKey);

    final signed = await store.signGet(
      key: objectGatewayTestKey,
      contentDisposition: 'attachment; filename="notes.txt"',
      expiresIn: const Duration(minutes: 5),
      registrationId: objectGatewayTestRegistrationId,
    );
    final claims = fixture.signer.verify(signed.url.queryParameters['token']!);

    expect(claims?.method, 'GET');
    expect(claims?.contentDisposition, 'attachment; filename="notes.txt"');
    expect(claims?.registrationId, objectGatewayTestRegistrationId);
    expect(signed.headers, isEmpty);
  });

  test(
    'legacy keys allow reads but never registration, upload, or deletion',
    () async {
      final fixture = FakeObjectGatewayFixture();
      final store = ServerpodObjectStore(
        session: fixture.session,
        runtime: fixture.runtime,
      );
      final legacyKey = '7/${'a' * 48}';

      final read = await store.signGet(
        key: legacyKey,
        contentDisposition: 'attachment',
        expiresIn: const Duration(minutes: 1),
      );
      expect(
        fixture.signer.verify(read.url.queryParameters['token']!)?.isLegacy,
        isTrue,
      );
      expect(await store.head(legacyKey), isNull);
      await expectLater(
        store.registerFreshKey(
          key: legacyKey,
          registrationId: objectGatewayTestRegistrationId,
        ),
        throwsArgumentError,
      );
      await expectLater(
        store.signPut(
          key: legacyKey,
          mimeType: 'text/plain',
          sizeBytes: 1,
          checksumSha256: 'b' * 64,
          expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 1)),
          registrationId: objectGatewayTestRegistrationId,
        ),
        throwsArgumentError,
      );
      await expectLater(
        store.delete(legacyKey),
        throwsA(
          isA<ObjectStoreDeleteBlockedException>().having(
            (error) => error.code,
            'code',
            'replica_provenance_unavailable',
          ),
        ),
      );
      expect(fixture.ledger.calls, isEmpty);
    },
  );

  test(
    'registered object deletion closes ledger then stays fail-closed',
    () async {
      final fixture = FakeObjectGatewayFixture();
      final store = ServerpodObjectStore(
        session: fixture.session,
        runtime: fixture.runtime,
      );
      await fixture.register(objectGatewayTestKey);

      await expectLater(
        store.delete(
          objectGatewayTestKey,
          registrationId: objectGatewayTestRegistrationId,
        ),
        throwsA(
          isA<ObjectStoreDeleteBlockedException>().having(
            (error) => error.code,
            'code',
            'replica_provenance_unavailable',
          ),
        ),
      );
      expect(fixture.ledger.closedKeys, contains(objectGatewayTestKey));
      expect(fixture.ledger.calls.last, 'close');
    },
  );

  test('rejects mismatched registration identity', () async {
    final fixture = FakeObjectGatewayFixture();
    final store = ServerpodObjectStore(
      session: fixture.session,
      runtime: fixture.runtime,
    );
    await fixture.register(objectGatewayTestKey);

    await expectLater(
      store.signGet(
        key: objectGatewayTestKey,
        contentDisposition: 'attachment',
        expiresIn: const Duration(minutes: 1),
        registrationId: 'z' * 64,
      ),
      throwsA(isA<ObjectStoreRegistrationConflictException>()),
    );
  });
}
