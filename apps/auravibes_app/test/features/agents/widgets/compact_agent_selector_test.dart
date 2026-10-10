import 'dart:async';

import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/agents/widgets/compact_agent_selector.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('sheet mode filters agents and selects agent', (tester) async {
    String? selected;

    await _pumpSubject(
      tester,
      agents: [
        _makeAgent('agent-1', 'Research Agent'),
        _makeAgent('agent-2', 'Code Agent'),
      ],
      onChanged: (value) => selected = value,
      agentId: 'agent-1',
      sheetMode: true,
    );

    expect(find.byType(AuraDropdownSelector<String>), findsNothing);
    expect(find.text('Research Agent'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'code');
    await tester.pump();

    expect(find.text('Code Agent'), findsOneWidget);
    expect(find.text('Research Agent'), findsNothing);

    await tester.tap(find.text('Code Agent'));
    await tester.pump();

    expect(selected, 'agent-2');
  });

  testWidgets('sheet mode none row maps to null', (tester) async {
    String? selected = 'agent-1';

    await _pumpSubject(
      tester,
      agents: [_makeAgent('agent-1', 'Research Agent')],
      onChanged: (value) => selected = value,
      agentId: 'agent-1',
      sheetMode: true,
    );

    await tester.tap(find.text('No agent'));
    await tester.pump();

    expect(selected, isNull);
  });

  testWidgets('dragging agent sheet results dismisses search focus', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 350);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpSubject(
      tester,
      agents: [
        for (var index = 0; index < 20; index++)
          _makeAgent('agent-$index', 'Agent $index'),
      ],
      onChanged: (_) => fail('Unexpected agent selection'),
      sheetMode: true,
    );

    final search = find.byType(EditableText);
    await tester.tap(search);
    await tester.pump();
    final focusNode = tester.widget<EditableText>(search).focusNode;
    expect(focusNode.hasFocus, isTrue);

    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pump();

    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('sheet mode updates when agents arrive after mount', (
    tester,
  ) async {
    final controller = StreamController<List<AgentEntity>>();
    addTearDown(controller.close);
    String? selected;
    controller.add(const []);

    await _pumpSubject(
      tester,
      agents: const [],
      onChanged: (value) => selected = value,
      agentStream: controller.stream,
      sheetMode: true,
    );

    expect(find.text('No agent'), findsOneWidget);

    controller.add([_makeAgent('agent-1', 'Research Agent')]);
    final pumpCount = await tester.pumpAndSettle();
    expect(pumpCount, greaterThanOrEqualTo(0));

    expect(find.text('Research Agent'), findsOneWidget);
    await tester.tap(find.text('Research Agent'));
    await tester.pump();

    expect(selected, 'agent-1');
  });

  testWidgets('sheet mode omits hidden and disabled agents', (tester) async {
    await _pumpSubject(
      tester,
      agents: [
        _makeAgent('chat', 'Chat Agent'),
        _makeAgent('sub-agent', 'Sub-agent Only', visibility: .subAgentList),
        _makeAgent('disabled', 'Disabled Agent', isEnabled: false),
      ],
      onChanged: (_) {
        final _ = Object();
      },
      sheetMode: true,
    );

    expect(find.text('Chat Agent'), findsOneWidget);
    expect(find.text('Sub-agent Only'), findsNothing);
    expect(find.text('Disabled Agent'), findsNothing);
  });

  testWidgets('compact mode shows selected agent chip', (tester) async {
    await _pumpSubject(
      tester,
      agents: [_makeAgent('agent-1', 'Research Agent')],
      onChanged: (_) {
        final _ = Object();
      },
      agentId: 'agent-1',
      compactMode: true,
    );

    expect(find.byType(AuraDropdownSelector<String>), findsNothing);
    expect(find.byType(AuraTile), findsOneWidget);
    expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
    expect(find.text('Research Agent'), findsOneWidget);
    expect(
      tester.getRect(find.text('Research Agent')).center.dy,
      closeTo(tester.getRect(find.byType(AuraTile)).center.dy, 0.1),
    );
  });

  testWidgets('compact no-agent label is vertically centered', (tester) async {
    await _pumpSubject(
      tester,
      agents: [_makeAgent('agent-1', 'Research Agent')],
      onChanged: (_) {
        final _ = Object();
      },
      compactMode: true,
    );

    expect(find.text('No agent'), findsOneWidget);
    expect(
      tester.getRect(find.text('No agent')).center.dy,
      closeTo(tester.getRect(find.byType(AuraTile)).center.dy, 0.1),
    );
  });

  testWidgets('compact tile handles its own tap', (tester) async {
    var tapped = false;
    await _pumpSubject(
      tester,
      agents: [_makeAgent('agent-1', 'Research Agent')],
      onChanged: (_) {
        final _ = Object();
      },
      agentId: 'agent-1',
      compactMode: true,
      onCompactTap: () => tapped = true,
    );

    final tile = tester.widget<AuraTile>(find.byType(AuraTile));
    expect(tile.onTap, isNotNull);
    await tester.tap(find.byType(AuraTile));
    final pumpCount = await tester.pumpAndSettle();
    expect(pumpCount, greaterThanOrEqualTo(0));
    expect(tapped, isTrue);
  });

  testWidgets('dropdown ignores unavailable selected agent', (tester) async {
    await _pumpSubject(
      tester,
      agents: [_makeAgent('agent-1', 'Disabled Agent', isEnabled: false)],
      onChanged: (_) {
        final _ = Object();
      },
      agentId: 'agent-1',
    );

    expect(find.byType(AuraDropdownSelector<String>), findsOneWidget);
    expect(find.text('Disabled Agent'), findsNothing);
  });

  testWidgets('compact mode falls back for unavailable selected agent', (
    tester,
  ) async {
    await _pumpSubject(
      tester,
      agents: [_makeAgent('agent-1', 'Disabled Agent', isEnabled: false)],
      onChanged: (_) {
        final _ = Object();
      },
      agentId: 'agent-1',
      compactMode: true,
    );

    expect(find.text('Disabled Agent'), findsNothing);
  });
}

Future<void> _pumpSubject(
  WidgetTester tester, {
  required List<AgentEntity> agents,
  required ValueChanged<String?> onChanged,
  Stream<List<AgentEntity>>? agentStream,
  String? agentId,
  bool compactMode = false,
  bool sheetMode = false,
  VoidCallback? onCompactTap,
}) async {
  final _ = await tester.runAsync(() async {
    await tester.pumpWidget(
      TestableApp(
        child: AuraThemeScope(
          theme: .light,
          child: Theme(
            data: .new(),
            child: Scaffold(
              body: Portal(
                child: CompactAgentSelector(
                  workspaceId: 'ws-1',
                  agentId: agentId,
                  onChanged: onChanged,
                  onCompactTap: onCompactTap,
                  compactMode: compactMode,
                  sheetMode: sheetMode,
                ),
              ),
            ),
          ),
        ),
        overrides: [
          agentsProvider('ws-1')
              .overrideWith((ref) => agentStream ?? Stream.value(agents)),
        ],
      ),
    );
  });
  final pumpCount = await tester.pumpAndSettle();
  expect(pumpCount, greaterThanOrEqualTo(0));
}

AgentEntity _makeAgent(
  String id,
  String name, {
  AgentVisibility visibility = .both,
  bool isEnabled = true,
}) {
  return AgentEntity(
    id: id,
    workspaceId: 'ws-1',
    name: name,
    content: 'content',
    skills: const [],
    createdAt: .new(2026),
    updatedAt: .new(2026),
    isEnabled: isEnabled,
    visibility: visibility,
  );
}
