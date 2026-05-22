import 'package:auravibes_app/features/chats/screens/chat_conversation_screen.dart';
import 'package:auravibes_app/features/chats/screens/chats_list_screen.dart';
import 'package:auravibes_app/features/chats/screens/new_chat_screen.dart';
import 'package:auravibes_app/features/models/screens/models_screen.dart';
import 'package:auravibes_app/features/settings/screens/more_screen.dart';
import 'package:auravibes_app/features/settings/screens/settings_screen.dart';
import 'package:auravibes_app/features/tools/screens/tools_screen.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_management_screen.dart';
import 'package:auravibes_app/widgets/aura_sidebar_wrapper.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

part 'workspace_route.g.dart';

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
            TypedGoRoute<MoreRoute>(
              path: 'more',
              routes: [
                TypedGoRoute<WorkspaceManagementRoute>(
                  path: 'manage-workspaces',
                ),
                TypedGoRoute<ToolsRoute>(
                  path: 'tools',
                ),
                TypedGoRoute<ModelsRoute>(
                  path: 'models',
                ),
              ],
            ),
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
    final workspaceId = state.pathParameters['workspaceId'];
    if (workspaceId == null || workspaceId.isEmpty) {
      throw StateError(
        'workspaceId must be present in route pathParameters',
      );
    }
    return AuraSidebarWrapper(
      navigationShell: navigationShell,
      workspaceId: workspaceId,
    );
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

class MoreRoute extends GoRouteData with $MoreRoute {
  MoreRoute({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return MoreScreen(workspaceId: workspaceId);
  }
}

class WorkspaceManagementRoute extends GoRouteData
    with $WorkspaceManagementRoute {
  WorkspaceManagementRoute({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return WorkspaceManagementScreen(workspaceId: workspaceId);
  }
}
