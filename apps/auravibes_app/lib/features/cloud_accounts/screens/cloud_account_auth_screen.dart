import 'package:auravibes_app/features/cloud_accounts/models/cloud_auth_mode.dart';
import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_auth_content.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/task_return.dart';
import 'package:auravibes_app/router/workspace_navigation.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/bottom_padding.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class const CloudAccountAuthScreen({
  required final String workspaceId,
  required final String? returnPath,
  final Map<String, String> query = const {},
  final CloudAuthMode mode = .login,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final routeUri = GoRouter.maybeOf(context) == null
        ? null
        : GoRouterState.of(context).uri;
    final generated = query['return-path'] ?? returnPath;
    final legacy = query['returnPath'];
    final compatible =
        generated == null || legacy == null || generated == legacy;
    final destination =
        TaskReturn.validate(
          compatible ? generated ?? legacy : null,
          workspaceId: workspaceId,
        ) ??
        CloudAccountsRoute(workspaceId: workspaceId).location;

    return AuraScreen(
      child: ListView(
        padding: const EdgeInsets.all(16)
            .copyWith(bottom: BottomPadding.of(context)),
        children: [
          CloudAccountAuthContent(
            onSignedIn: (_) => _return(context, routeUri, destination),
            onCancel: () => _return(context, routeUri, destination),
            target: .fromQuery(query),
            initialMode: mode,
            onModeChanged: (next) => _changeMode(context, routeUri, next),
            passwordChanged: query['password-changed'] == 'true',
            returnTaskLabel: _returnTaskKey(destination).tr(context: context),
          ),
        ],
        keyboardDismissBehavior: .onDrag,
      ),
    );
  }

  String _returnTaskKey(String destination) {
    final uri = Uri.parse(destination);

    return switch (WorkspaceNavigation.classify(uri)) {
      .chats => LocaleKeys.navigation_chats,
      .agentsAndSkills => LocaleKeys.navigation_agents_skills,
      .connections => LocaleKeys.navigation_connections,
      .appSettings => LocaleKeys.settings_screen_title,
      .cloudAccounts => LocaleKeys.cloud_accounts_title,
      null =>
        uri.pathSegments.lastOrNull == 'workspace-settings'
            ? LocaleKeys.navigation_workspace_settings
            : LocaleKeys.workspace_management_title,
    };
  }

  bool _ownsNavigation(BuildContext context, Uri? routeUri) =>
      context.mounted &&
      routeUri != null &&
      ModalRoute.of(context)?.isCurrent == true &&
      GoRouter.of(context).state.uri == routeUri;

  void _return(BuildContext context, Uri? routeUri, String destination) {
    if (!_ownsNavigation(context, routeUri)) return;
    context.go(destination);
  }

  void _changeMode(
    BuildContext context,
    Uri? routeUri,
    CloudAuthNavigation next,
  ) {
    if (!_ownsNavigation(context, routeUri)) return;
    final location = switch (next.mode) {
      .login => CloudAccountLoginRoute(workspaceId: workspaceId).location,
      .register => CloudAccountRegisterRoute(workspaceId: workspaceId).location,
      .forgotPassword => CloudAccountForgotPasswordRoute(
        workspaceId: workspaceId,
      ).location,
    };
    context.go(
      Uri.parse(location)
          .replace(
            queryParameters: {
              ...query,
              'return-path': ?returnPath,
              'email': next.email,
              'password-changed': '${next.passwordChanged}',
            },
          )
          .toString(),
    );
  }
}
