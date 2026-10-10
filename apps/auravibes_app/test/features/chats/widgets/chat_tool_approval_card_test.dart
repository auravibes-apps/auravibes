// Required: Widget tests override scoped providers directly.
// Required: Tests repeat finders and fixture lookups for clarity.

import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/chats/providers/aura_agent_service_provider.dart';
import 'package:auravibes_app/features/chats/providers/batch_tool_approval_provider.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/usecases/batch_tool_approval_usecase.dart';
import 'package:auravibes_app/features/chats/widgets/chat_tool_approval_card.dart';
import 'package:auravibes_app/features/skills/models/workspace_skill.dart';
import 'package:auravibes_app/features/skills/providers/skill_template_tools_provider.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _FakeBatchToolApprovalActions implements BatchToolApprovalActions {
  final approveCompleter = Completer<BatchToolApprovalResult>();
  final skipCompleter = Completer<BatchToolApprovalResult>();
  List<PendingToolCall>? approvedCalls;
  List<PendingToolCall>? skippedCalls;

  @override
  Future<BatchToolApprovalResult> approveOnce({
    required String rootConversationId,
    required String workspaceId,
    required List<PendingToolCall> pendingCalls,
  }) {
    approvedCalls = pendingCalls;

    return approveCompleter.future;
  }

  @override
  Future<BatchToolApprovalResult> skip({
    required String rootConversationId,
    required String workspaceId,
    required List<PendingToolCall> pendingCalls,
  }) {
    skippedCalls = pendingCalls;

    return skipCompleter.future;
  }
}

