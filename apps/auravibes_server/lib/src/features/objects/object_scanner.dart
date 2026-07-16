import 'dart:convert';
import 'dart:io';

enum ObjectScanResult { clean, infected }

String completedObjectStatus(ObjectScanResult result) => switch (result) {
  ObjectScanResult.clean => 'active',
  ObjectScanResult.infected => 'infected',
};

abstract interface class ObjectScanner {
  Future<ObjectScanResult> scan({
    required String objectKey,
    required String checksumSha256,
  });
}

class UnconfiguredObjectScanner implements ObjectScanner {
  const UnconfiguredObjectScanner();

  @override
  Future<ObjectScanResult> scan({
    required String objectKey,
    required String checksumSha256,
  }) => throw StateError('Object scanner is not configured.');
}

class HttpObjectScanner implements ObjectScanner {
  HttpObjectScanner({required this.endpoint, this.bearerToken});

  final Uri endpoint;
  final String? bearerToken;

  @override
  Future<ObjectScanResult> scan({
    required String objectKey,
    required String checksumSha256,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(endpoint);
      request.headers.contentType = ContentType.json;
      final token = bearerToken;
      if (token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      request.write(
        jsonEncode({
          'objectKey': objectKey,
          'checksumSha256': checksumSha256,
        }),
      );
      final response = await request.close();
      final body = await response.transform(const Utf8Decoder()).join();
      if (response.statusCode != HttpStatus.ok) {
        throw StateError('Object scanner failed (${response.statusCode}).');
      }
      return switch ((jsonDecode(body) as Map<String, dynamic>)['result']) {
        'clean' => ObjectScanResult.clean,
        'infected' => ObjectScanResult.infected,
        _ => throw const FormatException('Invalid object scanner result.'),
      };
    } finally {
      client.close(force: true);
    }
  }
}
