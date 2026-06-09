import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/models/widgets/select_workspace_model_selection_widget.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

WorkspaceModelSelectionWithConnectionEntity _makeSelection(
  String id, {
  String? connectionId,
  String connectionName = 'Test',
  String? modelName,
  String providerName = 'OpenAI',
}) {
  return WorkspaceModelSelectionWithConnectionEntity(
    workspaceModelSelection: WorkspaceModelSelectionEntity(
      id: id,
      modelId: 'model-$id',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      modelConnectionId: connectionId ?? 'conn-$id',
      modelName: modelName,
    ),
    modelConnection: ModelConnectionEntity(
      id: connectionId ?? 'conn-$id',
      name: connectionName,
      key: 'key',
      modelId: 'openai',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      workspaceId: 'ws-1',
    ),
    modelsProvider: ApiModelProviderEntity(
      id: 'openai',
      name: providerName,
      type: null,
    ),
  );
}

void main() {
  Widget buildLocalizedSelectChatData(SelectChatData child) {
    return EasyLocalization(
      child: Builder(
        builder: (context) {
          return MaterialApp(
            home: Scaffold(
              body: Portal(child: child),
            ),
            theme: ThemeData(extensions: [AuraTheme.light]),
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
          );
        },
      ),
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      useOnlyLangCode: true,
      useFallbackTranslations: true,
    );
  }

  group('findProviderForModelId', () {
    test('returns null when workspaceModelSelectionId is null', () {
      final result = findProviderForModelId({}, null);
      expect(result, isNull);
    });

    test('returns null when groupedModels is empty', () {
      final result = findProviderForModelId({}, 'sel-1');
      expect(result, isNull);
    });

    test('returns provider key when model found', () {
      final grouped =
          <String, List<WorkspaceModelSelectionWithConnectionEntity>>{
            'conn-1': [_makeSelection('sel-1', connectionId: 'conn-1')],
          };
      final result = findProviderForModelId(grouped, 'sel-1');
      expect(result, 'conn-1');
    });

    test('returns null when model not found in any provider', () {
      final grouped =
          <String, List<WorkspaceModelSelectionWithConnectionEntity>>{
            'conn-1': [_makeSelection('sel-1', connectionId: 'conn-1')],
            'conn-2': [_makeSelection('sel-2', connectionId: 'conn-2')],
          };
      final result = findProviderForModelId(grouped, 'sel-999');
      expect(result, isNull);
    });

    test('returns correct provider when model in second provider', () {
      final grouped =
          <String, List<WorkspaceModelSelectionWithConnectionEntity>>{
            'conn-1': [_makeSelection('sel-1', connectionId: 'conn-1')],
            'conn-2': [_makeSelection('sel-2', connectionId: 'conn-2')],
          };
      final result = findProviderForModelId(grouped, 'sel-2');
      expect(result, 'conn-2');
    });

    test('searches all providers and returns first match', () {
      final grouped =
          <String, List<WorkspaceModelSelectionWithConnectionEntity>>{
            'ProviderA': [_makeSelection('sel-a')],
            'ProviderB': [_makeSelection('sel-b')],
            'ProviderC': [_makeSelection('sel-c')],
          };
      final result = findProviderForModelId(grouped, 'sel-b');
      expect(result, 'ProviderB');
    });

    test('handles provider with empty model list', () {
      final grouped =
          <String, List<WorkspaceModelSelectionWithConnectionEntity>>{
            'conn-1': <WorkspaceModelSelectionWithConnectionEntity>[],
            'conn-2': [_makeSelection('sel-2', connectionId: 'conn-2')],
          };
      final result = findProviderForModelId(grouped, 'sel-2');
      expect(result, 'conn-2');
    });

    test('returns null when all providers have empty lists', () {
      final grouped =
          <String, List<WorkspaceModelSelectionWithConnectionEntity>>{
            'conn-1': <WorkspaceModelSelectionWithConnectionEntity>[],
            'conn-2': <WorkspaceModelSelectionWithConnectionEntity>[],
          };
      final result = findProviderForModelId(grouped, 'sel-1');
      expect(result, isNull);
    });

    test(
      'returns provider for first match when multiple providers have same id',
      () {
        final grouped =
            <String, List<WorkspaceModelSelectionWithConnectionEntity>>{
              'First': [_makeSelection('sel-dup')],
              'Second': [_makeSelection('sel-dup')],
            };
        final result = findProviderForModelId(grouped, 'sel-dup');
        expect(result, 'First');
      },
    );

    test('handles large number of providers', () {
      final grouped =
          <String, List<WorkspaceModelSelectionWithConnectionEntity>>{};
      for (var i = 0; i < 100; i++) {
        grouped['Provider$i'] = [_makeSelection('sel-$i')];
      }
      final result = findProviderForModelId(grouped, 'sel-50');
      expect(result, 'Provider50');
    });
  });

  group('SelectWorkspaceModelSelectionWidget', () {
    const widget = SelectWorkspaceModelSelectionWidget(
      workspaceId: 'ws-1',
      selectWorkspaceModelSelectionId: _noop,
      onProviderChanged: _noop,
    );

    test('preferredSize has height 120', () {
      expect(widget.preferredSize.height, 120);
    });

    test('preferredSize width is fromHeight derived', () {
      expect(widget.preferredSize.width, double.infinity);
    });

    test('is a PreferredSizeWidget', () {
      expect(widget, isA<PreferredSizeWidget>());
    });

    test('stores workspaceId', () {
      expect(widget.workspaceId, 'ws-1');
    });

    test('workspaceModelSelectionId defaults to null', () {
      expect(widget.workspaceModelSelectionId, isNull);
    });

    test('selectedProviderId defaults to null', () {
      expect(widget.selectedProviderId, isNull);
    });

    test('accepts optional workspaceModelSelectionId', () {
      const w = SelectWorkspaceModelSelectionWidget(
        workspaceId: 'ws-1',
        selectWorkspaceModelSelectionId: _noop,
        onProviderChanged: _noop,
        workspaceModelSelectionId: 'sel-1',
      );
      expect(w.workspaceModelSelectionId, 'sel-1');
    });

    test('accepts optional selectedProviderId', () {
      const w = SelectWorkspaceModelSelectionWidget(
        workspaceId: 'ws-1',
        selectWorkspaceModelSelectionId: _noop,
        onProviderChanged: _noop,
        selectedProviderId: 'conn-1',
      );
      expect(w.selectedProviderId, 'conn-1');
    });

    test('accepts optional key', () {
      const w = SelectWorkspaceModelSelectionWidget(
        workspaceId: 'ws-1',
        selectWorkspaceModelSelectionId: _noop,
        onProviderChanged: _noop,
        key: Key('test-key'),
      );
      expect(w.key, const Key('test-key'));
    });
  });

  group('findProviderForModelId additional', () {
    test('handles provider with single model', () {
      final grouped =
          <String, List<WorkspaceModelSelectionWithConnectionEntity>>{
            'conn-1': [_makeSelection('sel-1', connectionId: 'conn-1')],
          };
      expect(findProviderForModelId(grouped, 'sel-1'), 'conn-1');
      expect(findProviderForModelId(grouped, 'sel-999'), isNull);
    });

    test('handles provider with multiple models', () {
      final grouped =
          <String, List<WorkspaceModelSelectionWithConnectionEntity>>{
            'conn-1': [
              _makeSelection('sel-1', connectionId: 'conn-1'),
              _makeSelection('sel-2', connectionId: 'conn-1'),
              _makeSelection('sel-3', connectionId: 'conn-1'),
            ],
          };
      expect(findProviderForModelId(grouped, 'sel-2'), 'conn-1');
      expect(findProviderForModelId(grouped, 'sel-3'), 'conn-1');
    });

    test('returns null for null groupedModels map values', () {
      final grouped =
          <String, List<WorkspaceModelSelectionWithConnectionEntity>>{};
      expect(findProviderForModelId(grouped, 'any'), isNull);
    });
  });

  group('SelectChatData provider display', () {
    testWidgets('renders provider and model titles with subtitles', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: SelectChatData(
                groupedModels: {
                  'anthropic-work': [
                    _makeSelection(
                      'sel-1',
                      connectionId: 'anthropic-work',
                      connectionName: 'Work API Key',
                      modelName: 'Claude Sonnet 4',
                      providerName: 'Anthropic',
                    ),
                  ],
                },
                workspaceModelSelectionId: 'sel-1',
                selectedProviderId: null,
                onSelectProvider: _noop,
                selectWorkspaceModelSelectionId: _noop,
              ),
            ),
          ),
          theme: ThemeData(extensions: [AuraTheme.light]),
        ),
      );

      expect(find.text('Anthropic'), findsOneWidget);
      expect(find.text('Work API Key'), findsOneWidget);
      expect(find.text('Claude Sonnet 4'), findsOneWidget);
      expect(find.text('model-sel-1'), findsOneWidget);
    });

    testWidgets('filters models by visible model name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: SelectChatData(
                groupedModels: {
                  'anthropic-work': [
                    _makeSelection(
                      'sel-1',
                      connectionId: 'anthropic-work',
                      connectionName: 'Work API Key',
                      modelName: 'Claude Sonnet 4',
                      providerName: 'Anthropic',
                    ),
                  ],
                },
                workspaceModelSelectionId: 'sel-1',
                selectedProviderId: null,
                onSelectProvider: _noop,
                selectWorkspaceModelSelectionId: _noop,
              ),
            ),
          ),
          theme: ThemeData(extensions: [AuraTheme.light]),
        ),
      );

      await tester.tap(find.text('Claude Sonnet 4'));
      await tester.pump();
      await tester.enterText(find.byType(AuraInput), 'sonnet');
      await tester.pump();

      expect(find.text('Claude Sonnet 4'), findsNWidgets(2));
      expect(find.text('model-sel-1'), findsNWidgets(2));
    });

    testWidgets('renders empty selected provider group without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildLocalizedSelectChatData(
          const SelectChatData(
            groupedModels: {
              'empty-provider': <WorkspaceModelSelectionWithConnectionEntity>[],
            },
            workspaceModelSelectionId: null,
            selectedProviderId: 'empty-provider',
            onSelectProvider: _noop,
            selectWorkspaceModelSelectionId: _noop,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

void _noop(String? _) {
  final _ = Object();
}
