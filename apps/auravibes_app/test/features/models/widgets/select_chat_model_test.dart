import 'package:auravibes_app/domain/entities/api_model_provider.dart';
import 'package:auravibes_app/domain/entities/credentials_entities.dart';
import 'package:auravibes_app/domain/entities/credentials_models_entities.dart';
import 'package:auravibes_app/features/models/providers/list_chat_models_providers.dart';
import 'package:auravibes_app/features/models/widgets/select_chat_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Helper to create mock model data
CredentialsModelWithProviderEntity _createMockModel({
  required String providerName,
  required String modelId,
  required String credentialId,
  required ModelProvidersType providerType,
}) {
  return CredentialsModelWithProviderEntity(
    credentials: CredentialsEntity(
      id: 'cred-$providerName',
      name: providerName,
      key: 'test-key',
      modelId: modelId,
      workspaceId: 'workspace-1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    credentialsModel: CredentialsModelEntity(
      id: credentialId,
      modelId: modelId,
      credentialsId: 'cred-$providerName',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    modelsProvider: ApiModelProviderEntity(
      id: 'provider-$providerName',
      name: providerName,
      type: providerType,
    ),
  );
}

void main() {
  group('SelectCredentialsModelWidget - Two-Step Selection', () {
    late List<CredentialsModelWithProviderEntity> mockModels;

    setUp(() {
      // Create mock data with 2 providers, each with 2 models
      mockModels = [
        _createMockModel(
          providerName: 'Anthropic',
          modelId: 'claude-3-opus',
          credentialId: 'anthropic-1',
          providerType: ModelProvidersType.anthropic,
        ),
        _createMockModel(
          providerName: 'Anthropic',
          modelId: 'claude-3-sonnet',
          credentialId: 'anthropic-2',
          providerType: ModelProvidersType.anthropic,
        ),
        _createMockModel(
          providerName: 'OpenAI',
          modelId: 'gpt-4o',
          credentialId: 'openai-1',
          providerType: ModelProvidersType.openai,
        ),
        _createMockModel(
          providerName: 'OpenAI',
          modelId: 'gpt-4o-mini',
          credentialId: 'openai-2',
          providerType: ModelProvidersType.openai,
        ),
      ];
    });

    testWidgets('shows provider dropdown on load', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listCredentialsCredentialsProvider.overrideWith(
              (ref) => mockModels,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Portal(
                child: SelectCredentialsModelWidget(
                  selectCredentialsModelId: _ignore,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show provider dropdown
      expect(find.text('Select Provider'), findsOneWidget);
    });

    testWidgets('disables model dropdown when no provider selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listCredentialsCredentialsProvider.overrideWith(
              (ref) => mockModels,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Portal(
                child: SelectCredentialsModelWidget(
                  selectCredentialsModelId: _ignore,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Model dropdown should be disabled
      expect(find.text('Select provider first'), findsOneWidget);
    });

    testWidgets('enables model dropdown when provider selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listCredentialsCredentialsProvider.overrideWith(
              (ref) => mockModels,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Portal(
                child: SelectCredentialsModelWidget(
                  selectCredentialsModelId: _ignore,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap provider dropdown
      await tester.tap(find.text('Select Provider'));
      await tester.pumpAndSettle();

      // Select Anthropic
      await tester.tap(find.text('Anthropic').last);
      await tester.pumpAndSettle();

      // Model dropdown should now be enabled with placeholder
      expect(find.text('Select Model'), findsOneWidget);
    });

    testWidgets('shows only selected provider models', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listCredentialsCredentialsProvider.overrideWith(
              (ref) => mockModels,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Portal(
                child: SelectCredentialsModelWidget(
                  selectCredentialsModelId: _ignore,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select Anthropic provider
      await tester.tap(find.text('Select Provider'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anthropic').last);
      await tester.pumpAndSettle();

      // Open model dropdown
      await tester.tap(find.text('Select Model'));
      await tester.pumpAndSettle();

      // Should only show Anthropic models
      expect(find.text('claude-3-opus'), findsWidgets);
      expect(find.text('claude-3-sonnet'), findsWidgets);

      // Should NOT show OpenAI models
      expect(find.text('gpt-4o'), findsNothing);
      expect(find.text('gpt-4o-mini'), findsNothing);
    });

    testWidgets('resets model when provider changes', (tester) async {
      final container = ProviderContainer(
        overrides: [
          listCredentialsCredentialsProvider.overrideWith((ref) => mockModels),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Portal(
                child: SelectCredentialsModelWidget(
                  selectCredentialsModelId: _ignore,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select Anthropic provider
      await tester.tap(find.text('Select Provider'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anthropic').last);
      await tester.pumpAndSettle();

      // Select a model
      await tester.tap(find.text('Select Model'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('claude-3-opus').last);
      await tester.pumpAndSettle();

      // Change provider to OpenAI
      await tester.tap(find.text('Anthropic'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OpenAI').last);
      await tester.pumpAndSettle();

      // Model should be reset - Select Model placeholder should show
      expect(find.text('Select Model'), findsOneWidget);
    });
  });
}

// Helper callback that does nothing
void _ignore(String? _) {}
