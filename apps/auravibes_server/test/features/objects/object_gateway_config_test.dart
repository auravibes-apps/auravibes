import 'package:auravibes_server/src/features/objects/object_gateway_config.dart';
import 'package:test/test.dart';

void main() {
  test('does not read standalone gateway storage settings', () {
    expect(
      ObjectGatewayConfig.fromEnvironment(
        environment: {
          'S3_BUCKET': 'old-bucket',
          'S3_ENDPOINT': 'https://old.example.com',
          'GATEWAY_PUBLIC_BASE_URL': 'https://old.example.com/objects',
          'GATEWAY_SIGNING_KEY': 's' * 32,
          'AWS_REGION': 'auto',
        },
      ),
      isNull,
    );
  });

  test('rejects S3 endpoints with credentials or query parameters', () {
    for (final endpoint in [
      'https://user:password@account.r2.cloudflarestorage.com',
      'https://account.r2.cloudflarestorage.com?redirect=elsewhere',
    ]) {
      expect(
        () => S3ObjectConfig.fromEnvironment(
          environment: {
            'OBJECT_STORE_BUCKET': 'private-bucket',
            'OBJECT_STORE_REGION': 'auto',
            'OBJECT_STORE_S3_ENDPOINT': endpoint,
          },
        ),
        throwsStateError,
      );
    }
  });

  test('rejects public object URLs with credentials', () {
    expect(
      () => ObjectGatewayConfig.fromEnvironment(
        environment: {
          'OBJECT_STORE_BUCKET': 'private-bucket',
          'OBJECT_STORE_REGION': 'auto',
          'OBJECT_STORE_PUBLIC_BASE_URL':
              'https://user:password@storage.example.com/objects',
          'OBJECT_STORE_SIGNING_KEY': 's' * 32,
        },
      ),
      throwsArgumentError,
    );
  });
}
