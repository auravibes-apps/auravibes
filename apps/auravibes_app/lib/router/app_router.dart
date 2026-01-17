import 'package:auravibes_app/features/chats/screens/chat_conversation_screen.dart';
import 'package:auravibes_app/features/chats/screens/list_chats_screen.dart';
import 'package:auravibes_app/features/chats/screens/new_chat_screen.dart';
import 'package:auravibes_app/features/models/screens/models_screen.dart';
import 'package:auravibes_app/features/settings/screens/settings_screen.dart';
import 'package:auravibes_app/features/tools/tools_screen.dart';
import 'package:auravibes_app/widgets/app_navigation_wrappers.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

part 'app_router.g.dart';

final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

@TypedStatefulShellRoute<MyShellRouteData>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    TypedStatefulShellBranch(
      routes: [
        TypedGoRoute<NewChatRoute>(path: '/chat/new'),
        TypedGoRoute<CoversationRoute>(path: '/chats/:chatId'),
        TypedGoRoute<ChatsRoute>(
          path: '/chats',
        ),
      ],
    ),
    TypedStatefulShellBranch(
      routes: [
        TypedGoRoute<ToolsRoute>(path: '/tools'),
      ],
    ),
    TypedStatefulShellBranch(
      routes: [
        TypedGoRoute<ModelsRoute>(path: '/models'),
      ],
    ),
    TypedStatefulShellBranch(
      routes: [
        TypedGoRoute<SettingsRoute>(path: '/settings'),
      ],
    ),
  ],
)
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
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ChatScreen();
  }
}

class NewChatRoute extends GoRouteData with $NewChatRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const NewChatScreen();
  }
}

class CoversationRoute extends GoRouteData with $CoversationRoute {
  CoversationRoute({required this.chatId});
  String chatId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ChatConversationScreen(chatId: chatId);
  }
}

class ToolsRoute extends GoRouteData with $ToolsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ToolsScreen();
  }
}

class ModelsRoute extends GoRouteData with $ModelsRoute {
  // There is no need to implement [build] when this [redirect] is
  // unconditional.
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ModelsScreen();
  }
}

class SettingsRoute extends GoRouteData with $SettingsRoute {
  // There is no need to implement [build] when this [redirect] is
  // unconditional.
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SettingsScreen();
  }
}
