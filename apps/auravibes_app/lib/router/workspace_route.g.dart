// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_route.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$workspaceRoute, $introRoute];

RouteBase get $workspaceRoute => GoRouteData.$route(
  path: '/workspaces/:workspaceId',
  hasOverriddenOnExit: false,
  factory: $WorkspaceRoute._fromState,
  routes: [
    StatefulShellRouteData.$route(
      factory: $MyShellRouteDataExtension._fromState,
      branches: [
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: 'chat/new',
              hasOverriddenOnExit: true,
              factory: $NewChatRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'chats/:chatId',
              hasOverriddenOnExit: false,
              factory: $ConversationRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: 'sub-agents/:subAgentConversationId',
                  hasOverriddenOnExit: false,
                  factory: $SubAgentConversationRoute._fromState,
                ),
              ],
            ),
            GoRouteData.$route(
              path: 'chats',
              hasOverriddenOnExit: false,
              factory: $ChatsRoute._fromState,
            ),
          ],
        ),
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: 'more',
              hasOverriddenOnExit: false,
              factory: $MoreRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'more/manage-workspaces',
              hasOverriddenOnExit: false,
              factory: $WorkspaceManagementRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: 'create',
                  hasOverriddenOnExit: true,
                  factory: $WorkspaceCreateRoute._fromState,
                ),
                GoRouteData.$route(
                  path: 'cloud/:cloudAccountId/:cloudWorkspaceId',
                  hasOverriddenOnExit: false,
                  factory: $CloudWorkspaceDetailRoute._fromState,
                ),
              ],
            ),
            GoRouteData.$route(
              path: 'more/cloud-accounts',
              hasOverriddenOnExit: false,
              factory: $CloudAccountsRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: 'add',
                  hasOverriddenOnExit: false,
                  factory: $CloudAccountAddRoute._fromState,
                ),
                GoRouteData.$route(
                  path: 'login',
                  hasOverriddenOnExit: false,
                  factory: $CloudAccountLoginRoute._fromState,
                ),
                GoRouteData.$route(
                  path: 'register',
                  hasOverriddenOnExit: false,
                  factory: $CloudAccountRegisterRoute._fromState,
                ),
                GoRouteData.$route(
                  path: 'forgot-password',
                  hasOverriddenOnExit: false,
                  factory: $CloudAccountForgotPasswordRoute._fromState,
                ),
              ],
            ),
            GoRouteData.$route(
              path: 'more/tools',
              hasOverriddenOnExit: false,
              factory: $ToolsRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'more/models',
              hasOverriddenOnExit: false,
              factory: $ModelsRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'more/service-connections',
              hasOverriddenOnExit: false,
              factory: $ServiceConnectionsRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: 'new',
                  hasOverriddenOnExit: true,
                  factory: $ServiceConnectionCreateRoute._fromState,
                ),
                GoRouteData.$route(
                  path: ':connectionId',
                  hasOverriddenOnExit: true,
                  factory: $ServiceConnectionEditRoute._fromState,
                ),
              ],
            ),
            GoRouteData.$route(
              path: 'more/skills',
              hasOverriddenOnExit: false,
              factory: $SkillsRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: 'new',
                  hasOverriddenOnExit: true,
                  factory: $SkillCreateRoute._fromState,
                ),
                GoRouteData.$route(
                  path: ':skillId/tools/new',
                  hasOverriddenOnExit: true,
                  factory: $SkillToolCreateRoute._fromState,
                ),
                GoRouteData.$route(
                  path: ':skillId/tools/:toolId',
                  hasOverriddenOnExit: true,
                  factory: $SkillToolEditRoute._fromState,
                ),
                GoRouteData.$route(
                  path: ':skillId/resources/new',
                  hasOverriddenOnExit: true,
                  factory: $SkillResourceCreateRoute._fromState,
                ),
                GoRouteData.$route(
                  path: ':skillId/resources/:resourceId',
                  hasOverriddenOnExit: true,
                  factory: $SkillResourceEditRoute._fromState,
                ),
                GoRouteData.$route(
                  path: ':skillId',
                  hasOverriddenOnExit: true,
                  factory: $SkillDetailRoute._fromState,
                ),
              ],
            ),
            GoRouteData.$route(
              path: 'more/skill-credential-definitions',
              hasOverriddenOnExit: false,
              factory: $SkillCredentialDefinitionsRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: 'new',
                  hasOverriddenOnExit: true,
                  factory: $SkillCredentialDefinitionCreateRoute._fromState,
                ),
                GoRouteData.$route(
                  path: ':definitionId',
                  hasOverriddenOnExit: true,
                  factory: $SkillCredentialDefinitionEditRoute._fromState,
                ),
              ],
            ),
            GoRouteData.$route(
              path: 'more/agents',
              hasOverriddenOnExit: false,
              factory: $AgentsRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: 'new',
                  hasOverriddenOnExit: true,
                  factory: $AgentCreateRoute._fromState,
                ),
                GoRouteData.$route(
                  path: ':agentId',
                  hasOverriddenOnExit: true,
                  factory: $AgentDetailRoute._fromState,
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: 'settings',
              hasOverriddenOnExit: false,
              factory: $SettingsRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'workspace-settings',
              hasOverriddenOnExit: true,
              factory: $WorkspaceSettingsRoute._fromState,
            ),
          ],
        ),
      ],
    ),
  ],
);

