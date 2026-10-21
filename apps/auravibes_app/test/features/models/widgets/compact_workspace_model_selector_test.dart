import 'dart:ui' as ui;

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/models/models/model_stores.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/models/widgets/compact_workspace_model_selector.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../data/database/drift/database_test_utils.dart';
import '../../../helpers/test_app.dart';

AppDatabase _newDatabase() =>
    AppDatabase(connection: DatabaseConnection(NativeDatabase.memory()));
AppDatabase? _sharedDatabase;

void main() {
  final database = _newDatabase();
  _sharedDatabase = database;
  var isFirstTest = true;
  setUp(() async {
    if (isFirstTest) {
      isFirstTest = false;

      return;
    }
    await clearAppDatabase(database);
  });
  tearDownAll(() async {
    await database.close();
    _sharedDatabase = null;
  });

  testWidgets('shows loading placeholder', (tester) async {
    final _ = await tester.runAsync(() async {
      await tester.pumpWidget(
        _SubjectBuilder.build(
          groupedModelsStream: .multi(
            (controller) => controller.onCancel = Future<void>.value,
          ),
        ),
      );
      await Future<void>.delayed(.zero);
    });
    for (var index = 0; index < 10; index++) {
      await tester.pump();
      if (find.byType(AuraSpinner).evaluate().isNotEmpty) break;
    }

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
    expect(find.byType(AuraTile), findsOneWidget);
    expect(find.byIcon(Icons.memory_outlined), findsOneWidget);
    expect(find.text('Claude Sonnet 4'), findsOneWidget);
    expect(
      tester.getRect(find.text('Claude Sonnet 4')).center.dy,
      closeTo(tester.getRect(find.byType(AuraTile)).center.dy, 0.1),
    );
  });

  testWidgets('compact model placeholder is vertically centered', (
    tester,
  ) async {
    await _pumpSubject(
      tester,
      _SubjectBuilder.build(groupedModels: {}, compactMode: true),
    );

    expect(find.text('Model'), findsOneWidget);
    expect(
      tester.getRect(find.text('Model')).center.dy,
      closeTo(tester.getRect(find.byType(AuraTile)).center.dy, 0.1),
    );
  });

  testWidgets('compact tile handles its own tap', (tester) async {
    var tapped = false;
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
        onCompactTap: () => tapped = true,
      ),
    );

    final tile = tester.widget<AuraTile>(find.byType(AuraTile));
    expect(tile.onTap == null, isFalse);
    await tester.tap(find.byType(AuraTile));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('compact chip resolves its configured radius from theme', (
    tester,
  ) async {
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
        theme: AuraTheme.light.copyWith(
          borderRadius: const AuraBorderRadiusScale(xl: 12),
          globalBorderRadiusLevel: .xl,
        ),
      ),
    );

    final chipDecoration = find.ancestor(
      of: find.text('Claude Sonnet 4'),
      matching: find.byWidgetPredicate((widget) {
        if (widget is! AnimatedContainer) return false;
        final decoration = widget.decoration;

        return decoration is BoxDecoration &&
            decoration.borderRadius == const BorderRadius.all(.circular(12));
      }),
    );
    expect(chipDecoration, findsOneWidget);
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

  testWidgets('marks an unknown selected id unavailable automatically', (
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
        selectedId: 'deleted-selection',
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
    expect(find.text('Claude Sonnet 4'), findsNothing);

    await tester.tap(find.text('GPT 5.5'));
    await tester.pump();

    expect(selected, 'sel-2');
  });

  testWidgets('model sheet shows effective policy and saves each choice', (
    tester,
  ) async {
    final updates = <({String selectionId, ToolSamplingPolicy? policy})>[];
    await _pumpSubject(
      tester,
      _SubjectBuilder.build(
        groupedModels: {
          'openai-work': [
            _makeSelection(
              'sel-1',
              connectionId: 'openai-work',
              modelId: 'gpt-4o',
              providerName: 'OpenAI',
              modelName: 'GPT 4o',
              providerType: .openai,
              providerUrl: 'https://api.openai.com/v1',
            ),
          ],
        },
        modelSelectionStore: _FakeModelSelectionStore(
          onPolicyUpdate: (selectionId, policy) =>
              updates.add((selectionId: selectionId, policy: policy)),
        ),
        sheetMode: true,
      ),
    );

    expect(
      find.text('Tool sampling: Automatic (Prefer strict)'),
      findsOneWidget,
    );
    expect(find.text('Verified'), findsOneWidget);

    for (final label in [
      'Off',
      'Prefer strict',
      'Require strict',
      'Automatic (Prefer strict)',
    ]) {
      await tester.tap(find.byTooltip('Tool sampling settings for GPT 4o'));
      final _ = await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
      await tester.tap(find.text(label));
      final _ = await tester.pumpAndSettle();
    }

    expect(updates, [
      (selectionId: 'sel-1', policy: ToolSamplingPolicy.off),
      (selectionId: 'sel-1', policy: ToolSamplingPolicy.prefer),
      (selectionId: 'sel-1', policy: ToolSamplingPolicy.require),
      (selectionId: 'sel-1', policy: null),
    ]);
    expect(find.byTooltip('Tool sampling settings for GPT 4o'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byTooltip('Tool sampling settings for GPT 4o'))
          .tooltip,
      'Tool sampling settings for GPT 4o',
    );
  });

  for (final (:policy, :label) in <({ToolSamplingPolicy policy, String label})>[
    (policy: .off, label: 'Off'),
    (policy: .prefer, label: 'Prefer strict'),
    (policy: .require, label: 'Require strict'),
  ]) {
    testWidgets('shows saved tool sampling policy: $label', (tester) async {
      await _pumpSubject(
        tester,
        _SubjectBuilder.build(
          groupedModels: {
            'openai-work': [
              _makeSelection(
                'sel-1',
                connectionId: 'openai-work',
                modelId: 'gpt-4o',
                providerName: 'OpenAI',
                modelName: 'GPT 4o',
                providerType: .openai,
                providerUrl: 'https://api.openai.com/v1',
                toolSamplingPolicy: policy,
              ),
            ],
          },
          sheetMode: true,
        ),
      );

      expect(find.text('Tool sampling: $label'), findsOneWidget);
    });
  }

  testWidgets('localizes accessible tool sampling settings label', (
    tester,
  ) async {
    await _pumpSubject(
      tester,
      _SubjectBuilder.build(
        groupedModels: {
          'openai-work': [
            _makeSelection(
              'sel-1',
              connectionId: 'openai-work',
              modelId: 'gpt-4o',
              providerName: 'OpenAI',
              modelName: 'GPT 4o',
              providerType: .openai,
              providerUrl: 'https://api.openai.com/v1',
            ),
          ],
        },
        sheetMode: true,
        locale: const Locale('es'),
      ),
    );

    const tooltip = 'Ajustes de muestreo de herramientas para GPT 4o';
    final settingsButton = find.byTooltip(tooltip);
    expect(settingsButton, findsOneWidget);
    expect(tester.getSemantics(settingsButton).tooltip, tooltip);
  });

  testWidgets('unverified model explains and disables require', (tester) async {
    await _pumpSubject(
      tester,
      _SubjectBuilder.build(
        groupedModels: {
          'openai-work': [
            _makeSelection(
              'sel-1',
              connectionId: 'openai-work',
              modelId: 'gpt-4o',
              providerName: 'OpenAI',
              modelName: 'GPT 4o',
              providerType: .openai,
              providerUrl: 'https://proxy.example.com/v1',
            ),
          ],
        },
        sheetMode: true,
      ),
    );

    expect(find.text('Not verified'), findsOneWidget);
    expect(
      find.text(
        'Require strict is unavailable because model support or '
        'endpoint is not verified.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Tool sampling settings for GPT 4o'));
    final _ = await tester.pumpAndSettle();

    final requireLabel = find.text('Require strict');
    expect(requireLabel, findsOneWidget);
    final disabledRequire = find.ancestor(
      of: requireLabel,
      matching: find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.enabled == false,
      ),
    );
    expect(disabledRequire, findsOneWidget);
    final requireSemantics = tester.getSemantics(disabledRequire);
    final requireSemanticsData = requireSemantics.getSemanticsData();
    expect(requireSemanticsData.flagsCollection.isButton, isTrue);
    expect(requireSemanticsData.flagsCollection.isEnabled, ui.Tristate.isFalse);
  });

  testWidgets('unsupported tool calls explains disabled require', (
    tester,
  ) async {
    await _pumpSubject(
      tester,
      _SubjectBuilder.build(
        groupedModels: {
          'openai-work': [
            _makeSelection(
              'sel-1',
              connectionId: 'openai-work',
              modelId: 'gpt-4o',
              providerName: 'OpenAI',
              modelName: 'GPT 4o',
              providerType: .openai,
              providerUrl: 'https://api.openai.com/v1',
              supportsToolCalls: false,
            ),
          ],
        },
        sheetMode: true,
      ),
    );

    expect(find.text('No tool calls'), findsOneWidget);
    expect(
      find.text('This model does not support tool calls.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Tool sampling settings for GPT 4o'));
    final _ = await tester.pumpAndSettle();

    final requireLabel = find.text('Require strict');
    final disabledRequire = find.ancestor(
      of: requireLabel,
      matching: find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.enabled == false,
      ),
    );
    expect(disabledRequire, findsOneWidget);
  });

  testWidgets('shows existing recent models first and omits missing models', (
    tester,
  ) async {
    final database =
        _sharedDatabase ??
        (throw StateError('Shared test database has not been initialized.'));
    for (final selectionId in ['sel-1', 'sel-2', 'deleted-selection']) {
      await database.recentModelSelectionsDao.recordSelection(
        'ws-1',
        selectionId,
      );
    }
    await _pumpSubject(
      tester,
      _SubjectBuilder.build(
        database: database,
        groupedModels: {
          'openai-work': [
            _makeSelection(
              'sel-1',
              connectionId: 'openai-work',
              modelId: 'gpt-4.1',
              providerName: 'OpenAI',
              modelName: 'GPT 4.1',
            ),
            _makeSelection(
              'sel-2',
              connectionId: 'openai-work',
              modelId: 'gpt-5.5',
              providerName: 'OpenAI',
              modelName: 'GPT 5.5',
            ),
            _makeSelection(
              'sel-3',
              connectionId: 'openai-work',
              modelId: 'gpt-5.5-mini',
              providerName: 'OpenAI',
              modelName: 'GPT 5.5 Mini',
            ),
          ],
        },
        sheetMode: true,
      ),
    );

    expect(find.text('Recent models'), findsOneWidget);
    expect(find.text('All models'), findsOneWidget);
    expect(find.text('GPT 5.5'), findsOneWidget);
    expect(find.text('GPT 4.1'), findsOneWidget);
    expect(find.text('GPT 5.5 Mini'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('GPT 5.5')).dy,
      lessThan(tester.getTopLeft(find.text('GPT 4.1')).dy),
    );
    expect(
      tester.getTopLeft(find.text('GPT 4.1')).dy,
      lessThan(tester.getTopLeft(find.text('All models')).dy),
    );
    expect(
      tester.getTopLeft(find.text('All models')).dy,
      lessThan(tester.getTopLeft(find.text('GPT 5.5 Mini')).dy),
    );
  });

  testWidgets('hides recent section while searching', (tester) async {
    final database =
        _sharedDatabase ??
        (throw StateError('Shared test database has not been initialized.'));
    await database.recentModelSelectionsDao.recordSelection('ws-1', 'sel-1');
    await _pumpSubject(
      tester,
      _SubjectBuilder.build(
        database: database,
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
        sheetMode: true,
        selectedId: 'sel-1',
      ),
    );

    expect(find.text('Recent models'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'gpt');
    await tester.pump();

    expect(find.text('Recent models'), findsNothing);
    expect(find.text('All models'), findsNothing);
    expect(find.text('GPT 5.5'), findsOneWidget);
    expect(find.text('Claude Sonnet 4'), findsOneWidget);
  });
}

