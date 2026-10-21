import 'dart:async';

import 'package:async/async.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
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

class _SkillTemplateExecutor extends Mock
    implements engine.SkillTemplateExecutor;

void main() {
  test(
    'credential-required templates reject an omitted credentialId',
    () async {
      final now = DateTime.utc(2026);
      final skills = _SkillsRepository();
      final tools = _SkillTemplateToolsRepository();
      final credentials = _CredentialsRepository();
      final skill = SkillEntity(
        id: 'skill-1',
        workspaceId: 'workspace-1',
        source: .user,
        kind: .template,
        title: 'Example',
        slug: 'example-skill',
        description: 'Example skill',
        content: 'Use the example skill.',
        isEnabled: true,
        isCredentialOptional: false,
        createdAt: now,
        updatedAt: now,
        credentialDefinitionId: 'definition-1',
      );
      final tool = SkillTemplateToolEntity(
        id: 'tool-1',
        skillId: skill.id,
        templateType: .url,
        title: 'Example tool',
        description: 'Runs the example tool.',
        slug: 'example-tool',
        isEnabled: true,
        requiresCredential: true,
        createdAt: now,
        updatedAt: now,
      );
      when(() => skills.getSkillBySlug('workspace-1', skill.slug))
          .thenAnswer((_) async => skill);
      when(() => tools.getToolBySlug(skill.id, tool.slug))
          .thenAnswer((_) async => tool);
      final usecase = RunSkillTemplateToolUsecase(
        tools,
        skills,
        _CredentialDefinitionsRepository(),
        credentials,
        _SkillTemplateExecutor(),
        (_) async => const WorkspaceSession(
          LocalWorkspaceRef(localWorkspaceId: 'workspace-1'),
        ),
      );

      await expectLater(
        usecase.call(
          workspaceId: 'workspace-1',
          skillSlug: skill.slug,
          toolSlug: tool.slug,
          arguments: const {},
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Skill tool requires a credentialId argument.',
          ),
        ),
      );
      final _ = verifyNever(
        () => credentials.getCredentialsForDefinition(
          workspaceId: any(named: 'workspaceId'),
          credentialDefinitionId: any(named: 'credentialDefinitionId'),
        ),
      );
    },
  );

  test('cloud template execution never reads local repositories', () async {
    final skills = _SkillsRepository();
    final usecase = RunSkillTemplateToolUsecase(
      _SkillTemplateToolsRepository(),
      skills,
      _CredentialDefinitionsRepository(),
      _CredentialsRepository(),
      _SkillTemplateExecutor(),
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

  test('template cancellation reaches the in-flight HTTP operation', () async {
    final now = DateTime.utc(2026);
    final skills = _SkillsRepository();
    final tools = _SkillTemplateToolsRepository();
    final executor = _SkillTemplateExecutor();
    final skill = SkillEntity(
      id: 'skill-1',
      workspaceId: 'workspace-1',
      source: .user,
      kind: .template,
      title: 'Example',
      slug: 'example-skill',
      description: 'Example skill',
      content: 'Use the example skill.',
      isEnabled: true,
      isCredentialOptional: true,
      createdAt: now,
      updatedAt: now,
    );
    final tool = SkillTemplateToolEntity(
      id: 'tool-1',
      skillId: skill.id,
      templateType: .url,
      title: 'Example tool',
      description: 'Runs the example tool.',
      slug: 'example-tool',
      isEnabled: true,
      requiresCredential: false,
      createdAt: now,
      updatedAt: now,
      templateJson: '{"url":"https://example.com"}',
      inputsJson: '{}',
    );
    when(() => skills.getSkillBySlug('workspace-1', skill.slug))
        .thenAnswer((_) async => skill);
    when(() => tools.getToolBySlug(skill.id, tool.slug))
        .thenAnswer((_) async => tool);

    final requestStarted = Completer<void>();
    final response = Completer<engine.UrlResponse>();
    var cancelCalls = 0;
    final httpOperation = CancelableOperation<engine.UrlResponse>.fromFuture(
      response.future,
      onCancel: () {
        cancelCalls += 1;
      },
    );
    when(
      () => executor.call(
        definition: any(named: 'definition'),
        inputs: any(named: 'inputs'),
        credentials: any(named: 'credentials'),
        schema: any(named: 'schema'),
        credentialDefinitions: any(named: 'credentialDefinitions'),
      ),
    ).thenAnswer((_) {
      requestStarted.complete();

      return httpOperation;
    });

    final usecase = RunSkillTemplateToolUsecase(
      tools,
      skills,
      _CredentialDefinitionsRepository(),
      _CredentialsRepository(),
      executor,
      (_) async => const WorkspaceSession(
        LocalWorkspaceRef(localWorkspaceId: 'workspace-1'),
      ),
    );
    final operation = usecase.callCancelable(
      workspaceId: 'workspace-1',
      skillSlug: skill.slug,
      toolSlug: tool.slug,
      arguments: const {},
    );

    await requestStarted.future.timeout(const Duration(seconds: 1));
    final _ = await Future.wait([operation.cancel(), operation.cancel()]);

    expect(cancelCalls, 1);
    expect(await operation.valueOrCancellation(), isNull);
  });
}
