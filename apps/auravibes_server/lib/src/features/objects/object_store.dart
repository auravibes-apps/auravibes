import 'dart:async';

import 'package:serverpod/serverpod.dart';

import 'object_gateway_ledger.dart';
import 'object_gateway_signer.dart';
import 'object_gateway_storage.dart';

class const ObjectMetadata({
  required final int sizeBytes,
  required final String mimeType,
  required final String checksumSha256,
  final String? entityTag,
});

class const SignedObjectRequest({
  required final Uri url,
  required final Map<String, String> headers,
  required final DateTime expiresAt,
});

class const ObjectStoreDeletePendingException() implements Exception;

class const ObjectStoreDeleteBlockedException(final String code)
    implements Exception;

class const ObjectStoreRegistrationConflictException() implements Exception;

abstract interface class ObjectStore {
  Future<void> registerFreshKey({
    required String key,
    required String registrationId,
  });

  Future<SignedObjectRequest> signPut({
    required String key,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
    required DateTime expiresAt,
    String? registrationId,
  });

  /// Confirms that no upload signed through this store can still write [key].
  ///
  /// Legacy stores without registration provenance must return false. A
  /// timestamp alone is not proof that an upload request has quiesced.
  Future<bool> confirmsUploadQuiescence({
    required String key,
    required DateTime expiresAt,
    String? registrationId,
  });

  Future<ObjectMetadata?> head(String key, {String? registrationId});

  Future<SignedObjectRequest> signGet({
    required String key,
    required String contentDisposition,
    required Duration expiresIn,
    String? registrationId,
  });

  Future<void> delete(String key, {String? registrationId});
}

class const UnconfiguredObjectStore() implements ObjectStore {
  Never _missing() => throw StateError('Object store is not configured.');

  @override
  Future<void> registerFreshKey({
    required String key,
    required String registrationId,
  }) async => _missing();

  @override
  Future<void> delete(String key, {String? registrationId}) async => _missing();

  @override
  Future<ObjectMetadata?> head(String key, {String? registrationId}) async =>
      _missing();

  @override
  Future<SignedObjectRequest> signGet({
    required String key,
    required String contentDisposition,
    required Duration expiresIn,
    String? registrationId,
  }) async => _missing();

  @override
  Future<SignedObjectRequest> signPut({
    required String key,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
    required DateTime expiresAt,
    String? registrationId,
  }) async => _missing();

  @override
  Future<bool> confirmsUploadQuiescence({
    required String key,
    required DateTime expiresAt,
    String? registrationId,
  }) async => false;
}

ObjectStore objectStoreForSession(Session session) {
  final runtime = ObjectGatewayRuntime.current;
  if (runtime == null) return const UnconfiguredObjectStore();
  return ServerpodObjectStore(session: session, runtime: runtime);
}

class ServerpodObjectStore implements ObjectStore {
  ServerpodObjectStore({required this.session, required this.runtime})
    : _signer = ObjectGatewaySigner(runtime.config);

  final Session session;
  final ObjectGatewayRuntime runtime;
  final ObjectGatewaySigner _signer;

  @override
  Future<void> registerFreshKey({
    required String key,
    required String registrationId,
  }) async {
    if (!_isFreshKey(key) || !_matches(r'^[a-f0-9]{64}$', registrationId)) {
      throw ArgumentError('Invalid object registration.');
    }
    try {
      await runtime.ledger.register(session, key, registrationId);
    } on ObjectGatewayLedgerException {
      throw const ObjectStoreRegistrationConflictException();
    }
  }

