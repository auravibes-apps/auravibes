import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('injects the app storage namespace into secure stores', () {
    const namespace = 'auravibes_app_0123456789abcdef';
    final container = ProviderContainer(
      overrides: [appStorageNamespaceProvider.overrideWithValue(namespace)],
    );
    addTearDown(container.dispose);

    expect(
      container.read(serverpodAuthStoreProvider).storageNamespace,
      namespace,
    );
    expect(
      container.read(secretKeyManagerProvider).storageNamespace,
      namespace,
    );
  });
}
