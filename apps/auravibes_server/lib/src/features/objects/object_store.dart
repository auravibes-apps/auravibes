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
  Future<SignedObjectRequest> signPut({
    required String key,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
    required DateTime expiresAt,
  });

  /// Confirms that no upload signed through this store can still write [key].
  ///
  /// This must include both pending signing requests and uploads already in
  /// flight when [expiresAt] passed. A timestamp alone is not proof of this.
  Future<bool> confirmsUploadQuiescence({
    required String key,
    required DateTime expiresAt,
  });

  Future<ObjectMetadata?> head(String key);

  Future<SignedObjectRequest> signGet({
    required String key,
    required String contentDisposition,
    required Duration expiresIn,
  });

  Future<void> delete(String key);
}

class const UnconfiguredObjectStore() implements ObjectStore {
  Never _missing() => throw StateError('Object store is not configured.');

  @override
  Future<void> delete(String key) async => _missing();

  @override
  Future<ObjectMetadata?> head(String key) async => _missing();

  @override
  Future<SignedObjectRequest> signGet({
    required String key,
    required String contentDisposition,
    required Duration expiresIn,
  }) async => _missing();

  @override
  Future<SignedObjectRequest> signPut({
    required String key,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
    required DateTime expiresAt,
  }) async => _missing();

  @override
  Future<bool> confirmsUploadQuiescence({
    required String key,
    required DateTime expiresAt,
  }) async => false;
}

/// Narrow private-store adapter. The gateway issues short-lived object URLs;
/// permanent credentials remain server-side in the Authorization header.
class HttpObjectStore({required final Uri endpoint, final String? bearerToken})
    implements ObjectStore {
  Uri _uri(String key, [Map<String, String>? query]) => endpoint.replace(
    path: '${endpoint.path.replaceFirst(RegExp(r'/$'), '')}/$key',
    queryParameters: query,
  );

  @override
  Future<SignedObjectRequest> signPut({
    required String key,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
    required DateTime expiresAt,
  }) => _sign('PUT', key, expiresAt, {
    'content-type': mimeType,
    'content-length': '$sizeBytes',
    'x-checksum-sha256': checksumSha256,
  });

  @override
  Future<SignedObjectRequest> signGet({
    required String key,
    required String contentDisposition,
    required Duration expiresIn,
  }) => _sign('GET', key, DateTime.now().toUtc().add(expiresIn), {
    'response-content-disposition': contentDisposition,
    'response-cache-control': 'no-store',
  });

  Future<SignedObjectRequest> _sign(
    String method,
    String key,
    DateTime requestedExpiresAt,
    Map<String, String> values,
  ) async {
    final gatewayExpirySeconds =
        requestedExpiresAt.toUtc().millisecondsSinceEpoch ~/ 1000;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      gatewayExpirySeconds * 1000,
      isUtc: true,
    );
    final client = HttpClient();
    try {
      final request = await client.postUrl(
        _uri(key, {
          'sign': method,
          'expires': '$gatewayExpirySeconds',
          ...values,
        }),
      );
      final token = bearerToken;
      if (token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
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

  /// The current custom gateway contract has no quiescence operation, so this
  /// adapter cannot prove that an expired upload URL has no request in flight.
  @override
  Future<bool> confirmsUploadQuiescence({
    required String key,
    required DateTime expiresAt,
  }) async => false;

  @override
  Future<ObjectMetadata?> head(String key) async {
    final client = HttpClient();
    try {
      final request = await client.openUrl('HEAD', _uri(key));
      final token = bearerToken;
      if (token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      final response = await request.close();
      if (response.statusCode == HttpStatus.notFound) {
        return null;
      }
      if (response.statusCode != HttpStatus.ok) {
        throw StateError('Object HEAD failed.');
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
  Future<void> delete(String key) async {
    final client = HttpClient();
    try {
      final request = await client.deleteUrl(_uri(key));
      final token = bearerToken;
      if (token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      final response = await request.close();
      if (response.statusCode != HttpStatus.noContent &&
          response.statusCode != HttpStatus.notFound) {
        throw StateError('Object deletion failed.');
      }
    } finally {
      client.close(force: true);
    }
  }
}
