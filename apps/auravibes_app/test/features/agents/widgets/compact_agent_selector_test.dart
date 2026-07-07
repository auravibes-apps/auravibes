import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/features/agents/usecases/list_agents_usecase.dart';
import 'package:auravibes_app/features/agents/widgets/compact_agent_selector.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
    expect(find.text('Research Agent'), findsOneWidget);
  });
}

Future<void> _pumpSubject(
  WidgetTester tester, {
  required List<AgentEntity> agents,
  required ValueChanged<String?> onChanged,
  String? agentId,
  bool compactMode = false,
  bool sheetMode = false,
}) async {
  final _ = await tester.runAsync(() async {
    await tester.pumpWidget(
      TestableApp(
        child: Theme(
          data: ThemeData(extensions: [AuraTheme.light]),
          child: Scaffold(
            body: CompactAgentSelector(
              workspaceId: 'ws-1',
              agentId: agentId,
              onChanged: onChanged,
              compactMode: compactMode,
              sheetMode: sheetMode,
            ),
          ),
        ),
        overrides: [
          agentsProvider('ws-1').overrideWith((ref) => Stream.value(agents)),
        ],
      ),
    );
  });
  final pumpCount = await tester.pumpAndSettle();
  expect(pumpCount, greaterThanOrEqualTo(0));
}

AgentEntity _makeAgent(String id, String name) {
  return AgentEntity(
    id: id,
    workspaceId: 'ws-1',
    name: name,
    content: 'content',
    skills: const [],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}
