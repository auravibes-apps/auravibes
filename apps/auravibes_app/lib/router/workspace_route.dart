import 'package:auravibes_app/domain/entities/conversation_entity.dart';
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
import 'package:auravibes_app/features/models/providers/add_model_provider_state.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connection_create_screen.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connection_edit_screen.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connections_screen.dart';
import 'package:auravibes_app/features/settings/screens/more_screen.dart';
import 'package:auravibes_app/features/settings/screens/settings_screen.dart';
import 'package:auravibes_app/features/settings/screens/workspace_settings_screen.dart';
import 'package:auravibes_app/features/skills/screens/skill_credential_definition_edit_screen.dart';
import 'package:auravibes_app/features/skills/screens/skill_credential_definitions_screen.dart';
import 'package:auravibes_app/features/skills/screens/skill_detail_screen.dart';
import 'package:auravibes_app/features/skills/screens/skill_resource_edit_screen.dart';
import 'package:auravibes_app/features/skills/screens/skill_tool_edit_screen.dart';
import 'package:auravibes_app/features/skills/screens/skills_screen.dart';
import 'package:auravibes_app/features/tools/screens/tools_screen.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_route_failure.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/create_workspace_screen.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_management_screen.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_access_gate.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_sign_in_recovery.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_app/router/draft_exit_registry_provider.dart';
import 'package:auravibes_app/router/workspace_navigation.dart';
import 'package:auravibes_app/widgets/aura_sidebar_wrapper.dart';
import 'package:auravibes_app/widgets/route_recovery_view.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.

part 'intro_route.dart';
part 'workspace_route.g.dart';

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
            TypedGoRoute<MoreRoute>(path: 'more'),
            TypedGoRoute<WorkspaceManagementRoute>(
              path: 'more/manage-workspaces',
              routes: [
                TypedGoRoute<WorkspaceCreateRoute>(path: 'create'),
                TypedGoRoute<CloudWorkspaceDetailRoute>(
                  path: 'cloud/:cloudAccountId/:cloudWorkspaceId',
                ),
              ],
            ),
            TypedGoRoute<CloudAccountsRoute>(
              path: 'more/cloud-accounts',
              routes: [
                TypedGoRoute<CloudAccountAddRoute>(path: 'add'),
                TypedGoRoute<CloudAccountLoginRoute>(path: 'login'),
                TypedGoRoute<CloudAccountRegisterRoute>(path: 'register'),
                TypedGoRoute<CloudAccountForgotPasswordRoute>(
                  path: 'forgot-password',
                ),
              ],
            ),
            TypedGoRoute<ToolsRoute>(path: 'more/tools'),
            TypedGoRoute<ModelsRoute>(path: 'more/models'),
            TypedGoRoute<ServiceConnectionsRoute>(
              path: 'more/service-connections',
              routes: [
                TypedGoRoute<ServiceConnectionCreateRoute>(path: 'new'),
                TypedGoRoute<ServiceConnectionEditRoute>(path: ':connectionId'),
              ],
            ),
            TypedGoRoute<SkillsRoute>(
              path: 'more/skills',
              routes: [
                TypedGoRoute<SkillCreateRoute>(path: 'new'),
                TypedGoRoute<SkillToolCreateRoute>(path: ':skillId/tools/new'),
                TypedGoRoute<SkillToolEditRoute>(
                  path: ':skillId/tools/:toolId',
                ),
                TypedGoRoute<SkillResourceCreateRoute>(
                  path: ':skillId/resources/new',
                ),
                TypedGoRoute<SkillResourceEditRoute>(
                  path: ':skillId/resources/:resourceId',
                ),
                TypedGoRoute<SkillDetailRoute>(path: ':skillId'),
              ],
            ),
            TypedGoRoute<SkillCredentialDefinitionsRoute>(
              path: 'more/skill-credential-definitions',
              routes: [
                TypedGoRoute<SkillCredentialDefinitionCreateRoute>(path: 'new'),
                TypedGoRoute<SkillCredentialDefinitionEditRoute>(
                  path: ':definitionId',
                ),
              ],
            ),
            TypedGoRoute<AgentsRoute>(
              path: 'more/agents',
              routes: [
                TypedGoRoute<AgentCreateRoute>(path: 'new'),
                TypedGoRoute<AgentDetailRoute>(path: ':agentId'),
              ],
            ),
          ],
        ),
        TypedStatefulShellBranch(
          routes: [
            TypedGoRoute<SettingsRoute>(path: 'settings'),
            TypedGoRoute<WorkspaceSettingsRoute>(path: 'workspace-settings'),
          ],
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
    final session = ref.watch(workspaceSessionForRouteProvider(workspaceId));

    return _WorkspaceSessionGateContent(
      workspaceId: workspaceId,
      session: session,
      navigationShell: navigationShell,
      isAppScoped: WorkspaceNavigation.isAppScoped(
        GoRouterState.of(context).uri,
      ),
      onChooseWorkspace: () => _chooseWorkspace(context),
      onRetry: () =>
          ref.invalidate(workspaceSessionForRouteProvider(workspaceId)),
    );
  }

  void _chooseWorkspace(BuildContext context) {
    final _ = Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WorkspaceManagementScreen(workspaceId: workspaceId),
      ),
    );
  }
}