void main() {
  Widget buildSubject({required List<Object> overrides}) {
    return EasyLocalization(
      child: ProviderScope(
        overrides: overrides.cast(),
        child: Builder(
          builder: (context) {
            return MaterialApp(
              home: AuraThemeScope(
                theme: .light,
                child: Theme(
                  data: .new(),
                  child: const Material(
                    child: ChatToolApprovalCard(
                      workspaceId: 'ws-1',
                      conversationId: 'conv-1',
                    ),
                  ),
                ),
              ),
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
            );
          },
        ),
      ),
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      useOnlyLangCode: true,
      useFallbackTranslations: true,
    );
  }

  PendingToolCall _createPendingToolCall({
    String toolCallId = 'tc-1',
    String messageId = 'msg-1',
    String toolName = 'built_in_1_read_file',
    String argumentsRaw = '{"input": "test.txt"}',
    String? userFacingDescription,
    String? argumentsDigest,
    String? turnId,
    int? turnRevision,
    String sourceConversationId = '',
  }) {
    return PendingToolCall(
      toolCall: .new(
        id: toolCallId,
        name: toolName,
        argumentsRaw: argumentsRaw,
        userFacingDescription: userFacingDescription,
        argumentsDigest: argumentsDigest,
        turnId: turnId,
        turnRevision: turnRevision,
      ),
      messageId: messageId,
      sourceConversationId: sourceConversationId,
    );
  }

  List<Object> _skillTitleOverrides() => [
    workspaceSkillsProvider('ws-1').overrideWith(
      (ref) async => const [
        WorkspaceSkill(
          id: 'skill-1',
          slug: 'research',
          title: 'Research Assistant',
          description: '',
          source: .user,
          kind: .template,
          isEnabled: true,
        ),
      ],
    ),
    skillTemplateToolsProvider('ws-1', 'skill-1').overrideWith(
      (ref) async => [
        SkillTemplateToolEntity(
          id: 'tool-1',
          skillId: 'skill-1',
          templateType: .url,
          title: 'Search the web',
          description: 'Searches the web.',
          slug: 'search_web',
          isEnabled: true,
          requiresCredential: false,
          createdAt: .new(2026),
          updatedAt: .new(2026),
        ),
      ],
    ),
  ];

  Future<void> pumpAndInit(WidgetTester tester, Widget widget) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
    });
    await tester.pump();
    await tester.pump();
  }

  group('ChatToolApprovalCard', () {
    testWidgets('renders SizedBox.shrink when no pending calls', (
      tester,
    ) async {
      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith(
              (ref, _) => <PendingToolCall>[],
            ),
          ],
        ),
      );

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      expect(
        sizedBoxes.any((box) => box.width == 0 && box.height == 0),
        isTrue,
      );
    });

    testWidgets('renders approval card and actions for one pending call', (
      tester,
    ) async {
      final pendingCalls = [_createPendingToolCall()];
      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith((ref, _) => pendingCalls),
          ],
        ),
      );

      expect(find.byIcon(Icons.build_outlined), findsOneWidget);
      for (final selector in [
        'tool_approval_allow_once',
        'tool_approval_allow_conversation',
        'tool_approval_skip',
        'tool_approval_stop_all',
      ]) {
        expect(find.byKey(ValueKey<String>(selector)), findsOneWidget);
      }
      expect(
        find.byKey(const ValueKey<String>('tool_approval_allow_all')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('tool_approval_deny_all')),
        findsNothing,
      );
      expect(find.text('Read File'), findsOneWidget);
      expect(find.text('Review the arguments for Read File'), findsOneWidget);
      expect(find.text('Allow Once'), findsOneWidget);
      expect(find.text('Allow for Conversation'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Stop All'), findsOneWidget);
    });

    testWidgets('allow all closes immediately and submits one batch', (
      tester,
    ) async {
      final actions = _FakeBatchToolApprovalActions();
      final pendingCalls = [
        _createPendingToolCall(),
        _createPendingToolCall(toolCallId: 'tc-2'),
      ];
      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            batchToolApprovalUsecaseProvider.overrideWithValue(actions),
            pendingToolCallsProvider.overrideWith((ref, _) => pendingCalls),
          ],
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('tool_approval_allow_all')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('tool_approval_deny_all')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('tool_approval_allow_all')),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('tool_approval_allow_all')),
        findsNothing,
      );
      final approvedCalls = actions.approvedCalls;
      expect(approvedCalls, hasLength(2));
      if (approvedCalls case final calls?) {
        expect(
          calls.map((call) => call.toolCall.id),
          containsAll(<String>['tc-1', 'tc-2']),
        );
      }

      actions.approveCompleter.complete(
        const BatchToolApprovalResult(
          claimed: [],
          alreadyHandled: [],
          conflicted: [],
        ),
      );
      await tester.pump();
    });

    testWidgets('deny all closes immediately and submits one batch', (
      tester,
    ) async {
      final actions = _FakeBatchToolApprovalActions();
      final pendingCalls = [
        _createPendingToolCall(),
        _createPendingToolCall(toolCallId: 'tc-2'),
      ];
      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            batchToolApprovalUsecaseProvider.overrideWithValue(actions),
            pendingToolCallsProvider.overrideWith((ref, _) => pendingCalls),
          ],
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('tool_approval_deny_all')),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('tool_approval_deny_all')),
        findsNothing,
      );
      expect(actions.skippedCalls, hasLength(2));

      actions.skipCompleter.complete(
        const BatchToolApprovalResult(
          claimed: [],
          alreadyHandled: [],
          conflicted: [],
        ),
      );
      await tester.pump();
    });

    testWidgets('approves a child conversation tool call in its source', (
      tester,
    ) async {
      final approvalProvider = _MockApproveToolCallProvider();
      final agentService = _MockAuraAgentService();
      final cancellationEffects = _MockAgentCancellationEffects();
      when(() => cancellationEffects.start('child-1'))
          .thenReturn(agent.AgentCancellationScope());
      when(
        () => approvalProvider.loadToolCall(
          messageId: 'child-message-1',
          toolCallId: 'child-tool-1',
          conversationId: 'child-1',
        ),
      ).thenAnswer((_) async => null);
      when(() => agentService.tools).thenReturn(
        agent.ToolsNamespace<ResolvedTool>(
          approvals: approvalProvider,
          skips: _MockSkipToolCallProvider(),
          stopPending: _MockStopPendingToolCallsProvider(),
          resume: _MockAgentToolResumeProvider(),
          cancellationEffects: cancellationEffects,
        ),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith(
              (ref, _) => [
                _createPendingToolCall(
                  toolCallId: 'child-tool-1',
                  messageId: 'child-message-1',
                  sourceConversationId: 'child-1',
                ),
              ],
            ),
            auraAgentServiceProvider.overrideWithValue(agentService),
          ],
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('tool_approval_allow_once')),
      );
      final _ = await tester.pumpAndSettle();

      verify(
        () => approvalProvider.loadToolCall(
          messageId: 'child-message-1',
          toolCallId: 'child-tool-1',
          conversationId: 'child-1',
        ),
      ).called(1);
    });

    for (final source in ['conv-1', 'child-1']) {
      for (final action in [
        'allow_once',
        'allow_conversation',
        'skip',
        'stop_all',
      ]) {
        testWidgets('decision $action resolves exact source $source', (
          tester,
        ) async {
          final effects = _DecisionEffects();
          final runtime = _MockAuraAgentService();
          final cancellation = _MockAgentCancellationEffects();
          when(() => cancellation.start(source))
              .thenReturn(agent.AgentCancellationScope());
          when(() => runtime.tools).thenReturn(
            agent.ToolsNamespace<ResolvedTool>(
              approvals: effects,
              skips: effects,
              stopPending: effects,
              resume: _MockAgentToolResumeProvider(),
              cancellationEffects: cancellation,
            ),
          );
          await pumpAndInit(
            tester,
            buildSubject(
              overrides: [
                pendingToolCallsProvider.overrideWith(
                  (ref, _) => [
                    _createPendingToolCall(sourceConversationId: source),
                  ],
                ),
                auraAgentServiceProvider.overrideWithValue(runtime),
              ],
            ),
          );
          await tester.tap(
            find.byKey(ValueKey<String>('tool_approval_$action')),
          );
          final _ = await tester.pumpAndSettle();
          expect(effects.sources, everyElement(source));
          expect(effects.sources, isNotEmpty);
          expect(
            effects.grants,
            action == 'allow_conversation' ? [source] : isEmpty,
          );
          if (action.startsWith('allow')) {
            expect(effects.executions, 1);
            expect(
              effects.result?.resultStatus,
              agent.AgentToolResultStatus.success,
            );
            expect(effects.result?.messageId, 'msg-1');
            expect(effects.result?.toolCallId, 'tc-1');
            expect(effects.result?.conversationId, source);
            expect(effects.resumeCount, 1);
          } else {
            expect(effects.executions, 0);
            expect(effects.skipCount, action == 'skip' ? 1 : 0);
            expect(effects.stopCount, action == 'stop_all' ? 1 : 0);
            expect(effects.resumeCount, action == 'skip' ? 1 : 0);
          }
          expect(
            find.byKey(const ValueKey<String>('tool_approval_allow_once')),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('does not trust the model action description in an approval', (
      tester,
    ) async {
      final pendingCalls = [
        _createPendingToolCall(
          userFacingDescription: 'I will search for the requested item.',
          argumentsRaw: '{"arg1":"search","arg2":"item"}',
        ),
      ];
      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith((ref, _) => pendingCalls),
          ],
        ),
      );

      expect(find.text('I will search for the requested item.'), findsNothing);
      expect(find.text('Review the arguments for Read File'), findsOneWidget);
      expect(find.textContaining('arg1: search'), findsOneWidget);
      expect(find.textContaining('arg2: item'), findsOneWidget);

      final argumentColumn = tester.widget<Column>(
        find
            .ancestor(
              of: find.textContaining('arg1: search'),
              matching: find.byType(Column),
            )
            .first,
      );
      expect(argumentColumn.crossAxisAlignment, CrossAxisAlignment.start);
    });

    testWidgets('shows complete argument values', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith(
              (ref, _) => [
                _createPendingToolCall(
                  argumentsRaw: jsonEncode({'query': 'x' * 500}),
                ),
              ],
            ),
          ],
        ),
      );

      final argument = tester.widget<Text>(find.textContaining('query:'));
      expect(argument.maxLines, isNull);
      expect(argument.overflow, TextOverflow.clip);
    });

    testWidgets('never shows a model batch description while paging calls', (
      tester,
    ) async {
      const description = 'I will search and then open the result.';
      final pendingCalls = [
        _createPendingToolCall(userFacingDescription: description),
        _createPendingToolCall(
          toolCallId: 'tc-2',
          userFacingDescription: description,
        ),
      ];
      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith((ref, _) => pendingCalls),
          ],
        ),
      );

      expect(find.text(description), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey<String>('tool_approval_next')),
      );
      await tester.pump();
      expect(find.text(description), findsNothing);
    });

    testWidgets('shows effective skill target for local approval', (
      tester,
    ) async {
      final pendingCalls = [
        _createPendingToolCall(
          toolName: 'call_skill_tool',
          argumentsRaw:
              '{"skill":"research","tool":"search_web","args":'
              '{"api_key":"secret-key","query":"visible"}}',
        ),
      ];
      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith((ref, _) => pendingCalls),
            ..._skillTitleOverrides(),
          ],
        ),
      );

      expect(find.text('Research Assistant / Search the web'), findsOneWidget);
      expect(find.text('Call Skill Tool'), findsNothing);
      expect(find.textContaining('secret-key'), findsNothing);
      expect(find.textContaining('****'), findsOneWidget);
    });

    testWidgets('shows effective skill target for cloud approval', (
      tester,
    ) async {
      final pendingCalls = [
        _createPendingToolCall(
          toolName: 'call_skill_tool',
          argumentsRaw:
              '{"skill":"research","tool":"search_web","args":'
              '{"credential":"secret-value"}}',
          argumentsDigest: 'digest-1',
          turnId: 'turn-1',
          turnRevision: 2,
        ),
      ];
      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith((ref, _) => pendingCalls),
            ..._skillTitleOverrides(),
          ],
        ),
      );

      expect(find.text('Research Assistant / Search the web'), findsOneWidget);
      expect(find.text('Call Skill Tool'), findsNothing);
      expect(find.textContaining('secret-value'), findsNothing);
      expect(find.textContaining('****'), findsOneWidget);
    });

    testWidgets('keeps wrapper title for malformed skill target', (
      tester,
    ) async {
      final pendingCalls = [
        _createPendingToolCall(
          toolName: 'call_skill_tool',
          argumentsRaw: '{"skill":"DuckDuckGo"}',
        ),
      ];
      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith((ref, _) => pendingCalls),
          ],
        ),
      );

      expect(find.text('Call Skill Tool'), findsOneWidget);
      expect(find.text('Duck Duck Go: Search'), findsNothing);
    });

    testWidgets('shows decoded arguments when available', (tester) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'built_in_1_search',
        argumentsRaw: '{"query": "test query"}',
      );
      final pendingCalls = [
        const PendingToolCall(toolCall: toolCall, messageId: 'msg-1'),
      ];
      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith((ref, _) => pendingCalls),
          ],
        ),
      );

      expect(find.textContaining('query'), findsOneWidget);
    });

    testWidgets('copies all arguments as stable JSON', (tester) async {
      String? copiedContent;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedContent = (call.arguments as Map)['text'] as String?;
          }

          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final pendingCalls = [
        _createPendingToolCall(
          argumentsRaw: '{"query":"test query","limit":10}',
        ),
      ];

      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith((ref, _) => pendingCalls),
          ],
        ),
      );

      await tester.tap(find.byIcon(Icons.copy_outlined));
      await tester.pump();

      expect(
        copiedContent,
        '{\n'
        '  "query": "test query",\n'
        '  "limit": 10\n'
        '}',
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('flattens and exposes all arguments by default', (
      tester,
    ) async {
      final pendingCalls = [
        _createPendingToolCall(
          argumentsRaw: jsonEncode({
            'arg1': 'search',
            'arg2': 'item',
            'arg3': {
              'something': 'my search',
              'items': ['first', 'second'],
            },
            'arg4': 'last',
          }),
        ),
      ];

      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith((ref, _) => pendingCalls),
          ],
        ),
      );

      expect(find.textContaining('arg1: search'), findsOneWidget);
      expect(find.textContaining('arg3.something: my search'), findsOneWidget);
      expect(find.textContaining('arg4: last'), findsOneWidget);
      expect(find.textContaining('arg3.items[0]: first'), findsOneWidget);
      expect(find.text('Show more'), findsNothing);
    });

    testWidgets('flattens nested URL input', (tester) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'native_1_url',
        argumentsRaw:
            r'{"input":"{\"url\":\"https://example.com/api/items\",'
            r'\"method\":\"post\",'
            r'\"headers\":{\"Authorization\":\"Bearer secret-token\"}}"}',
      );
      final pendingCalls = [
        const PendingToolCall(toolCall: toolCall, messageId: 'msg-1'),
      ];

      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith((ref, _) => pendingCalls),
          ],
        ),
      );

      expect(find.textContaining('input.method: post'), findsOneWidget);
      expect(
        find.textContaining('input.url: https://example.com/api/items'),
        findsOneWidget,
      );
      expect(
        find.textContaining('input.headers.Authorization: ****'),
        findsOneWidget,
      );
      expect(find.textContaining('secret-token'), findsNothing);
    });

    testWidgets('redacts broad sensitive argument keys', (tester) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'skill__user__github__create_issue',
        argumentsRaw:
            '{"auth_header":"Bearer secret-token", '
            '"private_key":"secret-key", '
            '"query":"visible"}',
      );
      final pendingCalls = [
        const PendingToolCall(toolCall: toolCall, messageId: 'msg-1'),
      ];

      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith((ref, _) => pendingCalls),
          ],
        ),
      );

      expect(find.textContaining('secret-token'), findsNothing);
      expect(find.textContaining('secret-key'), findsNothing);
      expect(find.textContaining('****'), findsNWidgets(2));
      expect(find.textContaining('visible'), findsOneWidget);
    });

    testWidgets('renders SizedBox.shrink when async has error', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith(
              (ref, _) => throw Exception('fail'),
            ),
          ],
        ),
      );

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      expect(
        sizedBoxes.any((box) => box.width == 0 && box.height == 0),
        isTrue,
      );
    });

    testWidgets('shows count and navigates between pending calls', (
      tester,
    ) async {
      final pendingCalls = [
        _createPendingToolCall(),
        _createPendingToolCall(
          toolCallId: 'tc-2',
          toolName: 'built_in_1_search',
        ),
      ];
      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith((ref, _) => pendingCalls),
          ],
        ),
      );

      expect(find.text('Read File'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('tool_approval_previous')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('tool_approval_next')),
        findsOneWidget,
      );
      expect(find.textContaining('1'), findsOneWidget);
      expect(find.textContaining('2'), findsOneWidget);
      final countText = tester.widget<Text>(find.textContaining('1'));
      expect(
        countText.style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );

      await tester.tap(find.byIcon(Icons.chevron_right));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Search'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Read File'), findsOneWidget);
    });
  });
}

