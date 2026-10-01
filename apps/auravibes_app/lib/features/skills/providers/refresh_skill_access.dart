import 'package:auravibes_app/features/skills/providers/skill_access_summary_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credentials_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_template_tools_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

typedef SkillAccessRefreshRequest = ({
  String workspaceId,
  String skillId,
  String? credentialDefinitionId,
  bool toolsChanged,
});

abstract final class RefreshSkillAccess {
  static void refresh(
    ProviderContainer container,
    SkillAccessRefreshRequest request,
  ) {
    if (request.toolsChanged) {
      container.invalidate(
        skillTemplateToolsProvider(request.workspaceId, request.skillId),
      );
    }
    final definitionId = request.credentialDefinitionId;
    if (definitionId != null) {
      container.invalidate(
        skillCredentialsForDefinitionProvider(
          request.workspaceId,
          definitionId,
        ),
      );
    }
    container
      ..invalidate(
        appSkillCredentialCandidatesProvider(
          request.workspaceId,
          request.skillId,
        ),
      )
      ..invalidate(
        skillAccessSummaryProvider(request.workspaceId, request.skillId),
      );
  }
}
