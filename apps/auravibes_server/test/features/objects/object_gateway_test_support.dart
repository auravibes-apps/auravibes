import 'dart:async';
import 'dart:typed_data';

import 'package:auravibes_server/src/features/objects/object_gateway_config.dart';
import 'package:auravibes_server/src/features/objects/object_gateway_ledger.dart';
import 'package:auravibes_server/src/features/objects/object_gateway_service.dart';
import 'package:auravibes_server/src/features/objects/object_gateway_signer.dart';
import 'package:auravibes_server/src/features/objects/object_gateway_storage.dart';
import 'package:serverpod/serverpod.dart';

const objectGatewayTestKey =
    'bbbbbbbbbbbbbbbb'
    'bbbbbbbbbbbbbbbb'
    'bbbbbbbbbbbbbbbb';
const objectGatewayTestRegistrationId =
    'aaaaaaaaaaaaaaaa'
    'aaaaaaaaaaaaaaaa'
    'aaaaaaaaaaaaaaaa'
    'aaaaaaaaaaaaaaaa';

ObjectGatewayConfig objectGatewayTestConfig({
  int maxConcurrentUploads = 4,
  int maxConcurrentDownloads = 16,
  Duration requestTimeout = const Duration(seconds: 2),
  Duration readTimeout = const Duration(seconds: 2),
}) => ObjectGatewayConfig(
  storage: const S3ObjectConfig(bucket: 'test-bucket', region: 'auto'),
  publicBaseUrl: Uri.parse('http://127.0.0.1:8080/objects'),
  signingKey: List<int>.generate(32, (index) => index),
  allowedOrigins: const {'https://app.example'},
  maxConcurrentUploads: maxConcurrentUploads,
  maxConcurrentDownloads: maxConcurrentDownloads,
  requestTimeout: requestTimeout,
  readTimeout: readTimeout,
);

class FakeObjectGatewayLedger implements ObjectGatewayLedger {
  final registrations = <String, String>{};
  final closedKeys = <String>{};
  final operations = <String, ({String key, bool pending})>{};
  final calls = <String>[];
  ObjectGatewayLedgerException? failure;

  @override
  Future<void> register(
    Session session,
    String key,
    String registrationId,
  ) async {
    calls.add('register');
    if (failure case final error?) throw error;
    final existing = registrations[key];
    if (existing != null && existing != registrationId) {
      throw const ObjectGatewayLedgerException(
        ObjectGatewayLedgerFailure.replay,
      );
    }
    registrations[key] = registrationId;
  }

  @override
  Future<void> allow(Session session, String key, String registrationId) async {
    calls.add('allow');
    if (failure case final error?) throw error;
    if (registrations[key] != registrationId) {
      throw const ObjectGatewayLedgerException(
        ObjectGatewayLedgerFailure.unknown,
      );
    }
    if (closedKeys.contains(key)) {
      throw const ObjectGatewayLedgerException(
        ObjectGatewayLedgerFailure.closed,
      );
    }
  }

  @override
  Future<void> start(
    Session session,
    String key,
    String registrationId,
    String operationId,
  ) async {
    calls.add('start');
    if (failure case final error?) throw error;
    if (registrations[key] != registrationId) {
      throw const ObjectGatewayLedgerException(
        ObjectGatewayLedgerFailure.unknown,
      );
    }
    if (closedKeys.contains(key)) {
      throw const ObjectGatewayLedgerException(
        ObjectGatewayLedgerFailure.closed,
      );
    }
    if (operations.containsKey(operationId)) {
      throw const ObjectGatewayLedgerException(
        ObjectGatewayLedgerFailure.replay,
      );
    }
    operations[operationId] = (key: key, pending: true);
  }

  @override
  Future<void> finish(Session session, String key, String operationId) async {
    calls.add('finish');
    if (failure case final error?) throw error;
    final operation = operations[operationId];
    if (operation == null || operation.key != key || !operation.pending) {
      throw const ObjectGatewayLedgerException(
        ObjectGatewayLedgerFailure.unknown,
      );
    }
    operations[operationId] = (key: key, pending: false);
  }

  @override
  Future<ObjectGatewayLedgerStatus> status(
    Session session,
    String key,
    String registrationId,
  ) async {
    calls.add('status');
    if (failure case final error?) throw error;
    if (registrations[key] != registrationId) {
      throw const ObjectGatewayLedgerException(
        ObjectGatewayLedgerFailure.unknown,
      );
    }
    return ObjectGatewayLedgerStatus(
      closed: closedKeys.contains(key),
      pendingOperations: pendingFor(key),
    );
  }

  @override
  Future<bool> close(Session session, String key, String registrationId) async {
    calls.add('close');
    if (failure case final error?) throw error;
    if (registrations[key] != registrationId) {
      throw const ObjectGatewayLedgerException(
        ObjectGatewayLedgerFailure.unknown,
      );
    }
    closedKeys.add(key);
    return !operations.values.any(
      (operation) => operation.key == key && operation.pending,
    );
  }

  int pendingFor(String key) => operations.values
      .where((operation) => operation.key == key && operation.pending)
      .length;
}

