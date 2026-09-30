// ignore_for_file: type=lint, type=warning
// Required: Widget tests override scoped providers directly.
// Required: Tests repeat finders and fixture lookups for clarity.

import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Offset, PointerDeviceKind;

import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/models/chat_skill_suggestion_action.dart';
import 'package:auravibes_app/features/chats/notifiers/chat_a2ui_runtime.dart';
import 'package:auravibes_app/features/chats/providers/chat_a2ui_runtime_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/chats/widgets/chat_a2ui_surface_host.dart';
import 'package:auravibes_app/features/chats/widgets/chat_messages_widget.dart';
import 'package:auravibes_app/features/chats/widgets/chat_thinking_indicator.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/models/conversation_skill_action.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_provider.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_state.dart';
import 'package:auravibes_app/features/skills/models/workspace_skill.dart';
import 'package:auravibes_app/features/skills/providers/skill_template_tools_provider.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/skills/usecases/apply_conversation_skill_action_usecase.dart';
import 'package:auravibes_app/features/skills/widgets/conversation_skill_selector_modal.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/utils/relative_time_formatter.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show
        A2uiChatAction,
        AgentToolOutputPolicy,
        AppSkillDefinitionKind,
        ChatMessage,
        defaultToolOutputBytes,
        maxPersistedToolOutputBytes,
        projectToolOutput,
        skillCatalogMetadataKind,
        skillCatalogRevisionMetadataKey;
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    as sdk_localizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart' show DataPath;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

import '../../../helpers/test_provider_scope.dart';

Widget buildSubject({
  required List<String> messages,
  required List<Object> overrides,
  Map<String, MessageEntity>? messageEntitiesById,
  String conversationId = 'conv-1',
  List<PendingToolCall> pendingToolCalls = const [],
  bool showThinking = false,
  Future<void> Function(MessageEntity message)? onRetryMessage,
  ConversationEntity? conversation,
  AuraTheme? theme,
  Locale locale = const Locale('en'),
  Widget Function(BuildContext context, Widget child)? appBuilder,
}) {
  return _ChatMessagesTestSubject(
    conversationId: conversationId,
    messages: messages,
    overrides: overrides,
    pendingToolCalls: pendingToolCalls,
    showThinking: showThinking,
    onRetryMessage: onRetryMessage,
    messageEntitiesById: messageEntitiesById,
    conversation: conversation,
    theme: theme,
    locale: locale,
    appBuilder: appBuilder,
  );
}

Widget _scaffoldedApp(BuildContext context, Widget child) => MaterialApp(
  home: ChatPrimaryScrollController(child: Scaffold(body: child)),
  locale: context.locale,
  localizationsDelegates: context.localizationDelegates,
  supportedLocales: context.supportedLocales,
);

