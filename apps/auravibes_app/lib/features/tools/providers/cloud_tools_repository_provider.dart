import 'package:auravibes_app/features/tools/data/cloud_tools_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

CloudToolsRepository? cloudToolsRepository(Ref ref, WorkspaceSession session) {
  if (session.cloud == null) return null;

  return CloudToolsRepository(
    ref.read(cloudWorkspaceStateGatewayProvider(session).future),
  );
}
