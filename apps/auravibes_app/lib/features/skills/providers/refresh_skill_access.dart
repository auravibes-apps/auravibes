import 'package:auravibes_app/features/skills/providers/skill_access_summary_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

typedef SkillAccessRefreshRequest = ({String workspaceId, String skillId});

abstract final class RefreshSkillAccess {
  static void refresh(
    ProviderContainer container,
    SkillAccessRefreshRequest request,
  ) => container.invalidate(
    skillAccessSummaryProvider(request.workspaceId, request.skillId),
  );
}