void main() {
  MessageEntity _createMessage({
    String id = 'msg-1',
    String content = 'Hello',
    bool isUser = true,
    MessageStatus status = MessageStatus.sent,
    MessageMetadataEntity? metadata,
    MessageType messageType = MessageType.text,
    List<MessageAttachmentEntity> attachments = const [],
  }) {
    return MessageEntity(
      id: id,
      conversationId: 'conv-1',
      content: content,
      messageType: messageType,
      isUser: isUser,
      status: status,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
      metadata: metadata,
      attachments: attachments,
    );
  }

  List<Object> _messageOverrides(Map<String, MessageEntity> messages) => [
    messageConversationByIdProvider.overrideWith(
      (ref, id) => messages[id.messageId]!,
    ),
    isMessageStreamingProvider.overrideWith((ref, id) => false),
    conversationBusyStateProvider.overrideWith(
      (ref, _) async => const ConversationBusyState(
        isStreaming: false,
        hasPendingTools: false,
      ),
    ),
  ];

  void _mockUrlLauncher(
    WidgetTester tester,
    Future<Object?> Function(MethodCall call) handler,
  ) {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, handler);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  }

  Future<void> pumpAndInit(WidgetTester tester, Widget widget) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
    });
    await tester.pump();
    await tester.pump();
  }

  Future<void> revealActivityToolCalls(
    WidgetTester tester, {
    String runId = 'msg-1',
  }) async {
    final traceToggle = find.byKey(ValueKey('activity_trace_toggle_$runId'));
    if (traceToggle.evaluate().isNotEmpty) {
      await tester.ensureVisible(traceToggle);
      await tester.tap(traceToggle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
    }

    final toolListToggle = find.byKey(
      ValueKey('activity_tool_list_toggle_$runId'),
    );
    if (toolListToggle.evaluate().isNotEmpty) {
      await tester.ensureVisible(toolListToggle);
      await tester.tap(toolListToggle);
      await tester.pump();
    }
  }

  Future<({ChatA2uiRuntime runtime, List<String?> copies})> pumpCopySurface(
    WidgetTester tester,
    List<Map<String, Object?>> components, {
    Map<String, Object?> data = const {},
    bool form = false,
    bool a2uiEnabled = false,
    String content = '',
    List<Object> overrides = const [],
  }) async {
    final runtime = ChatA2uiRuntime(
      conversationId: 'conv-1',
      enabled: a2uiEnabled,
    );
    addTearDown(runtime.dispose);
    final message = _createMessage(
      content: content,
      isUser: false,
      status: form ? MessageStatus.unfinished : MessageStatus.sent,
      metadata: MessageMetadataEntity(
        a2uiMessages: [
          for (final operation in [
            {
              'createSurface': {
                'surfaceId': 'main',
                'catalogId': form
                    ? 'urn:auravibes:a2ui:chat:form:v1'
                    : 'urn:auravibes:a2ui:chat:v1',
              },
            },
            {
              'updateComponents': {
                'surfaceId': 'main',
                'components': components,
              },
            },
            {
              'updateDataModel': {
                'surfaceId': 'main',
                'path': '/',
                'value': data,
              },
            },
          ])
            jsonEncode({
              'protocolVersion': 'v1',
              'interactionMode': form ? 'requiresUserAction' : 'passive',
              'message': {'version': 'v0.9', ...operation},
            }),
        ],
      ),
    );
    final copies = <String?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copies.add((call.arguments as Map)['text'] as String?);
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
    await pumpAndInit(
      tester,
      buildSubject(
        messages: [message.id],
        messageEntitiesById: {message.id: message},
        conversation: ConversationEntity(
          id: 'conv-1',
          title: 'Chat',
          workspaceId: 'ws-1',
          isPinned: false,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
        overrides: [
          chatA2uiRuntimeProvider.overrideWith((ref, id) => runtime),
          messageConversationByIdProvider.overrideWith((ref, id) => message),
          isMessageStreamingProvider.overrideWith((ref, id) => false),
          conversationBusyStateProvider.overrideWith(
            (ref, _) async => const ConversationBusyState(
              isStreaming: false,
              hasPendingTools: false,
            ),
          ),
          ...overrides,
        ],
      ),
    );
    final _ = await tester.pumpAndSettle();
    expect(
      runtime.hasSurfaceIssue(message.id),
      isFalse,
      reason: '${runtime.a2uiIssuesBySurfaceFor(message.id)}',
    );
    expect(tester.takeException(), isNull);
    return (runtime: runtime, copies: copies);
  }

  group('ChatMessagesWidget', () {
    testWidgets('keeps unfinished form fields editable without final actions', (
      tester,
    ) async {
      final result = await pumpCopySurface(tester, [
        {
          'id': 'root',
          'component': 'Column',
          'children': ['name', 'city'],
        },
        {
          'id': 'name',
          'component': 'TextField',
          'label': 'Name',
          'value': {'path': '/name'},
        },
        {
          'id': 'city',
          'component': 'TextField',
          'label': 'City',
          'value': {'path': '/city'},
        },
      ], form: true);
      final fields = find.byType(EditableText);
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.first, 'Ada');
      await tester.enterText(fields.at(1), 'first-city');
      await tester.pump();
      await tester.enterText(fields.first, 'Grace');
      await tester.enterText(fields.at(1), 'second-city');
      await tester.pump();
      expect(find.byTooltip('Copy message'), findsNothing);
      expect(find.byIcon(Icons.call_split_outlined), findsNothing);
      expect(find.byKey(const ValueKey('message_footer_msg-1')), findsNothing);
      expect(
        find.byKey(const ValueKey('a2ui_submit_msg-1:main')),
        findsOneWidget,
      );
      expect(
        result.runtime.copyableTextFor('msg-1'),
        'Name\nGrace\nCity\nsecond-city',
      );
    });

    testWidgets(
      'updates copy eligibility and resolves the model at the press',
      (tester) async {
        final result = await pumpCopySurface(tester, [
          {
            'id': 'root',
            'component': 'Text',
            'text': {'path': '/answer'},
          },
        ]);
        expect(find.byTooltip('Copy message'), findsNothing);
        final model = result.runtime.controller
            .contextFor('msg-1:main')
            .dataModel;
        model.update(DataPath('/answer'), 'First answer');
        await tester.pump();
        expect(find.byTooltip('Copy message'), findsOneWidget);
        final button = tester.widget<AuraIconButton>(
          find.byType(AuraIconButton),
        );

        model.update(DataPath('/answer'), 'Latest answer');
        button.onPressed!();
        await tester.pump();
        expect(result.copies, ['Latest answer']);

        model.update(DataPath('/answer'), '');
        await tester.pump();
        expect(find.byType(AuraIconButton), findsNothing);
      },
    );

    for (final template in [false, true]) {
      for (final selection in [
        null,
        1,
        {'path': '/active'},
      ]) {
        testWidgets(
          'copies the visible ${template ? 'template' : 'static'} tab with activeTab $selection',
          (tester) async {
            final result = await pumpCopySurface(
              tester,
              [
                {
                  'id': 'root',
                  'component': 'Tabs',
                  'activeTab': ?selection,
                  'tabs': template
                      ? {'path': '/tabs', 'componentId': 'tab'}
                      : [
                          {'label': 'Overview', 'content': 'first'},
                          {'label': 'Details', 'content': 'second'},
                        ],
                },
                if (template) ...[
                  {
                    'id': 'tab',
                    'component': 'Tab',
                    'label': {'path': 'title'},
                    'content': 'body',
                  },
                  {
                    'id': 'body',
                    'component': 'Text',
                    'text': {'path': 'body'},
                  },
                ] else ...[
                  {'id': 'first', 'component': 'Text', 'text': 'First panel'},
                  {'id': 'second', 'component': 'Text', 'text': 'Second panel'},
                ],
              ],
              data: {
                'active': 1,
                'tabs': [
                  {'title': 'Overview', 'body': 'First panel'},
                  {'title': 'Details', 'body': 'Second panel'},
                ],
              },
            );
            final initialPanel = selection == null
                ? 'First panel'
                : 'Second panel';
            expect(find.text(initialPanel).hitTestable(), findsOneWidget);
            expect(
              result.runtime.copyableTextFor('msg-1'),
              'Overview\nDetails\n$initialPanel',
            );

            await tester.tap(
              find.text(selection == null ? 'Details' : 'Overview'),
            );
            await tester.pump();
            final selectedPanel =
                selection == null || template && selection == 1
                ? 'Second panel'
                : 'First panel';
            expect(find.text(selectedPanel).hitTestable(), findsOneWidget);
            await tester.tap(find.byTooltip('Copy message'));
            await tester.pump();
            expect(result.copies, ['Overview\nDetails\n$selectedPanel']);

            if (selection is Map) {
              final model = result.runtime.controller
                  .contextFor('msg-1:main')
                  .dataModel;
              final button = tester.widget<AuraIconButton>(
                find.byType(AuraIconButton),
              );
              model.update(DataPath('/active'), 30);
              button.onPressed!();
              await tester.pump();
              expect(find.text('Second panel').hitTestable(), findsOneWidget);
              expect(result.copies.last, 'Overview\nDetails\nSecond panel');
            }
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    testWidgets('renders empty list when no messages', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(
          messages: [],
          overrides: [
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.byType(ChatMessagesWidget), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('jumps to latest message after scrolling away', (tester) async {
      final messages = [
        for (var index = 0; index < 20; index++)
          _createMessage(
            id: 'message-$index',
            content: List.filled(8, 'Message $index').join('\n'),
          ),
      ];
      final messageEntitiesById = {
        for (final message in messages) message.id: message,
      };

      await pumpAndInit(
        tester,
        buildSubject(
          messages: [for (final message in messages) message.id],
          messageEntitiesById: messageEntitiesById,
          appBuilder: _scaffoldedApp,
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => messageEntitiesById[id.messageId],
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      final primaryController = PrimaryScrollController.maybeOf(
        tester.element(find.byType(Scaffold)),
      );
      expect(
        primaryController,
        same(tester.widget<ListView>(find.byType(ListView)).controller),
      );
      expect(scrollable.position.maxScrollExtent, greaterThan(64));
      expect(find.byKey(const ValueKey('chat_jump_to_latest')), findsNothing);

      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pump();

      expect(find.byKey(const ValueKey('chat_jump_to_latest')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('chat_jump_to_latest')));
      await tester.pumpAndSettle();

      expect(
        scrollable.position.pixels,
        closeTo(scrollable.position.minScrollExtent, .5),
      );
      expect(find.byKey(const ValueKey('chat_jump_to_latest')), findsNothing);
    });

    testWidgets('dragging chat history retains composer focus', (tester) async {
      final composerFocus = FocusNode();
      addTearDown(composerFocus.dispose);
      final messages = [
        for (var index = 0; index < 20; index++)
          _createMessage(
            id: 'message-$index',
            content: List.filled(8, 'Message $index').join('\n'),
          ),
      ];
      final entities = {for (final message in messages) message.id: message};
      await pumpAndInit(
        tester,
        buildSubject(
          messages: [for (final message in messages) message.id],
          messageEntitiesById: entities,
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => entities[id.messageId],
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
          appBuilder: (context, child) => MaterialApp(
            home: ChatPrimaryScrollController(
              child: Scaffold(
                body: Column(
                  children: [
                    Expanded(child: child),
                    TextField(
                      key: const ValueKey('chat_composer'),
                      focusNode: composerFocus,
                    ),
                  ],
                ),
              ),
            ),
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
          ),
        ),
      );

      final composer = find.byKey(const ValueKey('chat_composer'));
      await tester.tap(composer);
      await tester.pump();
      expect(composerFocus.hasFocus, isTrue);

      await tester.drag(find.byType(ListView), const Offset(0, -160));
      await tester.pump();

      expect(composerFocus.hasFocus, isTrue);
    });

    for (final status in [MessageStatus.error, MessageStatus.unfinished]) {
      testWidgets('shows retry action for user $status messages', (
        tester,
      ) async {
        final message = _createMessage(id: 'failed-user', status: status);
        final retriedIds = <String>[];

        await pumpAndInit(
          tester,
          buildSubject(
            messages: [message.id],
            messageEntitiesById: {message.id: message},
            onRetryMessage: (message) async => retriedIds.add(message.id),
            overrides: [
              messageConversationByIdProvider.overrideWith(
                (ref, id) => message,
              ),
              isMessageStreamingProvider.overrideWith((ref, id) => false),
              conversationBusyStateProvider.overrideWith(
                (ref, _) async => const ConversationBusyState(
                  isStreaming: false,
                  hasPendingTools: false,
                ),
              ),
            ],
          ),
        );

        expect(
          find.byKey(const ValueKey('retry_message_failed-user')),
          findsOneWidget,
        );
        expect(find.byTooltip('Retry message'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey('retry_message_failed-user')),
        );
        await tester.pump();

        expect(retriedIds, ['failed-user']);
      });
    }

    testWidgets('does not retry an older failed user message', (tester) async {
      final failed = _createMessage(
        id: 'failed-user',
        status: MessageStatus.error,
      );
      final latest = _createMessage(id: 'latest-user');

      await pumpAndInit(
        tester,
        buildSubject(
          messages: [failed.id, latest.id],
          messageEntitiesById: {failed.id: failed, latest.id: latest},
          onRetryMessage: (_) async {},
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => id.messageId == failed.id ? failed : latest,
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(
        find.byKey(const ValueKey('retry_message_failed-user')),
        findsNothing,
      );
    });

    testWidgets('renders user message with text content', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => _createMessage(content: 'Hello AI'),
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.text('Hello AI'), findsOneWidget);
      expect(find.byType(SelectionArea), findsOneWidget);
      expect(find.byIcon(Icons.copy_outlined), findsOneWidget);
      expect(
        tester.widget<AuraIconButton>(find.byType(AuraIconButton)).tooltip,
        'Copy message',
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Align && widget.alignment == Alignment.centerRight,
        ),
        findsOneWidget,
      );
    });

    testWidgets('aligns user copy action with the user bubble', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => _createMessage(content: 'Hello AI'),
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      final bubbleRight = tester.getTopRight(find.byType(AuraMessageBubble)).dx;
      final copyActionRight = tester
          .getTopRight(find.byTooltip('Copy message'))
          .dx;

      expect(copyActionRight, closeTo(bubbleRight, 1));
    });

    testWidgets('uses a visible selection color for user messages', (
      tester,
    ) async {
      for (final theme in [AuraTheme.light, AuraTheme.dark]) {
        await pumpAndInit(
          tester,
          buildSubject(
            messages: ['msg-1'],
            theme: theme,
            overrides: [
              messageConversationByIdProvider.overrideWith(
                (ref, id) => _createMessage(content: 'Hello AI'),
              ),
              isMessageStreamingProvider.overrideWith((ref, id) => false),
              conversationBusyStateProvider.overrideWith(
                (ref, _) async => const ConversationBusyState(
                  isStreaming: false,
                  hasPendingTools: false,
                ),
              ),
            ],
          ),
        );

        final selectionTheme = tester.widget<TextSelectionTheme>(
          find.byType(TextSelectionTheme),
        );
        final overlayColor = theme.colors.onPrimary.computeLuminance() > .5
            ? Colors.black
            : Colors.white;
        expect(
          selectionTheme.data.selectionColor,
          Color.alphaBlend(
            overlayColor.withValues(alpha: .24),
            theme.colors.primary,
          ),
        );
        expect(
          selectionTheme.data.selectionColor,
          isNot(equals(theme.colors.primary)),
        );
      }
    });

    testWidgets('copies text message content and confirms success', (
      tester,
    ) async {
      String? copiedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText = (call.arguments as Map)['text'] as String?;
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

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => _createMessage(content: 'Hello AI', isUser: false),
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.byIcon(Icons.copy_outlined), findsOneWidget);
      expect(find.byType(SelectionArea), findsOneWidget);
      expect(
        tester.widget<AuraIconButton>(find.byType(AuraIconButton)).tooltip,
        'Copy message',
      );
      await tester.tap(find.byIcon(Icons.copy_outlined));
      await tester.pump();

      expect(copiedText, 'Hello AI');
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(
        tester.widget<AuraIconButton>(find.byType(AuraIconButton)).tooltip,
        'Message copied',
      );
    });

    testWidgets('prefers reactive message updates over initial snapshot', (
      tester,
    ) async {
      final message = _createMessage(content: 'Provided message');
      final updatedMessage = message.copyWith(content: 'Updated message');

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => updatedMessage,
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
          messageEntitiesById: {'msg-1': message},
        ),
      );

      expect(find.text('Provided message'), findsNothing);
      expect(find.text('Updated message'), findsOneWidget);
    });

    testWidgets('renders AI message content', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => _createMessage(content: 'Hello user', isUser: false),
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.text('Hello user'), findsOneWidget);
    });

    testWidgets('uses click cursor for AI links', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => _createMessage(
                content: '[Open docs](https://example.com)',
                isUser: false,
              ),
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Open docs')),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();

      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.click,
      );

      await gesture.up();
    });

    testWidgets('opens Markdown and autolinks', (tester) async {
      final launchedUrls = <String>[];
      _mockUrlLauncher(tester, (call) async {
        launchedUrls.add((call.arguments as Map)['url'] as String);
        return true;
      });

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['markdown-link', 'autolink'],
          overrides: _messageOverrides({
            'markdown-link': _createMessage(
              id: 'markdown-link',
              content: '[Open docs](https://example.com)',
              isUser: false,
            ),
            'autolink': _createMessage(
              id: 'autolink',
              content: 'https://example.org',
              isUser: false,
            ),
          }),
        ),
      );

      await tester.tap(find.text('Open docs'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Host: example.com'), findsOneWidget);
      await tester.tap(find.text('Open link'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('https://example.org'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Host: example.org'), findsOneWidget);
      await tester.tap(find.text('Open link'));
      await tester.pumpAndSettle();

      expect(launchedUrls, ['https://example.com', 'https://example.org']);
    });

    testWidgets('does not open Markdown link without confirmation', (
      tester,
    ) async {
      var launchCount = 0;
      _mockUrlLauncher(tester, (_) async {
        launchCount++;
        return true;
      });

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['markdown-link'],
          overrides: _messageOverrides({
            'markdown-link': _createMessage(
              content: '[Open docs](https://example.com/path?value=secret)',
              isUser: false,
            ),
          }),
        ),
      );

      await tester.tap(find.text('Open docs'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Host: example.com'), findsOneWidget);
      expect(
        find.textContaining('https://example.com/path?value=secret'),
        findsOneWidget,
      );
      expect(launchCount, 0);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(launchCount, 0);
    });

    testWidgets('rejects unsafe and malformed URLs', (tester) async {
      var launchCount = 0;
      _mockUrlLauncher(tester, (_) async {
        launchCount++;
        return true;
      });

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['unsafe-links'],
          overrides: _messageOverrides({
            'unsafe-links': _createMessage(
              id: 'unsafe-links',
              content:
                  '[Unsafe](javascript:alert(1)) '
                  '[Missing host](https:///missing-host) '
                  '[Deceptive](https://accounts.example@attacker.example/sso)',
              isUser: false,
            ),
          }),
        ),
      );

      await tester.tap(find.text('Unsafe'));
      await tester.pump();
      await tester.tap(find.text('Missing host'));
      await tester.pump();
      await tester.tap(find.text('Deceptive'));
      await tester.pump();

      expect(launchCount, 0);
      expect(find.text('Open external link?'), findsNothing);
    });

    testWidgets('shows link failure feedback', (tester) async {
      _mockUrlLauncher(tester, (_) async => false);
      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: _messageOverrides({
            'msg-1': _createMessage(
              content: '[Open docs](https://example.com)',
              isUser: false,
            ),
          }),
          appBuilder: _scaffoldedApp,
        ),
      );

      await tester.tap(find.text('Open docs'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open link'));
      await tester.pumpAndSettle();

      expect(find.text('Could not open link'), findsOneWidget);
    });

    testWidgets('shows link exception feedback', (tester) async {
      const hapticsChannel = MethodChannel('haptic_feedback');
      final hapticMethods = <String>[];
      final messenger = tester.binding.defaultBinaryMessenger;
      AuraHaptics.resetForTesting();
      messenger.setMockMethodCallHandler(hapticsChannel, (call) async {
        hapticMethods.add(call.method);
        if (call.method == 'canVibrate') return true;

        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(hapticsChannel, null);
        AuraHaptics.resetForTesting();
      });
      _mockUrlLauncher(
        tester,
        (_) async => throw PlatformException(code: 'launch-failed'),
      );
      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: _messageOverrides({
            'msg-1': _createMessage(
              content: '[Open docs](https://example.com)',
              isUser: false,
            ),
          }),
          appBuilder: _scaffoldedApp,
        ),
      );

      await tester.tap(find.text('Open docs'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open link'));
      await tester.pumpAndSettle();

      expect(find.text('Could not open link'), findsOneWidget);
      expect(hapticMethods, ['canVibrate', 'error']);
    });

    testWidgets('uses text cursor for user messages', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-link', 'msg-text'],
          overrides: _messageOverrides({
            'msg-link': _createMessage(
              id: 'msg-link',
              content: '[Open docs](https://example.com)',
            ),
            'msg-text': _createMessage(id: 'msg-text', content: 'Plain text'),
          }),
        ),
      );

      final linkGesture = await tester.startGesture(
        tester.getCenter(find.text('Open docs')),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.click,
      );
      await linkGesture.up();

      final textGesture = await tester.startGesture(
        tester.getCenter(find.text('Plain text')),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.text,
      );
      await textGesture.up();
      expect(find.byType(SelectionArea), findsNWidgets(2));
      expect(find.byIcon(Icons.copy_outlined), findsNWidgets(2));
    });

    testWidgets('keeps text-only assistant metadata inline', (tester) async {
      final message = _createMessage(
        content: 'Text-only answer',
        isUser: false,
      );
      final relativeTime = RelativeTimeFormatter.format(message.createdAt);

      await pumpAndInit(
        tester,
        buildSubject(
          messages: [message.id],
          messageEntitiesById: {message.id: message},
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.text('Text-only answer'), findsOneWidget);
      expect(find.byKey(const ValueKey('message_footer_msg-1')), findsNothing);
      expect(find.byTooltip('Copy message'), findsOneWidget);
      expect(find.text(relativeTime), findsOneWidget);
    });

    testWidgets('renders one thinking indicator while generation is active', (
      tester,
    ) async {
      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          showThinking: true,
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => _createMessage(
                content: '',
                isUser: false,
                status: MessageStatus.unfinished,
              ),
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.byType(ChatThinkingIndicator), findsOneWidget);
      expect(find.byType(AuraTypingIndicator), findsOneWidget);
      expect(find.text('Thinking...'), findsOneWidget);
    });

    testWidgets('flattens one thinking card before the response', (
      tester,
    ) async {
      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => _createMessage(
                content: 'Final answer',
                isUser: false,
                metadata: const MessageMetadataEntity(
                  thinking: 'Reasoned before answering',
                ),
              ),
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.text('Thinking'), findsOneWidget);
      expect(find.text('Reasoned before answering'), findsOneWidget);
      expect(find.text('Final answer'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('activity_trace_toggle_msg-1')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('activity_thinking_msg-1')),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.text('Reasoned before answering')).dy,
        lessThan(tester.getTopLeft(find.text('Final answer')).dy),
      );
      expect(
        find.ancestor(
          of: find.text('Reasoned before answering'),
          matching: find.byType(SelectionArea),
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.text('Final answer'),
          matching: find.byType(SelectionArea),
        ),
        findsOneWidget,
      );
    });

    testWidgets('orders thinking, response, and tools for non-final response', (
      tester,
    ) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'built_in_1_read_file',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.success,
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => _createMessage(
                content: 'Final answer',
                isUser: false,
                metadata: const MessageMetadataEntity(
                  thinking: 'Reasoned before answering',
                  toolCalls: [toolCall],
                ),
              ),
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      final thinking = find.byKey(const ValueKey('activity_thinking_msg-1'));
      final response = find.text('Final answer');
      final tool = find.byKey(const ValueKey('activity_tool_tc-1'));
      final trace = find.byKey(const ValueKey('activity_trace_toggle_msg-1'));

      expect(thinking, findsNothing);
      expect(response, findsNothing);
      expect(trace, findsOneWidget);
      expect(tool, findsNothing);
      expect(find.byIcon(Icons.copy_outlined), findsNothing);

      await tester.tap(trace);
      await tester.pump();

      expect(thinking, findsOneWidget);
      expect(tool, findsOneWidget);
      expect(
        tester.getTopLeft(thinking).dy,
        lessThan(tester.getTopLeft(response).dy),
      );
      expect(
        tester.getTopLeft(response).dy,
        lessThan(tester.getTopLeft(tool).dy),
      );
      expect(find.byIcon(Icons.copy_outlined), findsNothing);
    });

    testWidgets('does not render actions for non-final assistant response', (
      tester,
    ) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'built_in_1_read_file',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.success,
      );

      final messagesById = {
        'intermediate': _createMessage(
          id: 'intermediate',
          content: 'Intermediate response',
          isUser: false,
        ),
        'tool': _createMessage(
          id: 'tool',
          content: '',
          isUser: false,
          metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
        ),
        'final': _createMessage(
          id: 'final',
          content: 'Final response',
          isUser: false,
        ),
      };

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['intermediate', 'tool', 'final'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => messagesById[id.messageId],
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(
        find.byKey(const ValueKey('activity_trace_toggle_intermediate')),
        findsOneWidget,
      );
      expect(find.text('Intermediate response'), findsNothing);
      expect(find.text('Final response'), findsOneWidget);
      expect(find.byIcon(Icons.copy_outlined), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('activity_trace_toggle_intermediate')),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('activity_narrative_intermediate')),
        findsOneWidget,
      );
      expect(find.text('Intermediate response'), findsOneWidget);
      expect(find.byIcon(Icons.copy_outlined), findsOneWidget);
    });

    testWidgets('keeps unfinished A2UI controls without final actions', (
      tester,
    ) async {
      final runtime = ChatA2uiRuntime(conversationId: 'conv-1');
      addTearDown(runtime.dispose);
      final message = _createMessage(
        id: 'pending-form',
        content: 'Please answer',
        isUser: false,
        status: MessageStatus.unfinished,
        metadata: MessageMetadataEntity(
          thinking: 'Preparing form',
          a2uiMessages: [
            for (final operation in [
              {
                'createSurface': {
                  'surfaceId': 'main',
                  'catalogId': 'urn:auravibes:a2ui:chat:form:v1',
                },
              },
              {
                'updateComponents': {
                  'surfaceId': 'main',
                  'components': [
                    {'id': 'root', 'component': 'Text', 'text': 'Answer here'},
                  ],
                },
              },
            ])
              jsonEncode({
                'protocolVersion': 'v1',
                'interactionMode': 'requiresUserAction',
                'message': {'version': 'v0.9', ...operation},
              }),
          ],
        ),
      );
      await pumpAndInit(
        tester,
        buildSubject(
          messages: [message.id],
          messageEntitiesById: {message.id: message},
          conversation: ConversationEntity(
            id: 'conv-1',
            title: 'Chat',
            workspaceId: 'ws-1',
            isPinned: false,
            createdAt: DateTime(2025),
            updatedAt: DateTime(2025),
          ),
          overrides: [
            chatA2uiRuntimeProvider.overrideWith((ref, id) => runtime),
            ..._messageOverrides({message.id: message}),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Answer here'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('a2ui_submit_pending-form:main')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.copy_outlined), findsNothing);
      expect(find.byIcon(Icons.call_split_outlined), findsNothing);
      expect(
        find.byKey(const ValueKey('retry_message_pending-form')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('message_footer_pending-form')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not show unfinished status for an A2UI message', (
      tester,
    ) async {
      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => _createMessage(
                content: 'Form result',
                isUser: false,
                status: MessageStatus.unfinished,
                metadata: const MessageMetadataEntity(
                  a2uiMessages: ['replayed-payload'],
                ),
              ),
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.byType(AuraMessageStatus), findsNothing);
    });

    testWidgets('replays A2UI metadata after build', (tester) async {
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(
          a2uiMessages: [
            '{"protocolVersion":"v1","interactionMode":"passive",'
                '"message":{"version":"v0.9","createSurface":{'
                '"surfaceId":"main","catalogId":'
                '"urn:auravibes:a2ui:chat:v1"}}}',
          ],
        ),
      );
      await pumpAndInit(
        tester,
        buildSubject(
          messages: [message.id],
          messageEntitiesById: {message.id: message},
          conversation: ConversationEntity(
            id: 'conv-1',
            title: 'Chat',
            workspaceId: 'ws-1',
            isPinned: false,
            createdAt: DateTime(2025),
            updatedAt: DateTime(2025),
          ),
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('opens skill picker when A2UI suggestion is stale', (
      tester,
    ) async {
      const suggestedRevision =
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      const currentRevision =
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
      const skill = AvailableSkill(
        source: SkillSource.user,
        id: 'skill-1',
        slug: 'research',
        title: 'Research',
        description: 'Find sources',
        content: 'Use primary sources',
        kind: .template,
        credentialReadiness: .ready,
      );
      var loadCalls = 0;
      var sendCalls = 0;
      final action = ApplyConversationSkillActionUsecase(
        workspaceIdForConversation: (_) async => 'ws-1',
        listSkills: (_, _, filter) async =>
            filter == .catalog ? const [skill] : const <AvailableSkill>[],
        buildContextMessages: (_, _) async => [
          ChatMessage(
            role: .system,
            content: '<skill_catalog />',
            metadata: {
              'kind': skillCatalogMetadataKind,
              skillCatalogRevisionMetadataKey: currentRevision,
            },
          ),
        ],
        loadSkill: (_, _, _) async {
          loadCalls++;
        },
        sendMessage: (_, _, _) async {
          sendCalls++;
        },
      );

      final result = await pumpCopySurface(
        tester,
        [
          {
            'id': 'root',
            'component': 'Column',
            'children': ['suggestion'],
          },
          {
            'id': 'suggestion',
            'component': 'SkillSuggestion',
            'slug': skill.slug,
            'catalogRevision': suggestedRevision,
          },
        ],
        a2uiEnabled: true,
        overrides: [
          conversationSkillSelectorProvider('ws-1', 'conv-1').overrideWith(
            (_) async => const ConversationSkillSelectorState(
              loaded: [],
              loadable: [skill],
            ),
          ),
          applyConversationSkillActionUsecaseProvider.overrideWith(
            (_) => action,
          ),
        ],
      );
      await tester.pumpAndSettle();
      expect(result.runtime.hasSkillSuggestions, isTrue);
      expect(find.text('Research'), findsOneWidget);

      expect(
        result.runtime.submitSkillSuggestion(
          surfaceId: result.runtime.surfaceIdsFor('msg-1').single,
          componentId: 'suggestion',
          action: ChatSkillSuggestionAction.add,
        ),
        isTrue,
      );
      await tester.pumpAndSettle();

      expect(find.byType(ConversationSkillSelectorModal), findsOneWidget);
      expect(loadCalls, 0);
      expect(sendCalls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders an A2UI-only assistant footer', (tester) async {
      final result = await pumpCopySurface(tester, [
        {'id': 'root', 'component': 'Text', 'text': 'UI answer'},
      ]);
      final surface = find.byKey(const ValueKey('a2ui_msg-1'));
      final footer = find.byKey(const ValueKey('message_footer_msg-1'));
      final relativeTime = RelativeTimeFormatter.format(DateTime(2025));
      final copyAction = find.descendant(
        of: footer,
        matching: find.byIcon(Icons.copy_outlined),
      );
      final timestamp = find.descendant(
        of: footer,
        matching: find.text(relativeTime),
      );

      expect(find.text('UI answer'), findsOneWidget);
      expect(find.byType(SelectionArea), findsOneWidget);
      expect(surface, findsOneWidget);
      expect(footer, findsOneWidget);
      expect(
        tester.getTopLeft(surface).dy,
        lessThan(tester.getTopLeft(footer).dy),
      );
      expect(copyAction, findsOneWidget);
      expect(timestamp, findsOneWidget);
      expect(find.text(relativeTime), findsOneWidget);
      expect(
        tester.getTopLeft(timestamp).dx,
        greaterThan(tester.getTopRight(copyAction).dx),
      );

      await tester.tap(copyAction);
      await tester.pump();
      expect(result.copies, ['UI answer']);
    });

    testWidgets('renders mixed text and A2UI content in one footer', (
      tester,
    ) async {
      final result = await pumpCopySurface(tester, [
        {'id': 'root', 'component': 'Text', 'text': 'UI answer'},
      ], content: 'Intro');
      final surface = find.byKey(const ValueKey('a2ui_msg-1'));
      final footer = find.byKey(const ValueKey('message_footer_msg-1'));
      final relativeTime = RelativeTimeFormatter.format(DateTime(2025));
      final copyAction = find.descendant(
        of: footer,
        matching: find.byIcon(Icons.copy_outlined),
      );
      final timestamp = find.descendant(
        of: footer,
        matching: find.text(relativeTime),
      );

      expect(find.text('Intro'), findsOneWidget);
      expect(find.text('UI answer'), findsOneWidget);
      expect(surface, findsOneWidget);
      expect(footer, findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Intro')).dy,
        lessThan(tester.getTopLeft(surface).dy),
      );
      expect(
        tester.getTopLeft(surface).dy,
        lessThan(tester.getTopLeft(footer).dy),
      );
      expect(copyAction, findsOneWidget);
      expect(timestamp, findsOneWidget);
      expect(find.text(relativeTime), findsOneWidget);
      expect(find.byType(AuraMessageStatus), findsNothing);
      expect(
        tester.getTopLeft(timestamp).dx,
        greaterThan(tester.getTopRight(copyAction).dx),
      );

      await tester.tap(copyAction);
      await tester.pump();
      expect(result.copies, ['Intro\n\nUI answer']);
    });

    testWidgets('copies message text together with an A2UI surface', (
      tester,
    ) async {
      final runtime = ChatA2uiRuntime(conversationId: 'conv-1');
      addTearDown(runtime.dispose);
      final message = _createMessage(
        content: 'Message answer',
        isUser: false,
        metadata: const MessageMetadataEntity(
          a2uiMessages: [
            '{"protocolVersion":"v1","interactionMode":"passive",'
                '"message":{"version":"v0.9","createSurface":{'
                '"surfaceId":"main","catalogId":'
                '"urn:auravibes:a2ui:chat:v1"}}}',
            '{"protocolVersion":"v1","interactionMode":"passive",'
                '"message":{"version":"v0.9","updateComponents":{'
                '"surfaceId":"main","components":[{"id":"root",'
                '"component":"Text","text":"UI answer"}]}}}',
          ],
        ),
      );
      String? copiedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText = (call.arguments as Map)['text'] as String?;
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

      await pumpAndInit(
        tester,
        buildSubject(
          messages: [message.id],
          messageEntitiesById: {message.id: message},
          conversation: ConversationEntity(
            id: 'conv-1',
            title: 'Chat',
            workspaceId: 'ws-1',
            isPinned: false,
            createdAt: DateTime(2025),
            updatedAt: DateTime(2025),
          ),
          overrides: [
            chatA2uiRuntimeProvider.overrideWith((ref, id) => runtime),
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );
      final _ = await tester.pumpAndSettle();

      final copyAction = find.byIcon(Icons.copy_outlined);
      expect(find.text('UI answer'), findsOneWidget);
      final selectionArea = find.byType(SelectionArea);
      expect(selectionArea, findsOneWidget);
      expect(
        find.ancestor(of: find.text('Message answer'), matching: selectionArea),
        findsOneWidget,
      );
      expect(
        find.ancestor(of: find.text('UI answer'), matching: selectionArea),
        findsOneWidget,
      );
      expect(
        find.ancestor(of: copyAction, matching: find.byType(SelectionArea)),
        findsNothing,
      );

      final messageParagraph = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.text('Message answer'),
          matching: find.byType(RichText),
        ),
      );
      final uiParagraph = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.text('UI answer'),
          matching: find.byType(RichText),
        ),
      );
      expect(messageParagraph.registrar, isNotNull);
      expect(uiParagraph.registrar, isNotNull);
      final gesture = await tester.startGesture(
        messageParagraph.localToGlobal(
          Offset(2, messageParagraph.size.height / 2),
        ),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await gesture.moveTo(
        uiParagraph.localToGlobal(
          Offset(uiParagraph.size.width - 2, uiParagraph.size.height / 2),
        ),
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(messageParagraph.selections, isNotEmpty);
      expect(uiParagraph.selections, isNotEmpty);

      await tester.tap(copyAction);
      await tester.pump();
      expect(copiedText, 'Message answer\n\nUI answer');
    });

    testWidgets('does not copy an image-only A2UI surface', (tester) async {
      final runtime = ChatA2uiRuntime(conversationId: 'conv-1');
      addTearDown(runtime.dispose);
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(
          a2uiMessages: [
            '{"protocolVersion":"v1","interactionMode":"passive",'
                '"message":{"version":"v0.9","createSurface":{'
                '"surfaceId":"main","catalogId":'
                '"urn:auravibes:a2ui:chat:v1"}}}',
            '{"protocolVersion":"v1","interactionMode":"passive",'
                '"message":{"version":"v0.9","updateComponents":{'
                '"surfaceId":"main","components":[{"id":"root",'
                '"component":"Image","url":'
                '"https://127.0.0.1/private.png"}]}}}',
          ],
        ),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: [message.id],
          messageEntitiesById: {message.id: message},
          conversation: ConversationEntity(
            id: 'conv-1',
            title: 'Chat',
            workspaceId: 'ws-1',
            isPinned: false,
            createdAt: DateTime(2025),
            updatedAt: DateTime(2025),
          ),
          overrides: [
            chatA2uiRuntimeProvider.overrideWith((ref, id) => runtime),
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(SelectionArea), findsOneWidget);
      expect(find.byTooltip('Copy message'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows persisted A2UI issue when assistant text is empty', (
      tester,
    ) async {
      final runtime = ChatA2uiRuntime(conversationId: 'conv-1');
      addTearDown(runtime.dispose);
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(
          a2uiIssuesBySurface: {
            'broken-surface': ['malformedPayload'],
          },
        ),
      );
      await pumpAndInit(
        tester,
        buildSubject(
          messages: [message.id],
          messageEntitiesById: {message.id: message},
          conversation: ConversationEntity(
            id: 'conv-1',
            title: 'Chat',
            workspaceId: 'ws-1',
            isPinned: false,
            createdAt: DateTime(2025),
            updatedAt: DateTime(2025),
          ),
          overrides: [
            chatA2uiRuntimeProvider.overrideWith((ref, id) => runtime),
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(runtime.hasSurfaceIssue(message.id), isTrue);
      expect(find.byType(ChatA2uiSurfaceHost), findsOneWidget);
      expect(find.text('This UI could not be loaded.'), findsOneWidget);
    });

    testWidgets('does not close a live A2UI turn before metadata persists', (
      tester,
    ) async {
      final runtime = ChatA2uiRuntime(conversationId: 'conv-1', enabled: true)
        ..bindMessage('assistant-1');
      addTearDown(runtime.dispose);
      await pumpAndInit(
        tester,
        buildSubject(
          messages: const [],
          conversation: ConversationEntity(
            id: 'conv-1',
            title: 'Chat',
            workspaceId: 'ws-1',
            isPinned: false,
            createdAt: DateTime(2025),
            updatedAt: DateTime(2025),
          ),
          overrides: [
            chatA2uiRuntimeProvider.overrideWith((ref, id) => runtime),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: true,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(runtime.currentMessageId, 'assistant-1');
    });

    testWidgets('handles null message gracefully', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['missing-msg'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => null),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.byType(ChatMessagesWidget), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('flattens one tool row from message metadata', (tester) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'built_in_1_read_file',
        argumentsRaw: '{"input": "test.txt"}',
        responseRaw: 'file content',
        resultStatus: ToolCallResultStatus.success,
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.byKey(const ValueKey('activity_tool_tc-1')), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(
        find.byKey(const ValueKey('activity_trace_toggle_msg-1')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('activity_tool_list_toggle_msg-1')),
        findsNothing,
      );
    });

    for (final (name, source, policy, persistedClipped, expectedLimit) in [
      (
        'context-only clipping',
        'x' * (defaultToolOutputBytes + 1),
        const AgentToolOutputPolicy(),
        false,
        defaultToolOutputBytes,
      ),
      (
        'persisted clipping',
        'x' * (maxPersistedToolOutputBytes + 1),
        const AgentToolOutputPolicy(),
        true,
        defaultToolOutputBytes,
      ),
      (
        'custom context limit',
        'x' * 1024,
        const AgentToolOutputPolicy(maxBytes: 512),
        false,
        512,
      ),
    ]) {
      testWidgets('discloses $name in expanded activity details', (
        tester,
      ) async {
        final projection = projectToolOutput(source, policy: policy);
        final toolCall = MessageToolCallEntity(
          id: 'tc-truncated',
          name: 'built_in_1_read_file',
          argumentsRaw: '{}',
          responseRaw: projection.persistedText,
          responseContextRaw: projection.text == projection.persistedText
              ? null
              : projection.text,
          outputTruncated: projection.truncated,
          originalResponseBytes: projection.originalBytes,
          resultStatus: ToolCallResultStatus.success,
        );
        final message = _createMessage(
          content: '',
          isUser: false,
          metadata: MessageMetadataEntity(toolCalls: [toolCall]),
        );
        await pumpAndInit(
          tester,
          buildSubject(
            messages: [message.id],
            overrides: _messageOverrides({message.id: message}),
          ),
        );
        await revealActivityToolCalls(tester);
        await tester.tap(
          find.byKey(const ValueKey('activity_tool_tc-truncated')),
        );
        await tester.pump();

        final disclosure = find.byKey(
          const ValueKey('activity_tool_truncation_tc-truncated'),
        );
        expect(disclosure, findsOneWidget);
        final text = tester.widget<Text>(disclosure).data!;
        expect(text, contains('${projection.originalBytes}'));
        expect(text, contains('$expectedLimit'));
        expect(
          text,
          contains(
            persistedClipped
                ? 'stored output was also clipped'
                : 'full output remains stored',
          ),
        );
      });
    }

    testWidgets('omits truncation disclosure for in-budget and legacy data', (
      tester,
    ) async {
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(
          toolCalls: [
            MessageToolCallEntity(
              id: 'tc-small',
              name: 'built_in_1_read_file',
              argumentsRaw: '{}',
              responseRaw: 'small result',
              resultStatus: ToolCallResultStatus.success,
            ),
            MessageToolCallEntity(
              id: 'tc-legacy',
              name: 'built_in_1_read_file',
              argumentsRaw: '{}',
              responseRaw: 'legacy result',
              outputTruncated: true,
              resultStatus: ToolCallResultStatus.success,
            ),
            MessageToolCallEntity(
              id: 'tc-malformed',
              name: 'built_in_1_read_file',
              argumentsRaw: '{}',
              responseRaw: 'legacy result',
              responseContextRaw: '{"_toolOutput":{}}',
              outputTruncated: true,
              originalResponseBytes: 1024,
              resultStatus: ToolCallResultStatus.success,
            ),
          ],
        ),
      );
      await pumpAndInit(
        tester,
        buildSubject(
          messages: [message.id],
          overrides: _messageOverrides({message.id: message}),
        ),
      );
      await revealActivityToolCalls(tester);
      await tester.tap(find.byKey(const ValueKey('activity_tool_tc-small')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('activity_tool_tc-legacy')));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('activity_tool_tc-malformed')),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('activity_tool_truncation_tc-small')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('activity_tool_truncation_tc-legacy')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('activity_tool_truncation_tc-malformed')),
        findsNothing,
      );
    });

    testWidgets('hides pending tool arguments from the activity details', (
      tester,
    ) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-pending',
        name: 'notion_update_page',
        argumentsRaw:
            '{"page":"Launch Plan",'
            '"change":"Add a task checklist"}',
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: [message.id],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: true,
              ),
            ),
          ],
          pendingToolCalls: const [
            PendingToolCall(toolCall: toolCall, messageId: 'msg-1'),
          ],
        ),
      );

      expect(
        find.byKey(const ValueKey('activity_tool_tc-pending')),
        findsOneWidget,
      );
      expect(find.text('Arguments'), findsNothing);
      expect(find.textContaining('Launch Plan'), findsNothing);
      expect(find.textContaining('Add a task checklist'), findsNothing);
    });

    testWidgets('shows a tool-call description beside its title', (
      tester,
    ) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-description',
        name: 'built_in_1_read_file',
        argumentsRaw: '{"input": "test.txt"}',
        userFacingDescription: 'I am going to inspect the file.',
        resultStatus: ToolCallResultStatus.success,
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      final label = tester.widget<Text>(
        find.byKey(const ValueKey('activity_tool_label_tc-description')),
      );
      expect(
        label.textSpan?.toPlainText(),
        contains('I am going to inspect the file.'),
      );
      final row = tester.getRect(
        find.byKey(const ValueKey('activity_tool_tc-description')),
      );
      final status = tester.getRect(find.text('Completed'));
      expect(status.right, greaterThan(row.center.dx));
      expect(row.right - status.right, lessThan(100));
    });

    testWidgets('shows saved skill and tool titles in activity rows', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 500));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final semantics = tester.ensureSemantics();
      const toolCall = MessageToolCallEntity(
        id: 'tc-skill',
        name: 'call_skill_tool',
        argumentsRaw: '{"skill":"research","tool":"search_web"}',
        resultStatus: ToolCallResultStatus.disabledInWorkspace,
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
            workspaceSkillsProvider('ws-1').overrideWith(
              (ref) async => const [
                WorkspaceSkill(
                  id: 'skill-1',
                  slug: 'research',
                  title: 'Research Assistant',
                  description: '',
                  source: SkillSource.user,
                  kind: SkillKind.template,
                  isEnabled: true,
                ),
              ],
            ),
            skillTemplateToolsProvider('ws-1', 'skill-1').overrideWith(
              (ref) async => [
                SkillTemplateToolEntity(
                  id: 'tool-1',
                  skillId: 'skill-1',
                  templateType: SkillTemplateToolType.url,
                  title: 'Search the web',
                  description: 'Searches the web.',
                  slug: 'search_web',
                  isEnabled: true,
                  requiresCredential: false,
                  createdAt: DateTime(2026),
                  updatedAt: DateTime(2026),
                ),
              ],
            ),
          ],
        ),
      );
      await revealActivityToolCalls(tester);
      await tester.pump();
      await tester.pump();

      final label = tester.widget<Text>(
        find.byKey(const ValueKey('activity_tool_label_tc-skill')),
      );
      expect(
        label.textSpan?.toPlainText(),
        contains('Research Assistant / Search the web'),
      );
      expect(find.text('Call Skill Tool'), findsNothing);
      final status = tester.widget<Text>(
        find.byKey(const ValueKey('activity_tool_status_tc-skill')),
      );
      expect(status.maxLines, 1);
      expect(status.overflow, TextOverflow.ellipsis);
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('activity_tool_tc-skill')))
            .label,
        contains('Research Assistant / Search the web Disabled in workspace'),
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('shows app skill and tool titles in activity rows', (
      tester,
    ) async {
      const registry = AppSkillRegistry();
      final appSkill = registry.getAll().firstWhere(
        (skill) => skill.tools.isNotEmpty,
      );
      final tool = appSkill.tools.first;
      final toolCall = MessageToolCallEntity(
        id: 'tc-app-skill',
        name: 'call_skill_tool',
        argumentsRaw: jsonEncode({'skill': appSkill.slug, 'tool': tool.slug}),
        resultStatus: ToolCallResultStatus.success,
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: MessageMetadataEntity(toolCalls: [toolCall]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
            workspaceSkillsProvider('ws-1').overrideWith(
              (ref) async => [
                WorkspaceSkill(
                  source: .app,
                  id: appSkill.identifier,
                  slug: appSkill.slug,
                  title: appSkill.title,
                  description: appSkill.description,
                  kind: appSkill.kind == AppSkillDefinitionKind.template
                      ? .template
                      : .native,
                  isEnabled: true,
                  titleKey: appSkill.titleKey,
                ),
              ],
            ),
          ],
        ),
      );
      await revealActivityToolCalls(tester);
      await tester.pump();
      await tester.pump();

      final labelFinder = find.byKey(
        const ValueKey('activity_tool_label_tc-app-skill'),
      );
      final context = tester.element(labelFinder);
      final skillTitle =
          appSkill.titleKey?.tr(context: context) ?? appSkill.title;
      final toolTitle = tool.titleKey?.tr(context: context) ?? tool.title;
      final label = tester.widget<Text>(labelFinder);
      expect(
        label.textSpan?.toPlainText(),
        contains('$skillTitle / $toolTitle'),
      );
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Call Skill Tool'), findsNothing);
    });

    testWidgets('uses slug and generic fallbacks when metadata is missing', (
      tester,
    ) async {
      const skillToolCall = MessageToolCallEntity(
        id: 'tc-missing-tool',
        name: 'call_skill_tool',
        argumentsRaw: '{"skill":"research","tool":"missing_tool"}',
        resultStatus: ToolCallResultStatus.success,
      );
      const malformedToolCall = MessageToolCallEntity(
        id: 'tc-malformed-skill',
        name: 'call_skill_tool',
        argumentsRaw: '{"skill":"research"}',
        resultStatus: ToolCallResultStatus.success,
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(
          toolCalls: [skillToolCall, malformedToolCall],
        ),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
            workspaceSkillsProvider('ws-1').overrideWith(
              (ref) async => const [
                WorkspaceSkill(
                  source: .user,
                  id: 'skill-1',
                  slug: 'research',
                  title: 'Research Assistant',
                  description: '',
                  kind: .template,
                  isEnabled: true,
                ),
              ],
            ),
            skillTemplateToolsProvider(
              'ws-1',
              'skill-1',
            ).overrideWith((ref) async => []),
          ],
        ),
      );
      await revealActivityToolCalls(tester);
      await tester.pump();
      await tester.pump();

      final missingToolLabel = tester.widget<Text>(
        find.byKey(const ValueKey('activity_tool_label_tc-missing-tool')),
      );
      expect(
        missingToolLabel.textSpan?.toPlainText(),
        contains('Research Assistant / Missing Tool'),
      );
      final malformedToolLabel = tester.widget<Text>(
        find.byKey(const ValueKey('activity_tool_label_tc-malformed-skill')),
      );
      expect(malformedToolLabel.textSpan?.toPlainText(), 'Call Skill Tool');
    });

    testWidgets('reveals a finished activity run in three compact levels', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final firstToolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'built_in_1_read_file',
        argumentsRaw: '{"path": "argument detail"}',
        responseRaw: 'first result detail',
        resultStatus: ToolCallResultStatus.success,
      );
      final secondToolCall = MessageToolCallEntity(
        id: 'tc-2',
        name: 'built_in_1_calculator',
        argumentsRaw: '{"expression": "second argument detail"}',
        responseRaw: 'second result detail',
        resultStatus: ToolCallResultStatus.success,
      );
      final message = _createMessage(
        content: 'Final answer',
        isUser: false,
        metadata: MessageMetadataEntity(
          thinking: 'Need to inspect the file first',
          toolCalls: [firstToolCall, secondToolCall],
        ),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.text('2 tools'), findsOneWidget);
      expect(find.text('Final answer'), findsNothing);
      expect(find.text('Need to inspect the file first'), findsNothing);
      expect(find.textContaining('argument detail'), findsNothing);
      expect(find.byKey(const ValueKey('activity_tool_tc-1')), findsNothing);
      expect(
        tester
            .widget<AuraPressable>(
              find.descendant(
                of: find.byKey(const ValueKey('activity_trace_toggle_msg-1')),
                matching: find.byType(AuraPressable),
              ),
            )
            .color,
        AuraTheme.light.colors.onSurfaceVariant,
      );
      expect(
        tester
            .widget<AuraPressable>(
              find.descendant(
                of: find.byKey(const ValueKey('activity_trace_toggle_msg-1')),
                matching: find.byType(AuraPressable),
              ),
            )
            .decoration,
        BoxDecoration(
          color: AuraTheme.light.colors.surfaceVariant.withValues(alpha: .5),
          borderRadius: BorderRadius.circular(
            AuraTheme.light.fromBorderRadius(.md),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('activity_trace_toggle_msg-1')),
      );
      await tester.pump();

      expect(find.text('2 tools'), findsOneWidget);
      expect(find.text('Final answer'), findsOneWidget);
      expect(find.text('Need to inspect the file first'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('activity_trace_toggle_msg-1')),
      );
      await tester.pump();
      expect(find.text('2 tools'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('activity_trace_toggle_msg-1')),
      );
      await tester.pump();
      expect(find.text('Need to inspect the file first'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('activity_tool_list_toggle_msg-1')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('activity_tool_tc-1')), findsNothing);
      expect(
        tester
            .widget<AuraPressable>(
              find.descendant(
                of: find.byKey(
                  const ValueKey('activity_tool_list_toggle_msg-1'),
                ),
                matching: find.byType(AuraPressable),
              ),
            )
            .color,
        AuraTheme.light.colors.secondary,
      );
      expect(
        tester
            .widget<AuraPressable>(
              find.descendant(
                of: find.byKey(
                  const ValueKey('activity_tool_list_toggle_msg-1'),
                ),
                matching: find.byType(AuraPressable),
              ),
            )
            .decoration,
        isNull,
      );
      final toolSummary = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('activity_tool_list_toggle_msg-1')),
          matching: find.byType(Text),
        ),
      );
      expect(toolSummary.maxLines, 1);
      expect(toolSummary.overflow, TextOverflow.ellipsis);

      final toolListToggle = find.byKey(
        const ValueKey('activity_tool_list_toggle_msg-1'),
      );
      final toolListPressable = find.descendant(
        of: toolListToggle,
        matching: find.byType(AuraPressable),
      );
      tester.widget<AuraPressable>(toolListPressable).onPressed!.call();
      await tester.pump();

      expect(find.byKey(const ValueKey('activity_tool_tc-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('activity_tool_tc-2')), findsOneWidget);
      expect(find.byType(AuraAccordion), findsNothing);
      expect(find.byType(AuraTile), findsNothing);
      expect(
        tester.getSize(find.byKey(const ValueKey('activity_tool_tc-1'))).width,
        lessThanOrEqualTo(320),
      );
      expect(
        tester
            .widget<AuraPressable>(
              find.byKey(const ValueKey('activity_tool_tc-1')),
            )
            .color,
        AuraTheme.light.colors.success,
      );

      final firstTool = find.byKey(const ValueKey('activity_tool_tc-1'));
      tester.widget<AuraPressable>(firstTool).onPressed!.call();
      await tester.pump();

      expect(find.text('Arguments'), findsOneWidget);
      expect(find.text('Result'), findsOneWidget);
      expect(find.textContaining('argument detail'), findsOneWidget);
      expect(find.textContaining('first result detail'), findsOneWidget);
      expect(
        tester
            .widget<AuraContainer>(
              find.byKey(const ValueKey('activity_tool_result_tc-1')),
            )
            .variant,
        AuraContainerVariant.surfaceVariant,
      );

      final secondTool = find.byKey(const ValueKey('activity_tool_tc-2'));
      tester.widget<AuraPressable>(secondTool).onPressed!.call();
      await tester.pump();

      expect(
        find.byKey(const ValueKey('activity_tool_details_tc-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('activity_tool_details_tc-2')),
        findsOneWidget,
      );
      expect(find.textContaining('second argument detail'), findsOneWidget);
      expect(find.textContaining('second result detail'), findsOneWidget);
    });

    testWidgets('keeps activity expansion below the tapped disclosure', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 500));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const toolCall = MessageToolCallEntity(
        id: 'tc-scroll',
        name: 'built_in_1_read_file',
        argumentsRaw: '{"path": "details"}',
        responseRaw: 'First line\nSecond line\nThird line\nFourth line',
        resultStatus: ToolCallResultStatus.success,
      );
      final olderMessages = {
        for (var index = 0; index < 8; index++)
          'old-$index': _createMessage(
            id: 'old-$index',
            content: 'Older message $index',
            isUser: true,
          ),
      };
      final targetMessage = _createMessage(
        id: 'target',
        content: 'Final answer',
        isUser: false,
        metadata: const MessageMetadataEntity(
          thinking: 'Activity details',
          toolCalls: [toolCall],
        ),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: [...olderMessages.keys, 'target'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => id.messageId == 'target'
                  ? targetMessage
                  : olderMessages[id.messageId],
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      final activityToggle = find.byKey(
        const ValueKey('activity_trace_toggle_target'),
      );
      final before = tester.getTopLeft(activityToggle).dy;

      await tester.tap(activityToggle);
      await tester.pump();
      expect(tester.getTopLeft(activityToggle).dy, closeTo(before, 1));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      final after = tester.getTopLeft(activityToggle).dy;
      final toolRow = find.byKey(const ValueKey('activity_tool_tc-scroll'));
      expect(after, closeTo(before, 1));
      expect(tester.getTopLeft(toolRow).dy, greaterThan(after));
      await tester.ensureVisible(toolRow);

      tester.widget<AuraPressable>(toolRow).onPressed!.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        find.byKey(const ValueKey('activity_tool_details_tc-scroll')),
        findsOneWidget,
      );

      tester.widget<AuraPressable>(toolRow).onPressed!.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      await tester.ensureVisible(activityToggle);
      final collapsedBefore = tester.getTopLeft(activityToggle).dy;
      await tester.tap(activityToggle);
      await tester.pump();
      expect(tester.getTopLeft(activityToggle).dy, closeTo(collapsedBefore, 1));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.getTopLeft(activityToggle).dy, closeTo(collapsedBefore, 1));
    });

    testWidgets('keeps a flattened tool expansion below its row', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 500));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const toolCall = MessageToolCallEntity(
        id: 'tc-flat-scroll',
        name: 'built_in_1_read_file',
        argumentsRaw: '{"path": "details"}',
        responseRaw: 'result',
        resultStatus: ToolCallResultStatus.success,
      );
      final olderMessages = {
        for (var index = 0; index < 8; index++)
          'old-flat-$index': _createMessage(
            id: 'old-flat-$index',
            content: 'Older message $index',
            isUser: true,
          ),
      };
      final targetMessage = _createMessage(
        id: 'flat-target',
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: [...olderMessages.keys, 'flat-target'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => id.messageId == 'flat-target'
                  ? targetMessage
                  : olderMessages[id.messageId],
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      final toolRow = find.byKey(
        const ValueKey('activity_tool_tc-flat-scroll'),
      );
      final before = tester.getTopLeft(toolRow).dy;

      await tester.tap(toolRow);
      await tester.pump();
      expect(tester.getTopLeft(toolRow).dy, closeTo(before, 1));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      final after = tester.getTopLeft(toolRow).dy;
      expect(after, closeTo(before, 1));
      expect(
        tester
            .getTopLeft(
              find.byKey(
                const ValueKey('activity_tool_details_tc-flat-scroll'),
              ),
            )
            .dy,
        greaterThanOrEqualTo(tester.getRect(toolRow).bottom),
      );

      await tester.tap(toolRow);
      await tester.pump();
      expect(tester.getTopLeft(toolRow).dy, closeTo(before, 1));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.getTopLeft(toolRow).dy, closeTo(before, 1));
    });

    testWidgets('consolidates chronological assistant activity sessions', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 2200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const firstTool = MessageToolCallEntity(
        id: 'tc-1',
        name: 'built_in_1_read_file',
        argumentsRaw: '{"path": "first"}',
        resultStatus: ToolCallResultStatus.success,
      );
      const secondTool = MessageToolCallEntity(
        id: 'tc-2',
        name: 'built_in_1_calculator',
        argumentsRaw: '{"expression": "2 + 2"}',
        resultStatus: ToolCallResultStatus.success,
      );
      const thirdTool = MessageToolCallEntity(
        id: 'tc-3',
        name: 'built_in_1_read_file',
        argumentsRaw: '{"path": "third"}',
        resultStatus: ToolCallResultStatus.success,
      );
      const fourthTool = MessageToolCallEntity(
        id: 'tc-4',
        name: 'built_in_1_calculator',
        argumentsRaw: '{"expression": "4 + 4"}',
        resultStatus: ToolCallResultStatus.success,
      );
      final olderMessages = {
        for (var index = 0; index < 8; index++)
          'old-$index': _createMessage(
            id: 'old-$index',
            content: 'Older message $index',
            isUser: true,
          ),
      };
      final messagesById = {
        ...olderMessages,
        'plan-response': _createMessage(
          id: 'plan-response',
          content: 'First plan',
          isUser: false,
        ),
        'plan-1': _createMessage(
          id: 'plan-1',
          content: '',
          isUser: false,
          metadata: const MessageMetadataEntity(
            thinking: 'First activity thought',
            toolCalls: [firstTool],
          ),
        ),
        'tools-1': _createMessage(
          id: 'tools-1',
          content: '',
          isUser: false,
          metadata: const MessageMetadataEntity(toolCalls: [secondTool]),
        ),
        'plan-2': _createMessage(
          id: 'plan-2',
          content: 'Second plan',
          isUser: false,
          metadata: const MessageMetadataEntity(
            thinking: 'Second activity thought',
            toolCalls: [thirdTool],
          ),
        ),
        'tools-2': _createMessage(
          id: 'tools-2',
          content: '',
          isUser: false,
          metadata: const MessageMetadataEntity(toolCalls: [fourthTool]),
        ),
        'final': _createMessage(
          id: 'final',
          content: 'Final response',
          isUser: false,
        ),
      };

      await pumpAndInit(
        tester,
        buildSubject(
          messages: [
            ...olderMessages.keys,
            'plan-response',
            'plan-1',
            'tools-1',
            'plan-2',
            'tools-2',
            'final',
          ],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => messagesById[id.messageId],
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      final activityToggle = find.byKey(
        const ValueKey('activity_trace_toggle_plan-response'),
      );
      expect(activityToggle, findsOneWidget);
      expect(
        find.byKey(const ValueKey('activity_trace_toggle_tools-1')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('activity_trace_toggle_plan-2')),
        findsNothing,
      );
      expect(find.text('4 tools'), findsOneWidget);
      expect(find.text('First plan'), findsNothing);
      expect(find.text('Second plan'), findsNothing);
      expect(find.text('Final response'), findsOneWidget);

      await tester.tap(activityToggle);
      await tester.pump();

      expect(find.text('First plan'), findsOneWidget);
      expect(find.text('First activity thought'), findsOneWidget);
      expect(find.text('Second plan'), findsOneWidget);
      expect(find.text('Second activity thought'), findsOneWidget);
      final firstToolGroup = find.byKey(
        const ValueKey('activity_tool_list_toggle_plan-1'),
      );
      final secondToolGroup = find.byKey(
        const ValueKey('activity_tool_list_toggle_plan-2'),
      );
      expect(firstToolGroup, findsOneWidget);
      expect(secondToolGroup, findsOneWidget);
      expect(find.byKey(const ValueKey('activity_tool_tc-1')), findsNothing);
      expect(find.byKey(const ValueKey('activity_tool_tc-2')), findsNothing);
      expect(find.byKey(const ValueKey('activity_tool_tc-3')), findsNothing);
      expect(find.byKey(const ValueKey('activity_tool_tc-4')), findsNothing);
      expect(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('activity_narrative_plan-response')),
            )
            .dy,
        lessThan(
          tester
              .getTopLeft(
                find.byKey(const ValueKey('activity_thinking_plan-1')),
              )
              .dy,
        ),
      );
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('activity_thinking_plan-1')))
            .dy,
        lessThan(tester.getTopLeft(firstToolGroup).dy),
      );
      expect(
        tester.getTopLeft(firstToolGroup).dy,
        lessThan(
          tester
              .getTopLeft(
                find.byKey(const ValueKey('activity_narrative_plan-2')),
              )
              .dy,
        ),
      );
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('activity_narrative_plan-2')))
            .dy,
        greaterThan(
          tester
              .getTopLeft(
                find.byKey(const ValueKey('activity_thinking_plan-2')),
              )
              .dy,
        ),
      );
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('activity_narrative_plan-2')))
            .dy,
        lessThan(tester.getTopLeft(secondToolGroup).dy),
      );
      await tester.ensureVisible(find.text('Final response'));
      expect(
        tester.getTopLeft(secondToolGroup).dy,
        lessThan(tester.getTopLeft(find.text('Final response')).dy),
      );

      await tester.tap(firstToolGroup);
      await tester.pump();
      expect(find.byKey(const ValueKey('activity_tool_tc-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('activity_tool_tc-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('activity_tool_tc-3')), findsNothing);
      expect(find.byKey(const ValueKey('activity_tool_tc-4')), findsNothing);

      await tester.ensureVisible(secondToolGroup);
      await tester.tap(secondToolGroup);
      await tester.pump();
      expect(find.byKey(const ValueKey('activity_tool_tc-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('activity_tool_tc-4')), findsOneWidget);
    });

    testWidgets(
      'renders_non_final_rich_responses_inside_expanded_activity_without_actions',
      (tester) async {
        final runtime = ChatA2uiRuntime(conversationId: 'conv-1');
        addTearDown(runtime.dispose);
        final rich = _createMessage(
          id: 'rich',
          content: 'Intermediate detail',
          isUser: false,
          attachments: [
            MessageAttachmentEntity(
              id: 'attachment-1',
              messageId: 'rich',
              localPath: '/missing/report.txt',
              fileName: 'report.txt',
              displayName: 'report.txt',
              mimeType: 'text/plain',
              modality: MessageAttachmentModality.file,
              sizeBytes: 6,
              createdAt: DateTime(2025),
              updatedAt: DateTime(2025),
            ),
          ],
          metadata: MessageMetadataEntity(
            a2uiMessages: [
              for (final operation in [
                {
                  'createSurface': {
                    'surfaceId': 'main',
                    'catalogId': 'urn:auravibes:a2ui:chat:v1',
                  },
                },
                {
                  'updateComponents': {
                    'surfaceId': 'main',
                    'components': [
                      {
                        'id': 'root',
                        'component': 'Text',
                        'text': 'A2UI detail',
                      },
                    ],
                  },
                },
              ])
                jsonEncode({
                  'protocolVersion': 'v1',
                  'interactionMode': 'passive',
                  'message': {'version': 'v0.9', ...operation},
                }),
            ],
          ),
        );
        final tool = _createMessage(
          id: 'tool',
          content: '',
          isUser: false,
          metadata: const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'tc-rich',
                name: 'built_in_1_read_file',
                argumentsRaw: '{}',
                resultStatus: ToolCallResultStatus.success,
              ),
            ],
          ),
        );
        final messagesById = {'rich': rich, 'tool': tool};
        await pumpAndInit(
          tester,
          buildSubject(
            messages: ['rich', 'tool'],
            messageEntitiesById: messagesById,
            conversation: ConversationEntity(
              id: 'conv-1',
              title: 'Chat',
              workspaceId: 'ws-1',
              isPinned: false,
              createdAt: DateTime(2025),
              updatedAt: DateTime(2025),
            ),
            overrides: [
              chatA2uiRuntimeProvider.overrideWith((ref, id) => runtime),
              ..._messageOverrides(messagesById),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final disclosure = find.byKey(
          const ValueKey('activity_trace_toggle_rich'),
        );
        expect(disclosure, findsOneWidget);
        expect(find.text('Intermediate detail'), findsNothing);
        expect(find.text('report.txt'), findsNothing);
        expect(find.text('A2UI detail'), findsNothing);
        expect(find.byKey(const ValueKey('a2ui_rich')), findsNothing);
        expect(find.byIcon(Icons.copy_outlined), findsNothing);
        expect(find.byIcon(Icons.call_split_outlined), findsNothing);
        expect(find.byKey(const ValueKey('retry_message_rich')), findsNothing);
        expect(find.byKey(const ValueKey('message_footer_rich')), findsNothing);

        await tester.tap(disclosure);
        await tester.pumpAndSettle();

        expect(find.text('Intermediate detail'), findsOneWidget);
        expect(find.text('report.txt'), findsOneWidget);
        expect(find.text('A2UI detail'), findsOneWidget);
        expect(find.byKey(const ValueKey('a2ui_rich')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('activity_tool_tc-rich')),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.copy_outlined), findsNothing);
        expect(find.byIcon(Icons.call_split_outlined), findsNothing);
        expect(find.byKey(const ValueKey('retry_message_rich')), findsNothing);
        expect(find.byKey(const ValueKey('message_footer_rich')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('replays submitted answers inside intermediate Activity', (
      tester,
    ) async {
      final runtime = ChatA2uiRuntime(conversationId: 'conv-1');
      addTearDown(runtime.dispose);
      final assistant = _createMessage(
        id: 'assistant-form',
        content: '',
        isUser: false,
        metadata: MessageMetadataEntity(
          a2uiMessages: [
            for (final operation in [
              {
                'createSurface': {
                  'surfaceId': 'main',
                  'catalogId': 'urn:auravibes:a2ui:chat:form:v1',
                },
              },
              {
                'updateComponents': {
                  'surfaceId': 'main',
                  'components': [
                    {
                      'id': 'root',
                      'component': 'Text',
                      'text': {'path': '/answer'},
                    },
                  ],
                },
              },
            ])
              jsonEncode({
                'protocolVersion': 'v1',
                'interactionMode': 'requiresUserAction',
                'message': {'version': 'v0.9', ...operation},
              }),
          ],
        ),
      );
      final tool = _createMessage(
        id: 'later-tool',
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(
          toolCalls: [
            MessageToolCallEntity(
              id: 'tc-replay',
              name: 'built_in_1_read_file',
              argumentsRaw: '{}',
              resultStatus: ToolCallResultStatus.success,
            ),
          ],
        ),
      );
      const submitted = A2uiChatAction(
        protocolVersion: 'v1',
        conversationId: 'conv-1',
        turnId: 'assistant-form',
        assistantMessageId: 'assistant-form',
        surfaceId: 'assistant-form:main',
        wireSurfaceId: 'main',
        componentId: '__aura_form_submit__',
        actionName: 'submit',
        context: {},
        messageText: 'Form answers submitted',
        answers: {'answer': 'Submitted answer'},
      );
      final answer = _createMessage(
        id: 'user-answer',
        content: 'Form answers submitted',
        metadata: MessageMetadataEntity(
          modelMetadata: {'a2uiAction': submitted.toJson()},
        ),
      );
      final messagesById = {
        assistant.id: assistant,
        tool.id: tool,
        answer.id: answer,
      };
      await pumpAndInit(
        tester,
        buildSubject(
          messages: [assistant.id, tool.id, answer.id],
          messageEntitiesById: messagesById,
          conversation: ConversationEntity(
            id: 'conv-1',
            title: 'Chat',
            workspaceId: 'ws-1',
            isPinned: false,
            createdAt: DateTime(2025),
            updatedAt: DateTime(2025),
          ),
          overrides: [
            chatA2uiRuntimeProvider.overrideWith((ref, id) => runtime),
            ..._messageOverrides(messagesById),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final disclosure = find.byKey(
        const ValueKey('activity_trace_toggle_assistant-form'),
      );
      expect(disclosure, findsOneWidget);
      expect(find.text('Submitted answer'), findsNothing);
      await tester.tap(disclosure);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('a2ui_assistant-form')), findsOneWidget);
      expect(find.text('Submitted answer'), findsOneWidget);
      expect(runtime.hasSurfaceIssue(assistant.id), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hides_response_actions_until_streamed_turn_is_final', (
      tester,
    ) async {
      final messagesById = {
        'intermediate': _createMessage(
          id: 'intermediate',
          content: 'Streaming answer',
          isUser: false,
        ),
        'tool': _createMessage(
          id: 'tool',
          content: '',
          isUser: false,
          metadata: const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'tc-stream',
                name: 'built_in_1_read_file',
                argumentsRaw: '{}',
                resultStatus: ToolCallResultStatus.success,
              ),
            ],
          ),
        ),
        'final': _createMessage(
          id: 'final',
          content: 'Terminal answer',
          isUser: false,
        ),
      };
      var visibleIds = ['intermediate'];
      var streaming = true;
      late StateSetter updateTimeline;
      await pumpAndInit(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            updateTimeline = setState;
            return buildSubject(
              messages: visibleIds,
              overrides: [
                messageConversationByIdProvider.overrideWith(
                  (ref, id) => messagesById[id.messageId],
                ),
                isMessageStreamingProvider.overrideWith(
                  (ref, id) => streaming && id == 'intermediate',
                ),
                conversationBusyStateProvider.overrideWith(
                  (ref, _) async => const ConversationBusyState(
                    isStreaming: false,
                    hasPendingTools: false,
                  ),
                ),
              ],
            );
          },
        ),
      );
      expect(find.byIcon(Icons.copy_outlined), findsNothing);
      expect(
        find.byKey(const ValueKey('message_footer_intermediate')),
        findsNothing,
      );

      updateTimeline(() {
        visibleIds = ['intermediate', 'tool'];
        streaming = false;
      });
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.copy_outlined), findsNothing);
      expect(
        find.byKey(const ValueKey('message_footer_intermediate')),
        findsNothing,
      );

      updateTimeline(() => visibleIds = ['intermediate', 'tool', 'final']);
      await tester.pumpAndSettle();
      expect(find.text('Terminal answer'), findsOneWidget);
      expect(find.byIcon(Icons.copy_outlined), findsOneWidget);
      expect(
        find.byKey(const ValueKey('message_footer_intermediate')),
        findsNothing,
      );
    });

    for (final later in [
      (status: MessageStatus.sent, isStreaming: true),
      (status: MessageStatus.unfinished, isStreaming: false),
    ]) {
      testWidgets('hides earlier response actions before later plain assistant '
          '${later.isStreaming ? 'stream' : 'unfinished message'}', (
        tester,
      ) async {
        final messagesById = {
          'first': _createMessage(
            id: 'first',
            content: 'First response',
            isUser: false,
          ),
          'later': _createMessage(
            id: 'later',
            content: 'Continuing response',
            isUser: false,
            status: later.status,
          ),
        };
        await pumpAndInit(
          tester,
          buildSubject(
            messages: ['first', 'later'],
            overrides: [
              messageConversationByIdProvider.overrideWith(
                (ref, id) => messagesById[id.messageId],
              ),
              isMessageStreamingProvider.overrideWith(
                (ref, id) => id == 'later' && later.isStreaming,
              ),
              conversationBusyStateProvider.overrideWith(
                (ref, _) async => const ConversationBusyState(
                  isStreaming: false,
                  hasPendingTools: false,
                ),
              ),
            ],
          ),
        );

        expect(find.byIcon(Icons.copy_outlined), findsNothing);
        expect(find.byIcon(Icons.call_split_outlined), findsNothing);
        expect(find.byKey(const ValueKey('retry_message_first')), findsNothing);
        expect(
          find.byKey(const ValueKey('message_footer_first')),
          findsNothing,
        );
      });
    }

    testWidgets('hides earlier response actions while next row is unresolved', (
      tester,
    ) async {
      final first = _createMessage(
        id: 'first',
        content: 'First response',
        isUser: false,
      );
      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['first', 'unresolved'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => id.messageId == 'first' ? first : null,
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.byIcon(Icons.copy_outlined), findsNothing);
      expect(find.byIcon(Icons.call_split_outlined), findsNothing);
      expect(find.byKey(const ValueKey('message_footer_first')), findsNothing);
    });

    for (final boundaryType in [MessageType.text, MessageType.system]) {
      testWidgets(
        'keeps earlier response actions across $boundaryType boundary',
        (tester) async {
          final first = _createMessage(
            id: 'first',
            content: 'First response',
            isUser: false,
          );
          final boundary = _createMessage(
            id: 'boundary',
            content: 'Next turn',
            isUser: boundaryType == MessageType.text,
            messageType: boundaryType,
          );
          await pumpAndInit(
            tester,
            buildSubject(
              messages: ['first', 'boundary'],
              overrides: _messageOverrides({
                'first': first,
                'boundary': boundary,
              }),
            ),
          );

          final firstItem = find.byKey(const ValueKey('first'));
          expect(
            find.descendant(
              of: firstItem,
              matching: find.byIcon(Icons.copy_outlined),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: firstItem,
              matching: find.byIcon(Icons.call_split_outlined),
            ),
            findsOneWidget,
          );
        },
      );
    }

    testWidgets('preserves rich responses before later assistant activity', (
      tester,
    ) async {
      final runtime = ChatA2uiRuntime(conversationId: 'conv-1');
      addTearDown(runtime.dispose);
      final richResponse = _createMessage(
        id: 'rich-response',
        content: '',
        isUser: false,
        metadata: MessageMetadataEntity(
          a2uiMessages: [
            jsonEncode({
              'protocolVersion': 'v1',
              'interactionMode': 'passive',
              'message': {
                'version': 'v0.9',
                'createSurface': {
                  'surfaceId': 'main',
                  'catalogId': 'urn:auravibes:a2ui:chat:v1',
                },
              },
            }),
            jsonEncode({
              'protocolVersion': 'v1',
              'interactionMode': 'passive',
              'message': {
                'version': 'v0.9',
                'updateComponents': {
                  'surfaceId': 'main',
                  'components': [
                    {'id': 'root', 'component': 'Text', 'text': 'Rich answer'},
                  ],
                },
              },
            }),
          ],
        ),
      );
      final activity = _createMessage(
        id: 'later-activity',
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(
          toolCalls: [
            MessageToolCallEntity(
              id: 'tc-later',
              name: 'built_in_1_read_file',
              argumentsRaw: '{"path": "later"}',
              resultStatus: ToolCallResultStatus.success,
            ),
          ],
        ),
      );
      final messagesById = {
        richResponse.id: richResponse,
        activity.id: activity,
      };

      await pumpAndInit(
        tester,
        buildSubject(
          messages: [richResponse.id, activity.id],
          messageEntitiesById: messagesById,
          conversation: ConversationEntity(
            id: 'conv-1',
            title: 'Chat',
            workspaceId: 'ws-1',
            isPinned: false,
            createdAt: DateTime(2025),
            updatedAt: DateTime(2025),
          ),
          overrides: [
            chatA2uiRuntimeProvider.overrideWith((ref, id) => runtime),
            messageConversationByIdProvider.overrideWith(
              (ref, id) => messagesById[id.messageId],
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final disclosure = find.byKey(
        const ValueKey('activity_trace_toggle_rich-response'),
      );
      expect(disclosure, findsOneWidget);
      expect(find.byKey(const ValueKey('a2ui_rich-response')), findsNothing);
      expect(find.text('Rich answer'), findsNothing);
      await tester.tap(disclosure);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('a2ui_rich-response')), findsOneWidget);
      expect(find.text('Rich answer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps an A2UI response visible before later activity', (
      tester,
    ) async {
      final runtime = ChatA2uiRuntime(conversationId: 'conv-1');
      addTearDown(runtime.dispose);
      const firstTool = MessageToolCallEntity(
        id: 'tc-form',
        name: 'built_in_1_read_file',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.success,
      );
      const secondTool = MessageToolCallEntity(
        id: 'tc-follow-up',
        name: 'built_in_1_calculator',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.success,
      );
      final messagesById = {
        'form': _createMessage(
          id: 'form',
          content: '',
          isUser: false,
          status: MessageStatus.unfinished,
          metadata: MessageMetadataEntity(
            thinking: 'Preparing the form',
            toolCalls: const [firstTool],
            a2uiMessages: [
              for (final operation in [
                {
                  'createSurface': {
                    'surfaceId': 'main',
                    'catalogId': 'urn:auravibes:a2ui:chat:form:v1',
                  },
                },
                {
                  'updateComponents': {
                    'surfaceId': 'main',
                    'components': [
                      {
                        'id': 'root',
                        'component': 'Text',
                        'text': 'Action required',
                      },
                    ],
                  },
                },
              ])
                jsonEncode({
                  'protocolVersion': 'v1',
                  'interactionMode': 'requiresUserAction',
                  'message': {'version': 'v0.9', ...operation},
                }),
            ],
          ),
        ),
        'follow-up': _createMessage(
          id: 'follow-up',
          content: '',
          isUser: false,
          metadata: const MessageMetadataEntity(toolCalls: [secondTool]),
        ),
      };

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['form', 'follow-up'],
          messageEntitiesById: messagesById,
          conversation: ConversationEntity(
            id: 'conv-1',
            title: 'Chat',
            workspaceId: 'ws-1',
            isPinned: false,
            createdAt: DateTime(2025),
            updatedAt: DateTime(2025),
          ),
          overrides: [
            chatA2uiRuntimeProvider.overrideWith((ref, id) => runtime),
            messageConversationByIdProvider.overrideWith(
              (ref, id) => messagesById[id.messageId],
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('a2ui_form')), findsOneWidget);
      expect(find.text('Action required'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('activity_trace_toggle_form')),
        findsOneWidget,
      );
      await revealActivityToolCalls(tester, runId: 'form');
      expect(
        find.byKey(const ValueKey('activity_tool_tc-form')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps final response visible after the activity session', (
      tester,
    ) async {
      const openingTool = MessageToolCallEntity(
        id: 'tc-opening',
        name: 'built_in_1_read_file',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.success,
      );
      const retryTool = MessageToolCallEntity(
        id: 'tc-retry',
        name: 'built_in_1_calculator',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.success,
      );
      final messagesById = {
        'opening': _createMessage(
          id: 'opening',
          content: 'I will look that up.',
          isUser: false,
          metadata: const MessageMetadataEntity(
            thinking: 'Opening thought',
            toolCalls: [openingTool],
          ),
        ),
        'retry': _createMessage(
          id: 'retry',
          content: '',
          isUser: false,
          metadata: const MessageMetadataEntity(toolCalls: [retryTool]),
        ),
        'answer': _createMessage(
          id: 'answer',
          content: 'Final answer',
          isUser: false,
          metadata: const MessageMetadataEntity(
            thinking: 'Final thought',
            modelMetadata: {'a2uiDiagnosticPayloads': <String>[]},
          ),
        ),
      };

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['opening', 'retry', 'answer'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => messagesById[id.messageId],
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(
        find.byKey(const ValueKey('activity_trace_toggle_opening')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('activity_trace_toggle_retry')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('activity_trace_toggle_answer')),
        findsNothing,
      );
      expect(find.text('I will look that up.'), findsNothing);
      expect(find.text('Opening thought'), findsNothing);
      expect(find.text('Final thought'), findsNothing);
      expect(find.text('Final answer'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('activity_trace_toggle_opening')),
      );
      await tester.pump();

      expect(find.text('I will look that up.'), findsOneWidget);
      expect(find.text('Opening thought'), findsOneWidget);
      expect(find.text('Final thought'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('activity_tool_list_toggle_opening')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('activity_tool_list_toggle_opening')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('activity_tool_tc-retry')),
        findsOneWidget,
      );
      expect(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('activity_narrative_opening')),
            )
            .dy,
        greaterThan(
          tester
              .getTopLeft(
                find.byKey(const ValueKey('activity_thinking_opening')),
              )
              .dy,
        ),
      );
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('activity_thinking_opening')))
            .dy,
        lessThan(
          tester
              .getTopLeft(
                find.byKey(const ValueKey('activity_tool_list_toggle_opening')),
              )
              .dy,
        ),
      );
      expect(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('activity_tool_list_toggle_opening')),
            )
            .dy,
        lessThan(
          tester
              .getTopLeft(
                find.byKey(const ValueKey('activity_thinking_answer')),
              )
              .dy,
        ),
      );
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('activity_tool_tc-retry')))
            .dy,
        lessThan(
          tester
              .getTopLeft(
                find.byKey(const ValueKey('activity_thinking_answer')),
              )
              .dy,
        ),
      );
      expect(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('activity_trace_toggle_opening')),
            )
            .dy,
        lessThan(tester.getTopLeft(find.text('Final answer')).dy),
      );
      expect(find.text('Final answer'), findsOneWidget);
    });

    testWidgets('splits user boundaries between activity sessions', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const firstTool = MessageToolCallEntity(
        id: 'tc-1',
        name: 'built_in_1_read_file',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.success,
      );
      const secondTool = MessageToolCallEntity(
        id: 'tc-2',
        name: 'built_in_1_calculator',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.success,
      );
      const thirdTool = MessageToolCallEntity(
        id: 'tc-3',
        name: 'built_in_1_read_file',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.success,
      );
      const fourthTool = MessageToolCallEntity(
        id: 'tc-4',
        name: 'built_in_1_calculator',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.success,
      );
      final messagesById = {
        'msg-1': _createMessage(
          id: 'msg-1',
          content: '',
          isUser: false,
          metadata: const MessageMetadataEntity(
            thinking: 'Before user one',
            toolCalls: [firstTool],
          ),
        ),
        'msg-2': _createMessage(
          id: 'msg-2',
          content: '',
          isUser: false,
          metadata: const MessageMetadataEntity(
            thinking: 'Before user two',
            toolCalls: [secondTool],
          ),
        ),
        'user-1': _createMessage(id: 'user-1', content: 'User boundary'),
        'msg-3': _createMessage(
          id: 'msg-3',
          content: '',
          isUser: false,
          metadata: const MessageMetadataEntity(
            thinking: 'After user',
            toolCalls: [thirdTool],
          ),
        ),
        'answer-1': _createMessage(
          id: 'answer-1',
          content: 'Visible answer',
          isUser: false,
          metadata: const MessageMetadataEntity(
            thinking: 'Before visible answer',
            toolCalls: [fourthTool],
          ),
        ),
      };

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1', 'msg-2', 'user-1', 'msg-3', 'answer-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => messagesById[id.messageId],
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(
        find.byKey(const ValueKey('activity_trace_toggle_msg-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('activity_trace_toggle_msg-2')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('activity_trace_toggle_msg-3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('activity_trace_toggle_answer-1')),
        findsNothing,
      );
      expect(find.text('User boundary'), findsOneWidget);
      expect(find.text('Visible answer'), findsNothing);
      expect(find.text('Before visible answer'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('activity_trace_toggle_msg-1')),
      );
      await tester.pump();

      expect(find.text('Before user one'), findsOneWidget);
      expect(find.text('Before user two'), findsOneWidget);
      expect(find.text('After user'), findsNothing);
      expect(find.text('Before visible answer'), findsNothing);

      final secondActivityToggle = find.byKey(
        const ValueKey('activity_trace_toggle_msg-3'),
      );
      await tester.ensureVisible(secondActivityToggle);
      await tester.tap(secondActivityToggle);
      await tester.pump();

      expect(find.text('After user'), findsOneWidget);
      expect(find.text('Before visible answer'), findsOneWidget);
      expect(find.byKey(const ValueKey('activity_tool_tc-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('activity_tool_tc-4')), findsOneWidget);
      await tester.ensureVisible(find.text('Visible answer'));
      expect(find.text('Visible answer'), findsOneWidget);
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('activity_thinking_msg-3')))
            .dy,
        lessThan(
          tester
              .getTopLeft(
                find.byKey(const ValueKey('activity_thinking_answer-1')),
              )
              .dy,
        ),
      );
      expect(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('activity_thinking_answer-1')),
            )
            .dy,
        lessThan(tester.getTopLeft(find.text('Visible answer')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Visible answer')).dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(const ValueKey('activity_tool_tc-4')))
              .dy,
        ),
      );
    });

    testWidgets('formats hidden tool-call counts using the active locale', (
      tester,
    ) async {
      final toolCalls = List.generate(
        1002,
        (index) => MessageToolCallEntity(
          id: 'tc-$index',
          name: 'built_in_1_read_file',
          argumentsRaw: '{}',
          resultStatus: ToolCallResultStatus.success,
        ),
      );
      final message = _createMessage(
        content: 'Final answer',
        isUser: false,
        metadata: MessageMetadataEntity(
          thinking: 'Need to inspect the file first',
          toolCalls: toolCalls,
        ),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          locale: const Locale('es'),
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );
      final traceToggle = find.byKey(
        const ValueKey('activity_trace_toggle_msg-1'),
      );
      await tester.tap(traceToggle);
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('activity_tool_list_toggle_msg-1')),
      );

      expect(find.textContaining('+1.000'), findsOneWidget);
    });

    testWidgets('flushes tool activity at timeline boundaries', (tester) async {
      const firstTool = MessageToolCallEntity(
        id: 'boundary-tool-1',
        name: 'built_in_1_read_file',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.success,
      );
      const secondTool = MessageToolCallEntity(
        id: 'boundary-tool-2',
        name: 'built_in_1_calculator',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.success,
      );

      Future<void> pumpBoundary({
        required String boundaryId,
        required MessageEntity? boundary,
      }) async {
        final messagesById = <String, MessageEntity?>{
          'before': _createMessage(
            id: 'before',
            content: '',
            isUser: false,
            metadata: const MessageMetadataEntity(
              toolCalls: [firstTool, secondTool],
            ),
          ),
          'after': _createMessage(
            id: 'after',
            content: '',
            isUser: false,
            metadata: const MessageMetadataEntity(
              toolCalls: [firstTool, secondTool],
            ),
          ),
          if (boundary != null) boundaryId: boundary,
        };
        await pumpAndInit(
          tester,
          buildSubject(
            messages: ['before', boundaryId, 'after'],
            overrides: [
              messageConversationByIdProvider.overrideWith(
                (ref, id) => messagesById[id.messageId],
              ),
              isMessageStreamingProvider.overrideWith((ref, id) => false),
              conversationBusyStateProvider.overrideWith(
                (ref, _) async => const ConversationBusyState(
                  isStreaming: false,
                  hasPendingTools: false,
                ),
              ),
            ],
          ),
        );

        expect(
          find.byKey(const ValueKey('activity_tool_list_toggle_before')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('activity_tool_list_toggle_after')),
          findsOneWidget,
        );
      }

      await pumpBoundary(
        boundaryId: 'user-boundary',
        boundary: _createMessage(id: 'user-boundary', content: 'User'),
      );
      await pumpBoundary(
        boundaryId: 'system-boundary',
        boundary: _createMessage(
          id: 'system-boundary',
          content: 'System',
          isUser: false,
          messageType: MessageType.system,
        ),
      );
      await pumpBoundary(
        boundaryId: 'error-boundary',
        boundary: _createMessage(
          id: 'error-boundary',
          content: 'compaction.errors.compaction_failed',
          isUser: false,
          status: MessageStatus.error,
          messageType: MessageType.system,
        ),
      );
      await pumpBoundary(
        boundaryId: 'compaction-boundary',
        boundary: _createMessage(
          id: 'compaction-boundary',
          content: 'Summary',
          isUser: false,
          metadata: const MessageMetadataEntity(
            isCompactionSummary: true,
            compactionKind: CompactionKind.auto,
          ),
        ),
      );
      await pumpBoundary(boundaryId: 'missing-boundary', boundary: null);
    });

    testWidgets(
      'reopens a stable live run for an appended tool and collapses on completion',
      (tester) async {
        const firstToolCall = MessageToolCallEntity(
          id: 'tc-1',
          name: 'built_in_1_read_file',
          argumentsRaw: '{"path": "first running detail"}',
          resultStatus: ToolCallResultStatus.running,
        );
        const secondToolCall = MessageToolCallEntity(
          id: 'tc-2',
          name: 'built_in_1_calculator',
          argumentsRaw: '{"expression": "second running detail"}',
          resultStatus: ToolCallResultStatus.running,
        );
        final initialMessage = _createMessage(
          id: 'msg-1',
          content: '',
          isUser: false,
          status: MessageStatus.unfinished,
          metadata: const MessageMetadataEntity(
            thinking: 'First live work',
            toolCalls: [firstToolCall],
          ),
        );
        final secondToolMessage = _createMessage(
          id: 'msg-2',
          content: '',
          isUser: false,
          status: MessageStatus.unfinished,
          metadata: const MessageMetadataEntity(toolCalls: [secondToolCall]),
        );
        final completedFirstMessage = _createMessage(
          id: 'msg-1',
          content: '',
          isUser: false,
          metadata: const MessageMetadataEntity(
            thinking: 'First live work',
            toolCalls: [
              MessageToolCallEntity(
                id: 'tc-1',
                name: 'built_in_1_read_file',
                argumentsRaw: '{"path": "first running detail"}',
                resultStatus: ToolCallResultStatus.success,
              ),
            ],
          ),
        );
        final completedSecondMessage = _createMessage(
          id: 'msg-2',
          content: '',
          isUser: false,
          metadata: const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'tc-2',
                name: 'built_in_1_calculator',
                argumentsRaw: '{"expression": "second running detail"}',
                resultStatus: ToolCallResultStatus.success,
              ),
            ],
          ),
        );
        final messageUpdates =
            StreamController<Map<String, MessageEntity>>.broadcast();
        final streamingUpdates = StreamController<bool>.broadcast();
        addTearDown(messageUpdates.close);
        addTearDown(streamingUpdates.close);
        final messageProvider = StreamProvider<Map<String, MessageEntity>>(
          (ref) => messageUpdates.stream,
        );
        final streamingProvider = StreamProvider<bool>(
          (ref) => streamingUpdates.stream,
        );
        var messageIds = <String>['msg-1'];
        late StateSetter updateMessages;

        await pumpAndInit(
          tester,
          StatefulBuilder(
            builder: (context, setState) {
              updateMessages = setState;
              return buildSubject(
                messages: messageIds,
                overrides: [
                  messageConversationByIdProvider.overrideWith(
                    (ref, id) =>
                        ref.watch(messageProvider).value?[id.messageId] ??
                        (id.messageId == 'msg-1' ? initialMessage : null),
                  ),
                  isMessageStreamingProvider.overrideWith(
                    (ref, id) => ref.watch(streamingProvider).value ?? true,
                  ),
                  conversationBusyStateProvider.overrideWith(
                    (ref, _) async => const ConversationBusyState(
                      isStreaming: true,
                      hasPendingTools: true,
                    ),
                  ),
                ],
              );
            },
          ),
        );

        expect(find.text('1 tool'), findsOneWidget);
        expect(find.text('First live work'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('activity_tool_tc-1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('activity_tool_details_tc-1')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey('activity_trace_toggle_msg-1')),
        );
        await tester.pump();
        expect(find.byKey(const ValueKey('activity_tool_tc-1')), findsNothing);

        messageIds = ['msg-1', 'msg-2'];
        updateMessages(() {});
        messageUpdates.add({
          'msg-1': initialMessage,
          'msg-2': secondToolMessage,
        });
        await tester.pump();
        await tester.pump();

        expect(find.text('2 tools'), findsOneWidget);
        expect(find.text('First live work'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('activity_tool_list_toggle_msg-1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('activity_tool_tc-2')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('activity_tool_details_tc-2')),
          findsOneWidget,
        );

        messageUpdates.add({
          'msg-1': completedFirstMessage,
          'msg-2': completedSecondMessage,
        });
        streamingUpdates.add(false);
        await tester.pump();
        await tester.pump();
        await tester.pump();

        expect(
          find.byKey(const ValueKey('activity_trace_toggle_msg-1')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('activity_tool_tc-1')), findsNothing);
        expect(find.byKey(const ValueKey('activity_tool_tc-2')), findsNothing);
        expect(
          find.byKey(const ValueKey('activity_tool_details_tc-2')),
          findsNothing,
        );
        expect(find.text('2 tools'), findsOneWidget);
      },
    );

    testWidgets('opens a sub-agent run without replacing the main chat', (
      tester,
    ) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'run_sub_agent',
        argumentsRaw: '{"title": "Child agent"}',
        responseRaw: '{"conversationId": "child-1"}',
        resultStatus: ToolCallResultStatus.success,
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
      );
      Widget? mainChat;
      final router = GoRouter(
        initialLocation: '/workspaces/ws-1/chats/conv-1',
        routes: [
          GoRoute(
            path: '/workspaces/:workspaceId/chats/:chatId',
            builder: (_, _) => mainChat ?? const SizedBox.shrink(),
            routes: [
              GoRoute(
                path: 'sub-agents/:subAgentConversationId',
                builder: (_, _) =>
                    const Material(child: Center(child: Text('Sub-agent run'))),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          messageEntitiesById: {message.id: message},
          conversation: ConversationEntity(
            id: 'conv-1',
            title: 'Chat',
            workspaceId: 'ws-1',
            isPinned: false,
            createdAt: DateTime(2025),
            updatedAt: DateTime(2025),
          ),
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
          appBuilder: (context, child) {
            mainChat = ChatPrimaryScrollController(child: child);

            return MaterialApp.router(
              routerConfig: router,
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
            );
          },
        ),
      );

      await revealActivityToolCalls(tester);

      expect(
        find.byKey(const ValueKey('activity_open_sub_agent_tc-1')),
        findsOneWidget,
      );

      final toolRow = find.byKey(const ValueKey('activity_tool_tc-1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.ensureVisible(toolRow);
      await tester.tap(toolRow);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('activity_tool_details_tc-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('activity_open_sub_agent_tc-1')),
        findsOneWidget,
      );

      expect(find.text('View run'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('activity_open_sub_agent_tc-1')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sub-agent run'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();

      expect(find.text('View run'), findsOneWidget);
    });

    testWidgets('renders failed sub-agent calls as errors with child ID', (
      tester,
    ) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'run_sub_agent',
        argumentsRaw: '{"title": "Failed child"}',
        responseRaw:
            '{"conversationId":"child-failed","status":"error",'
            '"content":"Sub-agent failed."}',
        resultStatus: ToolCallResultStatus.executionError,
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      await revealActivityToolCalls(tester);

      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
      expect(find.text('Execution failed'), findsOneWidget);
      expect(find.text('Completed'), findsNothing);
      expect(
        find.byKey(const ValueKey('activity_open_sub_agent_tc-1')),
        findsOneWidget,
      );
    });

    testWidgets('keeps a thinking card and one tool under the tool count', (
      tester,
    ) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'built_in_1_read_file',
        argumentsRaw: '{"input": "test.txt"}',
        resultStatus: ToolCallResultStatus.success,
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(
          toolCalls: [toolCall],
          thinking: 'Need to inspect the file first',
        ),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.text('1 tool'), findsOneWidget);
      expect(find.text('Need to inspect the file first'), findsNothing);
      expect(find.byType(AuraMessageBubble), findsNothing);

      await revealActivityToolCalls(tester);

      expect(find.text('Need to inspect the file first'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byKey(const ValueKey('activity_tool_tc-1')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('activity_tool_list_toggle_msg-1')),
        findsNothing,
      );
    });

    testWidgets('renders multiple messages', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1', 'msg-2'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, key) => _createMessage(
                id: key.messageId,
                content: 'Message ${key.messageId}',
                isUser: key.messageId == 'msg-1',
              ),
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.text('Message msg-1'), findsOneWidget);
      expect(find.text('Message msg-2'), findsOneWidget);
    });

    testWidgets('renders AI message without content but with tool calls', (
      tester,
    ) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'built_in_1_calculator',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.executionError,
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      await revealActivityToolCalls(tester);

      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
      expect(find.byIcon(Icons.copy_outlined), findsNothing);
    });

    testWidgets('renders unresolved tool call awaiting approval', (
      tester,
    ) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'built_in_1_calculator',
        argumentsRaw: '{}',
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: true,
              ),
            ),
          ],
          pendingToolCalls: const [
            PendingToolCall(toolCall: toolCall, messageId: 'msg-1'),
          ],
        ),
      );

      expect(find.text('Awaiting confirmation'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
      expect(find.byType(AuraMessageBubble), findsNothing);
    });

    testWidgets(
      'renders unresolved tool call as pending without approval projection',
      (tester) async {
        const toolCall = MessageToolCallEntity(
          id: 'tc-1',
          name: 'built_in_1_calculator',
          argumentsRaw: '{}',
        );
        final message = _createMessage(
          content: '',
          isUser: false,
          metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
        );

        await pumpAndInit(
          tester,
          buildSubject(
            messages: ['msg-1'],
            overrides: [
              messageConversationByIdProvider.overrideWith(
                (ref, id) => message,
              ),
              isMessageStreamingProvider.overrideWith((ref, id) => false),
              conversationBusyStateProvider.overrideWith(
                (ref, _) async => const ConversationBusyState(
                  isStreaming: false,
                  hasPendingTools: true,
                ),
              ),
            ],
          ),
        );

        expect(find.text('Awaiting confirmation'), findsOneWidget);
        expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
        expect(find.byType(AuraMessageBubble), findsNothing);
      },
    );

    testWidgets('renders tool call with skipped status', (tester) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'built_in_1_calculator',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.skippedByUser,
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      await revealActivityToolCalls(tester);

      expect(find.byIcon(Icons.skip_next), findsOneWidget);
    });

    testWidgets('renders tool call with stopped status', (tester) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'built_in_1_calculator',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.stoppedByUser,
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      await revealActivityToolCalls(tester);

      expect(find.byIcon(Icons.stop_circle_outlined), findsOneWidget);
    });

    testWidgets('keeps stopped sub-agent navigation with child ID', (
      tester,
    ) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'run_sub_agent',
        argumentsRaw: '{"title": "Stopped child"}',
        responseRaw:
            '{"conversationId":"child-stopped","status":"stopped",'
            '"content":"Sub-agent stopped."}',
        resultStatus: ToolCallResultStatus.stoppedByUser,
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      await revealActivityToolCalls(tester);

      expect(find.byIcon(Icons.stop_circle_outlined), findsOneWidget);
      expect(
        find.byKey(const ValueKey('activity_open_sub_agent_tc-1')),
        findsOneWidget,
      );
    });

    testWidgets('renders tool call with tool not found status', (tester) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'built_in_1_calculator',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.toolNotFound,
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      await revealActivityToolCalls(tester);

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders tool call with not configured status', (tester) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'built_in_1_calculator',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.notConfigured,
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      await revealActivityToolCalls(tester);

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('renders message with sending status', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => _createMessage(
                content: 'Sending...',
                status: MessageStatus.sending,
              ),
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.text('Sending...'), findsOneWidget);
    });

    testWidgets('renders message with error status', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => _createMessage(
                content: 'Error msg',
                isUser: false,
                status: MessageStatus.error,
              ),
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.text('Error msg'), findsOneWidget);
    });

    testWidgets('renders tool call with disabled in workspace status', (
      tester,
    ) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'built_in_1_calculator',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.disabledInWorkspace,
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      await revealActivityToolCalls(tester);

      expect(find.byIcon(Icons.block), findsOneWidget);
    });

    testWidgets('renders compacting indicator when compaction is running', (
      tester,
    ) async {
      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            conversationCompactionExecutionStateProvider.overrideWithValue(
              CompactionExecutionState(
                conversationId: 'conv-1',
                trigger: CompactionTrigger.auto,
                startedAt: DateTime(2025),
                status: CompactionExecutionStatus.running,
              ),
            ),
            messageConversationByIdProvider.overrideWith(
              (ref, id) => _createMessage(),
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.byType(AuraSpinner), findsOneWidget);
      expect(find.text('Compacting...'), findsOneWidget);
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('renders compacted message widget for compaction summary', (
      tester,
    ) async {
      final message = _createMessage(
        content: 'Summary of older messages',
        isUser: false,
        metadata: const MessageMetadataEntity(
          isCompactionSummary: true,
          compactionKind: CompactionKind.auto,
          compactedFromMessageId: 'old-1',
          compactedThroughMessageId: 'old-2',
          compactedMessageIds: ['old-1', 'old-2'],
        ),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.byIcon(Icons.compress_outlined), findsOneWidget);
      expect(find.text('Automatic'), findsOneWidget);
      expect(find.text('Summary of older messages'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.info_outline));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Compaction Details'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Compaction Details'), findsNothing);
      expect(find.text('Summary of older messages'), findsOneWidget);
    });

    testWidgets('renders error widget for non-user system error message', (
      tester,
    ) async {
      final message = _createMessage(
        content: 'compaction.errors.compaction_failed',
        isUser: false,
        status: MessageStatus.error,
        messageType: MessageType.system,
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders provider error details without localization', (
      tester,
    ) async {
      const providerDetails =
          '{"headers":{"x-api-key":"fixture-provider-credential",'
          '"Authorization":"Basic fixture-auth-secret"},'
          '"reason":"Quota exceeded"}';
      const safeDetails =
          '{"headers":{"x-api-key":"[REDACTED]",'
          '"Authorization":"[REDACTED]"},'
          '"reason":"Quota exceeded"}';
      String? copiedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText = (call.arguments as Map)['text'] as String?;
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
      final message = _createMessage(
        content: providerDetails,
        isUser: false,
        status: MessageStatus.error,
        messageType: MessageType.system,
        metadata: const MessageMetadataEntity(
          modelMetadata: {'providerError': true},
        ),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref, _) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.text(safeDetails), findsOneWidget);
      expect(find.text(providerDetails), findsNothing);
      expect(find.byType(AuraSelectableText), findsOneWidget);
      final selectable = tester.widget<AuraSelectableText>(
        find.byType(AuraSelectableText),
      );
      expect(selectable.data, safeDetails);
      expect(find.byIcon(Icons.copy_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.copy_outlined));
      await tester.pump();

      expect(copiedText, safeDetails);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}

class _MockConversationRepository extends Mock
    implements ConversationRepository;

class const _ChatMessagesTestSubject({
  required final String conversationId,
  required final List<String> messages,
  required final List<Object> overrides,
  required final List<PendingToolCall> pendingToolCalls,
  final Map<String, MessageEntity>? messageEntitiesById,
  final bool showThinking = false,
  final Future<void> Function(MessageEntity message)? onRetryMessage,
  final ConversationEntity? conversation,
  final AuraTheme? theme,
  final Locale locale = const Locale('en'),
  final Widget Function(BuildContext context, Widget child)? appBuilder,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final conversationRepository = _MockConversationRepository();
    when(() => conversationRepository.watchConversationById(conversationId))
        .thenAnswer((_) => Stream.value(conversation));
    when(() => conversationRepository.watchChildConversations(conversationId))
        .thenAnswer((_) => Stream.value(const []));

    return TestProviderScope(
      overrides: [
        conversationSelectedProvider.overrideWithValue(conversationId),
        conversationRepositoryProvider.overrideWithValue(
          conversationRepository,
        ),
        pendingToolCallsProvider.overrideWith((ref, _) => pendingToolCalls),
        workspaceSessionForRouteProvider('ws-1').overrideWithValue(
          const AsyncData(
            WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'ws-1')),
          ),
        ),
        ...overrides.cast(),
      ],
      child: EasyLocalization(
        child: Builder(
          builder: (context) {
            final child = AuraThemeScope(
              theme: theme ?? AuraTheme.light,
              child: Theme(
                data: ThemeData(),
                child: AuraLegacyMaterialBridge(
                  child: Material(
                    child: ChatMessagesWidget(
                      workspaceId: 'ws-1',
                      conversationId: conversationId,
                      messages: messages,
                      messageEntitiesById: messageEntitiesById,
                      pendingToolCalls: pendingToolCalls,
                      showThinking: showThinking,
                      onRetryMessage: onRetryMessage,
                    ),
                  ),
                ),
              ),
            );

            return appBuilder?.call(context, child) ??
                MaterialApp(
                  home: ChatPrimaryScrollController(child: child),
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
        supportedLocales: const [Locale('en'), Locale('es')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: locale,
        useOnlyLangCode: true,
        useFallbackTranslations: true,
      ),
    );
  }
}
