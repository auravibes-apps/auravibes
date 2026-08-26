// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/features/agents/screens/agent_detail_screen.dart';
import 'package:auravibes_app/features/agents/screens/agents_screen.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/screens/chat_conversation_screen.dart';
import 'package:auravibes_app/features/chats/screens/chats_list_screen.dart';
import 'package:auravibes_app/features/chats/screens/new_chat_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/screens/cloud_account_add_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/screens/cloud_account_forgot_password_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/screens/cloud_account_login_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/screens/cloud_account_register_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/screens/cloud_accounts_screen.dart';
import 'package:auravibes_app/features/cloud_workspaces/screens/cloud_workspace_detail_screen.dart';
import 'package:auravibes_app/features/intro/screens/intro_screen.dart';
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
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/create_workspace_screen.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_management_screen.dart';
import 'package:auravibes_app/widgets/aura_sidebar_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'workspace_route.g.dart';
part 'intro_route.dart';

// Required: Framework declaration must remain top-level.
// ignore: prefer-static-class
const introPath = '/intro';
// Required: GoRouter route global must remain top-level.
// ignore: prefer-static-class
const workspacePathPrefix = '/workspaces';

// Required: GoRouter navigator key must remain top-level.
// ignore: prefer-static-class
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();
// Required: GoRouter navigator key must remain top-level.
// ignore: prefer-static-class
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

@TypedGoRoute<WorkspaceRoute>(
  path: '$workspacePathPrefix/:workspaceId',
  routes: [
    TypedStatefulShellRoute<MyShellRouteData>(
      branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
        TypedStatefulShellBranch(
          routes: [
            TypedGoRoute<NewChatRoute>(path: 'chat/new'),
            TypedGoRoute<ConversationRoute>(
              path: 'chats/:chatId',
              routes: [
                TypedGoRoute<SubAgentConversationRoute>(
                  path: 'sub-agents/:subAgentConversationId',
                ),
              ],
            ),
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
                  routes: [
                    TypedGoRoute<WorkspaceCreateRoute>(path: 'create'),
                    TypedGoRoute<CloudWorkspaceDetailRoute>(
                      path: 'cloud/:cloudAccountId/:cloudWorkspaceId',
                    ),
                  ],
                ),
                TypedGoRoute<CloudAccountsRoute>(
                  path: 'cloud-accounts',
                  routes: [
                    TypedGoRoute<CloudAccountAddRoute>(path: 'add'),
                    TypedGoRoute<CloudAccountLoginRoute>(path: 'login'),
                    TypedGoRoute<CloudAccountRegisterRoute>(path: 'register'),
                    TypedGoRoute<CloudAccountForgotPasswordRoute>(
                      path: 'forgot-password',
                    ),
                  ],
                ),
                TypedGoRoute<ToolsRoute>(path: 'tools'),
                TypedGoRoute<ModelsRoute>(path: 'models'),
                TypedGoRoute<ServiceConnectionsRoute>(
                  path: 'service-connections',
                  routes: [
                    TypedGoRoute<ServiceConnectionCreateRoute>(path: 'new'),
                    TypedGoRoute<ServiceConnectionEditRoute>(
                      path: ':connectionId',
                    ),
                  ],
                ),
                TypedGoRoute<SkillsRoute>(
                  path: 'skills',
                  routes: [
                    TypedGoRoute<SkillCreateRoute>(path: 'new'),
                    TypedGoRoute<SkillToolCreateRoute>(
                      path: ':skillId/tools/new',
                    ),
                    TypedGoRoute<SkillToolEditRoute>(
                      path: ':skillId/tools/:toolId',
                    ),
                    TypedGoRoute<SkillDetailRoute>(path: ':skillId'),
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
                TypedGoRoute<AgentsRoute>(
                  path: 'agents',
                  routes: [
                    TypedGoRoute<AgentCreateRoute>(path: 'new'),
                    TypedGoRoute<AgentDetailRoute>(path: ':agentId'),
                  ],
                ),
              ],
            ),
          ],
        ),
        TypedStatefulShellBranch(
          routes: [TypedGoRoute<SettingsRoute>(path: 'settings')],
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
  static final GlobalKey<NavigatorState> $navigatorKey = shellNavigatorKey;
  const MyShellRouteData();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    final workspaceId = state.pathParameters['workspaceId'];
    if (workspaceId == null || workspaceId.isEmpty) {
      throw StateError('workspaceId must be present in route pathParameters');
    }

    return _WorkspaceSessionGate(
      workspaceId: workspaceId,
      navigationShell: navigationShell,
    );
  }
}

class _WorkspaceSessionGate extends ConsumerWidget {
  const _WorkspaceSessionGate({
    required this.workspaceId,
    required this.navigationShell,
  });

  final String workspaceId;
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(workspaceSessionForRouteProvider(workspaceId))) {
      AsyncData() => _WorkspaceShell(
        workspaceId: workspaceId,
        navigationShell: navigationShell,
      ),
      AsyncError(:final error) => ErrorWidget(error),
      _ => const SizedBox.shrink(),
    };
  }
}

