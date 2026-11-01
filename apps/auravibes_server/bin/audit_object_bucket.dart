// This is an operator command; stdout is its report format.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:auravibes_server/src/features/objects/object_bucket_audit.dart';
import 'package:auravibes_server/src/features/objects/object_gateway_config.dart';
import 'package:aws_client/credential_providers.dart';
import 'package:aws_client/s3.dart';

void main() async {
  final config = S3ObjectConfig.fromEnvironment();
  if (config == null || config.endpointUrl != null || config.region == 'auto') {
    print(
      'FAIL: audit supports AWS S3 only; configure OBJECT_STORE_BUCKET and '
      'AWS_REGION without an S3 endpoint override.',
    );
    exitCode = 2;
    return;
  }

  final client = S3(
    region: config.region,
    credentialsProvider: defaultProvider,
  );
  final checks = await auditObjectBucket(
    AwsS3ObjectBucketAuditApi(client),
    config.bucket,
  );
  var allPassed = true;
  for (final check in checks) {
    final status = switch (check.state) {
      ObjectBucketAuditState.pass => 'PASS',
      ObjectBucketAuditState.fail => 'FAIL',
      ObjectBucketAuditState.unknown => 'UNKNOWN',
    };
    print('$status: ${check.name} - ${check.detail}');
    allPassed = allPassed && check.state == ObjectBucketAuditState.pass;
  }
  print(
    'NOTE: This is a current-state snapshot. It does not prove historical '
    'configuration or prevent future changes.',
  );
  print(
    'NOTE: Preserve fail-closed erasure until bucket history, exclusive '
    'writer controls, and old signer/worker drain are independently verified.',
  );
  if (!allPassed) {
    print(
      'SNAPSHOT INCOMPLETE: bucket is not verified for the approved '
      'fresh-bucket setup',
    );
    exitCode = 1;
    return;
  }
  print(
    'SNAPSHOT PASS: current bucket settings match the expected fresh-bucket setup',
  );
}
