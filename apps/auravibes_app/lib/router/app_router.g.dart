// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

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
            GoRouteData.$route(path: 'tools', factory: $ToolsRoute._fromState),
          ],
        ),
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: 'models',
              factory: $ModelsRoute._fromState,
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

mixin $ToolsRoute on GoRouteData {
  static ToolsRoute _fromState(GoRouterState state) =>
      ToolsRoute(workspaceId: state.pathParameters['workspaceId']!);

  ToolsRoute get _self => this as ToolsRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/tools',
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
    '/workspaces/${Uri.encodeComponent(_self.workspaceId)}/models',
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
