import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';

import 'object_gateway_config.dart';
import 'object_gateway_ledger.dart';
import 'object_gateway_signer.dart';
import 'object_gateway_storage.dart';

const _objectKeyPattern = r'^(?:[1-9][0-9]*/)?[a-f0-9]{48}$';
const _registrationIdPattern = r'^[a-f0-9]{64}$';
const _checksumPattern = r'^[a-f0-9]{64}$';
const _noncePattern = r'^[a-f0-9]{48}$';
const _downloadChunkBytes = 4 * 1024 * 1024;
const _readCleanupTimeout = Duration(seconds: 2);

class ObjectGatewayRequest {
  const ObjectGatewayRequest({
    required this.method,
    required this.url,
    required this.headers,
    required this.queryParameters,
    required this.readBody,
    required this.contentLength,
  });

  final String method;
  final Uri url;
  final Map<String, String> headers;
  final Map<String, List<String>> queryParameters;
  final Stream<Uint8List> Function(int maxLength) readBody;
  final int? contentLength;
}

class ObjectGatewayResponse {
  ObjectGatewayResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
    this.contentLength,
  });

  final int statusCode;
  final Map<String, String> headers;
  final Stream<Uint8List> body;
  final int? contentLength;

  factory ObjectGatewayResponse.text(
    int statusCode,
    String value, {
    Map<String, String> headers = const {},
  }) {
    final bytes = Uint8List.fromList(utf8.encode(value));
    return ObjectGatewayResponse(
      statusCode: statusCode,
      headers: {'content-type': 'text/plain', ...headers},
      body: Stream.value(bytes),
      contentLength: bytes.length,
    );
  }
}

class ObjectGatewayService {
  ObjectGatewayService({
    required this.runtime,
    this.finishReadReservation,
  }) : _signer = ObjectGatewaySigner(runtime.config),
       _uploads = _CapacityLimiter(runtime.config.maxConcurrentUploads),
       _downloads = _CapacityLimiter(runtime.config.maxConcurrentDownloads);

  final ObjectGatewayRuntime runtime;
  final Future<void> Function(Session, String, String)? finishReadReservation;
  final ObjectGatewaySigner _signer;
  final _CapacityLimiter _uploads;
  final _CapacityLimiter _downloads;

  Future<ObjectGatewayResponse> handle(
    Session session,
    ObjectGatewayRequest request,
  ) async {
    final origin = request.headers['origin'];
    final corsHeaders = _corsHeaders(origin);
    if (origin != null && !runtime.config.allowedOrigins.contains(origin)) {
      return _text(403, 'forbidden', corsHeaders);
    }
    if (request.method == 'OPTIONS') {
      return ObjectGatewayResponse(
        statusCode: HttpStatus.noContent,
        headers: {
          ...corsHeaders,
          'access-control-allow-methods':
              'GET, PUT, HEAD, POST, DELETE, OPTIONS',
          'access-control-allow-headers':
              'Authorization, Content-Type, X-Checksum-Sha256, '
              'X-Registration-Id',
        },
        body: const Stream.empty(),
        contentLength: 0,
      );
    }

    final key = _keyFromUrl(request.url);
    if (key == null) return _text(400, 'invalid key', corsHeaders);
    if (request.method != 'GET' && request.method != 'PUT') {
      return _text(405, 'unsupported', corsHeaders);
    }
    final tokenValues = request.queryParameters['token'];
    if (tokenValues == null) {
      return _text(401, 'unauthorized', corsHeaders);
    }
    if (tokenValues.length != 1 ||
        request.queryParameters.keys.any((name) => name != 'token')) {
      return _text(403, 'invalid token', corsHeaders);
    }
    final claims = _signer.verify(tokenValues.single);
    if (claims == null ||
        claims.method != request.method ||
        claims.key != key ||
        claims.expiresAtSeconds <=
            DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 ||
        !_validNonce(claims.nonce)) {
      return _text(403, 'invalid token', corsHeaders);
    }
    if (!_validClaims(claims)) return _text(403, 'invalid token', corsHeaders);

    if (request.method == 'GET') {
      return _get(session, claims, corsHeaders);
    }
    return _put(session, request, claims, corsHeaders);
  }

