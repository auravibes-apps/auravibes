import 'package:auravibes_app/features/cloud_accounts/data/cloud_account_session.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_auth_mode.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_auth_target.dart';
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
  Widget build(BuildContext context) => _CloudAccountAuthScreenScaffold(
    data: _cloudAccountAuthScreenViewData(this, context),
  );

  String _returnDestination() {
    final generated = query['return-path'] ?? returnPath;
    final legacy = query['returnPath'];
    final compatible =
        generated == null || legacy == null || generated == legacy;

    return TaskReturn.validate(
          compatible ? generated ?? legacy : null,
          workspaceId: workspaceId,
        ) ??
        CloudAccountsRoute(workspaceId: workspaceId).location;
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
    _navigateIfCurrent(context, routeUri, destination);
  }

  void _changeMode(
    BuildContext context,
    Uri? routeUri,
    CloudAuthNavigation next,
  ) {
    _navigateIfCurrent(context, routeUri, _modeLocation(next));
  }

  void _navigateIfCurrent(
    BuildContext context,
    Uri? routeUri,
    String destination,
  ) {
    if (!_ownsNavigation(context, routeUri)) return;
    context.go(destination);
  }

  String _modeLocation(CloudAuthNavigation next) {
    final location = switch (next.mode) {
      .login => CloudAccountLoginRoute(workspaceId: workspaceId).location,
      .register => CloudAccountRegisterRoute(workspaceId: workspaceId).location,
      .forgotPassword => CloudAccountForgotPasswordRoute(
        workspaceId: workspaceId,
      ).location,
    };

    return Uri.parse(location)
        .replace(queryParameters: _modeQueryParameters(next))
        .toString();
  }

  Map<String, String> _modeQueryParameters(CloudAuthNavigation next) => {
    ...query,
    'return-path': ?returnPath,
    'email': next.email,
    'password-changed': '${next.passwordChanged}',
  };
}

typedef _CloudAccountAuthScreenViewData = ({
  CloudAccountAuthScreen screen,
  Uri? routeUri,
  String destination,
});

_CloudAccountAuthScreenViewData _cloudAccountAuthScreenViewData(
  CloudAccountAuthScreen screen,
  BuildContext context,
) => (
  screen: screen,
  routeUri: _currentCloudAccountRoute(context),
  destination: screen._returnDestination(),
);

Uri? _currentCloudAccountRoute(BuildContext context) =>
    GoRouter.maybeOf(context) == null ? null : GoRouterState.of(context).uri;

class const _CloudAccountAuthScreenScaffold({
  required final _CloudAccountAuthScreenViewData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraScreen(
    child: ListView(
      padding: const EdgeInsets.all(16)
          .copyWith(bottom: BottomPadding.of(context)),
      children: [_CloudAccountAuthScreenView(data: data)],
      keyboardDismissBehavior: .onDrag,
    ),
  );
}

class const _CloudAccountAuthScreenView({
  required final _CloudAccountAuthScreenViewData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _CloudAccountAuthScreenContent(
    request: _cloudAccountAuthContentRequest(context, data),
  );
}

typedef _CloudAccountAuthScreenCallbacks = ({
  ValueChanged<CloudAccountSession> onSignedIn,
  VoidCallback onCancel,
  ValueChanged<CloudAuthNavigation> onModeChanged,
});

_CloudAccountAuthScreenCallbacks _cloudAccountAuthScreenCallbacks(
  BuildContext context,
  _CloudAccountAuthScreenViewData data,
) => (
  onSignedIn: _cloudAuthSignedInCallback(context, data),
  onCancel: _cloudAuthCancelCallback(context, data),
  onModeChanged: _cloudAuthModeChangedCallback(context, data),
);

ValueChanged<CloudAccountSession> _cloudAuthSignedInCallback(
  BuildContext context,
  _CloudAccountAuthScreenViewData data,
) =>
    (_) => data.screen._return(context, data.routeUri, data.destination);

VoidCallback _cloudAuthCancelCallback(
  BuildContext context,
  _CloudAccountAuthScreenViewData data,
) =>
    () => data.screen._return(context, data.routeUri, data.destination);

ValueChanged<CloudAuthNavigation> _cloudAuthModeChangedCallback(
  BuildContext context,
  _CloudAccountAuthScreenViewData data,
) =>
    (next) => data.screen._changeMode(context, data.routeUri, next);

typedef _CloudAccountAuthContentRequest = ({
  _CloudAccountAuthScreenCallbacks callbacks,
  CloudAuthTarget target,
  CloudAuthMode initialMode,
  bool passwordChanged,
  String returnTaskLabel,
});

_CloudAccountAuthContentRequest _cloudAccountAuthContentRequest(
  BuildContext context,
  _CloudAccountAuthScreenViewData data,
) {
  final screen = data.screen;
  final query = screen.query;

  return (
    callbacks: _cloudAccountAuthScreenCallbacks(context, data),
    target: CloudAuthTarget.fromQuery(query),
    initialMode: screen.mode,
    passwordChanged: _cloudAuthPasswordWasChanged(query),
    returnTaskLabel: _cloudAuthReturnTaskLabel(
      screen,
      data.destination,
      context,
    ),
  );
}

class const _CloudAccountAuthScreenContent({
  required final _CloudAccountAuthContentRequest request,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final callbacks = request.callbacks;

    return CloudAccountAuthContent(
      onSignedIn: callbacks.onSignedIn,
      onCancel: callbacks.onCancel,
      target: request.target,
      initialMode: request.initialMode,
      onModeChanged: callbacks.onModeChanged,
      passwordChanged: request.passwordChanged,
      returnTaskLabel: request.returnTaskLabel,
    );
  }
}

bool _cloudAuthPasswordWasChanged(Map<String, String> query) =>
    query['password-changed'] == 'true';

String _cloudAuthReturnTaskLabel(
  CloudAccountAuthScreen screen,
  String destination,
  BuildContext context,
) => screen._returnTaskKey(destination).tr(context: context);
