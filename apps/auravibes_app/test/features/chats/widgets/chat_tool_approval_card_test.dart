// Required: Widget tests override scoped providers directly.
// Required: Tests repeat finders and fixture lookups for clarity.

import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/providers/aura_agent_service_provider.dart';
import 'package:auravibes_app/features/chats/providers/batch_tool_approval_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_agent_language_runtime.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/usecases/batch_tool_approval_usecase.dart';
import 'package:auravibes_app/features/chats/widgets/chat_tool_approval_card.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    as sdk_localizations;
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
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  Widget buildSubject({
    required List<Object> overrides,
    Locale startLocale = const Locale('en'),
    Widget? child,
  }) {
    return EasyLocalization(
      child: ProviderScope(
        overrides: overrides.cast(),
        child: Builder(
          builder: (context) {
            return MaterialApp(
              home: AuraThemeScope(
                theme: .light,
                child: Theme(
                  data: .new(fontFamily: 'Inter'),
                  child: Material(
                    child:
                        child ??
                        const ChatToolApprovalCard(
                          workspaceId: 'ws-1',
                          conversationId: 'conv-1',
                        ),
                  ),
                ),
              ),
              locale: context.locale,
              localizationsDelegates: [
                ...GlobalMaterialLocalizations.delegates,
                sdk_localizations.GlobalMaterialLocalizations.delegate,
                ...context.localizationDelegates,
              ],
              supportedLocales: context.supportedLocales,
            );
          },
        ),
      ),
      supportedLocales: const [Locale('en'), Locale('es')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: startLocale,
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

  Future<void> pumpAndInit(WidgetTester tester, Widget widget) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
    });
    await tester.pump();
    await tester.pump();
  }

  group('ChatToolApprovalCard', () {
    testWidgets('renders the recovered pending-approval load error', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(640, 240));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith(
              (ref, _) async => throw StateError('pending read failed'),
            ),
          ],
          child: const Center(
            child: SizedBox(
              key: ValueKey<String>('tool_approval_capture'),
              width: 480,
              height: 160,
              child: ColoredBox(
                color: .new(0xFFFFFFFF),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: ChatToolApprovalCard(
                    workspaceId: 'ws-1',
                    conversationId: 'conv-1',
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final _ = await tester.pumpAndSettle();
      final capture = find.byKey(
        const ValueKey<String>('tool_approval_capture'),
      );
      expect(
        find.descendant(
          of: capture,
          matching: find.text('Could not load pending tool approvals.'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: capture, matching: find.text('Retry')),
        findsOneWidget,
      );

      await expectLater(
        capture,
        matchesGoldenFile('goldens/chat_tool_approval_load_error.png'),
      );
    }, tags: ['golden']);

    testWidgets(
      'shows localized accessible retry UI after initial load failure',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await pumpAndInit(
            tester,
            buildSubject(
              startLocale: const Locale('es'),
              overrides: [
                pendingToolCallsProvider.overrideWith(
                  (ref, _) async => throw StateError('pending read failed'),
                ),
              ],
            ),
          );

          final errorMessage = find.text(
            'No se pudieron cargar las aprobaciones de '
            'herramientas pendientes.',
          );
          expect(errorMessage, findsOneWidget);
          expect(
            tester
                .getSemantics(errorMessage)
                .getSemanticsData()
                .flagsCollection
                .isLiveRegion,
            isTrue,
          );

          final retry = find.text('Reintentar');
          expect(retry, findsOneWidget);
          expect(
            tester.getSemantics(retry).getSemanticsData().hasAction(.tap),
            isTrue,
          );
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets('retry reloads pending calls without making a decision', (
      tester,
    ) async {
      final pendingCalls = [_createPendingToolCall()];
      final effects = _DecisionEffects();
      final runtime = _MockAuraAgentService();
      when(() => runtime.tools).thenReturn(
        agent.ToolsNamespace<ResolvedTool>(
          approvals: effects,
          skips: effects,
          stopPending: effects,
          resume: _MockAgentToolResumeProvider(),
          cancellationEffects: _MockAgentCancellationEffects(),
        ),
      );
      var providerReads = 0;

      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            auraAgentServiceProvider.overrideWithValue(runtime),
            pendingToolCallsProvider.overrideWith((ref, _) async {
              providerReads++;
              if (providerReads == 1) throw StateError('first read failed');

              return pendingCalls;
            }),
          ],
        ),
      );

      expect(providerReads, 1);
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      final _ = await tester.pumpAndSettle();

      expect(providerReads, 2);
      expect(find.text('Read File'), findsOneWidget);
      expect(effects.sources, isEmpty);
      expect(effects.grants, isEmpty);
      expect(effects.executions, 0);
      expect(effects.skipCount, 0);
      expect(effects.stopCount, 0);
      expect(effects.resumeCount, 0);
    });

    testWidgets('shows loading while pending calls are unresolved', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final pendingCalls = Completer<List<PendingToolCall>>();
      try {
        await pumpAndInit(
          tester,
          buildSubject(
            overrides: [
              pendingToolCallsProvider.overrideWith(
                (ref, _) => pendingCalls.future,
              ),
            ],
          ),
        );

        final loading = find.text('Loading pending tool approvals\u2026');
        expect(loading, findsOneWidget);
        expect(
          tester
              .getSemantics(loading)
              .getSemanticsData()
              .flagsCollection
              .isLiveRegion,
          isTrue,
        );

        pendingCalls.complete(const <PendingToolCall>[]);
        final _ = await tester.pumpAndSettle();
      } finally {
        semantics.dispose();
      }
    });

    testWidgets(
      'keeps prior calls visible with a loading status during refresh',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final pendingCalls = [_createPendingToolCall()];
        final refresh = Completer<List<PendingToolCall>>();
        var providerReads = 0;
        try {
          await pumpAndInit(
            tester,
            buildSubject(
              overrides: [
                pendingToolCallsProvider.overrideWith((ref, _) {
                  providerReads++;

                  return providerReads == 1
                      ? Future.value(pendingCalls)
                      : refresh.future;
                }),
              ],
            ),
          );

          expect(find.text('Read File'), findsOneWidget);
          ProviderScope.containerOf(
            tester.element(find.byType(ChatToolApprovalCard)),
            listen: false,
          )..invalidate(pendingToolCallsProvider('ws-1', 'conv-1'));
          for (var frame = 0; frame < 2; frame++) {
            final _ = await tester.pump();
          }

          final refreshing = find.text(
            'Refreshing pending tool approvals\u2026',
          );
          expect(providerReads, 2);
          expect(find.text('Read File'), findsOneWidget);
          expect(refreshing, findsOneWidget);
          expect(
            tester
                .getSemantics(refreshing)
                .getSemanticsData()
                .flagsCollection
                .isLiveRegion,
            isTrue,
          );

          refresh.complete(pendingCalls);
          final _ = await tester.pumpAndSettle();
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets(
      'keeps prior calls visible and marks them stale after refresh failure',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final pendingCalls = [_createPendingToolCall()];
        var providerReads = 0;

        try {
          await pumpAndInit(
            tester,
            buildSubject(
              overrides: [
                pendingToolCallsProvider.overrideWith((ref, _) {
                  providerReads++;
                  if (providerReads == 1) return Future.value(pendingCalls);

                  return Future.error(StateError('refresh failed'));
                }),
              ],
            ),
          );

          ProviderScope.containerOf(
            tester.element(find.byType(ChatToolApprovalCard)),
            listen: false,
          )..invalidate(pendingToolCallsProvider('ws-1', 'conv-1'));
          final _ = await tester.pumpAndSettle();

          final staleMessage = find.text(
            'Pending tool approvals are out of date. Could not refresh.',
          );
          expect(providerReads, 2);
          expect(find.text('Read File'), findsOneWidget);
          expect(staleMessage, findsOneWidget);
          expect(
            tester
                .getSemantics(staleMessage)
                .getSemanticsData()
                .flagsCollection
                .isLiveRegion,
            isTrue,
          );
          expect(find.text('Retry'), findsOneWidget);
        } finally {
          semantics.dispose();
        }
      },
    );

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

    testWidgets(
      'batch approval remembers locale for each source conversation',
      (tester) async {
        final actions = _FakeBatchToolApprovalActions();
        final languageRuntime = ConversationAgentLanguageRuntime();
        final pendingCalls = [
          _createPendingToolCall(),
          _createPendingToolCall(
            toolCallId: 'child-call',
            messageId: 'child-message',
            sourceConversationId: 'child',
          ),
        ];
        await pumpAndInit(
          tester,
          buildSubject(
            startLocale: const Locale('es'),
            overrides: [
              batchToolApprovalUsecaseProvider.overrideWithValue(actions),
              conversationAgentLanguageRuntimeProvider.overrideWithValue(
                languageRuntime,
              ),
              pendingToolCallsProvider.overrideWith((ref, _) => pendingCalls),
            ],
          ),
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('tool_approval_allow_all')),
        );
        await tester.pump();

        expect(languageRuntime.languageCodeFor('conv-1'), 'es');
        expect(languageRuntime.languageCodeFor('child'), 'es');

        actions.approveCompleter.complete(
          const BatchToolApprovalResult(
            claimed: [],
            alreadyHandled: [],
            conflicted: [],
          ),
        );
        await tester.pump();
      },
    );

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

    testWidgets('shows normalized user-facing tool descriptions in approvals', (
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

      expect(
        find.text('I will search for the requested item.'),
        findsOneWidget,
      );
      expect(find.text('Review the arguments for Read File'), findsNothing);
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

    testWidgets('shows the current call description while paging approvals', (
      tester,
    ) async {
      const firstDescription = 'I will search and then open the result.';
      const secondDescription = 'I will save the selected result.';
      final pendingCalls = [
        _createPendingToolCall(userFacingDescription: firstDescription),
        _createPendingToolCall(
          toolCallId: 'tc-2',
          userFacingDescription: secondDescription,
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

      expect(find.text(firstDescription), findsOneWidget);
      expect(find.text(secondDescription), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey<String>('tool_approval_next')),
      );
      await tester.pump();
      expect(find.text(secondDescription), findsOneWidget);
      expect(find.text(firstDescription), findsNothing);
    });

    testWidgets('shows the common Connector command and masks secret input', (
      tester,
    ) async {
      final pendingCalls = [
        _createPendingToolCall(
          toolName: agent.executeConnectorToolName,
          argumentsRaw:
              '{"toolId":"connector/brave/web_search",'
              '"args":{"api_key":"secret-key","query":"visible"}}',
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

      expect(find.text('Execute Connector Tool'), findsOneWidget);
      expect(find.textContaining('secret-key'), findsNothing);
      expect(find.textContaining('****'), findsOneWidget);
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

    testWidgets('shows an error and retry when initial async load fails', (
      tester,
    ) async {
      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith(
              (ref, _) async => throw Exception('fail'),
            ),
          ],
        ),
      );

      expect(
        find.text('Could not load pending tool approvals.'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
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
