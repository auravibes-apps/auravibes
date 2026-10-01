import 'package:auravibes_app/features/skills/providers/skill_access_summary_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credentials_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_template_tools_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void refreshSkillAccess(
  ProviderContainer container, {
  required String workspaceId,
  required String skillId,
  String? credentialDefinitionId,
  bool toolsChanged = false,
}) {
  if (toolsChanged) {
    container.invalidate(skillTemplateToolsProvider(workspaceId, skillId));
  }
  if (credentialDefinitionId != null) {
    container.invalidate(
      skillCredentialsForDefinitionProvider(
        workspaceId,
        credentialDefinitionId,
      ),
    );
  }
  container
    ..invalidate(appSkillCredentialCandidatesProvider(workspaceId, skillId))
    ..invalidate(skillAccessSummaryProvider(workspaceId, skillId));
}