class const _WorkspaceSessionGateContent({
  required final String workspaceId,
  required final AsyncValue<WorkspaceSession> session,
  required final StatefulNavigationShell navigationShell,
  required final bool isAppScoped,
  required final VoidCallback onChooseWorkspace,
  required final VoidCallback onRetry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final shell = _WorkspaceShell(
      workspaceId: workspaceId,
      navigationShell: navigationShell,
    );
    final loadedSession = _loadedWorkspaceSession(session);
    if (loadedSession != null) {
      return WorkspaceAccessGate(
        workspaceId: workspaceId,
        session: loadedSession,
        child: shell,
        onChooseWorkspace: onChooseWorkspace,
      );
    }
    if (isAppScoped) return shell;

    return _WorkspaceSessionRecovery(
      session: session,
      onChooseWorkspace: onChooseWorkspace,
      onRetry: onRetry,
    );
  }
}

WorkspaceSession? _loadedWorkspaceSession(
  AsyncValue<WorkspaceSession> session,
) {
  if (session.error is WorkspaceRouteFailure || session.value == null) {
    return null;
  }

  return session.requireValue;
}

class const _WorkspaceSessionRecovery({
  required final AsyncValue<WorkspaceSession> session,
  required final VoidCallback onChooseWorkspace,
  required final VoidCallback onRetry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (session) {
    AsyncError(error: final WorkspaceRouteFailure failure) => RouteRecoveryView(
      messageKey: failure.localizationKey,
      onReturn: onChooseWorkspace,
    ),
    AsyncError(isLoading: true) || AsyncLoading() => const RouteRecoveryView(
      messageKey: LocaleKeys.route_state_workspace_loading,
      isLoading: true,
    ),
    AsyncError() || AsyncData() => RouteRecoveryView(
      messageKey: LocaleKeys.route_state_workspace_error,
      onRetry: onRetry,
      onReturn: onChooseWorkspace,
    ),
  };
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
  Future<bool> onExit(BuildContext context, GoRouterState state) =>
      _canExitDraft(context, state);
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
    final provider = conversationByIdStreamProvider(
      workspaceId,
      conversationId: chatId,
    );
    final state = ref.watch(provider);
    final session = _sessionForState(ref, state);

    return _SubAgentConversationResult(
      gate: this,
      state: state,
      session: session,
      onReturn: () => _returnToParent(context),
      onRetry: () => ref.invalidate(provider),
    );
  }

  WorkspaceSession? _sessionForState(
    WidgetRef ref,
    AsyncValue<ConversationEntity?> state,
  ) => switch (state) {
    AsyncError(:final error)
        when WorkspaceRouteFailure.requiresAuthentication(error) =>
      ref.watch(workspaceSessionForRouteProvider(workspaceId)).value,
    AsyncError() || AsyncLoading() || AsyncData() => null,
  };

  void _returnToParent(BuildContext context) => ConversationRoute(
    workspaceId: workspaceId,
    chatId: parentConversationId,
  ).go(context);
}

