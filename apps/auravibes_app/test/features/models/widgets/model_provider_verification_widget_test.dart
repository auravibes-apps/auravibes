import 'dart:async';

import 'package:auravibes_app/data/repositories/model_connection_repository.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/features/models/models/add_model_provider_model.dart';
import 'package:auravibes_app/features/models/models/model_connection_store.dart';
import 'package:auravibes_app/features/models/models/model_provider_verification.dart';
import 'package:auravibes_app/features/models/providers/add_model_provider_state.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/models/widgets/add_model_provider_widget.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_operations_provider.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connection_edit_screen.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_operations.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

const _workspaceId = 'test-workspace';

void main() {
  testWidgets('add form requires verification and shows model count', (
    tester,
  ) async {
    final verification = _verification();
    final store = _FakeModelConnectionStore(
      verificationCompleter: Completer<ModelProviderVerification>(),
    );
    await _pumpAddForm(tester, store);

    expect(find.text('Verify connection'), findsOneWidget);
    expect(find.text('Add provider'), findsOneWidget);
    expect(
      tester.widgetList<AuraButton>(find.byType(AuraButton)).last.disabled,
      isTrue,
    );

    final verifyButton = find.text('Verify connection');
    await tester.ensureVisible(verifyButton);
    await tester.tap(verifyButton);
    await tester.pump();
    final buttons = tester.widgetList<AuraButton>(find.byType(AuraButton));
    expect(buttons.firstOrNull?.isLoading, isTrue);
    expect(buttons.last.disabled, isTrue);

    final completer = store.verificationCompleter;
    if (completer == null) throw StateError('Verification completer missing');
    completer.complete(verification);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('models available'), findsOneWidget);
    expect(
      tester.widgetList<AuraButton>(find.byType(AuraButton)).last.disabled,
      isFalse,
    );
  });

  testWidgets('add form renders provider error and keeps save disabled', (
    tester,
  ) async {
    final store = _FakeModelConnectionStore(
      verificationError: const ModelConnectionException('provider rejected'),
    );
    await _pumpAddForm(tester, store);

    final verifyButton = find.text('Verify connection');
    await tester.ensureVisible(verifyButton);
    await tester.tap(verifyButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('provider rejected'), findsOneWidget);
    expect(
      tester.widgetList<AuraButton>(find.byType(AuraButton)).last.disabled,
      isTrue,
    );
  });

  testWidgets('edit form allows name-only save but gates URL changes', (
    tester,
  ) async {
    final store = _FakeModelConnectionStore(editConnection: _editConnection());
    final serviceOperations = ServiceConnectionOperations(
      createAppSkillCredential: ({
        required workspaceId,
        required appSkillServiceId,
        required name,
        required apiKey,
      }) => Future<void>.value(),
      getGenericForEdit: (_) async => null,
      updateGeneric: (_, _) => Future<void>.value(),
    );
    final skillOperations = SkillCredentialOperations(
      create: (_, _) async => throw UnimplementedError(),
      getForEdit: (_) async => null,
      update: (_, _) async => throw UnimplementedError(),
      delete: (_) => Future<void>.value(),
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: const Scaffold(
            body: ServiceConnectionEditScreen(
              workspaceId: _workspaceId,
              connectionId: 'connection-1',
            ),
          ),
          overrides: [
            modelConnectionStoreProvider(_workspaceId)
                .overrideWith((_) async => store),
            serviceConnectionOperationsProvider(_workspaceId)
                .overrideWith((_) async => serviceOperations),
            skillCredentialOperationsProvider
                .call(_workspaceId)
                .overrideWithValue(skillOperations),
          ],
          key: UniqueKey(),
        ),
      );
    });
    final _ = await tester.pumpAndSettle();

    expect(find.text('Verify connection'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
    expect(
      tester.widgetList<AuraButton>(find.byType(AuraButton)).last.disabled,
      isFalse,
    );

    await tester.enterText(
      find.byType(TextFormField).last,
      'https://new.example.com',
    );
    await tester.pump();

    expect(
      tester.widgetList<AuraButton>(find.byType(AuraButton)).last.disabled,
      isTrue,
    );
  });
}

