import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/widgets/conversation_branch_navigation_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

const _workspaceId = 'test-workspace';
final _sourceConversation = _conversation('source', 'Original conversation');
final _currentConversation = _conversation(
  'current',
  'Current branch',
  forkSourceConversationId: _sourceConversation.id,
  forkSourceTitle: _sourceConversation.title,
);
final _siblingConversation = _conversation(
  'sibling',
  'Sibling branch',
  forkSourceConversationId: _sourceConversation.id,
);
final _childConversation = _conversation(
  'child',
  'Child branch',
  forkSourceConversationId: _currentConversation.id,
);

void main() {
  testWidgets('opens the parent conversation from the branch picker', (
    tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);

    await _pumpBranchNavigation(tester, router);
    await _openBranchPicker(tester);

    expect(find.text('Original conversation'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('conversation-branch-source')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Opened source'), findsOneWidget);
  });

  testWidgets('opens a sibling branch and lists direct child branches', (
    tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);

    await _pumpBranchNavigation(tester, router);
    await _openBranchPicker(tester);

    expect(find.text('Sibling branch'), findsOneWidget);
    expect(find.text('Child branch'), findsOneWidget);
    expect(
      tester
          .widget<ListTile>(
            find.byKey(const ValueKey<String>('conversation-current-branch')),
          )
          .selected,
      isTrue,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('conversation-branch-sibling')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Opened sibling'), findsOneWidget);
  });
}

Future<void> _pumpBranchNavigation(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(
    TestableApp(
      overrides: [
        conversationByIdStreamProvider(
          _workspaceId,
          conversationId: _sourceConversation.id,
        ).overrideWith((ref) => Stream.value(_sourceConversation)),
        forkedConversationsStreamProvider((
          workspaceId: _workspaceId,
          sourceConversationId: _sourceConversation.id,
        )).overrideWith(
          (ref) => Stream.value([_currentConversation, _siblingConversation]),
        ),
        forkedConversationsStreamProvider((
          workspaceId: _workspaceId,
          sourceConversationId: _currentConversation.id,
        )).overrideWith((ref) => Stream.value([_childConversation])),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openBranchPicker(WidgetTester tester) async {
  await tester.tap(
    find.byKey(const ValueKey<String>('conversation-branch-navigation')),
  );
  await tester.pumpAndSettle();
}

GoRouter _router() => GoRouter(
  initialLocation: '/workspaces/$_workspaceId/chats/${_currentConversation.id}',
  routes: [
    GoRoute(
      path: '/workspaces/:workspaceId/chats/:chatId',
      builder: (context, state) {
        final conversationId = state.pathParameters['chatId']!;
        if (conversationId == _currentConversation.id) {
          return Scaffold(
            appBar: AppBar(
              title: ConversationBranchNavigationButton(
                workspaceId: _workspaceId,
                conversation: _currentConversation,
              ),
            ),
          );
        }

        return Scaffold(body: Text('Opened $conversationId'));
      },
    ),
  ],
);

ConversationEntity _conversation(
  String id,
  String title, {
  String? forkSourceConversationId,
  String? forkSourceTitle,
}) => ConversationEntity(
  id: id,
  title: title,
  workspaceId: _workspaceId,
  isPinned: false,
  createdAt: .new(2026),
  updatedAt: .new(2026),
  forkSourceConversationId: forkSourceConversationId,
  forkSourceTitle: forkSourceTitle,
);
