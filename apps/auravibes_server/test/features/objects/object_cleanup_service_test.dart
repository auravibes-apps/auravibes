import 'package:auravibes_server/src/features/objects/object_cleanup_service.dart';
import 'package:auravibes_server/src/features/objects/object_store.dart';
import 'package:test/test.dart';

void main() {
  test('cleanup defaults stay bounded', () {
    final service = ObjectCleanupService(
      store: const UnconfiguredObjectStore(),
    );

    expect(service.batchSize, 20);
    expect(service.maxAttempts, 8);
  });

  test('object store delete remains adapter-owned', () {
    expect(
      () => const UnconfiguredObjectStore().delete('key'),
      throwsA(isA<StateError>()),
    );
  });
}
