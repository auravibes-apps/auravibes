import 'package:auravibes_app/features/chats/notifiers/conversation_result.dart';
import 'package:auravibes_app/features/chats/providers/context_usage_level.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selection_providers.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_operations_provider.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/settings/screens/more_screen.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

class _FakeGoRouter implements GoRouter {
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

@Dependencies([
  workspaceModelSelectionById,
  workspaceSession,
  cloudWorkspaceStateGateway,
  serviceConnectionOperations,
  serviceConnections,
  ConversationChatNotifier,
  conversationBusyState,
  pendingToolCalls,
  contextUsage,
  chatMessages,
  childConversationsStream,
  conversationByIdStream,
  messageConversationById,
])
void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  @Dependencies([
    workspaceModelSelectionById,
    workspaceSession,
    cloudWorkspaceStateGateway,
    serviceConnectionOperations,
    serviceConnections,
    ConversationChatNotifier,
    conversationBusyState,
    pendingToolCalls,
    contextUsage,
    chatMessages,
    childConversationsStream,
    conversationByIdStream,
    messageConversationById,
  ])
  Widget _buildScreen({required String workspaceId}) {
    return EasyLocalization(
      child: Builder(
        builder: (context) {
          return ProviderScope(
            overrides: [
              routerProvider.overrideWithValue(_FakeGoRouter()),
            ],
            child: MaterialApp(
              home: MoreScreen(workspaceId: workspaceId),
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
            ),
          );
        },
      ),
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      useOnlyLangCode: true,
      useFallbackTranslations: true,
    );
  }

  testWidgets('renders title, tiles, and icons', (tester) async {
    await tester.pumpWidget(_buildScreen(workspaceId: 'ws-1'));
    final _ = await tester.pumpAndSettle();

    expect(find.text('More'), findsOneWidget);
    expect(find.text('Workspaces'), findsOneWidget);
    expect(find.text('Service Connections'), findsOneWidget);
    expect(find.text('Credential Definitions'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Skills'), findsOneWidget);
    expect(find.byIcon(Icons.workspaces_outlined), findsOneWidget);
    expect(find.byIcon(Icons.hub_outlined), findsOneWidget);
    expect(find.byIcon(Icons.key_outlined), findsOneWidget);
    expect(find.byIcon(Icons.build_circle_outlined), findsOneWidget);
    expect(find.byIcon(Icons.psychology_alt_outlined), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsAtLeast(5));
  });
}