class const _SubAgentConversationResult({
  required final _SubAgentConversationGate gate,
  required final AsyncValue<ConversationEntity?> state,
  required final WorkspaceSession? session,
  required final VoidCallback onReturn,
  required final VoidCallback onRetry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (state) {
    AsyncData(:final value) => _SubAgentConversationData(
      gate: gate,
      conversation: value,
      onReturn: onReturn,
    ),
    AsyncError(:final error) => _SubAgentConversationError(
      result: this,
      requiresAuthentication: WorkspaceRouteFailure.requiresAuthentication(
        error,
      ),
    ),
    AsyncLoading() => const RouteRecoveryView(
      messageKey: LocaleKeys.route_state_child_loading,
      isLoading: true,
    ),
  };
}

class const _SubAgentConversationError({
  required final _SubAgentConversationResult result,
  required final bool requiresAuthentication,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (requiresAuthentication) {
      return _SubAgentAuthenticationRecovery(
        workspaceId: result.gate.workspaceId,
        session: result.session,
        onReturn: result.onReturn,
      );
    }
    if (result.state.isLoading) {
      return const RouteRecoveryView(
        messageKey: LocaleKeys.route_state_child_loading,
        isLoading: true,
      );
    }

    return _SubAgentLoadError(
      onReturn: result.onReturn,
      onRetry: result.onRetry,
    );
  }
}

class const _SubAgentConversationData({
  required final _SubAgentConversationGate gate,
  required final ConversationEntity? conversation,
  required final VoidCallback onReturn,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!_isMatchingConversation(
      conversation,
      gate.workspaceId,
      gate.parentConversationId,
      gate.chatId,
    )) {
      return _SubAgentNotFound(onReturn: onReturn);
    }

    return ChatConversationScreen(
      workspaceId: gate.workspaceId,
      chatId: gate.chatId,
      showInputComposer: false,
    );
  }
}

class const _SubAgentAuthenticationRecovery({
  required final String workspaceId,
  required final WorkspaceSession? session,
  required final VoidCallback onReturn,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceSignInRecovery(
    workspaceId: workspaceId,
    session: session,
    onReturn: onReturn,
    returnLabelKey: LocaleKeys.route_state_return_parent,
  );
}

class const _SubAgentNotFound({required final VoidCallback onReturn})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => RouteRecoveryView(
    messageKey: LocaleKeys.chats_screens_chat_conversation_error_not_found,
    onReturn: onReturn,
    returnLabelKey: LocaleKeys.route_state_return_parent,
  );
}

class const _SubAgentLoadError({
  required final VoidCallback onReturn,
  required final VoidCallback onRetry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => RouteRecoveryView(
    messageKey: LocaleKeys.route_state_child_error,
    onRetry: onRetry,
    onReturn: onReturn,
    returnLabelKey: LocaleKeys.route_state_return_parent,
  );
}

bool _isMatchingConversation(
  ConversationEntity? conversation,
  String workspaceId,
  String parentConversationId,
  String childConversationId,
) =>
    conversation?.id == childConversationId &&
    conversation?.workspaceId == workspaceId &&
    conversation?.parentConversationId == parentConversationId;

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
    return ServiceConnectionsRoute(
      workspaceId: workspaceId,
      view: 'providers',
    ).location;
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
  Future<bool> onExit(BuildContext context, GoRouterState state) =>
      _canExitDraft(context, state);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SkillDetailScreen(
      workspaceId: workspaceId,
      key: ValueKey(workspaceId),
    );
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
  Future<bool> onExit(BuildContext context, GoRouterState state) =>
      _canExitDraft(context, state);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return AgentDetailScreen(
      workspaceId: workspaceId,
      key: ValueKey(workspaceId),
    );
  }
}

class AgentDetailRoute({
  required final String workspaceId,
  required final String agentId,
}) extends GoRouteData with $AgentDetailRoute {
  @override
  Future<bool> onExit(BuildContext context, GoRouterState state) =>
      _canExitDraft(context, state);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return AgentDetailScreen(
      workspaceId: workspaceId,
      agentId: agentId,
      key: ValueKey((workspaceId: workspaceId, agentId: agentId)),
    );
  }
}

class SkillDetailRoute({
  required final String workspaceId,
  required final String skillId,
}) extends GoRouteData with $SkillDetailRoute {
  @override
  Future<bool> onExit(BuildContext context, GoRouterState state) =>
      _canExitDraft(context, state);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SkillDetailScreen(
      workspaceId: workspaceId,
      skillId: skillId,
      key: ValueKey((workspaceId: workspaceId, skillId: skillId)),
    );
  }
}

