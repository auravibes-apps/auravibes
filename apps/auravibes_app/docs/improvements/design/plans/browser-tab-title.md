# Fix: Update browser title from the current route

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/browser-tab-title
- **Needs new dependency**: none

## Why

`MaterialApp.router` sets one static title. GoRouter already exposes a listened route-information provider, but the title does not consume it.

## Where

`apps/auravibes_app/lib/main.dart:292-303`

```dart
  }) : super.router(
         routerConfig: routerConfig,
         builder: (context, child) => TweenAnimationBuilder<AuraTheme>(
           tween: _AuraThemeTween(end: targetAuraTheme),
           duration: kThemeAnimationDuration,
           builder: (context, theme, _) => AuraThemeScope(
             theme: theme,
             child: _snackBarBuilder(context, child),
           ),
         ),
         title: AppFlavorConfig.instance.title,
         theme: lightTheme,
```

`apps/auravibes_app/lib/providers/router_providers.dart:52-56`

```dart
final routerInformationProvider = Provider<GoRouteInformationProvider>((ref) {
  final router = ref.watch(routerProvider);

  return ref.listenAndDisposeChangeNotifier(router.routeInformationProvider);
});
```

`apps/auravibes_app/lib/router/workspace_route.dart:56-155`

```dart
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
```

## The fix

Add this wrapper beside `_AuraMaterialApp`; it is the article's `ListenableBuilder` pattern adapted to the injected router and existing localization keys:

```dart
class const _RouteTitle({
  required final GoRouter router,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: .merge([
      router.routerDelegate,
      router.routeInformationProvider,
    ]),
    builder: (context, _) {
      final key = titleKeyForPath(
        router.routeInformationProvider.value.uri.path,
      );
      final appTitle = AppFlavorConfig.instance.title;
      final title = key == null
          ? appTitle
          : '${key.tr(context: context)} - $appTitle';

      return Title(
        title: title,
        color: Theme.of(context).colorScheme.surface,
        child: child,
      );
    },
  );
}

String? titleKeyForPath(String path) {
  final segments = Uri.parse(path).pathSegments;
  if (path == '/') return LocaleKeys.intro_flow_welcome_title;
  if (segments case ['intro', ...]) {
    return LocaleKeys.intro_flow_welcome_title;
  }
  if (segments.length < 3 || segments.firstOrNull != 'workspaces') return null;

  if (segments[2] == 'chat') return LocaleKeys.menu_new_chat;
  if (segments[2] == 'chats') return LocaleKeys.menu_chats;
  if (segments[2] == 'settings') return LocaleKeys.settings_screen_title;
  if (segments[2] != 'more') return null;
  if (segments.length < 4) return LocaleKeys.more_screen_title;

  return switch (segments[3]) {
    'manage-workspaces' => LocaleKeys.workspace_management_title,
    'cloud-accounts' when segments.length > 4 => switch (segments[4]) {
      'login' => LocaleKeys.cloud_accounts_login_existing,
      'register' => LocaleKeys.cloud_accounts_register,
      'forgot-password' => LocaleKeys.cloud_accounts_forgot_password,
      _ => LocaleKeys.cloud_accounts_title,
    },
    'cloud-accounts' => LocaleKeys.cloud_accounts_title,
    'tools' => LocaleKeys.tools_screen_title,
    'models' => LocaleKeys.models_screens_title,
    'service-connections' => LocaleKeys.service_connections_title,
    'skills' => LocaleKeys.skills_screen_title,
    'skill-credential-definitions' =>
      LocaleKeys.skill_credentials_definitions_title,
    'agents' => LocaleKeys.agents_title,
    _ => null,
  };
}
```

Wrap the existing builder result without removing `AuraThemeScope` or `_snackBarBuilder`:

```dart
child: _RouteTitle(
  router: routerConfig,
  child: _snackBarBuilder(context, child),
),
```

Keep the static `title` fallback. Do not use `onGenerateTitle` alone; it does not rebuild for route changes. Detail routes deliberately use stable section titles because entity names are asynchronous.

## Steps

1. Add localized title keys only where an existing screen/menu key cannot be reused.
2. Add a pure `titleKeyForPath(String path)` matcher ordered from most-specific to broadest.
3. Add the listable wrapper to the existing `MaterialApp.builder` chain.
4. Add tests for every top-level route group, a detail route, query strings, intro, and unknown fallback.
5. Navigate across routes in a web build and inspect tab/history titles.

## Check it

```sh
fvm flutter test test/main_test.dart test/providers/router_providers_test.dart --no-pub
fvm dart run melos run generate:localization
fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine
```

## Don't touch

- Route paths, redirects, or generated route files.
- On-screen app-bar titles.
- Native window-title plugins.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- A desired detail title needs asynchronous entity data. Use the stable localized section title in this plan; dynamic entity names are separate scope.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report route cases tested and observed browser titles.

## Attempt log

- 2026-09-27: Added a route-listening `Title` wrapper around the existing app
  builder. Reused localized section titles, retained the flavor title as the
  unknown-route fallback, and mapped the initial `/` location to the intro
  title because the router can expose `/` before its first redirect. Focused
  main/router tests passed (46 tests); app fatal analyzer passed. A cold Chrome
  launch showed `Welcome to AuraVibes - AuraVibes Dev` at `#/intro`, and a local
  workspace navigation showed `New Chat - AuraVibes Dev`. Screenshot showed no
  app-surface layout change. Hot restart failed in Chrome's debug service, so
  the initial-route check used a cold launch. Automatic model sync warned
  because the local dev server at `localhost:8080` was unavailable; title checks
  still completed.
