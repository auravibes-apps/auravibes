import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation_message_search_result.dart';
import 'package:auravibes_app/features/chats/providers/conversation_message_search_provider.dart';
import 'package:auravibes_app/features/chats/screens/conversation_message_search_screen.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

const _dotCodePoint = 0x00B7;
const _ellipsisCodePoint = 0x2026;
const _expectedRetryAttempts = 2;
const _viewportSize = Size(466, 678);
final _dot = String.fromCharCode(_dotCodePoint);
final _ellipsis = String.fromCharCode(_ellipsisCodePoint);

final _firstSampleResult = ConversationMessageSearchResult(
  workspaceId: 'local',
  workspaceName: 'Design studio',
  conversationId: 'conv-1',
  conversationTitle: 'Q4 product launch',
  messageId: 'msg-1',
  role: 'user',
  createdAt: .utc(2026, 9, 30, 14, 30),
  excerpt:
      'Draft the release notes for the mobile and desktop workspace update.',
);

final _sampleResults = <ConversationMessageSearchResult>[
  _firstSampleResult,
  ConversationMessageSearchResult(
    workspaceId: 'local',
    workspaceName: 'Design studio',
    conversationId: 'conv-2',
    conversationTitle: '',
    messageId: 'msg-2',
    role: 'assistant',
    createdAt: .utc(2026, 9, 29, 9, 15),
    excerpt:
        'Here is a concise release notes summary covering theme and search '
        'improvements.',
  ),
];

void main() {
  testWidgets(
    'renders excerpt-first results, error callout recovery, and clear action',
    _testResultHierarchyAndClear,
  );
  testWidgets(
    'shows workspace name in All workspaces scope and retries after failure',
    _testAllWorkspacesAndRetry,
  );
  testWidgets(
    'shows localized loading status while searching',
    _testLoadingStatus,
  );
}

void _configureTestViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = _viewportSize;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _testResultHierarchyAndClear(WidgetTester tester) async {
  _configureTestViewport(tester);
  final _ = await tester.runAsync(
    () => tester.pumpWidget(
      TestableApp(
        child: const ConversationMessageSearchScreen(workspaceId: 'local'),
        overrides: [
          conversationMessageSearchPageProvider.overrideWith(
            (ref, request) async =>
                (results: _sampleResults, hasMore: true, hasError: true),
          ),
        ],
        workspaceId: 'local',
      ),
    ),
  );
  final _ = await tester.pumpAndSettle();

  final submitFinder = find.byKey(const ValueKey('conversation-search-submit'));
  expect(tester.widget<AuraButton>(submitFinder).disabled, isTrue);
  expect(find.text('0/256'), findsNothing);

  await tester.enterText(find.byType(EditableText).first, 'release notes');
  await tester.pump();
  expect(tester.widget<AuraButton>(submitFinder).disabled, isFalse);

  await tester.testTextInput.receiveAction(.search);
  final _ = await tester.pumpAndSettle();

  expect(
    find.text(
      'Draft the release notes for the mobile and desktop workspace update.',
    ),
    findsOneWidget,
  );
  expect(find.text('Q4 product launch'), findsOneWidget);
  expect(find.text('Untitled conversation'), findsOneWidget);
  expect(find.textContaining('You $_dot '), findsOneWidget);
  expect(find.textContaining('Assistant $_dot '), findsOneWidget);
  expect(find.textContaining('Design studio $_dot '), findsNothing);
  expect(
    find.byIcon(Icons.chevron_right),
    findsNWidgets(_sampleResults.length),
  );
  expect(find.byType(AuraCallout), findsOneWidget);
  expect(find.text('Retry'), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('conversation-search-clear')));
  final _ = await tester.pumpAndSettle();

  expect(find.text('Q4 product launch'), findsNothing);
  expect(tester.widget<AuraButton>(submitFinder).disabled, isTrue);
  expect(tester.takeException(), isNull);
}

Future<void> _testAllWorkspacesAndRetry(WidgetTester tester) async {
  _configureTestViewport(tester);
  var attempts = 0;
  final _ = await tester.runAsync(
    () => tester.pumpWidget(
      TestableApp(
        child: const ConversationMessageSearchScreen(workspaceId: 'local'),
        overrides: [
          conversationMessageSearchPageProvider.overrideWith((
            ref,
            request,
          ) async {
            attempts++;
            if (attempts == 1) {
              throw StateError('Search failed');
            }

            return (
              results: [_firstSampleResult],
              hasMore: false,
              hasError: false,
            );
          }),
        ],
        workspaceId: 'local',
      ),
    ),
  );
  final _ = await tester.pumpAndSettle();

  await tester.enterText(find.byType(EditableText).first, 'release');
  await tester.pump();
  await tester.tap(find.text('All workspaces'));
  final _ = await tester.pumpAndSettle();

  expect(attempts, 1);
  expect(find.byType(AuraCallout), findsOneWidget);
  expect(find.text('Could not search messages. Try again.'), findsOneWidget);

  await tester.tap(find.text('Retry'));
  final _ = await tester.pumpAndSettle();

  expect(attempts, _expectedRetryAttempts);
  expect(find.byType(AuraCallout), findsNothing);
  expect(find.textContaining('Design studio $_dot You $_dot '), findsOneWidget);
  expect(tester.takeException(), isNull);
}

Future<void> _testLoadingStatus(WidgetTester tester) async {
  _configureTestViewport(tester);
  final completer = Completer<ConversationMessageSearchPage>();
  final _ = await tester.runAsync(
    () => tester.pumpWidget(
      TestableApp(
        child: const ConversationMessageSearchScreen(workspaceId: 'local'),
        overrides: [
          conversationMessageSearchPageProvider.overrideWith(
            (ref, request) => completer.future,
          ),
        ],
        workspaceId: 'local',
      ),
    ),
  );
  final _ = await tester.pumpAndSettle();

  await tester.enterText(find.byType(EditableText).first, 'notes');
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('conversation-search-submit')));
  await tester.pump();

  expect(find.text('Searching messages$_ellipsis'), findsOneWidget);
  expect(find.byType(AuraSpinner), findsOneWidget);

  completer.complete(const (
    results: <ConversationMessageSearchResult>[],
    hasMore: false,
    hasError: false,
  ));
  final _ = await tester.pumpAndSettle();

  expect(find.text('No messages found'), findsOneWidget);
  expect(tester.takeException(), isNull);
}
