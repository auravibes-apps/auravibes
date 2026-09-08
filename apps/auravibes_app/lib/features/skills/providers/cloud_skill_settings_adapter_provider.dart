import 'package:auravibes_app/features/skills/services/cloud_skill_settings_adapter.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:riverpod/riverpod.dart';

Future<CloudSkillSettingsAdapter?> cloudSkillSettingsAdapterForWorkspace(
  Ref ref,
  String workspaceId,
) async {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayForWorkspaceProvider(workspaceId).future,
  );

  return gateway == null ? null : CloudSkillSettingsAdapter(gateway);
}