mixin $WorkspaceRoute on GoRouteData {
  static WorkspaceRoute _fromState(GoRouterState state) =>
      WorkspaceRoute(workspaceId: state.pathParameters['workspaceId']!);

  WorkspaceRoute get _self => this as WorkspaceRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

extension $MyShellRouteDataExtension on MyShellRouteData {
  static MyShellRouteData _fromState(GoRouterState state) =>
      const MyShellRouteData();
}

mixin $NewChatRoute on GoRouteData {
  static NewChatRoute _fromState(GoRouterState state) =>
      NewChatRoute(workspaceId: state.pathParameters['workspaceId']!);

  NewChatRoute get _self => this as NewChatRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/chat/new',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ConversationRoute on GoRouteData {
  static ConversationRoute _fromState(GoRouterState state) => ConversationRoute(
    workspaceId: state.pathParameters['workspaceId']!,
    chatId: state.pathParameters['chatId']!,
  );

  ConversationRoute get _self => this as ConversationRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/chats/${Uri.encodeComponent(_self.chatId)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SubAgentConversationRoute on GoRouteData {
  static SubAgentConversationRoute _fromState(GoRouterState state) =>
      SubAgentConversationRoute(
        workspaceId: state.pathParameters['workspaceId']!,
        chatId: state.pathParameters['chatId']!,
        subAgentConversationId: state.pathParameters['subAgentConversationId']!,
      );

  SubAgentConversationRoute get _self => this as SubAgentConversationRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/chats/${Uri.encodeComponent(_self.chatId)}/sub-agents/${Uri.encodeComponent(_self.subAgentConversationId)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ChatsRoute on GoRouteData {
  static ChatsRoute _fromState(GoRouterState state) =>
      ChatsRoute(workspaceId: state.pathParameters['workspaceId']!);

  ChatsRoute get _self => this as ChatsRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/chats',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $MoreRoute on GoRouteData {
  static MoreRoute _fromState(GoRouterState state) =>
      MoreRoute(workspaceId: state.pathParameters['workspaceId']!);

  MoreRoute get _self => this as MoreRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $WorkspaceManagementRoute on GoRouteData {
  static WorkspaceManagementRoute _fromState(GoRouterState state) =>
      WorkspaceManagementRoute(
        workspaceId: state.pathParameters['workspaceId']!,
        view: state.uri.queryParameters['view'],
      );

  WorkspaceManagementRoute get _self => this as WorkspaceManagementRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/manage-workspaces',
    queryParams: {if (_self.view != null) 'view': _self.view},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $WorkspaceCreateRoute on GoRouteData {
  static WorkspaceCreateRoute _fromState(GoRouterState state) =>
      WorkspaceCreateRoute(workspaceId: state.pathParameters['workspaceId']!);

  WorkspaceCreateRoute get _self => this as WorkspaceCreateRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/manage-workspaces/create',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $CloudWorkspaceDetailRoute on GoRouteData {
  static CloudWorkspaceDetailRoute _fromState(GoRouterState state) =>
      CloudWorkspaceDetailRoute(
        workspaceId: state.pathParameters['workspaceId']!,
        cloudAccountId: state.pathParameters['cloudAccountId']!,
        cloudWorkspaceId: int.parse(state.pathParameters['cloudWorkspaceId']!),
        serverUrl: state.uri.queryParameters['server-url'],
      );

  CloudWorkspaceDetailRoute get _self => this as CloudWorkspaceDetailRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/manage-workspaces/cloud/${Uri.encodeComponent(_self.cloudAccountId)}/${Uri.encodeComponent(_self.cloudWorkspaceId.toString())}',
    queryParams: {if (_self.serverUrl != null) 'server-url': _self.serverUrl},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $CloudAccountsRoute on GoRouteData {
  static CloudAccountsRoute _fromState(GoRouterState state) =>
      CloudAccountsRoute(workspaceId: state.pathParameters['workspaceId']!);

  CloudAccountsRoute get _self => this as CloudAccountsRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/cloud-accounts',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $CloudAccountAddRoute on GoRouteData {
  static CloudAccountAddRoute _fromState(GoRouterState state) =>
      CloudAccountAddRoute(
        workspaceId: state.pathParameters['workspaceId']!,
        returnPath: state.uri.queryParameters['return-path'],
      );

  CloudAccountAddRoute get _self => this as CloudAccountAddRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/cloud-accounts/add',
    queryParams: {
      if (_self.returnPath != null) 'return-path': _self.returnPath,
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $CloudAccountLoginRoute on GoRouteData {
  static CloudAccountLoginRoute _fromState(GoRouterState state) =>
      CloudAccountLoginRoute(
        workspaceId: state.pathParameters['workspaceId']!,
        returnPath: state.uri.queryParameters['return-path'],
      );

  CloudAccountLoginRoute get _self => this as CloudAccountLoginRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/cloud-accounts/login',
    queryParams: {
      if (_self.returnPath != null) 'return-path': _self.returnPath,
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $CloudAccountRegisterRoute on GoRouteData {
  static CloudAccountRegisterRoute _fromState(GoRouterState state) =>
      CloudAccountRegisterRoute(
        workspaceId: state.pathParameters['workspaceId']!,
        returnPath: state.uri.queryParameters['return-path'],
      );

  CloudAccountRegisterRoute get _self => this as CloudAccountRegisterRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/cloud-accounts/register',
    queryParams: {
      if (_self.returnPath != null) 'return-path': _self.returnPath,
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $CloudAccountForgotPasswordRoute on GoRouteData {
  static CloudAccountForgotPasswordRoute _fromState(GoRouterState state) =>
      CloudAccountForgotPasswordRoute(
        workspaceId: state.pathParameters['workspaceId']!,
        returnPath: state.uri.queryParameters['return-path'],
      );

  CloudAccountForgotPasswordRoute get _self =>
      this as CloudAccountForgotPasswordRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/cloud-accounts/forgot-password',
    queryParams: {
      if (_self.returnPath != null) 'return-path': _self.returnPath,
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ToolsRoute on GoRouteData {
  static ToolsRoute _fromState(GoRouterState state) =>
      ToolsRoute(workspaceId: state.pathParameters['workspaceId']!);

  ToolsRoute get _self => this as ToolsRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/tools',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ModelsRoute on GoRouteData {
  static ModelsRoute _fromState(GoRouterState state) =>
      ModelsRoute(workspaceId: state.pathParameters['workspaceId']!);

  ModelsRoute get _self => this as ModelsRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/models',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ServiceConnectionsRoute on GoRouteData {
  static ServiceConnectionsRoute _fromState(GoRouterState state) =>
      ServiceConnectionsRoute(
        workspaceId: state.pathParameters['workspaceId']!,
        view: state.uri.queryParameters['view'],
      );

  ServiceConnectionsRoute get _self => this as ServiceConnectionsRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/service-connections',
    queryParams: {if (_self.view != null) 'view': _self.view},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ServiceConnectionCreateRoute on GoRouteData {
  static ServiceConnectionCreateRoute _fromState(GoRouterState state) =>
      ServiceConnectionCreateRoute(
        workspaceId: state.pathParameters['workspaceId']!,
        returnPath: state.uri.queryParameters['return-path'],
        type: state.uri.queryParameters['type'],
        credentialDefinitionId:
            state.uri.queryParameters['credentialDefinitionId'],
      );

  ServiceConnectionCreateRoute get _self =>
      this as ServiceConnectionCreateRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/service-connections/new',
    queryParams: {
      if (_self.returnPath != null) 'return-path': _self.returnPath,
      if (_self.type != null) 'type': _self.type,
      if (_self.credentialDefinitionId != null)
        'credentialDefinitionId': _self.credentialDefinitionId,
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ServiceConnectionEditRoute on GoRouteData {
  static ServiceConnectionEditRoute _fromState(GoRouterState state) =>
      ServiceConnectionEditRoute(
        workspaceId: state.pathParameters['workspaceId']!,
        connectionId: state.pathParameters['connectionId']!,
      );

  ServiceConnectionEditRoute get _self => this as ServiceConnectionEditRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/service-connections/${Uri.encodeComponent(_self.connectionId)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SkillsRoute on GoRouteData {
  static SkillsRoute _fromState(GoRouterState state) =>
      SkillsRoute(workspaceId: state.pathParameters['workspaceId']!);

  SkillsRoute get _self => this as SkillsRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/skills',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SkillCreateRoute on GoRouteData {
  static SkillCreateRoute _fromState(GoRouterState state) =>
      SkillCreateRoute(workspaceId: state.pathParameters['workspaceId']!);

  SkillCreateRoute get _self => this as SkillCreateRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/skills/new',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SkillToolCreateRoute on GoRouteData {
  static SkillToolCreateRoute _fromState(GoRouterState state) =>
      SkillToolCreateRoute(
        workspaceId: state.pathParameters['workspaceId']!,
        skillId: state.pathParameters['skillId']!,
      );

  SkillToolCreateRoute get _self => this as SkillToolCreateRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/skills/${Uri.encodeComponent(_self.skillId)}/tools/new',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SkillToolEditRoute on GoRouteData {
  static SkillToolEditRoute _fromState(GoRouterState state) =>
      SkillToolEditRoute(
        workspaceId: state.pathParameters['workspaceId']!,
        skillId: state.pathParameters['skillId']!,
        toolId: state.pathParameters['toolId']!,
      );

  SkillToolEditRoute get _self => this as SkillToolEditRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/skills/${Uri.encodeComponent(_self.skillId)}/tools/${Uri.encodeComponent(_self.toolId)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SkillResourceCreateRoute on GoRouteData {
  static SkillResourceCreateRoute _fromState(GoRouterState state) =>
      SkillResourceCreateRoute(
        workspaceId: state.pathParameters['workspaceId']!,
        skillId: state.pathParameters['skillId']!,
      );

  SkillResourceCreateRoute get _self => this as SkillResourceCreateRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/skills/${Uri.encodeComponent(_self.skillId)}/resources/new',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SkillResourceEditRoute on GoRouteData {
  static SkillResourceEditRoute _fromState(GoRouterState state) =>
      SkillResourceEditRoute(
        workspaceId: state.pathParameters['workspaceId']!,
        skillId: state.pathParameters['skillId']!,
        resourceId: state.pathParameters['resourceId']!,
      );

  SkillResourceEditRoute get _self => this as SkillResourceEditRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/skills/${Uri.encodeComponent(_self.skillId)}/resources/${Uri.encodeComponent(_self.resourceId)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SkillDetailRoute on GoRouteData {
  static SkillDetailRoute _fromState(GoRouterState state) => SkillDetailRoute(
    workspaceId: state.pathParameters['workspaceId']!,
    skillId: state.pathParameters['skillId']!,
  );

  SkillDetailRoute get _self => this as SkillDetailRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/skills/${Uri.encodeComponent(_self.skillId)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SkillCredentialDefinitionsRoute on GoRouteData {
  static SkillCredentialDefinitionsRoute _fromState(GoRouterState state) =>
      SkillCredentialDefinitionsRoute(
        workspaceId: state.pathParameters['workspaceId']!,
      );

  SkillCredentialDefinitionsRoute get _self =>
      this as SkillCredentialDefinitionsRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/skill-credential-definitions',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SkillCredentialDefinitionCreateRoute on GoRouteData {
  static SkillCredentialDefinitionCreateRoute _fromState(GoRouterState state) =>
      SkillCredentialDefinitionCreateRoute(
        workspaceId: state.pathParameters['workspaceId']!,
        returnCreated:
            _$convertMapValue(
              'return-created',
              state.uri.queryParameters,
              _$boolConverter,
            ) ??
            false,
      );

  SkillCredentialDefinitionCreateRoute get _self =>
      this as SkillCredentialDefinitionCreateRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/skill-credential-definitions/new',
    queryParams: {
      if (_self.returnCreated != false)
        'return-created': _self.returnCreated.toString(),
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SkillCredentialDefinitionEditRoute on GoRouteData {
  static SkillCredentialDefinitionEditRoute _fromState(GoRouterState state) =>
      SkillCredentialDefinitionEditRoute(
        workspaceId: state.pathParameters['workspaceId']!,
        definitionId: state.pathParameters['definitionId']!,
      );

  SkillCredentialDefinitionEditRoute get _self =>
      this as SkillCredentialDefinitionEditRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/skill-credential-definitions/${Uri.encodeComponent(_self.definitionId)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AgentsRoute on GoRouteData {
  static AgentsRoute _fromState(GoRouterState state) =>
      AgentsRoute(workspaceId: state.pathParameters['workspaceId']!);

  AgentsRoute get _self => this as AgentsRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/agents',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AgentCreateRoute on GoRouteData {
  static AgentCreateRoute _fromState(GoRouterState state) =>
      AgentCreateRoute(workspaceId: state.pathParameters['workspaceId']!);

  AgentCreateRoute get _self => this as AgentCreateRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/agents/new',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AgentDetailRoute on GoRouteData {
  static AgentDetailRoute _fromState(GoRouterState state) => AgentDetailRoute(
    workspaceId: state.pathParameters['workspaceId']!,
    agentId: state.pathParameters['agentId']!,
  );

  AgentDetailRoute get _self => this as AgentDetailRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/agents/${Uri.encodeComponent(_self.agentId)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SettingsRoute on GoRouteData {
  static SettingsRoute _fromState(GoRouterState state) =>
      SettingsRoute(workspaceId: state.pathParameters['workspaceId']!);

  SettingsRoute get _self => this as SettingsRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/settings',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $WorkspaceSettingsRoute on GoRouteData {
  static WorkspaceSettingsRoute _fromState(GoRouterState state) =>
      WorkspaceSettingsRoute(workspaceId: state.pathParameters['workspaceId']!);

  WorkspaceSettingsRoute get _self => this as WorkspaceSettingsRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/workspace-settings',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

T? _$convertMapValue<T>(
  String key,
  Map<String, String> map,
  T? Function(String) converter,
) {
  final value = map[key];
  return value == null ? null : converter(value);
}

bool _$boolConverter(String value) {
  switch (value) {
    case 'true':
      return true;
    case 'false':
      return false;
    default:
      throw UnsupportedError('Cannot convert "$value" into a bool.');
  }
}

RouteBase get $introRoute => GoRouteData.$route(
  path: '/intro',
  hasOverriddenOnExit: false,
  factory: $IntroRoute._fromState,
);

mixin $IntroRoute on GoRouteData {
  static IntroRoute _fromState(GoRouterState state) => const IntroRoute();

  @override
  String get location => GoRouteData.$location('/intro');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
