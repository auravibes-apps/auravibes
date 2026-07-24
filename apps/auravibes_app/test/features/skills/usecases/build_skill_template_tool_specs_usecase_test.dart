import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_template_tool_specs_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _TemplateToolsRepository extends Mock
    implements SkillTemplateToolsRepository {}

class _CredentialsRepository extends Mock
    implements SkillCredentialsRepository {}

void main() {
  test('cloud template specs never load local skills', () async {
    var localLoads = 0;
    final usecase = BuildSkillTemplateToolSpecsUsecase(
      (_) {
        localLoads++;
        throw StateError('local skills must not load');
      },
      _TemplateToolsRepository(),
      _CredentialsRepository(),
      workspaceSession: (_) async => const WorkspaceSession(
        CloudWorkspaceRef(
          localWorkspaceId: 'workspace-1',
          serverUrl: 'https://example.com',
          accountId: 'account',
          cloudWorkspaceId: 1,
        ),
      ),
    );

    await expectLater(
      usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      ),
      throwsA(isA<StateError>()),
    );
    expect(localLoads, 0);
  });
}