class SkillToolCreateRoute({
  required final String workspaceId,
  required final String skillId,
}) extends GoRouteData with $SkillToolCreateRoute {
  final SkillToolEditRouteGuard _exitGuard = .new();

  @override
  Future<bool> onExit(BuildContext context, GoRouterState state) =>
      _canExitDraft(context, state);
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      SkillToolEditScreen(
        workspaceId: workspaceId,
        skillId: skillId,
        routeExitGuard: _exitGuard,
        key: ValueKey((workspaceId: workspaceId, skillId: skillId)),
      );
}

class SkillToolEditRoute({
  required final String workspaceId,
  required final String skillId,
  required final String toolId,
}) extends GoRouteData with $SkillToolEditRoute {
  final SkillToolEditRouteGuard _exitGuard = .new();

  @override
  Future<bool> onExit(BuildContext context, GoRouterState state) =>
      _canExitDraft(context, state);
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SkillToolEditScreen(
      workspaceId: workspaceId,
      skillId: skillId,
      toolId: toolId,
      routeExitGuard: _exitGuard,
      key: ValueKey((
        workspaceId: workspaceId,
        skillId: skillId,
        toolId: toolId,
      )),
    );
  }
}

class SkillResourceCreateRoute({
  required final String workspaceId,
  required final String skillId,
}) extends GoRouteData with $SkillResourceCreateRoute {
  @override
  Future<bool> onExit(BuildContext context, GoRouterState state) =>
      _canExitDraft(context, state);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SkillResourceEditScreen(
      workspaceId: workspaceId,
      skillId: skillId,
      key: ValueKey((workspaceId: workspaceId, skillId: skillId)),
    );
  }
}

class SkillResourceEditRoute({
  required final String workspaceId,
  required final String skillId,
  required final String resourceId,
}) extends GoRouteData with $SkillResourceEditRoute {
  @override
  Future<bool> onExit(BuildContext context, GoRouterState state) =>
      _canExitDraft(context, state);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SkillResourceEditScreen(
      workspaceId: workspaceId,
      skillId: skillId,
      resourceId: resourceId,
      key: ValueKey((
        workspaceId: workspaceId,
        skillId: skillId,
        resourceId: resourceId,
      )),
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

class SkillCredentialDefinitionCreateRoute({
  required final String workspaceId,
  final bool returnCreated = false,
}) extends GoRouteData with $SkillCredentialDefinitionCreateRoute {
  @override
  Future<bool> onExit(BuildContext context, GoRouterState state) =>
      _canExitDraft(context, state);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SkillCredentialDefinitionEditScreen(
      workspaceId: workspaceId,
      returnCreated: returnCreated,
      key: ValueKey(workspaceId),
    );
  }
}

class SkillCredentialDefinitionEditRoute({
  required final String workspaceId,
  required final String definitionId,
}) extends GoRouteData with $SkillCredentialDefinitionEditRoute {
  @override
  Future<bool> onExit(BuildContext context, GoRouterState state) =>
      _canExitDraft(context, state);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SkillCredentialDefinitionEditScreen(
      workspaceId: workspaceId,
      definitionId: definitionId,
      key: ValueKey((workspaceId: workspaceId, definitionId: definitionId)),
    );
  }
}

class ServiceConnectionsRoute({
  required final String workspaceId,
  final String? view,
}) extends GoRouteData with $ServiceConnectionsRoute {
  ConnectionDestination get destination =>
      WorkspaceNavigation.connectionView(view);
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ServiceConnectionsScreen(
      workspaceId: workspaceId,
      view: destination,
    );
  }
}

class ServiceConnectionCreateRoute({
  required final String workspaceId,
  final String? returnPath,
  final String? type,
  @TypedQueryParameter(name: 'credentialDefinitionId')
  final String? credentialDefinitionId,
}) extends GoRouteData with $ServiceConnectionCreateRoute {
  @override
  Future<bool> onExit(BuildContext context, GoRouterState state) =>
      _canExitDraft(context, state);

  @override
  Future<String?> redirect(BuildContext context, GoRouterState state) =>
      _serviceConnectionCreateRedirect(context, state, workspaceId);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ServiceConnectionCreateScreen(
      workspaceId: workspaceId,
      initialType: ServiceConnectionCreateTypeQuery.fromQueryValue(type),
      initialCredentialDefinitionId: credentialDefinitionId,
      initialAppSkillId: state.uri.queryParameters['appSkillId'],
      returnPath: returnPath,
      key: ValueKey((workspaceId: workspaceId, context: state.uri.query)),
    );
  }
}

