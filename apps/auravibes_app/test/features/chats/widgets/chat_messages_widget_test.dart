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
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/notifiers/chat_a2ui_runtime.dart';
import 'package:auravibes_app/features/chats/providers/chat_a2ui_runtime_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/chats/widgets/chat_a2ui_surface_host.dart';
import 'package:auravibes_app/features/chats/widgets/chat_messages_widget.dart';
import 'package:auravibes_app/features/chats/widgets/chat_thinking_indicator.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/utils/relative_time_formatter.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart' show DataPath;
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
  ConversationEntity? conversation,
  AuraTheme? theme,
}) {
  return _ChatMessagesTestSubject(
    conversationId: conversationId,
    messages: messages,
    overrides: overrides,
    pendingToolCalls: pendingToolCalls,
    showThinking: showThinking,
    messageEntitiesById: messageEntitiesById,
    conversation: conversation,
    theme: theme,
  );
}

void main() {
  MessageEntity _createMessage({
    String id = 'msg-1',
    String content = 'Hello',
    bool isUser = true,
    MessageStatus status = MessageStatus.sent,
    MessageMetadataEntity? metadata,
    MessageType messageType = MessageType.text,
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
    );
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
    String content = '',
  }) async {
    final runtime = ChatA2uiRuntime(conversationId: 'conv-1');
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
        ],
      ),
    );
    final _ = await tester.pumpAndSettle();
    expect(runtime.hasSurfaceIssue(message.id), isFalse);
    expect(tester.takeException(), isNull);
    return (runtime: runtime, copies: copies);
  }

  group('ChatMessagesWidget', () {
    testWidgets('copies the second form edit while excluding password values', (
      tester,
    ) async {
      final result = await pumpCopySurface(tester, [
        {
          'id': 'root',
          'component': 'Column',
          'children': ['name', 'password'],
        },
        {
          'id': 'name',
          'component': 'TextField',
          'label': 'Name',
          'value': {'path': '/name'},
        },
        {
          'id': 'password',
          'component': 'TextField',
          'variant': 'password',
          'label': 'Password',
          'value': {'path': '/password'},
        },
      ], form: true);
      final fields = find.byType(EditableText);
      expect(fields, findsNWidgets(2));
      expect(tester.widget<EditableText>(fields.at(1)).obscureText, isTrue);
      await tester.enterText(fields.first, 'Ada');
      await tester.enterText(fields.at(1), 'first-test-secret');
      await tester.pump();
      await tester.enterText(fields.first, 'Grace');
      await tester.enterText(fields.at(1), 'second-test-secret');
      await tester.pump();
      await tester.tap(find.byTooltip('Copy message'));
      await tester.pump();

      expect(result.copies, ['Name\nGrace\nPassword']);
      expect(find.byTooltip('Message copied'), findsOneWidget);
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
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'built_in_1_read_file',
        argumentsRaw: '{"input": "test.txt"}',
        responseRaw: 'tool output',
        resultStatus: ToolCallResultStatus.success,
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
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => _createMessage(
                content: 'Hello AI',
                isUser: false,
                metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
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
      expect(find.text('Final answer'), findsOneWidget);
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
      final toolBefore = tester.getTopLeft(toolRow).dy;

      await tester.tap(toolRow);
      await tester.pump();
      expect(tester.getTopLeft(toolRow).dy, closeTo(toolBefore, 1));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      final toolRowBottom = tester.getRect(toolRow).bottom;
      expect(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('activity_tool_details_tc-scroll')),
            )
            .dy,
        greaterThanOrEqualTo(toolRowBottom),
      );

      await tester.tap(toolRow);
      await tester.pump();
      expect(tester.getTopLeft(toolRow).dy, closeTo(toolBefore, 1));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.getTopLeft(toolRow).dy, closeTo(toolBefore, 1));

      await tester.tap(activityToggle);
      await tester.pump();
      expect(tester.getTopLeft(activityToggle).dy, closeTo(before, 1));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.getTopLeft(activityToggle).dy, closeTo(before, 1));
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
        content: 'Final answer',
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

    testWidgets(
      'groups adjacent activity-only assistant messages into one run',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 500));
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
          'msg-1': _createMessage(
            id: 'msg-1',
            content: '',
            isUser: false,
            metadata: const MessageMetadataEntity(
              thinking: 'First activity thought',
              toolCalls: [firstTool],
            ),
          ),
          'msg-2': _createMessage(
            id: 'msg-2',
            content: '',
            isUser: false,
            metadata: const MessageMetadataEntity(
              thinking: 'Second activity thought',
              toolCalls: [secondTool, thirdTool],
            ),
          ),
        };

        await pumpAndInit(
          tester,
          buildSubject(
            messages: [...olderMessages.keys, 'msg-1', 'msg-2'],
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
        expect(find.text('First activity thought'), findsNothing);
        expect(find.text('Second activity thought'), findsNothing);

        final activityToggle = find.byKey(
          const ValueKey('activity_trace_toggle_msg-1'),
        );
        final activityBefore = tester.getTopLeft(activityToggle).dy;
        await tester.tap(activityToggle);
        await tester.pump();
        expect(
          tester.getTopLeft(activityToggle).dy,
          closeTo(activityBefore, 1),
        );

        expect(find.text('First activity thought'), findsOneWidget);
        expect(find.text('Second activity thought'), findsOneWidget);
        expect(
          tester.getTopLeft(find.text('First activity thought')).dy,
          lessThan(tester.getTopLeft(find.text('Second activity thought')).dy),
        );
        expect(
          find.byKey(const ValueKey('activity_tool_list_toggle_msg-1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('activity_tool_list_toggle_msg-2')),
          findsNothing,
        );

        final toolSummary = tester.widget<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('activity_tool_list_toggle_msg-1')),
            matching: find.byType(Text),
          ),
        );
        expect(toolSummary.data, contains('+1'));
        expect(toolSummary.maxLines, 1);
        expect(toolSummary.overflow, TextOverflow.ellipsis);

        final toolToggle = find.byKey(
          const ValueKey('activity_tool_list_toggle_msg-1'),
        );
        await tester.ensureVisible(toolToggle);
        await tester.pump();
        final toolBefore = tester.getTopLeft(toolToggle).dy;
        await tester.tap(toolToggle);
        await tester.pump();
        expect(tester.getTopLeft(toolToggle).dy, closeTo(toolBefore, 1));
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.getTopLeft(toolToggle).dy, closeTo(toolBefore, 1));

        expect(
          find.byKey(const ValueKey('activity_tool_tc-1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('activity_tool_tc-2')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('activity_tool_tc-3')),
          findsOneWidget,
        );

        await tester.tap(toolToggle);
        await tester.pump();
        expect(tester.getTopLeft(toolToggle).dy, closeTo(toolBefore, 1));
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.getTopLeft(toolToggle).dy, closeTo(toolBefore, 1));

        await tester.tap(toolToggle);
        await tester.pump();

        final toolRow = find.byKey(const ValueKey('activity_tool_tc-1'));
        await tester.ensureVisible(toolRow);
        await tester.pump();
        final toolRowBefore = tester.getTopLeft(toolRow).dy;
        await tester.tap(toolRow);
        await tester.pump();
        expect(tester.getTopLeft(toolRow).dy, closeTo(toolRowBefore, 1));
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.getTopLeft(toolRow).dy, closeTo(toolRowBefore, 1));

        await tester.tap(toolRow);
        await tester.pump();
        expect(tester.getTopLeft(toolRow).dy, closeTo(toolRowBefore, 1));
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.getTopLeft(toolRow).dy, closeTo(toolRowBefore, 1));
      },
    );

    testWidgets('folds interim assistant progress into the activity run', (
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
      const finalTool = MessageToolCallEntity(
        id: 'tc-final',
        name: 'built_in_1_read_file',
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
            toolCalls: [finalTool],
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
      expect(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('activity_trace_toggle_opening')),
            )
            .dy,
        lessThan(tester.getTopLeft(find.text('Final answer')).dy),
      );
    });

    testWidgets('splits user boundaries and folds trailing response activity', (
      tester,
    ) async {
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
      expect(find.text('Visible answer'), findsOneWidget);
      expect(find.text('Before visible answer'), findsNothing);
      expect(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('activity_trace_toggle_msg-3')),
            )
            .dy,
        lessThan(tester.getTopLeft(find.text('Visible answer')).dy),
      );

      await tester.tap(
        find.byKey(const ValueKey('activity_trace_toggle_msg-1')),
      );
      await tester.pump();

      expect(find.text('Before user one'), findsOneWidget);
      expect(find.text('Before user two'), findsOneWidget);
      expect(find.text('After user'), findsNothing);
      expect(find.text('Before visible answer'), findsNothing);

      tester
          .widget<AuraPressable>(
            find.descendant(
              of: find.byKey(const ValueKey('activity_trace_toggle_msg-3')),
              matching: find.byType(AuraPressable),
            ),
          )
          .onPressed!
          .call();
      await tester.pump();

      expect(find.text('After user'), findsOneWidget);
      expect(find.text('Before visible answer'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('activity_tool_list_toggle_msg-3')),
        findsOneWidget,
      );
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
          metadata: const MessageMetadataEntity(
            thinking: 'Second live work',
            toolCalls: [secondToolCall],
          ),
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
            thinking: 'Second live work',
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
        expect(find.text('Second live work'), findsOneWidget);
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

    testWidgets('keeps sub-agent navigation beside inline tool details', (
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
  final ConversationEntity? conversation,
  final AuraTheme? theme,
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
            return MaterialApp(
              home: Theme(
                data: ThemeData(extensions: [theme ?? AuraTheme.light]),
                child: Material(
                  child: ChatMessagesWidget(
                    workspaceId: 'ws-1',
                    conversationId: conversationId,
                    messages: messages,
                    messageEntitiesById: messageEntitiesById,
                    pendingToolCalls: pendingToolCalls,
                    showThinking: showThinking,
                  ),
                ),
              ),
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
      ),
    );
  }
}
