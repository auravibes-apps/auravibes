import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/widgets/conversation_branch_navigation_button.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const _workspaceId = 'test-workspace';
final ConversationEntity _sourceConversation = _conversation(
  'source',
  'Original conversation',
);
final ConversationEntity _currentConversation = _conversation(
  'current',
  'Current branch',
  forkSourceConversationId: _sourceConversation.id,
  forkSourceTitle: _sourceConversation.title,
);
final ConversationEntity _siblingConversation = _conversation(
  'sibling',
  'Sibling branch',
  forkSourceConversationId: _sourceConversation.id,
);
final ConversationEntity _childConversation = _conversation(
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
    final _ = await tester.pumpAndSettle();

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
    final _ = await tester.pumpAndSettle();

    expect(find.text('Opened sibling'), findsOneWidget);
  });
}

Future<void> _pumpBranchNavigation(WidgetTester tester, GoRouter router) async {
  final container = ProviderContainer(
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
  );
  addTearDown(container.dispose);

  await tester.runAsync(
    () => tester.pumpWidget(
      EasyLocalization(
        child: Builder(
          builder: (context) => UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              builder: (_, child) => AuraLegacyMaterialBridge(
                child: AuraSnackBarHost(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
            ),
          ),
        ),
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        startLocale: const Locale('en'),
      ),
    ),
  );
  final _ = await tester.pumpAndSettle();
}

Future<void> _openBranchPicker(WidgetTester tester) async {
  await tester.tap(
    find.byKey(const ValueKey<String>('conversation-branch-navigation')),
  );
  final _ = await tester.pumpAndSettle();
}

GoRouter _router() => GoRouter(
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
  initialLocation: '/workspaces/$_workspaceId/chats/${_currentConversation.id}',
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