Future<void> _pumpSubject(WidgetTester tester, Widget subject) async {
  final _ = await tester.runAsync(() async {
    await tester.pumpWidget(subject);
    await Future<void>.delayed(.zero);
  });
  final _ = await tester.pumpAndSettle();
}

abstract final class _SubjectBuilder {
  static Widget build({
    AuraTheme? theme,
    Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>?
    groupedModels,
    Stream<Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>>?
    groupedModelsStream,
    AppDatabase? database,
    String? selectedId,
    ValueChanged<String?>? onChanged,
    ModelSelectionStore? modelSelectionStore,
    bool compactMode = false,
    bool sheetMode = false,
    bool modelUnavailable = false,
    Locale locale = const Locale('en'),
    VoidCallback? onCompactTap,
  }) {
    assert(
      groupedModels != null || groupedModelsStream != null,
      'Provide groupedModels or groupedModelsStream.',
    );
    final stream =
        groupedModelsStream ?? Stream.value(groupedModels ?? const {});
    final appDatabase =
        database ??
        _sharedDatabase ??
        (throw StateError('Shared test database has not been initialized.'));

    return TestableApp(
      child: AuraThemeScope(
        theme: theme ?? .light,
        child: Theme(
          data: .new(),
          child: Scaffold(
            body: Portal(
              child: CompactWorkspaceModelSelector(
                workspaceId: 'ws-1',
                workspaceModelSelectionId: selectedId,
                onChanged: onChanged ?? (_) => fail('Unexpected model change'),
                compactMode: compactMode,
                sheetMode: sheetMode,
                modelUnavailable: modelUnavailable,
                onCompactTap: onCompactTap,
              ),
            ),
          ),
        ),
      ),
      overrides: [
        appDatabaseProvider.overrideWithValue(appDatabase),
        cloudModelGatewayForWorkspaceProvider.overrideWith(
          (_, _) async => null,
        ),
        listModelsGroupedByProviderProvider.overrideWith(
          (ref, workspaceId) => stream,
        ),
        if (modelSelectionStore case final store?)
          modelSelectionStoreProvider('ws-1').overrideWith((_) => store),
      ],
      startLocale: locale,
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
  ModelProvidersType? providerType,
  String? providerUrl,
  String? connectionUrl,
  bool supportsToolCalls = true,
  ToolSamplingPolicy? toolSamplingPolicy,
}) {
  return WorkspaceModelSelectionWithConnectionEntity(
    workspaceModelSelection: .new(
      id: id,
      modelId: modelId,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      modelConnectionId: connectionId,
      modelName: modelName,
      supportsToolCalls: supportsToolCalls,
      toolSamplingPolicy: toolSamplingPolicy,
    ),
    modelConnection: .new(
      id: connectionId,
      name: connectionName,
      modelId: providerName.toLowerCase(),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      workspaceId: 'ws-1',
      hasKey: true,
      url: connectionUrl,
    ),
    modelsProvider: .new(
      id: providerName.toLowerCase(),
      name: providerName,
      type: providerType,
      url: providerUrl,
    ),
  );
}

class _FakeModelSelectionStore implements ModelSelectionStore {
  new({required this.onPolicyUpdate});

  final void Function(String selectionId, ToolSamplingPolicy? policy)
  onPolicyUpdate;

  @override
  Future<WorkspaceModelSelectionWithConnectionEntity?> getById(
    String id,
  ) async => null;

  @override
  Future<void> updateToolSamplingPolicy(
    String selectionId,
    ToolSamplingPolicy? policy,
  ) async => onPolicyUpdate(selectionId, policy);

  @override
  Stream<List<WorkspaceModelSelectionWithConnectionEntity>> watch(
    String workspaceId,
  ) => const Stream.empty();
}
