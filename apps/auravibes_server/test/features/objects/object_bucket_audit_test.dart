import 'package:auravibes_server/src/features/objects/object_bucket_audit.dart';
import 'package:test/test.dart';

void main() {
  test('passes only a verified empty bucket configuration', () async {
    final api = _FakeObjectBucketAuditApi(
      versionPages: const [
        ObjectVersionsAuditPage(
          hasVersions: false,
          isTruncated: true,
          nextKeyMarker: 'next-page',
        ),
        ObjectVersionsAuditPage(hasVersions: false, isTruncated: false),
      ],
    );

    final checks = await auditObjectBucket(api, 'private-bucket');

    expect(checks, hasLength(7));
    expect(
      checks.map((check) => check.state),
      everyElement(ObjectBucketAuditState.pass),
    );
    expect(api.versionRequests, [
      (keyMarker: null, versionIdMarker: null),
      (keyMarker: 'next-page', versionIdMarker: null),
    ]);
    expect(api.calls, hasLength(8));
  });

  test('fails when current bucket posture is unsafe', () async {
    final api = _FakeObjectBucketAuditApi(
      replicationRulesPresent: true,
      versioningPresent: true,
      objectLockPresent: true,
      lifecycleRulesPresent: true,
      bucketOwnerEnforced: false,
      publicAccessBlocked: false,
      versionPages: const [
        ObjectVersionsAuditPage(hasVersions: true, isTruncated: false),
      ],
    );

    final checks = await auditObjectBucket(api, 'private-bucket');

    expect(
      checks.map((check) => check.state),
      everyElement(ObjectBucketAuditState.fail),
    );
  });

  test('reports inspection failures as unknown', () async {
    final api = _FakeObjectBucketAuditApi(
      failedChecks: const {
        'replication',
        'versioning',
        'object lock',
        'lifecycle',
        'ownership',
        'public access',
      },
      failVersionListing: true,
    );

    final checks = await auditObjectBucket(api, 'private-bucket');

    expect(
      checks.map((check) => check.state),
      everyElement(ObjectBucketAuditState.unknown),
    );
  });

  test('fails closed on truncated listing without a next key marker', () async {
    final api = _FakeObjectBucketAuditApi(
      versionPages: const [
        ObjectVersionsAuditPage(hasVersions: false, isTruncated: true),
      ],
    );

    final checks = await auditObjectBucket(api, 'private-bucket');

    expect(checks.last.state, ObjectBucketAuditState.unknown);
    expect(
      checks.last.detail,
      'version listing pagination could not be verified',
    );
  });
}

class _FakeObjectBucketAuditApi implements ObjectBucketAuditApi {
  _FakeObjectBucketAuditApi({
    this.replicationRulesPresent = false,
    this.versioningPresent = false,
    this.objectLockPresent = false,
    this.lifecycleRulesPresent = false,
    this.bucketOwnerEnforced = true,
    this.publicAccessBlocked = true,
    this.versionPages = const [
      ObjectVersionsAuditPage(hasVersions: false, isTruncated: false),
    ],
    this.failedChecks = const {},
    this.failVersionListing = false,
  });

  final bool replicationRulesPresent;
  final bool versioningPresent;
  final bool objectLockPresent;
  final bool lifecycleRulesPresent;
  final bool bucketOwnerEnforced;
  final bool publicAccessBlocked;
  final List<ObjectVersionsAuditPage> versionPages;
  final Set<String> failedChecks;
  final bool failVersionListing;
  final calls = <String>[];
  final versionRequests = <({String? keyMarker, String? versionIdMarker})>[];
  var _pageIndex = 0;

  @override
  Future<bool> hasReplicationRules(String bucket) =>
      _check('replication', replicationRulesPresent);

  @override
  Future<bool> hasVersioning(String bucket) =>
      _check('versioning', versioningPresent);

  @override
  Future<bool> hasObjectLock(String bucket) =>
      _check('object lock', objectLockPresent);

  @override
  Future<bool> hasLifecycleRules(String bucket) =>
      _check('lifecycle', lifecycleRulesPresent);

  @override
  Future<bool> hasBucketOwnerEnforced(String bucket) =>
      _check('ownership', bucketOwnerEnforced);

  @override
  Future<bool> blocksPublicAccess(String bucket) =>
      _check('public access', publicAccessBlocked);

  Future<bool> _check(String name, bool result) async {
    calls.add(name);
    if (failedChecks.contains(name)) throw StateError('private audit failure');
    return result;
  }

  @override
  Future<ObjectVersionsAuditPage> listObjectVersions({
    required String bucket,
    required int maxKeys,
    String? keyMarker,
    String? versionIdMarker,
  }) async {
    calls.add('contents');
    versionRequests.add((
      keyMarker: keyMarker,
      versionIdMarker: versionIdMarker,
    ));
    if (failVersionListing) throw StateError('private listing failure');
    if (_pageIndex >= versionPages.length) {
      throw StateError('unexpected extra listing page');
    }
    return versionPages[_pageIndex++];
  }
}
