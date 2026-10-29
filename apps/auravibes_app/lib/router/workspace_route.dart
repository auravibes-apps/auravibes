import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/agents/screens/agent_detail_screen.dart';
import 'package:auravibes_app/features/agents/screens/agents_screen.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/screens/chat_conversation_screen.dart';
import 'package:auravibes_app/features/chats/screens/chats_list_screen.dart';
import 'package:auravibes_app/features/chats/screens/conversation_message_search_screen.dart';
import 'package:auravibes_app/features/chats/screens/message_bookmarks_screen.dart';
import 'package:auravibes_app/features/chats/screens/new_chat_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/screens/cloud_account_add_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/screens/cloud_account_forgot_password_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/screens/cloud_account_login_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/screens/cloud_account_register_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/screens/cloud_accounts_screen.dart';
import 'package:auravibes_app/features/cloud_workspaces/screens/cloud_workspace_detail_screen.dart';
import 'package:auravibes_app/features/intro/screens/intro_screen.dart';
import 'package:auravibes_app/features/models/providers/add_model_provider_state.dart';
import 'package:auravibes_app/features/quick_switcher/widgets/quick_switcher_shortcut_scope.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connection_create_screen.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connection_edit_screen.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connections_screen.dart';
import 'package:auravibes_app/features/settings/screens/settings_screen.dart';
import 'package:auravibes_app/features/settings/screens/workspace_settings_screen.dart';
import 'package:auravibes_app/features/skills/screens/skill_detail_screen.dart';
import 'package:auravibes_app/features/skills/screens/skill_resource_edit_screen.dart';
import 'package:auravibes_app/features/skills/screens/skills_screen.dart';
import 'package:auravibes_app/features/tools/screens/tools_screen.dart';
import 'package:auravibes_app/features/workflows/screens/workflow_editor_screen.dart';
import 'package:auravibes_app/features/workflows/screens/workflows_screen.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_route_failure.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/create_workspace_screen.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_items_screen.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_management_screen.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_access_gate.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_sign_in_recovery.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_app/router/draft_exit_registry_provider.dart';
import 'package:auravibes_app/router/workspace_navigation.dart';
import 'package:auravibes_app/widgets/aura_sidebar_wrapper.dart';
import 'package:auravibes_app/widgets/feature_destination_shell.dart';
import 'package:auravibes_app/widgets/feature_destination_shell_scope.dart';
import 'package:auravibes_app/widgets/feature_destinations.dart';
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
// Required: Feature Navigator keys stay stable across router updates.
// ignore: prefer-static-class
final GlobalKey<NavigatorState> connectionsFeatureNavigatorKey =
    GlobalKey<NavigatorState>();
// Required: Feature Navigator keys stay stable across router updates.
// ignore: prefer-static-class
final GlobalKey<NavigatorState> agentsSkillsFeatureNavigatorKey =
    GlobalKey<NavigatorState>();
// Required: Workspace branch navigator keys stay stable across router updates.
// ignore: prefer-static-class
final GlobalKey<NavigatorState> workspaceChatsNavigatorKey =
    GlobalKey<NavigatorState>();
// Required: Workspace branch navigator keys stay stable across router updates.
// ignore: prefer-static-class
final GlobalKey<NavigatorState> workspaceFeatureNavigatorKey =
    GlobalKey<NavigatorState>();
// Required: Workspace branch navigator keys stay stable across router updates.
// ignore: prefer-static-class
final GlobalKey<NavigatorState> workspaceSettingsNavigatorKey =
    GlobalKey<NavigatorState>();
final _pendingFeatureLocations = <String, String>{};
final _pendingFeatureAuthReturnLocations = <String, String>{};

abstract class const _AppGoRouteData() extends GoRouteData {
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      MaterialPage<void>(
        child: build(context, state),
        key: state.pageKey,
        name: state.name ?? state.path,
        arguments: {...state.pathParameters, ...state.uri.queryParameters},
        restorationId: state.pageKey.value,
      );
}