class _MockAuraAgentService extends Mock
    implements agent.AuraAgentService<ResolvedTool>;

class _MockApproveToolCallProvider extends Mock
    implements agent.ApproveToolCallProvider<ResolvedTool>;

class _MockSkipToolCallProvider extends Mock
    implements agent.SkipToolCallProvider;

class _MockStopPendingToolCallsProvider extends Mock
    implements agent.StopPendingToolCallsProvider;

class _MockAgentToolResumeProvider extends Mock
    implements agent.AgentToolResumeProvider;

class _MockAgentCancellationEffects extends Mock
    implements agent.AgentCancellationEffects;

class _DecisionEffects
    implements
        agent.ApproveToolCallProvider<ResolvedTool>,
        agent.SkipToolCallProvider,
        agent.StopPendingToolCallsProvider {
  final sources = <String>[];
  final grants = <String>[];
  int executions = 0;
  int resumeCount = 0;
  int skipCount = 0;
  int stopCount = 0;
  agent.AgentToolCallResultUpdateRequest? result;

  @override
  Future<agent.AgentApprovableToolCall?> loadToolCall({
    required String messageId,
    required String toolCallId,
    required String conversationId,
  }) async {
    sources.add(conversationId);

    return agent.AgentApprovableToolCall(
      conversationId: conversationId,
      name: 'built_in_1_read_file',
      argumentsRaw: '{"input": "test.txt"}',
    );
  }

  @override
  Future<ResolvedTool?> resolveTool({
    required String conversationId,
    required String toolName,
    required String argumentsRaw,
  }) async {
    sources.add(conversationId);

    return ResolvedTool.skillControl(toolIdentifier: 'fixture');
  }

  @override
  Future<void> grantToolForConversation({
    required String conversationId,
    required ResolvedTool tool,
  }) async {
    grants.add(conversationId);
  }

  @override
  Future<Object?> runResolvedTool({
    required String conversationId,
    required String toolCallId,
    required ResolvedTool tool,
    required Map<String, dynamic> arguments,
  }) async {
    sources.add(conversationId);
    executions++;
    expect(arguments, {'input': 'test.txt'});

    return {'fixtureResult': 'Complete'};
  }

  @override
  Future<void> markToolCallRunning({
    required String messageId,
    required String toolCallId,
    required String conversationId,
  }) async {
    sources.add(conversationId);
  }

  @override
  Future<void> updateToolCallResult(
    agent.AgentToolCallResultUpdateRequest request,
  ) async {
    result = request;
  }

  @override
  Future<void> resumeConversationIfReady({
    required String messageId,
    required String conversationId,
  }) async {
    sources.add(conversationId);
    resumeCount++;
  }

  @override
  bool isCancellationRequested(String conversationId) => false;
  @override
  void logToolExecutionError(
    agent.AgentToolExecutionErrorRequest<ResolvedTool> request,
  ) {
    throw StateError('Unexpected fixture execution error');
  }

  @override
  Future<bool> skipToolCall({
    required String messageId,
    required String toolCallId,
    required String conversationId,
  }) async {
    sources.add(conversationId);
    skipCount++;

    return true;
  }

  @override
  Future<void> stopPendingToolCalls({
    required String messageId,
    required String conversationId,
  }) async {
    sources.add(conversationId);
    stopCount++;
  }
}
