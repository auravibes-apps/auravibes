import 'dart:convert';
import 'dart:io';

class ObjectMetadata {
  const ObjectMetadata({
    required this.sizeBytes,
    required this.mimeType,
    required this.checksumSha256,
  });

  final int sizeBytes;
  final String mimeType;
  final String checksumSha256;
}

class SignedObjectRequest {
  const SignedObjectRequest({
    required this.url,
    required this.headers,
    required this.expiresAt,
  });

  final Uri url;
  final Map<String, String> headers;
  final DateTime expiresAt;
}

abstract interface class ObjectStore {
  Future<SignedObjectRequest> signPut({
    required String key,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
    required Duration expiresIn,
  });

  Future<ObjectMetadata?> head(String key);

  Future<SignedObjectRequest> signGet({
    required String key,
    required String contentDisposition,
    required Duration expiresIn,
  });

  Future<void> delete(String key);
}

class UnconfiguredObjectStore implements ObjectStore {
  const UnconfiguredObjectStore();

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
    required Duration expiresIn,
  }) async => _missing();
}

/// Narrow private-store adapter. The gateway issues short-lived object URLs;
/// permanent credentials remain server-side in the Authorization header.
class HttpObjectStore implements ObjectStore {
  HttpObjectStore({required this.endpoint, this.bearerToken});

  final Uri endpoint;
  final String? bearerToken;

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
    required Duration expiresIn,
  }) => _sign('PUT', key, expiresIn, {
    'content-type': mimeType,
    'content-length': '$sizeBytes',
    'x-checksum-sha256': checksumSha256,
  });

  @override
  Future<SignedObjectRequest> signGet({
    required String key,
    required String contentDisposition,
    required Duration expiresIn,
  }) => _sign('GET', key, expiresIn, {
    'response-content-disposition': contentDisposition,
  });

  Future<SignedObjectRequest> _sign(
    String method,
    String key,
    Duration expiresIn,
    Map<String, String> values,
  ) async {
    final expiresAt = DateTime.now().toUtc().add(expiresIn);
    final client = HttpClient();
    try {
      final request = await client.postUrl(
        _uri(key, {
          'sign': method,
          'expires': '${expiresAt.millisecondsSinceEpoch ~/ 1000}',
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
