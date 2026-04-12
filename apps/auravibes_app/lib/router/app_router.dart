import 'package:auravibes_app/features/chats/screens/chat_conversation_screen.dart';
import 'package:auravibes_app/features/chats/screens/list_chats_screen.dart';
import 'package:auravibes_app/features/chats/screens/new_chat_screen.dart';
import 'package:auravibes_app/features/models/screens/models_screen.dart';
import 'package:auravibes_app/features/settings/screens/settings_screen.dart';
import 'package:auravibes_app/features/tools/screens/tools_screen.dart';
import 'package:auravibes_app/widgets/app_navigation_wrappers.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

part 'app_router.g.dart';

const workspacePathPrefix = '/workspaces';

final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

@TypedGoRoute<WorkspaceRoute>(
  path: '$workspacePathPrefix/:workspaceId',
  routes: [
    TypedStatefulShellRoute<MyShellRouteData>(
      branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
        TypedStatefulShellBranch(
          routes: [
            TypedGoRoute<NewChatRoute>(path: 'chat/new'),
            TypedGoRoute<ConversationRoute>(path: 'chats/:chatId'),
            TypedGoRoute<ChatsRoute>(path: 'chats'),
          ],
        ),
        TypedStatefulShellBranch(
          routes: [
            TypedGoRoute<ToolsRoute>(path: 'tools'),
          ],
        ),
        TypedStatefulShellBranch(
          routes: [
            TypedGoRoute<ModelsRoute>(path: 'models'),
          ],
        ),
        TypedStatefulShellBranch(
          routes: [
            TypedGoRoute<SettingsRoute>(path: 'settings'),
          ],
        ),
      ],
    ),
  ],
)
class WorkspaceRoute extends GoRouteData with $WorkspaceRoute {
  WorkspaceRoute({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SizedBox.shrink();
  }

  @override
  String? redirect(BuildContext context, GoRouterState state) {
    final workspacePath = '$workspacePathPrefix/$workspaceId';

    if (state.uri.path == workspacePath) {
      return NewChatRoute(workspaceId: workspaceId).location;
    }

    return null;
  }
}

class MyShellRouteData extends StatefulShellRouteData {
  const MyShellRouteData();

  static final GlobalKey<NavigatorState> $navigatorKey = shellNavigatorKey;

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return AuraSidebarWrapper(navigationShell: navigationShell);
  }
}

class ChatsRoute extends GoRouteData with $ChatsRoute {
  ChatsRoute({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ChatsListScreen(workspaceId: workspaceId);
  }
}

class NewChatRoute extends GoRouteData with $NewChatRoute {
  NewChatRoute({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return NewChatScreen(workspaceId: workspaceId);
  }
}

class ConversationRoute extends GoRouteData with $ConversationRoute {
  ConversationRoute({required this.workspaceId, required this.chatId});

  final String workspaceId;
  final String chatId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ChatConversationScreen(workspaceId: workspaceId, chatId: chatId);
  }
}

class ToolsRoute extends GoRouteData with $ToolsRoute {
  ToolsRoute({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ToolsScreen(workspaceId: workspaceId);
  }
}

class ModelsRoute extends GoRouteData with $ModelsRoute {
  ModelsRoute({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ModelsScreen(workspaceId: workspaceId);
  }
}

class SettingsRoute extends GoRouteData with $SettingsRoute {
  SettingsRoute({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SettingsScreen(workspaceId: workspaceId);
  }
}