  Future<ObjectGatewayResponse> _put(
    Session session,
    ObjectGatewayRequest request,
    ObjectGatewayClaims claims,
    Map<String, String> corsHeaders,
  ) async {
    if (!_uploads.tryAcquire()) return _text(503, 'busy', corsHeaders);
    try {
      final contentLength = _contentLength(request);
      if (contentLength != claims.length ||
          request.headers['content-type'] != claims.contentType ||
          request.headers['x-checksum-sha256'] != claims.checksumSha256 ||
          contentLength == null ||
          contentLength < 1 ||
          contentLength > maxObjectUploadBytes) {
        return _text(400, 'invalid upload', corsHeaders);
      }

      final body = BytesBuilder(copy: false);
      final readWatch = Stopwatch()..start();
      try {
        await for (final chunk
            in request
                .readBody(maxObjectUploadBytes)
                .timeout(runtime.config.readTimeout)) {
          body.add(chunk);
          if (readWatch.elapsed > runtime.config.readTimeout) {
            return _text(408, 'request timeout', corsHeaders);
          }
        }
      } on TimeoutException {
        return _text(408, 'request timeout', corsHeaders);
      } on MaxBodySizeExceeded {
        return _text(400, 'invalid upload', corsHeaders);
      } on Object {
        return _text(400, 'invalid upload', corsHeaders);
      }

      if (readWatch.elapsed > runtime.config.readTimeout) {
        return _text(408, 'request timeout', corsHeaders);
      }
      final bytes = body.takeBytes();
      final checksum = sha256.convert(bytes).toString();
      if (bytes.length != contentLength ||
          checksum != claims.checksumSha256 ||
          claims.expiresAtSeconds <=
              DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000) {
        return _text(400, 'invalid upload', corsHeaders);
      }

      try {
        await runtime.ledger.start(
          session,
          claims.key,
          claims.registrationId!,
          claims.nonce,
        );
      } on ObjectGatewayLedgerException catch (error) {
        return _ledgerFailure(error, corsHeaders);
      } on Object {
        return _text(503, 'unavailable', corsHeaders);
      }

      try {
        await runtime.bucket
            .put(
              key: claims.key,
              bytes: bytes,
              mimeType: claims.contentType!,
              checksumSha256: claims.checksumSha256!,
            )
            .timeout(runtime.config.requestTimeout);
      } on Object {
        // Keep uncertain writes pending. Quiescence must fail closed.
        return _text(502, 'storage unavailable', corsHeaders);
      }

      try {
        await runtime.ledger.finish(session, claims.key, claims.nonce);
      } on Object {
        return _text(503, 'unavailable', corsHeaders);
      }
      return _response(HttpStatus.noContent, corsHeaders, contentLength: 0);
    } finally {
      _uploads.release();
    }
  }

  Future<ObjectGatewayResponse> _get(
    Session session,
    ObjectGatewayClaims claims,
    Map<String, String> corsHeaders,
  ) async {
    if (!_downloads.tryAcquire()) return _text(503, 'busy', corsHeaders);
    var reservationStarted = false;
    var streamOwnsSlot = false;
    String? reservationId;
    try {
      if (claims.isLegacy) {
        if (!_isLegacyKey(claims.key)) {
          return _text(403, 'invalid token', corsHeaders);
        }
      } else {
        try {
          await runtime.ledger.allow(
            session,
            claims.key,
            claims.registrationId!,
          );
          reservationId = _signer.nonce();
          await runtime.ledger.start(
            session,
            claims.key,
            claims.registrationId!,
            reservationId,
          );
          reservationStarted = true;
        } on ObjectGatewayLedgerException catch (error) {
          return _ledgerFailure(error, corsHeaders);
        } on Object {
          return _text(503, 'unavailable', corsHeaders);
        }
      }

      final metadata = await runtime.bucket
          .head(claims.key)
          .timeout(runtime.config.requestTimeout);
      if (metadata == null) {
        if (reservationStarted) {
          await _finishReservation(session, claims.key, reservationId!);
          reservationStarted = false;
        }
        return _text(404, 'not found', corsHeaders);
      }

      final serverpod = finishReadReservation == null
          ? session.serverpod
          : null;
      final stream = _streamObject(
        session: session,
        serverpod: serverpod,
        key: claims.key,
        metadata: metadata,
        reservationId: reservationId,
      );
      streamOwnsSlot = true;
      return ObjectGatewayResponse(
        statusCode: HttpStatus.ok,
        headers: {
          ...corsHeaders,
          'content-type': metadata.mimeType,
          'content-disposition': claims.contentDisposition!,
        },
        body: stream,
        contentLength: metadata.sizeBytes,
      );
    } on TimeoutException {
      // The S3 client Future.timeout does not cancel its underlying request.
      // Keep the reservation pending until an operator can prove it settled.
      return _text(503, 'unavailable', corsHeaders);
    } on Object {
      if (reservationStarted) {
        await _finishReservation(session, claims.key, reservationId!);
      }
      return _text(503, 'unavailable', corsHeaders);
    } finally {
      if (!streamOwnsSlot) _downloads.release();
    }
  }

