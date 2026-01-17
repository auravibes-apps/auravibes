// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$myShellRouteData];

RouteBase get $myShellRouteData => StatefulShellRouteData.$route(
  factory: $MyShellRouteDataExtension._fromState,
  branches: [
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/chat/new',
          factory: $NewChatRoute._fromState,
        ),
        GoRouteData.$route(
          path: '/chats/:chatId',
          factory: $CoversationRoute._fromState,
        ),
        GoRouteData.$route(path: '/chats', factory: $ChatsRoute._fromState),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(path: '/tools', factory: $ToolsRoute._fromState),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(path: '/models', factory: $ModelsRoute._fromState),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/settings',
          factory: $SettingsRoute._fromState,
        ),
      ],
    ),
  ],
);

extension $MyShellRouteDataExtension on MyShellRouteData {
  static MyShellRouteData _fromState(GoRouterState state) =>
      const MyShellRouteData();
}

mixin $NewChatRoute on GoRouteData {
  static NewChatRoute _fromState(GoRouterState state) => NewChatRoute();

  @override
  String get location => GoRouteData.$location('/chat/new');

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

mixin $CoversationRoute on GoRouteData {
  static CoversationRoute _fromState(GoRouterState state) =>
      CoversationRoute(chatId: state.pathParameters['chatId']!);

  CoversationRoute get _self => this as CoversationRoute;

  @override
  String get location =>
      GoRouteData.$location('/chats/${Uri.encodeComponent(_self.chatId)}');

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
  static ChatsRoute _fromState(GoRouterState state) => ChatsRoute();

  @override
  String get location => GoRouteData.$location('/chats');

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
  static ToolsRoute _fromState(GoRouterState state) => ToolsRoute();

  @override
  String get location => GoRouteData.$location('/tools');

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
  static ModelsRoute _fromState(GoRouterState state) => ModelsRoute();

  @override
  String get location => GoRouteData.$location('/models');

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
  static SettingsRoute _fromState(GoRouterState state) => SettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings');

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
