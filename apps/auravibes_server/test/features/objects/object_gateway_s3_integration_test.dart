import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:auravibes_server/src/features/objects/object_gateway_config.dart';
import 'package:auravibes_server/src/features/objects/object_gateway_storage.dart';
import 'package:aws_client/credential_providers.dart';
import 'package:aws_client/s3.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

void main() {
  final localStackEndpoint =
      Platform.environment['OBJECT_GATEWAY_LOCALSTACK_ENDPOINT'];
  test(
    'LocalStack accepts object put, head, and range read',
    () async {
      final bucketName =
          Platform.environment['OBJECT_GATEWAY_LOCALSTACK_BUCKET'];
      if (bucketName == null || bucketName.isEmpty) {
        throw StateError('OBJECT_GATEWAY_LOCALSTACK_BUCKET is required.');
      }
      await _roundTrip(
        S3ObjectConfig(
          bucket: bucketName,
          region:
              Platform.environment['OBJECT_GATEWAY_LOCALSTACK_REGION'] ??
              'us-east-1',
          endpointUrl: Uri.parse(localStackEndpoint!),
        ),
      );
    },
    skip: localStackEndpoint == null
        ? 'Set OBJECT_GATEWAY_LOCALSTACK_ENDPOINT and bucket to opt in.'
        : null,
  );

  final r2Endpoint = Platform.environment['OBJECT_GATEWAY_R2_ENDPOINT'];
  test(
    'R2 accepts object put, head, and range read',
    () async {
      final bucketName = Platform.environment['OBJECT_GATEWAY_R2_BUCKET'];
      if (bucketName == null || bucketName.isEmpty) {
        throw StateError('OBJECT_GATEWAY_R2_BUCKET is required.');
      }
      final region = Platform.environment['OBJECT_GATEWAY_R2_REGION'] ?? 'auto';
      if (region != 'auto') throw StateError('R2 region must be auto.');
      await _roundTrip(
        S3ObjectConfig(
          bucket: bucketName,
          region: region,
          endpointUrl: Uri.parse(r2Endpoint!),
        ),
      );
    },
    skip: r2Endpoint == null
        ? 'Set R2 endpoint, bucket, credentials, and region auto to opt in.'
        : null,
  );
}

Future<void> _roundTrip(S3ObjectConfig config) async {
  final objectKey = _randomObjectKey();
  final bytes = Uint8List.fromList(utf8.encode('range-tested-object'));
  final checksum = sha256.convert(bytes).toString();
  final bucket = AwsS3ObjectBucket(config);
  final client = S3(
    region: config.region,
    endpointUrl: config.endpointUrl?.toString(),
    forcePathStyle: config.endpointUrl != null,
    credentialsProvider: defaultProvider,
  );
  try {
    await bucket.put(
      key: objectKey,
      bytes: bytes,
      mimeType: 'text/plain',
      checksumSha256: checksum,
    );
    final metadata = await bucket.head(objectKey);
    expect(metadata?.sizeBytes, bytes.length);
    expect(metadata?.mimeType, 'text/plain');
    expect(metadata?.checksumSha256, checksum);
    final range = await bucket.getRange(
      key: objectKey,
      start: 2,
      end: 8,
      entityTag: metadata?.entityTag,
    );
    expect(range, Uint8List.sublistView(bytes, 2, 9));
  } finally {
    await client.deleteObject(bucket: config.bucket, key: objectKey);
  }
}

String _randomObjectKey() => List<int>.generate(
  24,
  (_) => Random.secure().nextInt(256),
).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