Future<String?> _serviceConnectionCreateRedirect(
  BuildContext context,
  GoRouterState state,
  String workspaceId,
) {
  final redirect = _serviceConnectionRedirectRequest(context, state);
  if (redirect == null) return Future<String?>.value();

  return _completeServiceConnectionRedirect(context, workspaceId, redirect);
}

typedef _ServiceConnectionRedirect = ({
  GoRouter router,
  DraftExitRegistry registry,
  Uri target,
});

_ServiceConnectionRedirect? _serviceConnectionRedirectRequest(
  BuildContext context,
  GoRouterState state,
) {
  final router = GoRouter.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  final registry = container.read(draftExitRegistryProvider);
  final target = _serviceConnectionRedirectTarget(router, state, registry);
  if (target == null) return null;

  return (router: router, registry: registry, target: target);
}

Future<String?> _completeServiceConnectionRedirect(
  BuildContext context,
  String workspaceId,
  _ServiceConnectionRedirect redirect,
) async {
  if (!await redirect.registry.canExitActive(redirect.router)) {
    return redirect.target.toString();
  }
  if (context.mounted) _resetAddModel(context, workspaceId);

  return null;
}

void _resetAddModel(BuildContext context, String workspaceId) =>
    ProviderScope.containerOf(
      context,
      listen: false,
    ).read(addModelProviderStateProvider(workspaceId).notifier).reset();

Uri? _serviceConnectionRedirectTarget(
  GoRouter router,
  GoRouterState state,
  DraftExitRegistry registry,
) {
  if (!registry.hasActiveRoute(router)) return null;
  final current = router.state.uri;
  if (current.path != state.uri.path || current == state.uri) return null;

  return current;
}

class ServiceConnectionEditRoute({
  required final String workspaceId,
  required final String connectionId,
}) extends GoRouteData with $ServiceConnectionEditRoute {
  @override
  Future<bool> onExit(BuildContext context, GoRouterState state) =>
      _canExitDraft(context, state);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ServiceConnectionEditScreen(
      workspaceId: workspaceId,
      connectionId: connectionId,
      key: ValueKey((workspaceId: workspaceId, connectionId: connectionId)),
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

class WorkspaceSettingsRoute({required final String workspaceId})
    extends GoRouteData
    with $WorkspaceSettingsRoute {
  final DraftExitGuard _exitGuard = .new();

  @override
  Future<bool> onExit(BuildContext context, GoRouterState state) =>
      _canExitDraft(context, state);

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      WorkspaceSettingsScreen(
        workspaceId: workspaceId,
        guard: _exitGuard,
        key: ValueKey(workspaceId),
      );
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
  final String? serverUrl,
}) extends GoRouteData with $CloudWorkspaceDetailRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CloudWorkspaceDetailScreen(
      workspaceId: workspaceId,
      cloudAccountId: cloudAccountId,
      cloudWorkspaceId: cloudWorkspaceId,
      serverUrl: serverUrl,
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
      query: state.uri.queryParameters,
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
      query: state.uri.queryParameters,
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
      query: state.uri.queryParameters,
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
      query: state.uri.queryParameters,
    );
  }
}

class WorkspaceManagementRoute({
  required final String workspaceId,
  final String? view,
}) extends GoRouteData with $WorkspaceManagementRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return WorkspaceManagementScreen(
      workspaceId: workspaceId,
      connectView: view == 'connect',
    );
  }
}

class WorkspaceCreateRoute({required final String workspaceId})
    extends GoRouteData
    with $WorkspaceCreateRoute {
  @override
  Future<bool> onExit(BuildContext context, GoRouterState state) =>
      _canExitDraft(context, state);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CreateWorkspaceScreen(
      workspaceId: workspaceId,
      key: ValueKey(workspaceId),
    );
  }
}
// Top-level API/provider declarations are required by their consumers.

Future<bool> _canExitDraft(BuildContext context, GoRouterState state) =>
    ProviderScope.containerOf(
      context,
      listen: false,
    ).read(draftExitRegistryProvider).canExitRoute(state.uri);