  @override
  Future<SignedObjectRequest> signPut({
    required String key,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
    required DateTime expiresAt,
    String? registrationId,
  }) async {
    if (!_isFreshKey(key) ||
        registrationId == null ||
        !_matches(r'^[a-f0-9]{64}$', registrationId) ||
        sizeBytes < 1 ||
        sizeBytes > 25 * 1024 * 1024 ||
        mimeType.isEmpty ||
        _containsLineBreak(mimeType) ||
        !_matches(r'^[a-f0-9]{64}$', checksumSha256)) {
      throw ArgumentError('Invalid object upload signature request.');
    }
    final expiresAtSeconds = expiresAt.toUtc().millisecondsSinceEpoch ~/ 1000;
    final nowSeconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    if (expiresAtSeconds <= nowSeconds || expiresAtSeconds > nowSeconds + 600) {
      throw ArgumentError.value(expiresAt, 'expiresAt');
    }
    await _allow(key, registrationId);
    final claims = ObjectGatewayClaims(
      method: 'PUT',
      key: key,
      expiresAtSeconds: expiresAtSeconds,
      nonce: _signer.nonce(),
      contentType: mimeType,
      length: sizeBytes,
      checksumSha256: checksumSha256,
      registrationId: registrationId,
    );
    return SignedObjectRequest(
      url: _signer.url(key, claims),
      headers: {
        'content-type': mimeType,
        'content-length': '$sizeBytes',
        'x-checksum-sha256': checksumSha256,
      },
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        expiresAtSeconds * 1000,
        isUtc: true,
      ),
    );
  }

  @override
  Future<bool> confirmsUploadQuiescence({
    required String key,
    required DateTime expiresAt,
    String? registrationId,
  }) async {
    if (registrationId == null || !_isFreshKey(key)) return false;
    try {
      return await runtime.ledger.close(session, key, registrationId);
    } on ObjectGatewayLedgerException {
      throw const ObjectStoreRegistrationConflictException();
    }
  }

  @override
  Future<ObjectMetadata?> head(String key, {String? registrationId}) async {
    String? operationId;
    if (registrationId == null) {
      if (!_isLegacyKey(key)) return null;
    } else {
      if (!_isFreshKey(key)) {
        throw const ObjectStoreRegistrationConflictException();
      }
      operationId = _signer.nonce();
      try {
        await runtime.ledger.start(session, key, registrationId, operationId);
      } on ObjectGatewayLedgerException {
        throw const ObjectStoreRegistrationConflictException();
      }
    }
    var requestCompleted = false;
    try {
      final metadata = await runtime.bucket
          .head(key)
          .timeout(runtime.config.requestTimeout);
      requestCompleted = true;
      if (metadata == null) return null;
      return ObjectMetadata(
        sizeBytes: metadata.sizeBytes,
        mimeType: metadata.mimeType,
        checksumSha256: metadata.checksumSha256,
        entityTag: metadata.entityTag,
      );
    } on TimeoutException {
      rethrow;
    } on Object {
      requestCompleted = true;
      rethrow;
    } finally {
      if (operationId != null && requestCompleted) {
        try {
          await runtime.ledger
              .finish(session, key, operationId)
              .timeout(const Duration(seconds: 2));
        } on Object {
          // A failed read cleanup remains pending and blocks erasure.
        }
      }
    }
  }

  @override
  Future<SignedObjectRequest> signGet({
    required String key,
    required String contentDisposition,
    required Duration expiresIn,
    String? registrationId,
  }) async {
    if (contentDisposition.isEmpty || _containsLineBreak(contentDisposition)) {
      throw ArgumentError.value(contentDisposition, 'contentDisposition');
    }
    final legacy = registrationId == null;
    if (legacy) {
      if (!_isLegacyKey(key)) {
        throw const ObjectStoreRegistrationConflictException();
      }
    } else {
      if (!_isFreshKey(key)) {
        throw const ObjectStoreRegistrationConflictException();
      }
      await _allow(key, registrationId);
    }
    if (expiresIn <= Duration.zero || expiresIn > const Duration(minutes: 10)) {
      throw ArgumentError.value(expiresIn, 'expiresIn');
    }
    final expiresAtSeconds =
        (DateTime.now().toUtc().add(expiresIn).millisecondsSinceEpoch ~/ 1000);
    final claims = ObjectGatewayClaims(
      method: 'GET',
      key: key,
      expiresAtSeconds: expiresAtSeconds,
      nonce: _signer.nonce(),
      contentDisposition: contentDisposition,
      registrationId: registrationId,
    );
    return SignedObjectRequest(
      url: _signer.url(key, claims),
      headers: const {},
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        expiresAtSeconds * 1000,
        isUtc: true,
      ),
    );
  }

  @override
  Future<void> delete(String key, {String? registrationId}) async {
    if (registrationId == null || !_isFreshKey(key)) {
      throw const ObjectStoreDeleteBlockedException(
        'replica_provenance_unavailable',
      );
    }
    final bool ready;
    try {
      ready = await runtime.ledger.close(session, key, registrationId);
    } on ObjectGatewayLedgerException {
      throw const ObjectStoreRegistrationConflictException();
    }
    if (!ready) throw const ObjectStoreDeletePendingException();
    throw const ObjectStoreDeleteBlockedException(
      'replica_provenance_unavailable',
    );
  }

  Future<void> _allow(String key, String registrationId) async {
    try {
      await runtime.ledger.allow(session, key, registrationId);
    } on ObjectGatewayLedgerException {
      throw const ObjectStoreRegistrationConflictException();
    }
  }

  static bool _isFreshKey(String key) => _matches(r'^[a-f0-9]{48}$', key);

  static bool _isLegacyKey(String key) => _matches(
    r'^[1-9][0-9]*/[a-f0-9]{48}$',
    key,
  );

  static bool _matches(String pattern, String value) =>
      RegExp(pattern).hasMatch(value);

  static bool _containsLineBreak(String value) =>
      value.contains('\r') || value.contains('\n');
}