Future<void> _pumpAddForm(
  WidgetTester tester,
  _FakeModelConnectionStore store,
) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(
      TestableApp(
        child: const Scaffold(
          body: AddModelProviderWidget(
            workspaceId: _workspaceId,
            showHeader: false,
          ),
        ),
        overrides: [
          modelConnectionStoreProvider(_workspaceId)
              .overrideWith((_) async => store),
          addModelProviderStateProvider.overrideWith2(
            (_) => _PresetAddModelProviderState(),
          ),
          apiModelProvidersProvider.overrideWith(
            (_, _) async => [
              const ApiModelProviderEntity(
                id: 'openai',
                name: 'OpenAI',
                type: .openai,
              ),
            ],
          ),
        ],
        key: UniqueKey(),
      ),
    );
  });
  await tester.pump();
  final _ = await tester.pumpAndSettle();
  for (
    var attempt = 0;
    attempt < 20 && find.text('Verify connection').evaluate().isEmpty;
    attempt++
  ) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

ModelProviderVerification _verification() => createModelProviderVerification(
  request: const ModelProviderVerificationRequest(
    workspaceId: _workspaceId,
    providerId: 'test-provider',
    connectionId: null,
    expectedRevision: null,
    url: null,
    key: 'valid-key',
  ),
  modelIds: const ['gpt-4o', 'gpt-4.1'],
);

ModelConnectionForEdit _editConnection() => const ModelConnectionForEdit(
  id: 'connection-1',
  name: 'OpenAI',
  modelId: 'openai',
  workspaceId: _workspaceId,
  hasKey: true,
  url: 'https://api.example.com',
);

class _FakeModelConnectionStore implements ModelConnectionStore {
  new({
    this.verificationCompleter,
    this.verificationError,
    this.editConnection,
  });

  final Completer<ModelProviderVerification>? verificationCompleter;
  final Exception? verificationError;
  final ModelConnectionForEdit? editConnection;

  @override
  Future<ModelProviderVerification> verifyModelConnection(
    ModelProviderVerificationRequest request,
  ) async {
    final error = verificationError;
    if (error != null) throw error;
    final completer = verificationCompleter;
    if (completer != null) return await completer.future;

    return createModelProviderVerification(
      request: request,
      modelIds: const ['gpt-4o'],
    );
  }

  @override
  Future<ModelConnectionEntity> createModelConnection(
    ModelConnectionToCreate connection, {
    ModelProviderVerification? verification,
  }) async => .new(
    id: 'created',
    name: connection.name,
    modelId: connection.modelId,
    createdAt: .new(2026),
    updatedAt: .new(2026),
    workspaceId: connection.workspaceId,
    hasKey: true,
    url: connection.url,
  );

  @override
  Future<ModelConnectionForEdit?> getModelConnectionForEdit(String id) async =>
      editConnection?.id == id ? editConnection : null;

  @override
  Future<ModelConnectionEntity> updateModelConnection(
    String id,
    ModelConnectionToUpdate connection, {
    ModelProviderVerification? verification,
  }) async => .new(
    id: id,
    name: connection.name ?? editConnection?.name ?? '',
    modelId: editConnection?.modelId ?? 'openai',
    createdAt: .new(2026),
    updatedAt: .new(2026),
    workspaceId: _workspaceId,
    hasKey: true,
    url: connection.url,
  );

  @override
  Future<void> deleteModelConnection(String _) => Future<void>.value();

  @override
  Stream<List<ModelConnectionEntity>> watchModelConnections(
    ModelConnectionFilter filter,
  ) => Stream.value(const []);
}

class _PresetAddModelProviderState extends AddModelProviderState {
  @override
  AddModelProviderModel build(String workspaceId) {
    final _ = super.build(workspaceId);

    return const AddModelProviderModel(
      name: 'OpenAI',
      modelId: 'test-provider',
      key: 'valid-key',
    );
  }
}