@TypedGoRoute<WorkspaceRoute>(
  path: '$workspacePathPrefix/:workspaceId',
  routes: [
    TypedStatefulShellRoute<MyShellRouteData>(
      branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
        TypedStatefulShellBranch<WorkspaceChatsBranchData>(
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
            TypedGoRoute<MessageBookmarksRoute>(path: 'bookmarks'),
            TypedGoRoute<ConversationSearchRoute>(path: 'search'),
          ],
        ),
        TypedStatefulShellBranch<WorkspaceFeatureBranchData>(
          routes: [
            TypedGoRoute<WorkspaceItemsRoute>(path: 'items'),
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
            TypedGoRoute<ModelsRoute>(path: 'models'),
            TypedShellRoute<ConnectionsFeatureShellRouteData>(
              routes: [
                TypedGoRoute<ToolsRoute>(path: 'tools'),
                TypedGoRoute<ServiceConnectionsRoute>(
                  path: 'service-connections',
                  routes: [
                    TypedGoRoute<ServiceConnectionCreateRoute>(path: 'new'),
                    TypedGoRoute<ServiceConnectionEditRoute>(
                      path: ':connectionId',
                    ),
                  ],
                ),
              ],
            ),
            TypedShellRoute<AgentsSkillsFeatureShellRouteData>(
              routes: [
                TypedGoRoute<SkillsRoute>(
                  path: 'skills',
                  routes: [
                    TypedGoRoute<SkillCreateRoute>(path: 'new'),
                    TypedGoRoute<SkillResourceCreateRoute>(
                      path: ':skillId/resources/new',
                    ),
                    TypedGoRoute<SkillResourceEditRoute>(
                      path: ':skillId/resources/:resourceId',
                    ),
                    TypedGoRoute<SkillDetailRoute>(path: ':skillId'),
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
            TypedGoRoute<WorkflowsRoute>(
              path: 'more/workflows',
              routes: [
                TypedGoRoute<WorkflowCreateRoute>(path: 'new'),
                TypedGoRoute<WorkflowEditRoute>(path: ':workflowId'),
              ],
            ),
          ],
        ),
        TypedStatefulShellBranch<WorkspaceSettingsBranchData>(
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
    extends _AppGoRouteData
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

class const WorkspaceFeatureBranchData() extends StatefulShellBranchData {
  static final GlobalKey<NavigatorState> $navigatorKey =
      workspaceFeatureNavigatorKey;
}

class const WorkspaceChatsBranchData() extends StatefulShellBranchData {
  static final GlobalKey<NavigatorState> $navigatorKey =
      workspaceChatsNavigatorKey;
}

class const WorkspaceSettingsBranchData() extends StatefulShellBranchData {
  static final GlobalKey<NavigatorState> $navigatorKey =
      workspaceSettingsNavigatorKey;
}

class const ConnectionsFeatureShellRouteData() extends ShellRouteData {
  static final GlobalKey<NavigatorState> $navigatorKey =
      connectionsFeatureNavigatorKey;

  @override
  String? redirect(BuildContext context, GoRouterState state) =>
      _seedFeatureMaster(
        state,
        navigatorKey: $navigatorKey,
        masterLocation: FeatureDestinations.masterLocation(
          ServiceConnectionsRoute(
            workspaceId: state.pathParameters['workspaceId']!,
          ).location,
        ),
        pendingKey: 'connections:${state.pathParameters['workspaceId']}',
      );

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) {
    final workspaceId = state.pathParameters['workspaceId']!;
    final pendingKey = 'connections:$workspaceId';
    final initialLocation = _pendingFeatureLocations.remove(pendingKey);

    return FeatureDestinationShell(
      navigatorKey: $navigatorKey,
      parentNavigatorKey: workspaceFeatureNavigatorKey,
      destinations: FeatureDestinations.connections(workspaceId),
      child: navigator,
      initialLocation: initialLocation,
      key: ValueKey(pendingKey),
    );
  }
}

class const AgentsSkillsFeatureShellRouteData() extends ShellRouteData {
  static final GlobalKey<NavigatorState> $navigatorKey =
      agentsSkillsFeatureNavigatorKey;

  @override
  String? redirect(BuildContext context, GoRouterState state) =>
      _seedFeatureMaster(
        state,
        navigatorKey: $navigatorKey,
        masterLocation: FeatureDestinations.masterLocation(
          AgentsRoute(workspaceId: state.pathParameters['workspaceId']!)
              .location,
        ),
        pendingKey: 'agents-skills:${state.pathParameters['workspaceId']}',
      );

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) {
    final workspaceId = state.pathParameters['workspaceId']!;
    final pendingKey = 'agents-skills:$workspaceId';
    final initialLocation = _pendingFeatureLocations.remove(pendingKey);

    return FeatureDestinationShell(
      navigatorKey: $navigatorKey,
      parentNavigatorKey: workspaceFeatureNavigatorKey,
      destinations: FeatureDestinations.agents(workspaceId),
      child: navigator,
      initialLocation: initialLocation,
      key: ValueKey(pendingKey),
    );
  }
}

String? _seedFeatureMaster(
  GoRouterState state, {
  required GlobalKey<NavigatorState> navigatorKey,
  required String masterLocation,
  required String pendingKey,
}) {
  if (FeatureDestinations.isMasterLocation(state.uri) ||
      state.extra is FeatureDestinationStackPush ||
      (navigatorKey.currentState?.canPop() ?? false)) {
    return null;
  }
  _pendingFeatureLocations[pendingKey] = state.uri.toString();
  _pendingFeatureAuthReturnLocations[masterLocation] = state.uri.toString();

  return masterLocation;
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
        returnLocation: _takeFeatureAuthReturnLocation(context),
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

String? _takeFeatureAuthReturnLocation(BuildContext context) =>
    _pendingFeatureAuthReturnLocations.remove(
      GoRouterState.of(context).uri.toString(),
    );

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
    child: QuickSwitcherShortcutScope(
      workspaceId: workspaceId,
      child: AuraSidebarWrapper(
        navigationShell: navigationShell,
        workspaceId: workspaceId,
      ),
    ),
    canPop: false,
  );
}

class ChatsRoute({required final String workspaceId})
    extends _AppGoRouteData
    with $ChatsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ChatsListScreen(workspaceId: workspaceId);
  }
}

class MessageBookmarksRoute({
  required final String workspaceId,
  @TypedQueryParameter(name: 'conversation-id') final String? conversationId,
}) extends _AppGoRouteData with $MessageBookmarksRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      MessageBookmarksScreen(
        workspaceId: workspaceId,
        conversationId: conversationId,
      );
}

class ConversationSearchRoute({required final String workspaceId})
    extends _AppGoRouteData
    with $ConversationSearchRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ConversationMessageSearchScreen(workspaceId: workspaceId);
}

