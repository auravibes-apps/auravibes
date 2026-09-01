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
class WorkspaceRoute({required final String workspaceId})
    extends GoRouteData
    with $WorkspaceRoute {
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

class const MyShellRouteData() extends StatefulShellRouteData {
  static final GlobalKey<NavigatorState> $navigatorKey = shellNavigatorKey;
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

class const _WorkspaceSessionGate({
  required final String workspaceId,
  required final StatefulNavigationShell navigationShell,
}) extends ConsumerWidget {
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

class const _WorkspaceShell({
  required final String workspaceId,
  required final StatefulNavigationShell navigationShell,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => PopScope(
    child: AuraSidebarWrapper(
      navigationShell: navigationShell,
      workspaceId: workspaceId,
    ),
    canPop: false,
  );
}

class ChatsRoute({required final String workspaceId})
    extends GoRouteData
    with $ChatsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ChatsListScreen(workspaceId: workspaceId);
  }
}

class NewChatRoute({required final String workspaceId})
    extends GoRouteData
    with $NewChatRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return NewChatScreen(workspaceId: workspaceId);
  }
}

class ConversationRoute({
  required final String workspaceId,
  required final String chatId,
}) extends GoRouteData with $ConversationRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ChatConversationScreen(workspaceId: workspaceId, chatId: chatId);
  }
}

class SubAgentConversationRoute({
  required final String workspaceId,
  required final String chatId,
  required final String subAgentConversationId,
}) extends GoRouteData with $SubAgentConversationRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return _SubAgentConversationGate(
      workspaceId: workspaceId,
      parentConversationId: chatId,
      chatId: subAgentConversationId,
    );
  }
}

class const _SubAgentConversationGate({
  required final String workspaceId,
  required final String parentConversationId,
  required final String chatId,
}) extends ConsumerWidget {
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

class ToolsRoute({required final String workspaceId})
    extends GoRouteData
    with $ToolsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ToolsScreen(workspaceId: workspaceId);
  }
}

class ModelsRoute({required final String workspaceId})
    extends GoRouteData
    with $ModelsRoute {
  @override
  String redirect(BuildContext context, GoRouterState state) {
    return ServiceConnectionsRoute(workspaceId: workspaceId).location;
  }
}

class SkillsRoute({required final String workspaceId})
    extends GoRouteData
    with $SkillsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SkillsScreen(workspaceId: workspaceId);
  }
}

class SkillCreateRoute({required final String workspaceId})
    extends GoRouteData
    with $SkillCreateRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SkillDetailScreen(workspaceId: workspaceId);
  }
}

class AgentsRoute({required final String workspaceId})
    extends GoRouteData
    with $AgentsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return AgentsScreen(workspaceId: workspaceId);
  }
}

class AgentCreateRoute({required final String workspaceId})
    extends GoRouteData
    with $AgentCreateRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return AgentDetailScreen(workspaceId: workspaceId);
  }
}

class AgentDetailRoute({
  required final String workspaceId,
  required final String agentId,
}) extends GoRouteData with $AgentDetailRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return AgentDetailScreen(workspaceId: workspaceId, agentId: agentId);
  }
}

class SkillDetailRoute({
  required final String workspaceId,
  required final String skillId,
}) extends GoRouteData with $SkillDetailRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SkillDetailScreen(workspaceId: workspaceId, skillId: skillId);
  }
}

class SkillToolCreateRoute({
  required final String workspaceId,
  required final String skillId,
}) extends GoRouteData with $SkillToolCreateRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SkillToolEditScreen(workspaceId: workspaceId, skillId: skillId);
  }
}

class SkillToolEditRoute({
  required final String workspaceId,
  required final String skillId,
  required final String toolId,
}) extends GoRouteData with $SkillToolEditRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SkillToolEditScreen(
      workspaceId: workspaceId,
      skillId: skillId,
      toolId: toolId,
    );
  }
}