class _WorkspaceShell extends StatelessWidget {
  const _WorkspaceShell({
    required this.workspaceId,
    required this.navigationShell,
  });

  final String workspaceId;
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => PopScope(
    child: AuraSidebarWrapper(
      navigationShell: navigationShell,
      workspaceId: workspaceId,
    ),
    canPop: false,
  );
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

class SubAgentConversationRoute extends GoRouteData
    with $SubAgentConversationRoute {
  SubAgentConversationRoute({
    required this.workspaceId,
    required this.chatId,
    required this.subAgentConversationId,
  });

  final String workspaceId;
  final String chatId;
  final String subAgentConversationId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return _SubAgentConversationGate(
      workspaceId: workspaceId,
      parentConversationId: chatId,
      chatId: subAgentConversationId,
    );
  }
}

class _SubAgentConversationGate extends ConsumerWidget {
  const _SubAgentConversationGate({
    required this.workspaceId,
    required this.parentConversationId,
    required this.chatId,
  });

  final String workspaceId;
  final String parentConversationId;
  final String chatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversation = ref.watch(
      conversationByIdStreamProvider(workspaceId, conversationId: chatId),
    );

    return switch (conversation) {
      AsyncData(:final value)
          when value?.workspaceId == workspaceId &&
              value?.parentConversationId == parentConversationId =>
        ChatConversationScreen(
          workspaceId: workspaceId,
          chatId: chatId,
          showInputComposer: false,
        ),
      _ => const SizedBox.shrink(),
    };
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

class AgentsRoute extends GoRouteData with $AgentsRoute {
  AgentsRoute({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return AgentsScreen(workspaceId: workspaceId);
  }
}

class AgentCreateRoute extends GoRouteData with $AgentCreateRoute {
  AgentCreateRoute({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return AgentDetailScreen(workspaceId: workspaceId);
  }
}

class AgentDetailRoute extends GoRouteData with $AgentDetailRoute {
  AgentDetailRoute({required this.workspaceId, required this.agentId});

  final String workspaceId;
  final String agentId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return AgentDetailScreen(workspaceId: workspaceId, agentId: agentId);
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
      initialAppSkillId: state.uri.queryParameters['appSkillId'],
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

class CloudAccountsRoute extends GoRouteData with $CloudAccountsRoute {
  CloudAccountsRoute({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CloudAccountsScreen(workspaceId: workspaceId);
  }
}

class CloudWorkspaceDetailRoute extends GoRouteData
    with $CloudWorkspaceDetailRoute {
  CloudWorkspaceDetailRoute({
    required this.workspaceId,
    required this.cloudAccountId,
    required this.cloudWorkspaceId,
  });

  final String workspaceId;
  final String cloudAccountId;
  final int cloudWorkspaceId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CloudWorkspaceDetailScreen(
      workspaceId: workspaceId,
      cloudAccountId: cloudAccountId,
      cloudWorkspaceId: cloudWorkspaceId,
    );
  }
}

class CloudAccountAddRoute extends GoRouteData with $CloudAccountAddRoute {
  CloudAccountAddRoute({required this.workspaceId, this.returnPath});

  final String workspaceId;
  final String? returnPath;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CloudAccountAddScreen(
      workspaceId: workspaceId,
      returnPath: returnPath,
    );
  }
}

class CloudAccountLoginRoute extends GoRouteData with $CloudAccountLoginRoute {
  CloudAccountLoginRoute({required this.workspaceId, this.returnPath});

  final String workspaceId;
  final String? returnPath;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CloudAccountLoginScreen(
      workspaceId: workspaceId,
      returnPath: returnPath,
    );
  }
}

class CloudAccountRegisterRoute extends GoRouteData
    with $CloudAccountRegisterRoute {
  CloudAccountRegisterRoute({required this.workspaceId, this.returnPath});

  final String workspaceId;
  final String? returnPath;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CloudAccountRegisterScreen(
      workspaceId: workspaceId,
      returnPath: returnPath,
    );
  }
}

class CloudAccountForgotPasswordRoute extends GoRouteData
    with $CloudAccountForgotPasswordRoute {
  CloudAccountForgotPasswordRoute({required this.workspaceId, this.returnPath});

  final String workspaceId;
  final String? returnPath;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CloudAccountForgotPasswordScreen(
      workspaceId: workspaceId,
      returnPath: returnPath,
    );
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

class WorkspaceCreateRoute extends GoRouteData with $WorkspaceCreateRoute {
  WorkspaceCreateRoute({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CreateWorkspaceScreen(workspaceId: workspaceId);
  }
}
// Top-level API/provider declarations are required by their consumers.
