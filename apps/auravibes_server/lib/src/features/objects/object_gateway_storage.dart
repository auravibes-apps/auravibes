import 'dart:typed_data';

import 'package:aws_client/credential_providers.dart';
import 'package:aws_client/s3.dart';

import 'object_gateway_config.dart';
import 'object_gateway_ledger.dart';

class GatewayObjectMetadata {
  const GatewayObjectMetadata({
    required this.sizeBytes,
    required this.mimeType,
    required this.checksumSha256,
    this.entityTag,
  });

  final int sizeBytes;
  final String mimeType;
  final String checksumSha256;
  final String? entityTag;
}

abstract interface class ObjectBucket {
  Future<void> put({
    required String key,
    required Uint8List bytes,
    required String mimeType,
    required String checksumSha256,
  });

  Future<GatewayObjectMetadata?> head(String key);

  Future<Uint8List> getRange({
    required String key,
    required int start,
    required int end,
    String? entityTag,
  });
}

class AwsS3ObjectBucket implements ObjectBucket {
  AwsS3ObjectBucket(S3ObjectConfig config)
    : _bucket = config.bucket,
      _client = S3(
        region: config.region,
        endpointUrl: config.endpointUrl?.toString(),
        forcePathStyle: config.endpointUrl != null,
        credentialsProvider: defaultProvider,
      );

  final String _bucket;
  final S3 _client;

  @override
  Future<void> put({
    required String key,
    required Uint8List bytes,
    required String mimeType,
    required String checksumSha256,
  }) async {
    await _client.putObject(
      bucket: _bucket,
      key: key,
      body: bytes,
      contentLength: bytes.length,
      contentType: mimeType,
      metadata: {'checksum-sha256': checksumSha256},
    );
  }

  @override
  Future<GatewayObjectMetadata?> head(String key) async {
    try {
      final object = await _client.headObject(bucket: _bucket, key: key);
      return GatewayObjectMetadata(
        sizeBytes: object.contentLength ?? 0,
        mimeType: object.contentType ?? 'application/octet-stream',
        checksumSha256: object.metadata?['checksum-sha256'] ?? '',
        entityTag: object.eTag,
      );
    } on NoSuchKey {
      return null;
    } on NotFound {
      return null;
    }
  }

  @override
  Future<Uint8List> getRange({
    required String key,
    required int start,
    required int end,
    String? entityTag,
  }) async {
    final object = await _client.getObject(
      bucket: _bucket,
      key: key,
      range: 'bytes=$start-$end',
      ifMatch: entityTag,
    );
    return object.body ?? Uint8List(0);
  }
}

class ObjectGatewayRuntime {
  ObjectGatewayRuntime({
    required this.config,
    required this.bucket,
    this.ledger = const PostgresObjectGatewayLedger(),
  });

  final ObjectGatewayConfig config;
  final ObjectBucket bucket;
  final ObjectGatewayLedger ledger;

  static ObjectGatewayRuntime? _current;

  static ObjectGatewayRuntime? get current => _current;

  static ObjectGatewayRuntime? configureFromEnvironment() {
    final config = ObjectGatewayConfig.fromEnvironment();
    if (config == null) {
      _current = null;
      return null;
    }
    return _current = ObjectGatewayRuntime(
      config: config,
      bucket: AwsS3ObjectBucket(config.storage),
    );
  }
}
