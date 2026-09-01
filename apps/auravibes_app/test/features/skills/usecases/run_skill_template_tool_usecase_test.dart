import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/features/skills/usecases/run_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as engine;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _SkillsRepository extends Mock implements SkillsRepository;

class _SkillTemplateToolsRepository extends Mock
    implements SkillTemplateToolsRepository;

class _CredentialDefinitionsRepository extends Mock
    implements SkillCredentialDefinitionsRepository;

class _CredentialsRepository extends Mock implements SkillCredentialsRepository;

class _RunSkillUrlTemplate extends Mock implements engine.RunSkillUrlTemplate;

void main() {
  test('cloud template execution never reads local repositories', () async {
    final skills = _SkillsRepository();
    final usecase = RunSkillTemplateToolUsecase(
      _SkillTemplateToolsRepository(),
      skills,
      _CredentialDefinitionsRepository(),
      _CredentialsRepository(),
      _RunSkillUrlTemplate(),
      (_) async => const WorkspaceSession(
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
        workspaceId: 'workspace-1',
        skillSlug: 'example-skill',
        toolSlug: 'example-tool',
        arguments: const {},
      ),
      throwsA(isA<StateError>()),
    );
    final _ = verifyNever(() => skills.getSkillBySlug(any(), any()));
  });
}
