// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_route.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$workspaceRoute];

RouteBase get $workspaceRoute => GoRouteData.$route(
  path: '/workspaces/:workspaceId',
  factory: $WorkspaceRoute._fromState,
  routes: [
    StatefulShellRouteData.$route(
      factory: $MyShellRouteDataExtension._fromState,
      branches: [
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: 'chat/new',
              factory: $NewChatRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'chats/:chatId',
              factory: $ConversationRoute._fromState,
            ),
            GoRouteData.$route(path: 'chats', factory: $ChatsRoute._fromState),
          ],
        ),
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: 'more',
              factory: $MoreRoute._fromState,
              routes: [
                GoRouteData.$route(
                  path: 'manage-workspaces',
                  factory: $WorkspaceManagementRoute._fromState,
                ),
                GoRouteData.$route(
                  path: 'tools',
                  factory: $ToolsRoute._fromState,
                ),
                GoRouteData.$route(
                  path: 'models',
                  factory: $ModelsRoute._fromState,
                ),
                GoRouteData.$route(
                  path: 'service-connections',
                  factory: $ServiceConnectionsRoute._fromState,
                  routes: [
                    GoRouteData.$route(
                      path: 'new',
                      factory: $ServiceConnectionCreateRoute._fromState,
                    ),
                    GoRouteData.$route(
                      path: ':connectionId',
                      factory: $ServiceConnectionEditRoute._fromState,
                    ),
                  ],
                ),
                GoRouteData.$route(
                  path: 'skills',
                  factory: $SkillsRoute._fromState,
                  routes: [
                    GoRouteData.$route(
                      path: 'new',
                      factory: $SkillCreateRoute._fromState,
                    ),
                    GoRouteData.$route(
                      path: ':skillId/tools/new',
                      factory: $SkillToolCreateRoute._fromState,
                    ),
                    GoRouteData.$route(
                      path: ':skillId/tools/:toolId',
                      factory: $SkillToolEditRoute._fromState,
                    ),
                    GoRouteData.$route(
                      path: ':skillId',
                      factory: $SkillDetailRoute._fromState,
                    ),
                  ],
                ),
                GoRouteData.$route(
                  path: 'skill-credential-definitions',
                  factory: $SkillCredentialDefinitionsRoute._fromState,
                  routes: [
                    GoRouteData.$route(
                      path: 'new',
                      factory: $SkillCredentialDefinitionCreateRoute._fromState,
                    ),
                    GoRouteData.$route(
                      path: ':definitionId',
                      factory: $SkillCredentialDefinitionEditRoute._fromState,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: 'settings',
              factory: $SettingsRoute._fromState,
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
      );

  WorkspaceManagementRoute get _self => this as WorkspaceManagementRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/manage-workspaces',
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
      );

  ServiceConnectionsRoute get _self => this as ServiceConnectionsRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/service-connections',
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
      );

  SkillCredentialDefinitionCreateRoute get _self =>
      this as SkillCredentialDefinitionCreateRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/more/skill-credential-definitions/new',
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
