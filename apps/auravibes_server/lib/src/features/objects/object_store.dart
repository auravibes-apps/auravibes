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
  });

  final Uri? gatewayEndpoint;
  final String? gatewayBearerToken;
  final Uri? legacyEndpoint;
  final String? legacyBearerToken;

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
    return endpoint;
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
      final request = await client.postUrl(
        _uri(registrationId, key, {'register': '1'}),
      );
      _authorize(request, registrationId);
      final response = await request.close();
      await response.drain<void>();
      if (response.statusCode != HttpStatus.noContent) {
        throw StateError(
          'Object gateway registration failed (${response.statusCode}).',
        );
      }
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
    if (registrationId != null) {
      await _register(key: key, registrationId: registrationId);
    }
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
      final request = await client.postUrl(
        _uri(registrationId, key, {
          'sign': method,
          'expires': '$gatewayExpirySeconds',
          ...values,
        }),
      );
      _authorize(request, registrationId);
      final response = await request.close();
      final body = await response.transform(const Utf8Decoder()).join();
      if (response.statusCode != HttpStatus.ok) {
        throw StateError(
          'Object signing gateway failed (${response.statusCode}).',
        );
      }
      return SignedObjectRequest(
        url: Uri.parse(body.trim()),
        headers: method == 'PUT' ? values : const {},
        expiresAt: expiresAt,
      );
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
    await _register(key: key, registrationId: registrationId);
    final client = HttpClient();
    try {
      final request = await client.postUrl(
        _uri(registrationId, key, {'quiesce': '1'}),
      );
      _authorize(request, registrationId);
      final response = await request.close();
      await response.drain<void>();
      if (response.statusCode == HttpStatus.noContent) return true;
      if (response.statusCode == HttpStatus.conflict) return false;
      throw StateError(
        'Object gateway quiescence failed (${response.statusCode}).',
      );
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<ObjectMetadata?> head(
    String key, {
    String? registrationId,
  }) async {
    if (registrationId != null) {
      await _register(key: key, registrationId: registrationId);
    }
    final client = HttpClient();
    try {
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
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<void> delete(String key, {String? registrationId}) async {
    final client = HttpClient();
    try {
      final request = await client.deleteUrl(_uri(registrationId, key));
      _authorize(request, registrationId);
      final response = await request.close();
      await response.drain<void>();
      if (response.statusCode != HttpStatus.noContent &&
          response.statusCode != HttpStatus.notFound) {
        throw StateError(
          'Object deletion failed (${response.statusCode}).',
        );
      }
    } finally {
      client.close(force: true);
    }
  }
}