class SkillCredentialDefinitionsRoute({required final String workspaceId})
    extends GoRouteData
    with $SkillCredentialDefinitionsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SkillCredentialDefinitionsScreen(workspaceId: workspaceId);
  }
}

class SkillCredentialDefinitionCreateRoute({required final String workspaceId})
    extends GoRouteData
    with $SkillCredentialDefinitionCreateRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SkillCredentialDefinitionEditScreen(workspaceId: workspaceId);
  }
}

class SkillCredentialDefinitionEditRoute({
  required final String workspaceId,
  required final String definitionId,
}) extends GoRouteData with $SkillCredentialDefinitionEditRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SkillCredentialDefinitionEditScreen(
      workspaceId: workspaceId,
      definitionId: definitionId,
    );
  }
}

class ServiceConnectionsRoute({required final String workspaceId})
    extends GoRouteData
    with $ServiceConnectionsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ServiceConnectionsScreen(workspaceId: workspaceId);
  }
}

class ServiceConnectionCreateRoute({
  required final String workspaceId,
  final String? type,
  @TypedQueryParameter(name: 'credentialDefinitionId')
  final String? credentialDefinitionId,
}) extends GoRouteData with $ServiceConnectionCreateRoute {
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

class ServiceConnectionEditRoute({
  required final String workspaceId,
  required final String connectionId,
}) extends GoRouteData with $ServiceConnectionEditRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ServiceConnectionEditScreen(
      workspaceId: workspaceId,
      connectionId: connectionId,
    );
  }
}

class SettingsRoute({required final String workspaceId})
    extends GoRouteData
    with $SettingsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SettingsScreen(workspaceId: workspaceId);
  }
}

class MoreRoute({required final String workspaceId})
    extends GoRouteData
    with $MoreRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return MoreScreen(workspaceId: workspaceId);
  }
}

class CloudAccountsRoute({required final String workspaceId})
    extends GoRouteData
    with $CloudAccountsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CloudAccountsScreen(workspaceId: workspaceId);
  }
}

class CloudWorkspaceDetailRoute({
  required final String workspaceId,
  required final String cloudAccountId,
  required final int cloudWorkspaceId,
}) extends GoRouteData with $CloudWorkspaceDetailRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CloudWorkspaceDetailScreen(
      workspaceId: workspaceId,
      cloudAccountId: cloudAccountId,
      cloudWorkspaceId: cloudWorkspaceId,
    );
  }
}

class CloudAccountAddRoute({
  required final String workspaceId,
  final String? returnPath,
}) extends GoRouteData with $CloudAccountAddRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CloudAccountAddScreen(
      workspaceId: workspaceId,
      returnPath: returnPath,
    );
  }
}

class CloudAccountLoginRoute({
  required final String workspaceId,
  final String? returnPath,
}) extends GoRouteData with $CloudAccountLoginRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CloudAccountLoginScreen(
      workspaceId: workspaceId,
      returnPath: returnPath,
    );
  }
}

class CloudAccountRegisterRoute({
  required final String workspaceId,
  final String? returnPath,
}) extends GoRouteData with $CloudAccountRegisterRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CloudAccountRegisterScreen(
      workspaceId: workspaceId,
      returnPath: returnPath,
    );
  }
}

class CloudAccountForgotPasswordRoute({
  required final String workspaceId,
  final String? returnPath,
}) extends GoRouteData with $CloudAccountForgotPasswordRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CloudAccountForgotPasswordScreen(
      workspaceId: workspaceId,
      returnPath: returnPath,
    );
  }
}

class WorkspaceManagementRoute({required final String workspaceId})
    extends GoRouteData
    with $WorkspaceManagementRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return WorkspaceManagementScreen(workspaceId: workspaceId);
  }
}

class WorkspaceCreateRoute({required final String workspaceId})
    extends GoRouteData
    with $WorkspaceCreateRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CreateWorkspaceScreen(workspaceId: workspaceId);
  }
}
// Top-level API/provider declarations are required by their consumers.
