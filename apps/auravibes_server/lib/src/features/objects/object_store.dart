import 'dart:convert';
import 'dart:io';

class const ObjectMetadata({
  required final int sizeBytes,
  required final String mimeType,
  required final String checksumSha256,
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

/// Routes registered objects to the fenced gateway and legacy objects to an
/// explicitly configured legacy endpoint. It never falls back between them.
class HttpObjectStore implements ObjectStore {
  const HttpObjectStore({
    this.gatewayEndpoint,
    this.gatewayBearerToken,
    this.legacyEndpoint,
    this.legacyBearerToken,
    this.requestTimeout = const Duration(seconds: 30),
  });

  final Uri? gatewayEndpoint;
  final String? gatewayBearerToken;
  final Uri? legacyEndpoint;
  final String? legacyBearerToken;
  final Duration requestTimeout;
  static const _maxResponseBytes = 8192;

  Future<String> _boundedResponse(
    HttpClientResponse response, {
    String errorMessage = 'Object gateway response is too large.',
  }) async {
    final bytes = <int>[];
    await for (final chunk in response) {
      if (bytes.length + chunk.length > _maxResponseBytes) {
        throw StateError(errorMessage);
      }
      bytes.addAll(chunk);
    }
    return utf8.decode(bytes);
  }

  static ObjectStore fromEnvironment() {
    final gatewayEndpoint = _environmentUri('OBJECT_STORE_GATEWAY_ENDPOINT');
    final legacyEndpoint = _environmentUri('OBJECT_STORE_LEGACY_ENDPOINT');
    if (gatewayEndpoint == null && legacyEndpoint == null) {
      return const UnconfiguredObjectStore();
    }
    return HttpObjectStore(
      gatewayEndpoint: gatewayEndpoint,
      gatewayBearerToken:
          Platform.environment['OBJECT_STORE_GATEWAY_BEARER_TOKEN'],
      legacyEndpoint: legacyEndpoint,
      legacyBearerToken:
          Platform.environment['OBJECT_STORE_LEGACY_BEARER_TOKEN'],
    );
  }

  static Uri? _environmentUri(String key) {
    final value = Platform.environment[key];
    return value == null || value.isEmpty ? null : Uri.parse(value);
  }

  Uri _endpoint(String? registrationId) {
    final endpoint = registrationId == null ? legacyEndpoint : gatewayEndpoint;
    if (endpoint == null) {
      throw StateError(
        registrationId == null
            ? 'Legacy object storage is not configured.'
            : 'Registered object gateway is not configured.',
      );
    }
    _requireSecureEndpoint(endpoint);
    return endpoint;
  }

  void _requireSecureEndpoint(Uri endpoint) {
    if (endpoint.scheme == 'https') return;
    if (endpoint.scheme == 'http' && _isLoopbackHost(endpoint.host)) return;
    throw StateError(
      'Object storage endpoints must use HTTPS except for loopback.',
    );
  }

  bool _isLoopbackHost(String host) {
    if (host.toLowerCase() == 'localhost') return true;
    return InternetAddress.tryParse(host)?.isLoopback ?? false;
  }

  String? _token(String? registrationId) =>
      registrationId == null ? legacyBearerToken : gatewayBearerToken;

  Uri _uri(
    String? registrationId,
    String key, [
    Map<String, String>? query,
  ]) {
    final endpoint = _endpoint(registrationId);
    return endpoint.replace(
      path: '${endpoint.path.replaceFirst(RegExp(r'/$'), '')}/$key',
      queryParameters: query,
    );
  }

  void _authorize(HttpClientRequest request, String? registrationId) {
    final token = _token(registrationId);
    if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    if (registrationId != null) {
      request.headers.set('X-Registration-Id', registrationId);
    }
  }

  Future<void> _register({
    required String key,
    required String registrationId,
  }) async {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(registrationId)) {
      throw ArgumentError.value(registrationId, 'registrationId');
    }
    final client = HttpClient();
    try {
      await (() async {
        final request = await client.postUrl(
          _uri(registrationId, key, {'register': '1'}),
        );
        _authorize(request, registrationId);
        final response = await request.close();
        final body = await _boundedResponse(response);
        if (response.statusCode == HttpStatus.conflict &&
            body.trim() == 'conflict') {
          throw const ObjectStoreRegistrationConflictException();
        }
        if (response.statusCode != HttpStatus.noContent) {
          throw StateError(
            'Object gateway registration failed (${response.statusCode}).',
          );
        }
      })().timeout(requestTimeout);
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<void> registerFreshKey({
    required String key,
    required String registrationId,
  }) => _register(key: key, registrationId: registrationId);

  @override
  Future<SignedObjectRequest> signPut({
    required String key,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
    required DateTime expiresAt,
    String? registrationId,
  }) async {
    return _sign('PUT', key, expiresAt, {
      'content-type': mimeType,
      'content-length': '$sizeBytes',
      'x-checksum-sha256': checksumSha256,
    }, registrationId: registrationId);
  }

  @override
  Future<SignedObjectRequest> signGet({
    required String key,
    required String contentDisposition,
    required Duration expiresIn,
    String? registrationId,
  }) async {
    return _sign(
      'GET',
      key,
      DateTime.now().toUtc().add(expiresIn),
      {
        'response-content-disposition': contentDisposition,
        'response-cache-control': 'no-store',
      },
      registrationId: registrationId,
    );
  }

  Future<SignedObjectRequest> _sign(
    String method,
    String key,
    DateTime requestedExpiresAt,
    Map<String, String> values, {
    required String? registrationId,
  }) async {
    final gatewayExpirySeconds =
        requestedExpiresAt.toUtc().millisecondsSinceEpoch ~/ 1000;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      gatewayExpirySeconds * 1000,
      isUtc: true,
    );
    final client = HttpClient();
    try {
      return await (() async {
        final request = await client.postUrl(
          _uri(registrationId, key, {
            'sign': method,
            'expires': '$gatewayExpirySeconds',
            ...values,
          }),
        );
        _authorize(request, registrationId);
        final response = await request.close();
        if (response.statusCode != HttpStatus.ok) {
          throw StateError(
            'Object signing gateway failed (${response.statusCode}).',
          );
        }
        final body = await _boundedResponse(
          response,
          errorMessage: 'Object signing gateway response is too large.',
        );
        return SignedObjectRequest(
          url: Uri.parse(body.trim()),
          headers: method == 'PUT' ? values : const {},
          expiresAt: expiresAt,
        );
      })().timeout(requestTimeout);
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<bool> confirmsUploadQuiescence({
    required String key,
    required DateTime expiresAt,
    String? registrationId,
  }) async {
    if (registrationId == null) return false;
    final client = HttpClient();
    try {
      return await (() async {
        final request = await client.postUrl(
          _uri(registrationId, key, {'quiesce': '1'}),
        );
        _authorize(request, registrationId);
        final response = await request.close();
        if (response.statusCode == HttpStatus.noContent) return true;
        final body = await _boundedResponse(response);
        if (response.statusCode == HttpStatus.conflict) {
          if (body.trim() == 'pending') return false;
          if (body.trim() == 'conflict') {
            throw const ObjectStoreRegistrationConflictException();
          }
        }
        throw StateError(
          'Object gateway quiescence failed (${response.statusCode}).',
        );
      })().timeout(requestTimeout);
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<ObjectMetadata?> head(
    String key, {
    String? registrationId,
  }) async {
    final client = HttpClient();
    try {
      return await (() async {
        final request = await client.openUrl(
          'HEAD',
          _uri(registrationId, key),
        );
        _authorize(request, registrationId);
        final response = await request.close();
        if (response.statusCode == HttpStatus.notFound) return null;
        if (response.statusCode != HttpStatus.ok) {
          throw StateError('Object HEAD failed (${response.statusCode}).');
        }
        return ObjectMetadata(
          sizeBytes: response.contentLength,
          mimeType: response.headers.contentType?.mimeType ?? '',
          checksumSha256: response.headers.value('x-checksum-sha256') ?? '',
        );
      })().timeout(requestTimeout);
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<void> delete(String key, {String? registrationId}) async {
    final client = HttpClient();
    try {
      await (() async {
        final request = await client.deleteUrl(_uri(registrationId, key));
        _authorize(request, registrationId);
        final response = await request.close();
        if (response.statusCode == HttpStatus.noContent) return;
        final body = await _boundedResponse(response);
        if (registrationId != null &&
            response.statusCode == HttpStatus.conflict) {
          if (body.trim() == 'pending') {
            throw const ObjectStoreDeletePendingException();
          }
          if (body.trim() == 'conflict') {
            throw const ObjectStoreRegistrationConflictException();
          }
        }
        if (registrationId == null &&
            response.statusCode == HttpStatus.notFound) {
          return;
        }
        if (registrationId != null &&
            response.statusCode == HttpStatus.unprocessableEntity &&
            _isReplicaProvenanceBlocker(body)) {
          throw const ObjectStoreDeleteBlockedException(
            'replica_provenance_unavailable',
          );
        }
        throw StateError(
          'Object deletion failed (${response.statusCode}).',
        );
      })().timeout(requestTimeout);
    } finally {
      client.close(force: true);
    }
  }

  bool _isReplicaProvenanceBlocker(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map &&
          decoded['code'] == 'replica_provenance_unavailable';
    } on FormatException {
      return false;
    }
  }
}