  Stream<Uint8List> _streamObject({
    required Session session,
    required Serverpod? serverpod,
    required String key,
    required GatewayObjectMetadata metadata,
    required String? reservationId,
  }) async* {
    final stopwatch = Stopwatch()..start();
    var readTimedOut = false;
    try {
      for (var start = 0; start < metadata.sizeBytes;) {
        final end = min(start + _downloadChunkBytes, metadata.sizeBytes) - 1;
        final remaining = runtime.config.requestTimeout - stopwatch.elapsed;
        if (remaining <= Duration.zero) {
          throw TimeoutException('Object stream timed out.');
        }
        final Future<Uint8List> rangeRequest = runtime.bucket.getRange(
          key: key,
          start: start,
          end: end,
          entityTag: metadata.entityTag,
        );
        final Uint8List chunk;
        try {
          chunk = await rangeRequest.timeout(remaining);
        } on TimeoutException {
          readTimedOut = true;
          rethrow;
        }
        if (chunk.length != end - start + 1) {
          throw StateError('Object range length mismatch.');
        }
        yield chunk;
        start = end + 1;
      }
    } finally {
      try {
        if (reservationId != null && !readTimedOut) {
          final finishReadReservation = this.finishReadReservation;
          if (finishReadReservation != null) {
            await finishReadReservation(session, key, reservationId);
          } else {
            await _finishReservationAfterStream(
              serverpod!,
              key,
              reservationId,
            );
          }
        }
      } finally {
        _downloads.release();
      }
    }
  }

  Future<void> _finishReservation(
    Session session,
    String key,
    String reservationId,
  ) async {
    try {
      await runtime.ledger
          .finish(session, key, reservationId)
          .timeout(_readCleanupTimeout);
    } on Object {
      // A failed cleanup remains pending and blocks erasure.
    }
  }

  Future<void> _finishReservationAfterStream(
    Serverpod serverpod,
    String key,
    String reservationId,
  ) async {
    Session? cleanupSession;
    try {
      cleanupSession = await serverpod.createSession();
      await runtime.ledger
          .finish(cleanupSession, key, reservationId)
          .timeout(_readCleanupTimeout);
    } on Object {
      // A failed cleanup remains pending and blocks erasure.
    } finally {
      await cleanupSession?.close();
    }
  }

  bool _validClaims(ObjectGatewayClaims claims) {
    if (claims.isLegacy) {
      return claims.method == 'GET' &&
          _isLegacyKey(claims.key) &&
          claims.contentDisposition != null &&
          !_containsLineBreak(claims.contentDisposition!);
    }
    if (!_matches(_registrationIdPattern, claims.registrationId!)) {
      return false;
    }
    if (claims.method == 'PUT') {
      return !_isLegacyKey(claims.key) &&
          claims.contentType != null &&
          claims.contentType!.isNotEmpty &&
          !_containsLineBreak(claims.contentType!) &&
          claims.length != null &&
          claims.length! > 0 &&
          claims.length! <= maxObjectUploadBytes &&
          claims.checksumSha256 != null &&
          _matches(_checksumPattern, claims.checksumSha256!);
    }
    if (claims.method == 'GET') {
      return claims.contentDisposition != null &&
          !_containsLineBreak(claims.contentDisposition!);
    }
    return false;
  }

