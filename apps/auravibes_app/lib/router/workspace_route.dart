// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/features/chats/screens/chat_conversation_screen.dart';
import 'package:auravibes_app/features/chats/screens/chats_list_screen.dart';
import 'package:auravibes_app/features/chats/screens/new_chat_screen.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connection_create_screen.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connection_edit_screen.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connections_screen.dart';
import 'package:auravibes_app/features/settings/screens/more_screen.dart';
import 'package:auravibes_app/features/settings/screens/settings_screen.dart';
import 'package:auravibes_app/features/skills/screens/skill_credential_definition_edit_screen.dart';
import 'package:auravibes_app/features/skills/screens/skill_credential_definitions_screen.dart';
import 'package:auravibes_app/features/skills/screens/skill_detail_screen.dart';
import 'package:auravibes_app/features/skills/screens/skill_tool_edit_screen.dart';
import 'package:auravibes_app/features/skills/screens/skills_screen.dart';
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
                TypedGoRoute<ServiceConnectionsRoute>(
                  path: 'service-connections',
                  routes: [
                    TypedGoRoute<ServiceConnectionCreateRoute>(
                      path: 'new',
                    ),
                    TypedGoRoute<ServiceConnectionEditRoute>(
                      path: ':connectionId',
                    ),
                  ],
                ),
                TypedGoRoute<SkillsRoute>(
                  path: 'skills',
                  routes: [
                    TypedGoRoute<SkillCreateRoute>(
                      path: 'new',
                    ),
                    TypedGoRoute<SkillToolCreateRoute>(
                      path: ':skillId/tools/new',
                    ),
                    TypedGoRoute<SkillToolEditRoute>(
                      path: ':skillId/tools/:toolId',
                    ),
                    TypedGoRoute<SkillDetailRoute>(
                      path: ':skillId',
                    ),
                  ],
                ),
                TypedGoRoute<SkillCredentialDefinitionsRoute>(
                  path: 'skill-credential-definitions',
                  routes: [
                    TypedGoRoute<SkillCredentialDefinitionCreateRoute>(
                      path: 'new',
                    ),
                    TypedGoRoute<SkillCredentialDefinitionEditRoute>(
                      path: ':definitionId',
                    ),
                  ],
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
  String redirect(BuildContext context, GoRouterState state) {
    return ServiceConnectionsRoute(workspaceId: workspaceId).location;
  }
}

class SkillsRoute extends GoRouteData with $SkillsRoute {
  SkillsRoute({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SkillsScreen(workspaceId: workspaceId);
  }
}

class SkillCreateRoute extends GoRouteData with $SkillCreateRoute {
  SkillCreateRoute({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SkillDetailScreen(workspaceId: workspaceId);
  }
}

class SkillDetailRoute extends GoRouteData with $SkillDetailRoute {
  SkillDetailRoute({required this.workspaceId, required this.skillId});

  final String workspaceId;
  final String skillId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SkillDetailScreen(workspaceId: workspaceId, skillId: skillId);
  }
}

class SkillToolCreateRoute extends GoRouteData with $SkillToolCreateRoute {
  SkillToolCreateRoute({required this.workspaceId, required this.skillId});

  final String workspaceId;
  final String skillId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SkillToolEditScreen(workspaceId: workspaceId, skillId: skillId);
  }
}

class SkillToolEditRoute extends GoRouteData with $SkillToolEditRoute {
  SkillToolEditRoute({
    required this.workspaceId,
    required this.skillId,
    required this.toolId,
  });

  final String workspaceId;
  final String skillId;
  final String toolId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SkillToolEditScreen(
      workspaceId: workspaceId,
      skillId: skillId,
      toolId: toolId,
    );
  }
}

class SkillCredentialDefinitionsRoute extends GoRouteData
    with $SkillCredentialDefinitionsRoute {
  SkillCredentialDefinitionsRoute({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SkillCredentialDefinitionsScreen(workspaceId: workspaceId);
  }
}

class SkillCredentialDefinitionCreateRoute extends GoRouteData
    with $SkillCredentialDefinitionCreateRoute {
  SkillCredentialDefinitionCreateRoute({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SkillCredentialDefinitionEditScreen(workspaceId: workspaceId);
  }
}

class SkillCredentialDefinitionEditRoute extends GoRouteData
    with $SkillCredentialDefinitionEditRoute {
  SkillCredentialDefinitionEditRoute({
    required this.workspaceId,
    required this.definitionId,
  });

  final String workspaceId;
  final String definitionId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SkillCredentialDefinitionEditScreen(
      workspaceId: workspaceId,
      definitionId: definitionId,
    );
  }
}

class ServiceConnectionsRoute extends GoRouteData
    with $ServiceConnectionsRoute {
  ServiceConnectionsRoute({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ServiceConnectionsScreen(workspaceId: workspaceId);
  }
}

class ServiceConnectionCreateRoute extends GoRouteData
    with $ServiceConnectionCreateRoute {
  ServiceConnectionCreateRoute({
    required this.workspaceId,
    this.type,
    @TypedQueryParameter(name: 'credentialDefinitionId')
    this.credentialDefinitionId,
  });

  final String workspaceId;
  final String? type;
  final String? credentialDefinitionId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ServiceConnectionCreateScreen(
      workspaceId: workspaceId,
      initialType: ServiceConnectionCreateTypeQuery.fromQueryValue(type),
      initialCredentialDefinitionId: credentialDefinitionId,
    );
  }
}

class ServiceConnectionEditRoute extends GoRouteData
    with $ServiceConnectionEditRoute {
  ServiceConnectionEditRoute({
    required this.workspaceId,
    required this.connectionId,
  });

  final String workspaceId;
  final String connectionId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ServiceConnectionEditScreen(
      workspaceId: workspaceId,
      connectionId: connectionId,
    );
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