class NewChatRoute({
  required final String workspaceId,
  final String? modelSelectionId,
}) extends _AppGoRouteData with $NewChatRoute {
  @override
  FutureOr<bool> onExit(BuildContext context, GoRouterState state) =>
      _canExitDraft(context, state);
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return NewChatScreen(
      workspaceId: workspaceId,
      initialModelSelectionId: modelSelectionId,
    );
  }
}

class ConversationRoute({
  required final String workspaceId,
  required final String chatId,
  @TypedQueryParameter(name: 'message-id') final String? messageId,
}) extends _AppGoRouteData with $ConversationRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ChatConversationScreen(workspaceId: workspaceId, chatId: chatId);
  }
}

class SubAgentConversationRoute({
  required final String workspaceId,
  required final String chatId,
  required final String subAgentConversationId,
}) extends _AppGoRouteData with $SubAgentConversationRoute {
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
    extends _AppGoRouteData
    with $ToolsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ToolsScreen(workspaceId: workspaceId);
  }
}

class ModelsRoute({required final String workspaceId})
    extends _AppGoRouteData
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
    extends _AppGoRouteData
    with $SkillsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SkillsScreen(workspaceId: workspaceId);
  }
}

class SkillCreateRoute({required final String workspaceId})
    extends _AppGoRouteData
    with $SkillCreateRoute {
  @override
  FutureOr<bool> onExit(BuildContext context, GoRouterState state) =>
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
    extends _AppGoRouteData
    with $AgentsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return AgentsScreen(workspaceId: workspaceId);
  }
}

