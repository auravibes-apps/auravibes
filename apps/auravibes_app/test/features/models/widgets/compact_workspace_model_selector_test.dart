import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/models/widgets/compact_workspace_model_selector.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('shows loading placeholder', (tester) async {
    final _ = await tester.runAsync(() async {
      await tester.pumpWidget(
        _SubjectBuilder.build(groupedModelsStream: const Stream.empty()),
      );
    });
    await tester.pump();

    expect(find.byType(AuraSpinner), findsOneWidget);
  });

  testWidgets('shows error fallback', (tester) async {
    await _pumpSubject(
      tester,
      _SubjectBuilder.build(
        groupedModelsStream: .error(StateError('model error'), .current),
      ),
    );

    expect(find.byType(AppErrorWidget), findsOneWidget);
  });

  testWidgets('shows selected model name', (tester) async {
    await _pumpSubject(
      tester,
      _SubjectBuilder.build(
        groupedModels: {
          'anthropic-work': [
            _makeSelection(
              'sel-1',
              connectionId: 'anthropic-work',
              modelId: 'claude-sonnet-4',
              providerName: 'Anthropic',
              connectionName: 'Work API Key',
              modelName: 'Claude Sonnet 4',
            ),
          ],
        },
        selectedId: 'sel-1',
      ),
    );

    expect(find.text('Claude Sonnet 4'), findsOneWidget);
  });

  testWidgets('compact mode shows selected model chip', (tester) async {
    await _pumpSubject(
      tester,
      _SubjectBuilder.build(
        groupedModels: {
          'anthropic-work': [
            _makeSelection(
              'sel-1',
              connectionId: 'anthropic-work',
              modelId: 'claude-sonnet-4',
              providerName: 'Anthropic',
              modelName: 'Claude Sonnet 4',
            ),
          ],
        },
        selectedId: 'sel-1',
        compactMode: true,
      ),
    );

    expect(find.byType(AuraDropdownSelector<String>), findsNothing);
    expect(find.byIcon(Icons.memory_outlined), findsOneWidget);
    expect(find.text('Claude Sonnet 4'), findsOneWidget);
  });

  testWidgets('compact mode shows warning for unavailable model', (
    tester,
  ) async {
    await _pumpSubject(
      tester,
      _SubjectBuilder.build(
        groupedModels: {
          'openai-work': [
            _makeSelection(
              'sel-2',
              connectionId: 'openai-work',
              modelId: 'gpt-5.5',
              providerName: 'OpenAI',
              modelName: 'GPT 5.5',
            ),
          ],
        },
        selectedId: 'deleted-selection',
        compactMode: true,
        modelUnavailable: true,
      ),
    );

    expect(find.text('Model unavailable'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('shows empty provider placeholder', (tester) async {
    await _pumpSubject(tester, _SubjectBuilder.build(groupedModels: {}));

    expect(find.text('Model'), findsOneWidget);
  });

  testWidgets('filters models by search text', (tester) async {
    await _pumpSubject(
      tester,
      _SubjectBuilder.build(
        groupedModels: {
          'anthropic-work': [
            _makeSelection(
              'sel-1',
              connectionId: 'anthropic-work',
              modelId: 'claude-sonnet-4',
              providerName: 'Anthropic',
              modelName: 'Claude Sonnet 4',
            ),
            _makeSelection(
              'sel-3',
              connectionId: 'anthropic-work',
              modelId: 'claude-opus-4',
              providerName: 'Anthropic',
              modelName: 'Claude Opus 4',
            ),
          ],
          'openai-work': [
            _makeSelection(
              'sel-2',
              connectionId: 'openai-work',
              modelId: 'gpt-5.5',
              providerName: 'OpenAI',
              modelName: 'GPT 5.5',
            ),
          ],
        },
        selectedId: 'sel-1',
      ),
    );

    await tester.tap(find.text('Claude Sonnet 4'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'gpt');
    await tester.pump();

    expect(find.text('GPT 5.5'), findsOneWidget);
    expect(find.text('Claude Sonnet 4'), findsWidgets);
    expect(find.text('Claude Opus 4'), findsNothing);
  });

  testWidgets('sheet mode filters models without dropdown', (tester) async {
    String? selected;
    await _pumpSubject(
      tester,
      _SubjectBuilder.build(
        groupedModels: {
          'anthropic-work': [
            _makeSelection(
              'sel-1',
              connectionId: 'anthropic-work',
              modelId: 'claude-sonnet-4',
              providerName: 'Anthropic',
              modelName: 'Claude Sonnet 4',
            ),
          ],
          'openai-work': [
            _makeSelection(
              'sel-2',
              connectionId: 'openai-work',
              modelId: 'gpt-5.5',
              providerName: 'OpenAI',
              modelName: 'GPT 5.5',
            ),
          ],
        },
        selectedId: 'sel-1',
        onChanged: (value) => selected = value,
        sheetMode: true,
      ),
    );

    expect(find.byType(AuraDropdownSelector<String>), findsNothing);
    expect(find.text('Claude Sonnet 4'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'gpt');
    await tester.pump();

    expect(find.text('GPT 5.5'), findsOneWidget);
    expect(find.text('gpt-5.5'), findsOneWidget);
    expect(find.text('OpenAI - Test'), findsOneWidget);
    expect(find.text('Claude Sonnet 4'), findsOneWidget);

    await tester.tap(find.text('GPT 5.5'));
    await tester.pump();

    expect(selected, 'sel-2');
  });
}

Future<void> _pumpSubject(WidgetTester tester, Widget subject) async {
  final _ = await tester.runAsync(() async {
    await tester.pumpWidget(subject);
  });
  final _ = await tester.pumpAndSettle();
}

abstract final class _SubjectBuilder {
  static Widget build({
    Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>?
    groupedModels,
    Stream<Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>>?
    groupedModelsStream,
    String? selectedId,
    ValueChanged<String?>? onChanged,
    bool compactMode = false,
    bool sheetMode = false,
    bool modelUnavailable = false,
  }) {
    assert(
      groupedModels != null || groupedModelsStream != null,
      'Provide groupedModels or groupedModelsStream.',
    );
    final stream =
        groupedModelsStream ?? Stream.value(groupedModels ?? const {});

    return TestableApp(
      child: Theme(
        data: .new(extensions: [AuraTheme.light]),
        child: Scaffold(
          body: Portal(
            child: CompactWorkspaceModelSelector(
              workspaceId: 'ws-1',
              workspaceModelSelectionId: selectedId,
              onChanged: onChanged ?? (_) => fail('Unexpected model change'),
              compactMode: compactMode,
              sheetMode: sheetMode,
              modelUnavailable: modelUnavailable,
            ),
          ),
        ),
      ),
      overrides: [
        listModelsGroupedByProviderProvider.overrideWith(
          (ref, workspaceId) => stream,
        ),
      ],
    );
  }
}

WorkspaceModelSelectionWithConnectionEntity _makeSelection(
  String id, {
  required String connectionId,
  required String modelId,
  required String providerName,
  String connectionName = 'Test',
  String? modelName,
}) {
  return WorkspaceModelSelectionWithConnectionEntity(
    workspaceModelSelection: .new(
      id: id,
      modelId: modelId,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      modelConnectionId: connectionId,
      modelName: modelName,
    ),
    modelConnection: .new(
      id: connectionId,
      name: connectionName,
      modelId: providerName.toLowerCase(),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      workspaceId: 'ws-1',
      hasKey: true,
    ),
    modelsProvider: .new(
      id: providerName.toLowerCase(),
      name: providerName,
      type: null,
    ),
  );
}