class FakeObjectBucket implements ObjectBucket {
  final objects = <String, _StoredObject>{};
  final ranges = <(String key, int start, int end)>[];
  final putStarted = Completer<void>();
  Completer<void>? putGate;
  Object? putError;
  Object? headError;
  Object? rangeError;
  Duration headDelay = Duration.zero;
  Duration rangeDelay = Duration.zero;
  var putCount = 0;

  void seed(
    String key,
    Uint8List bytes, {
    String mimeType = 'application/octet-stream',
  }) {
    objects[key] = _StoredObject(
      bytes,
      mimeType,
      'c' * 64,
      'etag-$key',
    );
  }

  @override
  Future<void> put({
    required String key,
    required Uint8List bytes,
    required String mimeType,
    required String checksumSha256,
  }) async {
    putCount++;
    if (!putStarted.isCompleted) putStarted.complete();
    await putGate?.future;
    if (putError case final error?) throw error;
    objects[key] = _StoredObject(bytes, mimeType, checksumSha256, 'etag-$key');
  }

  @override
  Future<GatewayObjectMetadata?> head(String key) async {
    if (headDelay > Duration.zero) await Future<void>.delayed(headDelay);
    if (headError case final error?) throw error;
    final object = objects[key];
    if (object == null) return null;
    return GatewayObjectMetadata(
      sizeBytes: object.bytes.length,
      mimeType: object.mimeType,
      checksumSha256: object.checksum,
      entityTag: object.entityTag,
    );
  }

  @override
  Future<Uint8List> getRange({
    required String key,
    required int start,
    required int end,
    String? entityTag,
  }) async {
    if (rangeDelay > Duration.zero) await Future<void>.delayed(rangeDelay);
    if (rangeError case final error?) throw error;
    final object = objects[key];
    if (object == null || object.entityTag != entityTag) {
      throw StateError('Object changed or disappeared.');
    }
    ranges.add((key, start, end));
    return Uint8List.sublistView(object.bytes, start, end + 1);
  }
}

class FakeObjectGatewayFixture {
  FakeObjectGatewayFixture({
    int maxConcurrentUploads = 4,
    int maxConcurrentDownloads = 16,
    Duration requestTimeout = const Duration(seconds: 2),
    Duration readTimeout = const Duration(seconds: 2),
  }) : config = objectGatewayTestConfig(
         maxConcurrentUploads: maxConcurrentUploads,
         maxConcurrentDownloads: maxConcurrentDownloads,
         requestTimeout: requestTimeout,
         readTimeout: readTimeout,
       ),
       bucket = FakeObjectBucket(),
       ledger = FakeObjectGatewayLedger() {
    runtime = ObjectGatewayRuntime(
      config: config,
      bucket: bucket,
      ledger: ledger,
    );
    signer = ObjectGatewaySigner(config);
    service = ObjectGatewayService(
      runtime: runtime,
      finishReadReservation: (session, key, operationId) =>
          ledger.finish(session, key, operationId),
    );
  }

  final ObjectGatewayConfig config;
  final FakeObjectBucket bucket;
  final FakeObjectGatewayLedger ledger;
  late final ObjectGatewayRuntime runtime;
  late final ObjectGatewaySigner signer;
  late final ObjectGatewayService service;
  final Session session = _FakeSession();

  ObjectGatewayRequest request({
    required String method,
    required ObjectGatewayClaims claims,
    Map<String, String> headers = const {},
    List<Uint8List> body = const [],
    int? contentLength,
    Uri? url,
    Stream<Uint8List> Function(int maxLength)? readBody,
    Map<String, List<String>>? queryParameters,
  }) {
    final requestUrl =
        url ??
        config.publicBaseUrl.replace(
          path: '${config.publicBaseUrl.path}/${claims.key}',
          queryParameters: {'token': signer.sign(claims)},
        );
    return ObjectGatewayRequest(
      method: method,
      url: requestUrl,
      headers: {
        for (final entry in headers.entries)
          entry.key.toLowerCase(): entry.value,
      },
      queryParameters: queryParameters ?? requestUrl.queryParametersAll,
      readBody: readBody ?? (_) => Stream.fromIterable(body),
      contentLength: contentLength,
    );
  }

  ObjectGatewayClaims claims({
    required String method,
    required String key,
    int? expiresAtSeconds,
    String nonce =
        '0000000000000000'
        '0000000000000000'
        '0000000000000000',
    String? contentType,
    int? length,
    String? checksumSha256,
    String? contentDisposition,
    String? registrationId = objectGatewayTestRegistrationId,
  }) => ObjectGatewayClaims(
    method: method,
    key: key,
    expiresAtSeconds:
        expiresAtSeconds ??
        DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 + 60,
    nonce: nonce,
    contentType: contentType,
    length: length,
    checksumSha256: checksumSha256,
    contentDisposition: contentDisposition,
    registrationId: registrationId,
  );

  Future<void> register(String key) => ledger.register(
    session,
    key,
    objectGatewayTestRegistrationId,
  );
}

class _FakeSession implements Session {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _StoredObject {
  const _StoredObject(this.bytes, this.mimeType, this.checksum, this.entityTag);

  final Uint8List bytes;
  final String mimeType;
  final String checksum;
  final String entityTag;
}