  Map<String, String> _corsHeaders(String? origin) {
    if (origin == null || !runtime.config.allowedOrigins.contains(origin)) {
      return {'cache-control': 'no-store'};
    }
    return {
      'cache-control': 'no-store',
      'access-control-allow-origin': origin,
      'vary': 'Origin',
    };
  }

  ObjectGatewayResponse _ledgerFailure(
    ObjectGatewayLedgerException error,
    Map<String, String> corsHeaders,
  ) => switch (error.failure) {
    ObjectGatewayLedgerFailure.closed => _text(403, 'closed', corsHeaders),
    ObjectGatewayLedgerFailure.unknown ||
    ObjectGatewayLedgerFailure.replay => _text(409, 'conflict', corsHeaders),
  };

  ObjectGatewayResponse _text(
    int status,
    String text,
    Map<String, String> corsHeaders,
  ) => ObjectGatewayResponse.text(status, text, headers: corsHeaders);

  ObjectGatewayResponse _response(
    int status,
    Map<String, String> corsHeaders, {
    required int contentLength,
  }) => ObjectGatewayResponse(
    statusCode: status,
    headers: corsHeaders,
    body: const Stream.empty(),
    contentLength: contentLength,
  );

  int? _contentLength(ObjectGatewayRequest request) {
    final value = request.headers['content-length'];
    final parsedHeader = value == null ? null : int.tryParse(value);
    if (value != null && parsedHeader == null) return null;
    if (request.contentLength != null &&
        parsedHeader != null &&
        request.contentLength != parsedHeader) {
      return null;
    }
    return parsedHeader ?? request.contentLength;
  }

  String? _keyFromUrl(Uri url) {
    if (url.path.contains('%')) return null;
    final segments = url.pathSegments;
    if (segments.length < 2 || segments.first != 'objects') return null;
    final key = segments.skip(1).join('/');
    if (!_matches(_objectKeyPattern, key)) return null;
    if (url.path != '/objects/$key') return null;
    return key;
  }

  static bool _isLegacyKey(String key) => key.contains('/');

  static bool _validNonce(String nonce) => _matches(_noncePattern, nonce);

  static bool _matches(String pattern, String value) =>
      RegExp(pattern).hasMatch(value);

  static bool _containsLineBreak(String value) =>
      value.contains('\r') || value.contains('\n');
}

class ObjectGatewayRoute extends Route {
  ObjectGatewayRoute(ObjectGatewayRuntime runtime)
    : _service = ObjectGatewayService(runtime: runtime),
      super(methods: const {Method.get, Method.put, Method.options});

  final ObjectGatewayService _service;

  @override
  Future<Result> handleCall(Session session, Request request) async {
    final headers = <String, String>{};
    for (final entry in request.headers.entries) {
      final values = entry.value.toList();
      if (values.isNotEmpty) headers[entry.key.toLowerCase()] = values.first;
    }
    final result = await _service.handle(
      session,
      ObjectGatewayRequest(
        method: request.method.value,
        url: request.url,
        headers: headers,
        queryParameters: request.url.queryParametersAll,
        readBody: (maxLength) => request.read(maxLength: maxLength),
        contentLength: request.body.contentLength,
      ),
    );
    final responseHeaders = Headers.fromMap({
      for (final entry in result.headers.entries) entry.key: [entry.value],
    });
    final mimeType = _mimeType(result.headers['content-type']);
    final responseBody = Body.fromDataStream(
      result.body,
      contentLength: result.contentLength,
      mimeType: mimeType,
    );
    return Response(
      result.statusCode,
      headers: responseHeaders,
      body: responseBody,
    );
  }

  static MimeType _mimeType(String? value) {
    if (value == null) return MimeType.octetStream;
    try {
      return MimeType.parse(value.split(';').first.trim());
    } on FormatException {
      return MimeType.octetStream;
    }
  }
}

class _CapacityLimiter {
  _CapacityLimiter(this.capacity);

  final int capacity;
  var _active = 0;

  bool tryAcquire() {
    if (_active >= capacity) return false;
    _active++;
    return true;
  }

  void release() {
    if (_active == 0) throw StateError('Capacity released without a lease.');
    _active--;
  }
}
