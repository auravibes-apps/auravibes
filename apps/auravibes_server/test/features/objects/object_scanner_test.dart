import 'package:auravibes_server/src/features/objects/object_scanner.dart';
import 'package:test/test.dart';

void main() {
  test(
    'fake scanner can drive clean and infected completion outcomes',
    () async {
      final clean = _FakeObjectScanner(ObjectScanResult.clean);
      final infected = _FakeObjectScanner(ObjectScanResult.infected);

      expect(
        completedObjectStatus(
          await clean.scan(objectKey: 'object', checksumSha256: 'checksum'),
        ),
        'active',
      );
      expect(
        completedObjectStatus(
          await infected.scan(objectKey: 'object', checksumSha256: 'checksum'),
        ),
        'infected',
      );
    },
  );

  test('unconfigured scanner fails closed', () {
    expect(
      () => const UnconfiguredObjectScanner().scan(
        objectKey: 'object',
        checksumSha256: 'checksum',
      ),
      throwsStateError,
    );
  });
}

class const _FakeObjectScanner(final ObjectScanResult result)
    implements ObjectScanner {
  @override
  Future<ObjectScanResult> scan({
    required String objectKey,
    required String checksumSha256,
  }) async => result;
}
