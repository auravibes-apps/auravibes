import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unsupported reads throw a localized capability exception', () async {
    await expectLater(
      () => _resourceStore().read(
        pages: [WorkspaceResourcePageRequest(resourceKind: .skill, limit: 1)],
      ),
      throwsA(_unsupportedCapability),
    );
  });

  test(
    'unsupported agent duplication throws a localized capability exception',
    () async {
      await expectLater(
        () => _resourceStore().duplicateAgent('agent-1'),
        throwsA(_unsupportedCapability),
      );
    },
  );
}

Matcher get _unsupportedCapability =>
    isA<UnsupportedWorkspaceCapabilityException>().having(
      (error) => error.localizationKey,
      'localizationKey',
      LocaleKeys.workspace_capabilities_unsupported_error,
    );

CloudWorkspaceResourceStore _resourceStore() =>
    CloudWorkspaceResourceStore.forTesting(
      patch: ({required requestId, required operations}) =>
          Future.error(StateError('Unexpected patch')),
      watch: (_) => const Stream.empty(),
      putSecret: (_) => Future.error(StateError('Unexpected secret write')),
      mutateCredential: (_) =>
          Future.error(StateError('Unexpected credential mutation')),
    );
