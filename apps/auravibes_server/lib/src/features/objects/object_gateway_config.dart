import 'dart:convert';
import 'dart:io';

const maxObjectUploadBytes = 25 * 1024 * 1024;

class S3ObjectConfig {
  const S3ObjectConfig({
    required this.bucket,
    required this.region,
    this.endpointUrl,
  });

  final String bucket;
  final String region;
  final Uri? endpointUrl;

  static S3ObjectConfig? fromEnvironment({
    Map<String, String>? environment,
  }) {
    final bucket = _environmentValue('OBJECT_STORE_BUCKET', environment);
    if (bucket == null) return null;

    final endpointValue = _environmentValue(
      'OBJECT_STORE_S3_ENDPOINT',
      environment,
    );
    final endpoint = endpointValue == null ? null : Uri.parse(endpointValue);
    final region =
        _environmentValue('OBJECT_STORE_REGION', environment) ??
        _environmentValue('AWS_REGION', environment) ??
        (endpoint == null ? null : 'auto');
    if (region == null) {
      throw StateError('AWS_REGION is required for AWS S3.');
    }
    if (bucket.contains('/') || bucket.trim() != bucket) {
      throw StateError('Object store bucket name is invalid.');
    }
    if (endpoint != null &&
        (!endpoint.hasAuthority ||
            endpoint.host.isEmpty ||
            endpoint.userInfo.isNotEmpty ||
            endpoint.hasQuery ||
            endpoint.hasFragment ||
            (endpoint.scheme != 'https' &&
                !(endpoint.scheme == 'http' &&
                    _isLoopbackHost(endpoint.host))))) {
      throw StateError(
        'Object store endpoint must use HTTPS except for loopback and cannot '
        'contain credentials, query parameters, or fragments.',
      );
    }
    if (endpoint?.host.endsWith('.r2.cloudflarestorage.com') == true &&
        region != 'auto') {
      throw StateError('Cloudflare R2 requires region auto.');
    }

    return S3ObjectConfig(
      bucket: bucket,
      region: region,
      endpointUrl: endpoint,
    );
  }
}

class ObjectGatewayConfig {
  ObjectGatewayConfig({
    required this.storage,
    required this.publicBaseUrl,
    required List<int> signingKey,
    this.allowedOrigins = const {},
    this.maxConcurrentUploads = 4,
    this.maxConcurrentDownloads = 16,
    this.requestTimeout = const Duration(seconds: 30),
    this.readTimeout = const Duration(seconds: 60),
  }) : signingKey = List.unmodifiable(signingKey) {
    if (signingKey.length < 32) {
      throw ArgumentError.value(signingKey.length, 'signingKey.length');
    }
    if (maxConcurrentUploads < 1 || maxConcurrentDownloads < 1) {
      throw ArgumentError('Object store concurrency limits must be positive.');
    }
    if (requestTimeout <= Duration.zero || readTimeout <= Duration.zero) {
      throw ArgumentError('Object store timeouts must be positive.');
    }
    if (!publicBaseUrl.hasAuthority ||
        publicBaseUrl.host.isEmpty ||
        publicBaseUrl.userInfo.isNotEmpty ||
        publicBaseUrl.path != '/objects' ||
        publicBaseUrl.hasQuery ||
        publicBaseUrl.hasFragment ||
        (publicBaseUrl.scheme != 'https' &&
            !(publicBaseUrl.scheme == 'http' &&
                _isLoopbackHost(publicBaseUrl.host)))) {
      throw ArgumentError.value(publicBaseUrl, 'publicBaseUrl');
    }
    for (final origin in allowedOrigins) {
      final uri = Uri.tryParse(origin);
      if (uri == null ||
          !uri.isAbsolute ||
          uri.userInfo.isNotEmpty ||
          uri.origin != origin ||
          (uri.scheme != 'https' &&
              !(uri.scheme == 'http' && _isLoopbackHost(uri.host)))) {
        throw ArgumentError.value(origin, 'allowedOrigins');
      }
    }
  }

  final S3ObjectConfig storage;
  final Uri publicBaseUrl;
  final List<int> signingKey;
  final Set<String> allowedOrigins;
  final int maxConcurrentUploads;
  final int maxConcurrentDownloads;
  final Duration requestTimeout;
  final Duration readTimeout;

  static ObjectGatewayConfig? fromEnvironment({
    Map<String, String>? environment,
  }) {
    final bucket = _environmentValue('OBJECT_STORE_BUCKET', environment);
    final baseUrl = _environmentValue(
      'OBJECT_STORE_PUBLIC_BASE_URL',
      environment,
    );
    final signingKey = _environmentValue(
      'OBJECT_STORE_SIGNING_KEY',
      environment,
    );
    if (bucket == null && baseUrl == null && signingKey == null) return null;
    if (bucket == null || baseUrl == null || signingKey == null) {
      throw StateError(
        'OBJECT_STORE_BUCKET, OBJECT_STORE_PUBLIC_BASE_URL, and '
        'OBJECT_STORE_SIGNING_KEY must be configured together.',
      );
    }

    return ObjectGatewayConfig(
      storage: S3ObjectConfig.fromEnvironment(environment: environment)!,
      publicBaseUrl: Uri.parse(baseUrl),
      signingKey: utf8.encode(signingKey),
      allowedOrigins:
          _environmentValue('OBJECT_STORE_ALLOWED_ORIGINS', environment)
              ?.split(',')
              .map((origin) => origin.trim())
              .where((origin) => origin.isNotEmpty)
              .toSet() ??
          const {},
      maxConcurrentUploads: _positiveInt(
        'OBJECT_STORE_MAX_CONCURRENT_UPLOADS',
        defaultValue: 4,
        environment: environment,
      ),
      maxConcurrentDownloads: _positiveInt(
        'OBJECT_STORE_MAX_CONCURRENT_DOWNLOADS',
        defaultValue: 16,
        environment: environment,
      ),
      requestTimeout: Duration(
        seconds: _boundedInt(
          'OBJECT_STORE_REQUEST_TIMEOUT_SECONDS',
          defaultValue: 30,
          maximum: 3600,
          environment: environment,
        ),
      ),
      readTimeout: Duration(
        seconds: _boundedInt(
          'OBJECT_STORE_READ_TIMEOUT_SECONDS',
          defaultValue: 60,
          maximum: 3600,
          environment: environment,
        ),
      ),
    );
  }
}

String? _environmentValue(String name, Map<String, String>? environment) {
  final value = (environment ?? Platform.environment)[name];
  if (value == null || value.isEmpty) return null;
  return value;
}

int _positiveInt(
  String name, {
  required int defaultValue,
  Map<String, String>? environment,
}) {
  final value = _environmentValue(name, environment);
  if (value == null) return defaultValue;
  final parsed = int.tryParse(value);
  if (parsed == null || parsed < 1) {
    throw StateError('$name must be a positive integer.');
  }
  return parsed;
}

int _boundedInt(
  String name, {
  required int defaultValue,
  required int maximum,
  Map<String, String>? environment,
}) {
  final parsed = _positiveInt(
    name,
    defaultValue: defaultValue,
    environment: environment,
  );
  if (parsed > maximum) throw StateError('$name must be at most $maximum.');
  return parsed;
}

bool _isLoopbackHost(String host) {
  if (host.toLowerCase() == 'localhost') return true;
  return InternetAddress.tryParse(host)?.isLoopback ?? false;
}
