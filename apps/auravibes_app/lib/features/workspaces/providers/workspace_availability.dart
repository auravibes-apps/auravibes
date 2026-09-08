import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';

sealed class const WorkspaceAvailability(final WorkspaceSession session);

// ignore: unused-code, returned by workspaceAvailability provider.
final class const WorkspaceAvailable(super.session)
    extends WorkspaceAvailability;

final class const WorkspaceAuthenticationRequired(super.session)
    extends WorkspaceAvailability;
