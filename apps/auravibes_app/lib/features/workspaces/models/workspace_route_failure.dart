import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

/// Structural failures cannot be repaired by retrying authentication.
class const WorkspaceRouteFailure({required final bool invalidMirror})
    implements Exception {
  String get localizationKey => invalidMirror
      ? LocaleKeys.route_state_invalid_workspace
      : LocaleKeys.route_state_workspace_missing;

  static bool requiresAuthentication(Object error) => switch (error) {
    CloudWorkspaceException(
      code: .authenticationRequired || .emailAccountRequired,
    ) ||
    ConversationException(code: .authenticationRequired) ||
    CloudAppException(
      localizationKey: LocaleKeys.cloud_errors_authentication_required,
    ) => true,
    _ => false,
  };
}
