import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/features/models/models/model_connection_store.dart';
import 'package:auravibes_app/features/models/models/model_provider_verification.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/service_connections/models/cloud_service_connection.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_operations_provider.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connection_edit_screen.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_definitions_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_operations.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

const _workspaceId = 'test-workspace';
const _modelConnectionId = 'model-connection';
const _genericConnectionId = 'generic-connection';
const _credentialId = 'credential-1';
const _definitionId = 'definition-1';

void main() {
  testWidgets('model provider key replacement prompts without exposing value', (
    tester,
  ) async {
    const secret = 'model-private-token';
    await _pumpEditor(
      tester,
      connectionId: _modelConnectionId,
      modelConnection: _modelConnection(),
    );
    await _openEditor(tester);
    final _ = await tester.binding.handlePopRoute();
    final _ = await tester.pumpAndSettle();
    expect(find.byType(AuraConfirmDialog), findsNothing);
    expect(find.text('Open editor'), findsOneWidget);
    await _openEditor(tester);

    await tester.enterText(find.byType(EditableText).at(1), secret);
    await tester.tap(find.byIcon(Icons.arrow_back));
    final _ = await tester.pumpAndSettle();

    final dialog = find.byType(AuraConfirmDialog);
    expect(dialog, findsOneWidget);
    expect(
      find.descendant(of: dialog, matching: find.text(secret)),
      findsNothing,
    );
    await tester.tap(find.text('Keep editing'));
    final _ = await tester.pumpAndSettle();

    final _ = await tester.binding.handlePopRoute();
    final _ = await tester.pumpAndSettle();
    expect(find.byType(AuraConfirmDialog), findsOneWidget);
    await tester.tap(find.text('Discard changes'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Open editor'), findsOneWidget);
  });

  testWidgets('generic connection secret clear sends clear intent', (
    tester,
  ) async {
    GenericServiceConnectionUpdate? savedUpdate;
    await _pumpEditor(
      tester,
      connectionId: _genericConnectionId,
      genericConnection: _genericConnection(),
      onGenericUpdate: (update) => savedUpdate = update,
    );
    await _openEditor(tester);
    final _ = await tester.binding.handlePopRoute();
    final _ = await tester.pumpAndSettle();
    expect(find.byType(AuraConfirmDialog), findsNothing);
    expect(find.text('Open editor'), findsOneWidget);
    await _openEditor(tester);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();
    final _ = await tester.binding.handlePopRoute();
    final _ = await tester.pumpAndSettle();
    expect(find.byType(AuraConfirmDialog), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    final _ = await tester.pumpAndSettle();

    expect(savedUpdate?.secretEdit, ServiceConnectionSecretEdit.clear);
    expect(savedUpdate?.secret, isNull);
    expect(find.text('Open editor'), findsOneWidget);
  });

  testWidgets('generic connection can replace secret after clearing it', (
    tester,
  ) async {
    const secret = 'generic-replacement-secret';
    GenericServiceConnectionUpdate? savedUpdate;
    await _pumpEditor(
      tester,
      connectionId: _genericConnectionId,
      genericConnection: _genericConnection(),
      onGenericUpdate: (update) => savedUpdate = update,
    );
    await _openEditor(tester);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.enterText(find.byType(EditableText).last, secret);
    await tester.pump();
    final _ = await tester.binding.handlePopRoute();
    final _ = await tester.pumpAndSettle();
    expect(find.byType(AuraConfirmDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AuraConfirmDialog),
        matching: find.text(secret),
      ),
      findsNothing,
    );
    await tester.tap(find.text('Keep editing'));
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    final _ = await tester.pumpAndSettle();

    expect(savedUpdate?.secretEdit, ServiceConnectionSecretEdit.replace);
    expect(savedUpdate?.secret, secret);
  });

  testWidgets('skill credential edits track values without exposing secrets', (
    tester,
  ) async {
    const secret = 'credential-replacement-secret';
    SkillCredentialToUpdate? savedUpdate;
    await _pumpEditor(
      tester,
      connectionId: _credentialId,
      skillCredential: _skillCredential(),
      definition: _skillCredentialDefinition(),
      onSkillUpdate: (update) => savedUpdate = update,
    );
    await _openEditor(tester);
    final _ = await tester.binding.handlePopRoute();
    final _ = await tester.pumpAndSettle();
    expect(find.byType(AuraConfirmDialog), findsNothing);
    expect(find.text('Open editor'), findsOneWidget);
    await _openEditor(tester);

    await tester.enterText(find.byType(EditableText).at(1), 'new-team');
    await tester.tap(find.byIcon(Icons.arrow_back));
    final _ = await tester.pumpAndSettle();
    expect(find.byType(AuraConfirmDialog), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.clear));
    await tester.enterText(find.byType(EditableText).last, secret);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_back));
    final _ = await tester.pumpAndSettle();
    final dialog = find.byType(AuraConfirmDialog);
    expect(dialog, findsOneWidget);
    expect(
      find.descendant(of: dialog, matching: find.text(secret)),
      findsNothing,
    );
    await tester.tap(find.text('Keep editing'));
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    final _ = await tester.pumpAndSettle();

    expect(savedUpdate?.name, 'Account');
    expect(savedUpdate?.nonSecretAttributes, {'team': 'new-team'});
    expect(savedUpdate?.secretAttributes, {'api_key': secret});
    expect(savedUpdate?.clearSecretAttributeNames, isEmpty);
  });
}

