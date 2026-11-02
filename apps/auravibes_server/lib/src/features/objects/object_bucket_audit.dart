import 'package:aws_client/s3.dart';

abstract interface class ObjectBucketAuditApi {
  Future<bool> hasReplicationRules(String bucket);

  Future<bool> hasVersioning(String bucket);

  Future<bool> hasObjectLock(String bucket);

  Future<bool> hasLifecycleRules(String bucket);

  Future<bool> hasBucketOwnerEnforced(String bucket);

  Future<bool> blocksPublicAccess(String bucket);

  Future<ObjectVersionsAuditPage> listObjectVersions({
    required String bucket,
    required int maxKeys,
    String? keyMarker,
    String? versionIdMarker,
  });
}

class ObjectVersionsAuditPage {
  const ObjectVersionsAuditPage({
    required this.hasVersions,
    required this.isTruncated,
    this.nextKeyMarker,
    this.nextVersionIdMarker,
  });

  final bool hasVersions;
  final bool isTruncated;
  final String? nextKeyMarker;
  final String? nextVersionIdMarker;
}

enum ObjectBucketAuditState { pass, fail, unknown }

class ObjectBucketAuditCheck {
  const ObjectBucketAuditCheck({
    required this.name,
    required this.state,
    required this.detail,
  });

  final String name;
  final ObjectBucketAuditState state;
  final String detail;
}

class AwsS3ObjectBucketAuditApi implements ObjectBucketAuditApi {
  const AwsS3ObjectBucketAuditApi(this.client);

  final S3 client;

  @override
  Future<bool> hasReplicationRules(String bucket) async {
    try {
      final result = await client.getBucketReplication(bucket: bucket);
      return (result.replicationConfiguration?.rules.length ?? 0) > 0;
    } on Object catch (error) {
      if (_errorCode(error) == 'NoSuchReplicationConfiguration') return false;
      rethrow;
    }
  }

  @override
  Future<bool> hasVersioning(String bucket) async {
    final result = await client.getBucketVersioning(bucket: bucket);
    return result.status != null || result.mFADelete != null;
  }

  @override
  Future<bool> hasObjectLock(String bucket) async {
    try {
      final result = await client.getObjectLockConfiguration(bucket: bucket);
      return result.objectLockConfiguration != null;
    } on Object catch (error) {
      if (_errorCode(error) == 'ObjectLockConfigurationNotFoundError') {
        return false;
      }
      rethrow;
    }
  }

  @override
  Future<bool> hasLifecycleRules(String bucket) async {
    try {
      final result = await client.getBucketLifecycleConfiguration(
        bucket: bucket,
      );
      return (result.rules?.length ?? 0) > 0;
    } on Object catch (error) {
      if (_errorCode(error) == 'NoSuchLifecycleConfiguration') return false;
      rethrow;
    }
  }

  @override
  Future<bool> hasBucketOwnerEnforced(String bucket) async {
    final result = await client.getBucketOwnershipControls(bucket: bucket);
    final rules = result.ownershipControls?.rules;
    return rules != null &&
        rules.length == 1 &&
        rules.single.objectOwnership == ObjectOwnership.bucketOwnerEnforced;
  }

  @override
  Future<bool> blocksPublicAccess(String bucket) async {
    final result = await client.getPublicAccessBlock(bucket: bucket);
    final block = result.publicAccessBlockConfiguration;
    return block != null &&
        block.blockPublicAcls == true &&
        block.ignorePublicAcls == true &&
        block.blockPublicPolicy == true &&
        block.restrictPublicBuckets == true;
  }

  @override
  Future<ObjectVersionsAuditPage> listObjectVersions({
    required String bucket,
    required int maxKeys,
    String? keyMarker,
    String? versionIdMarker,
  }) async {
    final result = await client.listObjectVersions(
      bucket: bucket,
      maxKeys: maxKeys,
      keyMarker: keyMarker,
      versionIdMarker: versionIdMarker,
    );
    return ObjectVersionsAuditPage(
      hasVersions:
          (result.versions?.isNotEmpty ?? false) ||
          (result.deleteMarkers?.isNotEmpty ?? false),
      isTruncated: result.isTruncated == true,
      nextKeyMarker: result.nextKeyMarker,
      nextVersionIdMarker: result.nextVersionIdMarker,
    );
  }
}

