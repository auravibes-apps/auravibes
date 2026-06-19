// ignore_for_file: provider_dependencies
// Required: widget tests override scoped providers directly.
// Required: Tests repeat finders and fixture lookups for clarity.

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/widgets/chat_tool_approval_card.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([pendingToolCalls])
void main() {
  @Dependencies([pendingToolCalls])
  Widget buildSubject({
    required List<Object> overrides,
  }) {
    return EasyLocalization(
      child: ProviderScope(
        overrides: overrides.cast(),
        child: Builder(
          builder: (context) {
            return MaterialApp(
              home: Theme(
                data: ThemeData(extensions: [AuraTheme.light]),
                child: const Material(
                  child: ChatToolApprovalCard(),
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
  }) {
    return PendingToolCall(
      toolCall: MessageToolCallEntity(
        id: toolCallId,
        name: toolName,
        argumentsRaw: '{"input": "test.txt"}',
      ),
      messageId: messageId,
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
    testWidgets('renders SizedBox.shrink when no pending calls', (
      tester,
    ) async {
      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith((ref) => []),
          ],
        ),
      );

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      expect(
        sizedBoxes.any((box) => box.width == 0 && box.height == 0),
        isTrue,
      );
    });

    testWidgets('renders approval card when pending calls exist', (
      tester,
    ) async {
      final pendingCalls = [_createPendingToolCall()];
      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith((ref) => pendingCalls),
          ],
        ),
      );

      expect(find.byIcon(Icons.build_outlined), findsOneWidget);
    });

    testWidgets('shows navigation chevrons for multiple pending calls', (
      tester,
    ) async {
      final pendingCalls = [
        _createPendingToolCall(),
        _createPendingToolCall(toolCallId: 'tc-2'),
      ];
      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith((ref) => pendingCalls),
          ],
        ),
      );

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('shows formatted tool display name', (tester) async {
      final pendingCalls = [
        _createPendingToolCall(),
      ];
      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith((ref) => pendingCalls),
          ],
        ),
      );

      expect(find.text('Read File'), findsOneWidget);
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
            pendingToolCallsProvider.overrideWith((ref) => pendingCalls),
          ],
        ),
      );

      expect(find.textContaining('query'), findsOneWidget);
    });

    testWidgets('shows URL request summary from native tool input', (
      tester,
    ) async {
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
            pendingToolCallsProvider.overrideWith((ref) => pendingCalls),
          ],
        ),
      );

      expect(find.textContaining('"method": "POST"'), findsOneWidget);
      expect(find.textContaining('"host": "example.com"'), findsOneWidget);
      expect(find.textContaining('"path": "/api/items"'), findsOneWidget);
      expect(find.textContaining('Authorization'), findsNothing);
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
            pendingToolCallsProvider.overrideWith((ref) => pendingCalls),
          ],
        ),
      );

      expect(find.textContaining('secret-token'), findsNothing);
      expect(find.textContaining('secret-key'), findsNothing);
      expect(find.textContaining('****'), findsOneWidget);
      expect(find.textContaining('visible'), findsOneWidget);
    });

    testWidgets('renders confirmation buttons', (tester) async {
      final pendingCalls = [_createPendingToolCall()];
      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith((ref) => pendingCalls),
          ],
        ),
      );

      expect(find.text('Allow Once'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Stop All'), findsOneWidget);
    });

    testWidgets('renders SizedBox.shrink when async has error', (
      tester,
    ) async {
      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith(
              (ref) => throw Exception('fail'),
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

    testWidgets('shows Allow for Conversation button', (tester) async {
      final pendingCalls = [_createPendingToolCall()];
      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith((ref) => pendingCalls),
          ],
        ),
      );

      expect(find.text('Allow for Conversation'), findsOneWidget);
    });

    testWidgets('navigates to next pending call on chevron right', (
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
            pendingToolCallsProvider.overrideWith((ref) => pendingCalls),
          ],
        ),
      );

      expect(find.text('Read File'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('navigates to previous pending call on chevron left', (
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
            pendingToolCallsProvider.overrideWith((ref) => pendingCalls),
          ],
        ),
      );

      await tester.tap(find.byIcon(Icons.chevron_right));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Search'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Read File'), findsOneWidget);
    });

    testWidgets('shows pending count text', (tester) async {
      final pendingCalls = [
        _createPendingToolCall(),
        _createPendingToolCall(toolCallId: 'tc-2'),
      ];
      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith((ref) => pendingCalls),
          ],
        ),
      );

      expect(find.textContaining('1'), findsOneWidget);
      expect(find.textContaining('2'), findsOneWidget);
    });

    testWidgets('shows SizedBox.shrink when pending calls empty list', (
      tester,
    ) async {
      await pumpAndInit(
        tester,
        buildSubject(
          overrides: [
            pendingToolCallsProvider.overrideWith((ref) => <PendingToolCall>[]),
          ],
        ),
      );

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      expect(
        sizedBoxes.any((box) => box.width == 0 && box.height == 0),
        isTrue,
      );
    });
  });
}