Future<void> _pumpEditor(
  WidgetTester tester, {
  required String connectionId,
  ModelConnectionForEdit? modelConnection,
  GenericServiceConnectionForEdit? genericConnection,
  SkillCredentialForEdit? skillCredential,
  SkillCredentialDefinitionEntity? definition,
  void Function(GenericServiceConnectionUpdate)? onGenericUpdate,
  void Function(SkillCredentialToUpdate)? onSkillUpdate,
}) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(
      TestableApp(
        child: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => ServiceConnectionEditScreen(
                      workspaceId: _workspaceId,
                      connectionId: connectionId,
                    ),
                  ),
                );
              },
              child: const Text('Open editor'),
            ),
          ),
        ),
        overrides: [
          modelConnectionStoreProvider(_workspaceId).overrideWith(
            (_) async => _FakeModelConnectionStore(modelConnection),
          ),
          serviceConnectionOperationsProvider(_workspaceId).overrideWith(
            (_) async => _serviceOperations(
              genericConnection: genericConnection,
              onUpdate: onGenericUpdate,
            ),
          ),
          skillCredentialOperationsProvider(_workspaceId).overrideWithValue(
            _skillOperations(
              credential: skillCredential,
              onUpdate: onSkillUpdate,
            ),
          ),
          if (definition != null)
            skillCredentialDefinitionProvider(
              _workspaceId,
              definition.id,
            ).overrideWith((_) async => definition),
        ],
      ),
    );
  });
  final _ = await tester.pumpAndSettle();
}

Future<void> _openEditor(WidgetTester tester) async {
  await tester.tap(find.text('Open editor'));
  final _ = await tester.pumpAndSettle();
}

ServiceConnectionOperations _serviceOperations({
  GenericServiceConnectionForEdit? genericConnection,
  void Function(GenericServiceConnectionUpdate)? onUpdate,
}) => ServiceConnectionOperations(
  createAppSkillCredential: ({
    required workspaceId,
    required appSkillServiceId,
    required name,
    required apiKey,
  }) => Future<void>.value(),
  getGenericForEdit: (id) =>
      Future.value(genericConnection?.id == id ? genericConnection : null),
  updateGeneric: (_, update) async => onUpdate?.call(update),
);

SkillCredentialOperations _skillOperations({
  SkillCredentialForEdit? credential,
  void Function(SkillCredentialToUpdate)? onUpdate,
}) => SkillCredentialOperations(
  create: (_, _) async => throw UnimplementedError(),
  getForEdit: (id) => Future.value(credential?.id == id ? credential : null),
  update: (_, update) async {
    onUpdate?.call(update);

    return SkillCredentialEntity(
      id: _credentialId,
      workspaceId: _workspaceId,
      credentialDefinitionId: _definitionId,
      name: update.name ?? 'Account',
      attributes: {...update.nonSecretAttributes, ...update.secretAttributes},
      isEnabled: true,
      createdAt: .new(2026),
      updatedAt: .new(2026),
    );
  },
  delete: (_) => Future<void>.value(),
);

ModelConnectionForEdit _modelConnection() => const ModelConnectionForEdit(
  id: _modelConnectionId,
  name: 'OpenAI',
  modelId: 'gpt-4o',
  workspaceId: _workspaceId,
  hasKey: true,
  url: 'https://api.example.com',
  keySuffix: '1234',
);

GenericServiceConnectionForEdit _genericConnection() =>
    const GenericServiceConnectionForEdit(
      id: _genericConnectionId,
      name: 'Automation',
      serviceId: 'app-skill',
      hasSecret: true,
      keySuffix: '1234',
    );

SkillCredentialForEdit _skillCredential() => const SkillCredentialForEdit(
  id: _credentialId,
  workspaceId: _workspaceId,
  credentialDefinitionId: _definitionId,
  name: 'Account',
  nonSecretAttributes: {'team': 'old-team'},
  secretAttributes: {
    'api_key': SkillCredentialSecretState(hasValue: true, keySuffix: '1234'),
  },
  isEnabled: true,
);

SkillCredentialDefinitionEntity _skillCredentialDefinition() =>
    SkillCredentialDefinitionEntity(
      id: _definitionId,
      workspaceId: _workspaceId,
      title: 'Test credential',
      slug: 'test-credential',
      attributesJson:
          '{"team":{"description":"Team","secret":false},'
          '"api_key":{"description":"API key","optional":true}}',
      createdAt: .new(2026),
      updatedAt: .new(2026),
    );

class const _FakeModelConnectionStore(final ModelConnectionForEdit? connection)
    implements ModelConnectionStore {
  @override
  Future<ModelProviderVerification> verifyModelConnection(
    ModelProviderVerificationRequest request,
  ) async => throw UnimplementedError();

  @override
  Future<ModelConnectionEntity> createModelConnection(
    ModelConnectionToCreate connection, {
    ModelProviderVerification? verification,
  }) async => throw UnimplementedError();

  @override
  Future<ModelConnectionForEdit?> getModelConnectionForEdit(String id) async =>
      connection?.id == id ? connection : null;

  @override
  Future<ModelConnectionEntity> updateModelConnection(
    String id,
    ModelConnectionToUpdate connection, {
    ModelProviderVerification? verification,
  }) async => throw UnimplementedError();

  @override
  Future<void> deleteModelConnection(String id) async =>
      throw UnimplementedError();

  @override
  Stream<List<ModelConnectionEntity>> watchModelConnections(
    ModelConnectionFilter filter,
  ) => const Stream.empty();
}