Future<List<ObjectBucketAuditCheck>> auditObjectBucket(
  ObjectBucketAuditApi client,
  String bucket,
) async => [
  await _configurationCheck(
    name: 'replication',
    check: () async => !(await client.hasReplicationRules(bucket)),
    passDetail: 'no replication rules configured',
    failDetail: 'replication rules are configured',
    unknownDetail: 'could not verify replication configuration',
  ),
  await _configurationCheck(
    name: 'versioning',
    check: () async => !(await client.hasVersioning(bucket)),
    passDetail: 'versioning has never been enabled',
    failDetail: 'bucket versioning was enabled or suspended',
    unknownDetail: 'could not verify versioning history',
  ),
  await _configurationCheck(
    name: 'object lock',
    check: () async => !(await client.hasObjectLock(bucket)),
    passDetail: 'no object lock configuration',
    failDetail: 'object lock is configured',
    unknownDetail: 'could not verify object lock configuration',
  ),
  await _configurationCheck(
    name: 'lifecycle',
    check: () async => !(await client.hasLifecycleRules(bucket)),
    passDetail: 'no lifecycle rules',
    failDetail: 'lifecycle rules are configured',
    unknownDetail: 'could not verify lifecycle rules',
  ),
  await _configurationCheck(
    name: 'ownership',
    check: () => client.hasBucketOwnerEnforced(bucket),
    passDetail: 'bucket-owner-enforced ownership',
    failDetail: 'bucket-owner-enforced ownership is not enabled',
    unknownDetail: 'bucket-owner-enforced ownership is not verified',
  ),
  await _configurationCheck(
    name: 'public access',
    check: () => client.blocksPublicAccess(bucket),
    passDetail: 'all public access blocks enabled',
    failDetail: 'all public access blocks are not enabled',
    unknownDetail: 'all public access blocks are not verified',
  ),
  await _auditEmpty(client, bucket),
];

Future<ObjectBucketAuditCheck> _configurationCheck({
  required String name,
  required Future<bool> Function() check,
  required String passDetail,
  required String failDetail,
  required String unknownDetail,
}) async {
  try {
    final passed = await check();
    return ObjectBucketAuditCheck(
      name: name,
      state: passed ? ObjectBucketAuditState.pass : ObjectBucketAuditState.fail,
      detail: passed ? passDetail : failDetail,
    );
  } catch (_) {
    return ObjectBucketAuditCheck(
      name: name,
      state: ObjectBucketAuditState.unknown,
      detail: unknownDetail,
    );
  }
}

Future<ObjectBucketAuditCheck> _auditEmpty(
  ObjectBucketAuditApi client,
  String bucket,
) async {
  String? keyMarker;
  String? versionIdMarker;
  for (var page = 0; page < 1000; page++) {
    try {
      final result = await client.listObjectVersions(
        bucket: bucket,
        maxKeys: 1000,
        keyMarker: keyMarker,
        versionIdMarker: versionIdMarker,
      );
      if (result.hasVersions) {
        return const ObjectBucketAuditCheck(
          name: 'contents',
          state: ObjectBucketAuditState.fail,
          detail: 'bucket contains object versions or delete markers',
        );
      }
      if (!result.isTruncated) {
        return const ObjectBucketAuditCheck(
          name: 'contents',
          state: ObjectBucketAuditState.pass,
          detail: 'bucket has no object versions or delete markers',
        );
      }
      keyMarker = result.nextKeyMarker;
      versionIdMarker = result.nextVersionIdMarker;
      if (keyMarker == null) {
        return const ObjectBucketAuditCheck(
          name: 'contents',
          state: ObjectBucketAuditState.unknown,
          detail: 'version listing pagination could not be verified',
        );
      }
    } catch (_) {
      return const ObjectBucketAuditCheck(
        name: 'contents',
        state: ObjectBucketAuditState.unknown,
        detail: 'could not verify bucket contents',
      );
    }
  }
  return const ObjectBucketAuditCheck(
    name: 'contents',
    state: ObjectBucketAuditState.unknown,
    detail: 'version listing exceeded the audit page limit',
  );
}

String? _errorCode(Object error) {
  final value = error.toString().split(' ').first;
  return value.isEmpty ? null : value;
}
