import 'dart:async';

import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_definitions_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_operations_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/providers/skill_template_tools_provider.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/skills/usecases/check_skill_credential_readiness_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/delete_cloud_routed_skill_usecases.dart';
import 'package:auravibes_app/features/skills/usecases/disable_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/duplicate_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/duplicate_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/load_conversation_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_skills_manager_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/unload_conversation_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class _Gateway extends Mock implements CloudWorkspaceStateGateway {}

void main() {
  setUpAll(() {
    registerFallbackValue(WorkspaceSecretKind.skillCredential);
    registerFallbackValue(WorkspaceSecretScope.workspace);
  });

  const workspaceId = 'local-cloud';
  const workspace = WorkspaceSession(
    CloudWorkspaceRef(
      localWorkspaceId: workspaceId,
      serverUrl: 'https://example.com',
      accountId: 'account',
      cloudWorkspaceId: 7,
    ),
  );

  test(
    'cloud production providers never construct local skill storage',
    () async {
      final gateway = _Gateway();
      final resources = <WorkspaceResource>[];
      when(() => gateway.watchResources(any())).thenAnswer((invocation) {
        final kinds =
            invocation.positionalArguments.single
                as List<WorkspaceResourceKind>;

        return Stream.value(
          resources.where((item) => kinds.contains(item.resourceKind)).toList(),
        );
      });
      when(
        () => gateway.patch(
          requestId: any(named: 'requestId'),
          operations: any(named: 'operations'),
        ),
      ).thenAnswer((invocation) async {
        final operations =
            invocation.namedArguments[#operations]
                as List<WorkspacePatchOperation>;
        for (final operation in operations) {
          if (operation.operation == WorkspacePatchOperationKind.delete) {
            resources.removeWhere(
              (item) =>
                  item.resourceKind == operation.resourceKind &&
                  item.resourceId == operation.resourceId,
            );
          } else {
            resources
              ..removeWhere(
                (item) =>
                    item.resourceKind == operation.resourceKind &&
                    item.resourceId == operation.resourceId,
              )
              ..add(
                _resource(
                  kind: operation.resourceKind,
                  id: operation.resourceId,
                  data: operation.data ?? '{}',
                  revision: (operation.expectedRevision ?? 0) + 1,
                ),
              );
          }
        }

        return PatchWorkspaceStateResponse(resources: const [], sequence: 1);
      });
      when(
        () => gateway.putSecret(
          requestId: any(named: 'requestId'),
          secretKind: any(named: 'secretKind'),
          scope: any(named: 'scope'),
          resourceId: any(named: 'resourceId'),
          secret: any(named: 'secret'),
          expectedRevision: any(named: 'expectedRevision'),
        ),
      ).thenAnswer(
        (_) async => PutWorkspaceSecretResponse(
          configured: true,
          revision: 1,
          sequence: 1,
        ),
      );

      Never local() => throw StateError('local storage touched');
      final container = ProviderContainer(
        overrides: [
          workspaceSessionProvider.overrideWithValue(workspace),
          cloudWorkspaceStateGatewayProvider.overrideWith((_) async => gateway),
          skillsRepositoryProvider.overrideWith((_) => local()),
          skillTemplateToolsRepositoryProvider.overrideWith((_) => local()),
          skillCredentialDefinitionsRepositoryProvider.overrideWith(
            (_) => local(),
          ),
          skillCredentialsRepositoryProvider.overrideWith((_) => local()),
          conversationSkillsRepositoryProvider.overrideWith((_) => local()),
          appSkillWorkspaceSettingsRepositoryProvider.overrideWith(
            (_) => local(),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(workspaceSkillsProvider(workspaceId).future),
        isEmpty,
      );
      final skill = await container.read(createSkillUsecaseProvider)(
        workspaceId,
        const SkillToCreate(
          kind: SkillKind.template,
          title: 'Weather',
          description: 'Forecast',
          content: 'Use weather',
        ),
      );
      await container.read(disableSkillUsecaseProvider)(
        workspaceId: workspaceId,
        source: SkillSource.user,
        skillId: skill.id,
        isEnabled: false,
      );
      await container.read(disableSkillUsecaseProvider)(
        workspaceId: workspaceId,
        source: SkillSource.app,
        skillId: 'skills_manager',
        isEnabled: true,
        slug: 'skills_manager',
        title: 'Skills Manager',
        description: 'Manage skills',
        content: 'Manage workspace skills',
      );
      await container.read(loadConversationSkillUsecaseProvider)(
        conversationId: 'conversation-1',
        workspaceId: workspaceId,
        slug: 'skills_manager',
      );
      await container.read(unloadConversationSkillUsecaseProvider)(
        conversationId: 'conversation-1',
        workspaceId: workspaceId,
        slug: 'skills_manager',
      );
      final updatedSkill = await container.read(updateSkillUsecaseProvider)(
        skill.id,
        const SkillToUpdate(description: 'Updated forecast'),
      );
      final duplicatedSkill = await container.read(
        duplicateSkillUsecaseProvider,
      )(skill.id);

      final definition =
          await container.read(createSkillCredentialDefinitionUsecaseProvider)(
            workspaceId,
            const SkillCredentialDefinitionToCreate(
              title: 'API',
              attributesJson: '{"token":{"description":"Token","secret":true}}',
            ),
          );
      final updatedDefinition =
          await container.read(updateSkillCredentialDefinitionUsecaseProvider)(
            definition.id,
            const SkillCredentialDefinitionToUpdate(title: 'API Key'),
          );
      final credentialSkill = await container.read(createSkillUsecaseProvider)(
        workspaceId,
        SkillToCreate(
          kind: SkillKind.template,
          title: 'Protected Weather',
          description: 'Forecast',
          content: 'Use weather',
          credentialDefinitionId: definition.id,
        ),
      );
      final tool = await container.read(createSkillTemplateToolUsecaseProvider)(
        credentialSkill.id,
        const SkillTemplateToolToCreate(
          templateType: SkillTemplateToolType.url,
          title: 'Forecast',
          description: 'Get forecast',
          templateJson: '{"url":"https://example.com/{{credential.token}}"}',
          inputsJson: '{}',
          requiresCredential: true,
        ),
      );
      final updatedTool =
          await container.read(updateSkillTemplateToolUsecaseProvider)(
            tool.id,
            const SkillTemplateToolToUpdate(description: 'Updated tool'),
          );
      final duplicatedTool = await container.read(
        duplicateSkillTemplateToolUsecaseProvider,
      )(tool.id);

      final credential = await container
          .read(skillCredentialOperationsProvider)
          .create(
            workspaceId,
            SkillCredentialToCreate(
              credentialDefinitionId: definition.id,
              name: 'Primary',
              attributes: const {'token': 'secret'},
            ),
          );
      final edited = await container
          .read(skillCredentialOperationsProvider)
          .getForEdit(credential.id);
      final updatedCredential = await container
          .read(skillCredentialOperationsProvider)
          .update(
            credential.id,
            const SkillCredentialToUpdate(
              name: 'Updated credential',
              secretAttributes: {'token': 'replacement'},
            ),
          );
      expect(
        await container.read(
          checkSkillCredentialReadinessUsecaseProvider,
        )(workspaceId: workspaceId, skill: credentialSkill),
        isTrue,
      );
      await container.read(loadConversationSkillUsecaseProvider)(
        conversationId: 'conversation-1',
        workspaceId: workspaceId,
        slug: credentialSkill.slug,
      );
      await container.read(unloadConversationSkillUsecaseProvider)(
        conversationId: 'conversation-1',
        workspaceId: workspaceId,
        slug: credentialSkill.slug,
      );

      expect(
        await container.read(
          skillTemplateToolsProvider(credentialSkill.id).future,
        ),
        isNotEmpty,
      );
      expect(
        await container.read(
          skillCredentialDefinitionsProvider(workspaceId).future,
        ),
        isNotEmpty,
      );
      expect(updatedSkill.description, 'Updated forecast');
      expect(duplicatedSkill.title, 'Weather Copy');
      expect(updatedDefinition.title, 'API Key');
      expect(updatedTool.description, 'Updated tool');
      expect(duplicatedTool.title, 'Forecast Copy');
      expect(edited?.id, credential.id);
      expect(updatedCredential.name, 'Updated credential');
      final managed = await container.read(runSkillsManagerToolUsecaseProvider)(
        workspaceId: workspaceId,
        toolSlug: 'list_user_skills',
        arguments: const {},
      );
      expect((managed as Map)['skills'], isNotEmpty);

      expect(credential.attributes, isEmpty);
      verify(
        () => gateway.putSecret(
          requestId: any(named: 'requestId'),
          secretKind: WorkspaceSecretKind.skillCredential,
          scope: WorkspaceSecretScope.workspace,
          resourceId: credential.id,
          secret: any(named: 'secret'),
          expectedRevision: any(named: 'expectedRevision'),
        ),
      ).called(2);

      await container
          .read(skillCredentialOperationsProvider)
          .delete(
            credential.id,
          );
      await container.read(deleteSkillTemplateToolProvider)(duplicatedTool.id);
      await container.read(deleteSkillCredentialDefinitionProvider)(
        updatedDefinition.id,
      );
      await container.read(deleteSkillProvider)(duplicatedSkill.id);
    },
  );
}

WorkspaceResource _resource({
  required WorkspaceResourceKind kind,
  required String id,
  required String data,
  int revision = 1,
}) {
  final now = DateTime.utc(2026);

  return WorkspaceResource(
    workspaceId: 7,
    resourceKind: kind,
    resourceId: id,
    data: data,
    revision: revision,
    createdAt: now,
    updatedAt: now,
  );
}