class AgentCreateRoute({required final String workspaceId})
    extends _AppGoRouteData
    with $AgentCreateRoute {
  @override
  FutureOr<bool> onExit(BuildContext context, GoRouterState state) =>
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
}) extends _AppGoRouteData with $AgentDetailRoute {
  @override
  FutureOr<bool> onExit(BuildContext context, GoRouterState state) =>
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

class WorkflowsRoute({required final String workspaceId})
    extends GoRouteData
    with $WorkflowsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      WorkflowsScreen(workspaceId: workspaceId);
}

class WorkflowCreateRoute({required final String workspaceId})
    extends GoRouteData
    with $WorkflowCreateRoute {
  @override
  FutureOr<bool> onExit(BuildContext context, GoRouterState state) =>
      _canExitDraft(context, state);

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      WorkflowEditorScreen(workspaceId: workspaceId);
}

class WorkflowEditRoute({
  required final String workspaceId,
  required final String workflowId,
}) extends GoRouteData with $WorkflowEditRoute {
  @override
  FutureOr<bool> onExit(BuildContext context, GoRouterState state) =>
      _canExitDraft(context, state);

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      WorkflowEditorScreen(
        workspaceId: workspaceId,
        workflowId: workflowId,
        key: ValueKey((workspaceId: workspaceId, workflowId: workflowId)),
      );
}

class SkillDetailRoute({
  required final String workspaceId,
  required final String skillId,
}) extends _AppGoRouteData with $SkillDetailRoute {
  @override
  FutureOr<bool> onExit(BuildContext context, GoRouterState state) =>
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

class SkillResourceCreateRoute({
  required final String workspaceId,
  required final String skillId,
}) extends _AppGoRouteData with $SkillResourceCreateRoute {
  @override
  FutureOr<bool> onExit(BuildContext context, GoRouterState state) =>
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
}) extends _AppGoRouteData with $SkillResourceEditRoute {
  @override
  FutureOr<bool> onExit(BuildContext context, GoRouterState state) =>
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

class ServiceConnectionsRoute({
  required final String workspaceId,
  final String? view,
}) extends _AppGoRouteData with $ServiceConnectionsRoute {
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
  @TypedQueryParameter(name: 'connectorId') final String? connectorId,
  @TypedQueryParameter(name: 'modelProviderId') final String? modelProviderId,
}) extends _AppGoRouteData with $ServiceConnectionCreateRoute {
  @override
  FutureOr<bool> onExit(BuildContext context, GoRouterState state) =>
      _canExitDraft(context, state);

  @override
  Future<String?> redirect(BuildContext context, GoRouterState state) =>
      _serviceConnectionCreateRedirect(context, state, workspaceId);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final routeState = _serviceConnectionCreateRouteState(state);

    return ServiceConnectionCreateScreen(
      workspaceId: workspaceId,
      initialType: routeState.initialType,
      initialConnectorId: routeState.initialConnectorId,
      initialModelProviderId: modelProviderId,
      returnPath: routeState.returnPath,
      returnNavigatorKey: routeState.navigatorKey,
      key: routeState.key,
    );
  }

  _ServiceConnectionCreateRouteState _serviceConnectionCreateRouteState(
    GoRouterState state,
  ) {
    final crossShellPush = _crossShellCreateReturn(state.extra);

    return (
      initialType: _serviceConnectionCreateType(type),
      initialConnectorId:
          connectorId ?? _serviceConnectionCreateConnectorId(state),
      returnPath: _serviceConnectionCreateReturnPath(
        returnPath,
        crossShellPush?.returnLocation,
      ),
      navigatorKey: crossShellPush?.navigatorKey,
      key: _serviceConnectionCreateScreenKey(workspaceId, state.uri.query),
    );
  }
}

typedef _ServiceConnectionCreateRouteState = ({
  ServiceConnectionCreateType? initialType,
  String? initialConnectorId,
  String? returnPath,
  GlobalKey<NavigatorState>? navigatorKey,
  Key key,
});

Key _serviceConnectionCreateScreenKey(String workspaceId, String query) =>
    ValueKey(_serviceConnectionCreateScreenIdentity(workspaceId, query));

Object _serviceConnectionCreateScreenIdentity(
  String workspaceId,
  String query,
) => (workspaceId: workspaceId, context: query);

String? _serviceConnectionCreateConnectorId(GoRouterState state) =>
    state.uri.queryParameters['connectorId'];

ServiceConnectionCreateType? _serviceConnectionCreateType(String? type) =>
    ServiceConnectionCreateTypeQuery.fromQueryValue(type);

String? _serviceConnectionCreateReturnPath(
  String? returnPath,
  String? crossShellReturnPath,
) => returnPath ?? crossShellReturnPath;

({GlobalKey<NavigatorState>? navigatorKey, String? returnLocation})?
_crossShellCreateReturn(Object? extra) => switch (extra) {
  FeatureDestinationStackPush(
    :final sourceNavigatorKey,
    :final parentNavigatorKey,
    :final returnLocation,
  ) =>
    (
      navigatorKey:
          sourceNavigatorKey != null &&
              sourceNavigatorKey != connectionsFeatureNavigatorKey
          ? parentNavigatorKey
          : null,
      returnLocation: returnLocation,
    ),
  _ => null,
};

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
}) extends _AppGoRouteData with $ServiceConnectionEditRoute {
  @override
  FutureOr<bool> onExit(BuildContext context, GoRouterState state) =>
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
    extends _AppGoRouteData
    with $SettingsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SettingsScreen(workspaceId: workspaceId);
  }
}

class WorkspaceSettingsRoute({required final String workspaceId})
    extends _AppGoRouteData
    with $WorkspaceSettingsRoute {
  final DraftExitGuard _exitGuard = .new();

  @override
  FutureOr<bool> onExit(BuildContext context, GoRouterState state) =>
      _canExitDraft(context, state);

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      WorkspaceSettingsScreen(
        workspaceId: workspaceId,
        guard: _exitGuard,
        key: ValueKey(workspaceId),
      );
}

class CloudAccountsRoute({required final String workspaceId})
    extends _AppGoRouteData
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
}) extends _AppGoRouteData with $CloudWorkspaceDetailRoute {
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
}) extends _AppGoRouteData with $CloudAccountAddRoute {
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
}) extends _AppGoRouteData with $CloudAccountLoginRoute {
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
}) extends _AppGoRouteData with $CloudAccountRegisterRoute {
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
}) extends _AppGoRouteData with $CloudAccountForgotPasswordRoute {
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
}) extends _AppGoRouteData with $WorkspaceManagementRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return WorkspaceManagementScreen(
      workspaceId: workspaceId,
      connectView: view == 'connect',
    );
  }
}

class WorkspaceCreateRoute({required final String workspaceId})
    extends _AppGoRouteData
    with $WorkspaceCreateRoute {
  @override
  FutureOr<bool> onExit(BuildContext context, GoRouterState state) =>
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

FutureOr<bool> _canExitDraft(BuildContext context, GoRouterState state) {
  final registry = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(draftExitRegistryProvider);
  if (registry.canUseNativeBack(.of(context))) return true;

  return registry.canExitRoute(state.uri);
}

class WorkspaceItemsRoute({required final String workspaceId})
    extends _AppGoRouteData
    with $WorkspaceItemsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      WorkspaceItemsScreen(
        workspaceId: workspaceId,
        key: ValueKey(workspaceId),
      );
}
