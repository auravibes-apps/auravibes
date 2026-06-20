import 'dart:convert';

import 'package:async/async.dart';
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_skills_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/skills/models/skill_url_template.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_dynamic_skill_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_context_messages_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_template_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/check_skill_credential_readiness_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/duplicate_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/load_conversation_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/resolve_skill_url_template_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_skills_manager_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/unload_conversation_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/validate_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/validate_skill_title_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/run_resolved_tool_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/url/url_service.dart';
import 'package:collection/collection.dart';
import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SkillsRepository', () {
    final initialDatabase = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    var database = initialDatabase;
    var workspaceRepository = WorkspaceRepository(database);
    var conversationRepository = ConversationRepository(database);
    var skillsRepository = SkillsRepository(database);
    var toolsRepository = SkillTemplateToolsRepository(database);
    var skillCredentialDefinitionsRepository =
        SkillCredentialDefinitionsRepository(database);
    var skillCredentialsRepository = SkillCredentialsRepository(
      database: database,
      encryptionService: EncryptionService(_FakeSecretKeyManager()),
    );
    var conversationSkillsRepository = ConversationSkillsRepository(
      database,
    );
    var appSkillSettingsRepository = AppSkillWorkspaceSettingsRepository(
      database,
    );
    var createSkillUsecase = CreateSkillUsecase(skillsRepository);
    var updateSkillUsecase = UpdateSkillUsecase(skillsRepository);
    var listAvailableSkillsUsecase = ListAvailableSkillsUsecase(
      skillsRepository,
      conversationSkillsRepository,
      appSkillSettingsRepository,
      const AppSkillRegistry(),
      CheckSkillCredentialReadinessUsecase(skillCredentialsRepository),
    );

    setUp(() {
      database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      workspaceRepository = WorkspaceRepository(database);
      conversationRepository = ConversationRepository(database);
      skillsRepository = SkillsRepository(database);
      toolsRepository = SkillTemplateToolsRepository(database);
      skillCredentialDefinitionsRepository =
          SkillCredentialDefinitionsRepository(database);
      skillCredentialsRepository = SkillCredentialsRepository(
        database: database,
        encryptionService: EncryptionService(_FakeSecretKeyManager()),
      );
      conversationSkillsRepository = ConversationSkillsRepository(database);
      appSkillSettingsRepository = AppSkillWorkspaceSettingsRepository(
        database,
      );
      createSkillUsecase = CreateSkillUsecase(skillsRepository);
      updateSkillUsecase = UpdateSkillUsecase(skillsRepository);
      listAvailableSkillsUsecase = ListAvailableSkillsUsecase(
        skillsRepository,
        conversationSkillsRepository,
        appSkillSettingsRepository,
        const AppSkillRegistry(),
        CheckSkillCredentialReadinessUsecase(skillCredentialsRepository),
      );
    });

    tearDown(() async {
      await database.close();
    });

    tearDownAll(() async {
      await initialDatabase.close();
    });

    DuplicateSkillUsecase duplicateSkillUsecase() {
      return DuplicateSkillUsecase(
        skillsRepository,
        toolsRepository,
        createSkillUsecase,
      );
    }

    CreateSkillTemplateToolUsecase createTemplateToolUsecase() {
      return CreateSkillTemplateToolUsecase(
        toolsRepository,
        validateSkillTemplateToolUsecase:
            const ValidateSkillTemplateToolUsecase(),
        skillsRepository: skillsRepository,
        skillCredentialDefinitionsRepository:
            skillCredentialDefinitionsRepository,
      );
    }

    UpdateSkillTemplateToolUsecase updateTemplateToolUsecase() {
      return UpdateSkillTemplateToolUsecase(
        toolsRepository,
        validateSkillTemplateToolUsecase:
            const ValidateSkillTemplateToolUsecase(),
        skillsRepository: skillsRepository,
        skillCredentialDefinitionsRepository:
            skillCredentialDefinitionsRepository,
      );
    }

    RunSkillsManagerToolUsecase runSkillsManagerToolUsecase() {
      return RunSkillsManagerToolUsecase(
        skillsRepository,
        toolsRepository,
        skillCredentialDefinitionsRepository,
        createSkillUsecase,
        updateSkillUsecase,
        createTemplateToolUsecase(),
        updateTemplateToolUsecase(),
        CreateSkillCredentialDefinitionUsecase(
          skillCredentialDefinitionsRepository,
        ),
        UpdateSkillCredentialDefinitionUsecase(
          skillCredentialDefinitionsRepository,
        ),
      );
    }

    test('creates user skill with generated immutable slug', () async {
      final workspace = await workspaceRepository.createWorkspace(
        const WorkspaceToCreate(
          name: 'Test Workspace',
          type: WorkspaceType.local,
        ),
      );
      final skill = await createSkillUsecase.call(
        workspace.id,
        const SkillToCreate(
          kind: SkillKind.template,
          title: 'Example Services',
          description: 'Call Example APIs',
          content: 'Use Example Services for company data.',
        ),
      );

      final updated = await updateSkillUsecase.call(
        skill.id,
        const SkillToUpdate(title: 'Renamed Skill'),
      );

      expect(skill.slug, 'example_services');
      expect(updated.title, 'Renamed Skill');
      expect(updated.slug, 'example_services');
    });

    test('rejects invalid and duplicate skill titles', () async {
      final workspace = await workspaceRepository.createWorkspace(
        const WorkspaceToCreate(
          name: 'Test Workspace',
          type: WorkspaceType.local,
        ),
      );
      final _ = await createSkillUsecase.call(
        workspace.id,
        const SkillToCreate(
          kind: SkillKind.template,
          title: 'Example Services',
          description: 'Call Example APIs',
          content: 'Use Example Services for company data.',
        ),
      );

      await expectLater(
        createSkillUsecase.call(
          workspace.id,
          const SkillToCreate(
            kind: SkillKind.template,
            title: 'Bad/Title',
            description: 'Invalid title',
            content: 'Invalid title',
          ),
        ),
        throwsA(
          isA<SkillTitleValidationException>()
              .having(
                (error) => error.message,
                'message',
                'Skill title can only contain letters, numbers, and spaces',
              )
              .having(
                (error) => error.localizationKey,
                'localizationKey',
                LocaleKeys.skills_screen_error_title_invalid,
              ),
        ),
      );
      await expectLater(
        createSkillUsecase.call(
          workspace.id,
          const SkillToCreate(
            kind: SkillKind.template,
            title: 'Example Services',
            description: 'Duplicate title',
            content: 'Duplicate title',
          ),
        ),
        throwsA(isA<SkillTitleValidationException>()),
      );
    });

    test('stores template tools under user skill', () async {
      final workspace = await workspaceRepository.createWorkspace(
        const WorkspaceToCreate(
          name: 'Test Workspace',
          type: WorkspaceType.local,
        ),
      );
      final skill = await createSkillUsecase.call(
        workspace.id,
        const SkillToCreate(
          kind: SkillKind.template,
          title: 'Example Services',
          description: 'Call Example APIs',
          content: 'Use Example Services for company data.',
        ),
      );

      final tool = await toolsRepository.createTool(
        skill.id,
        const SkillTemplateToolToCreate(
          templateType: SkillTemplateToolType.url,
          title: 'Find Company',
          description: 'Find a company by id.',
          templateJson: '{"url":"https://example.com"}',
          inputsJson: '{"company_id":{"type":"string"}}',
        ),
      );
      final tools = await toolsRepository.getSkillTools(skill.id);

      expect(tool.slug, 'find_company');
      expect(tools, hasLength(1));
      expect(tools.firstOrNull?.templateType, SkillTemplateToolType.url);
    });

    test('duplicates user skill with template tools', () async {
      final workspace = await workspaceRepository.createWorkspace(
        const WorkspaceToCreate(
          name: 'Test Workspace',
          type: WorkspaceType.local,
        ),
      );
      final skill = await createSkillUsecase.call(
        workspace.id,
        const SkillToCreate(
          kind: SkillKind.template,
          title: 'Example Services',
          description: 'Call Example APIs',
          content: 'Use Example Services for company data.',
        ),
      );
      final _ = await toolsRepository.createTool(
        skill.id,
        const SkillTemplateToolToCreate(
          templateType: SkillTemplateToolType.url,
          title: 'Find Company',
          description: 'Find a company by id.',
          templateJson: '{"url":"https://example.com"}',
          inputsJson: '{}',
        ),
      );
      final usecase = duplicateSkillUsecase();

      final duplicate = await usecase.call(skill.id);
      final duplicateTools = await toolsRepository.getSkillTools(
        duplicate.id,
      );

      expect(duplicate.title, 'Example Services Copy');
      expect(duplicate.slug, 'example_services_copy');
      expect(duplicateTools, hasLength(1));
      expect(duplicateTools.single.slug, 'find_company');
    });

    test(
      'tracks conversation skill load state for user and app skills',
      () async {
        final workspace = await workspaceRepository.createWorkspace(
          const WorkspaceToCreate(
            name: 'Test Workspace',
            type: WorkspaceType.local,
          ),
        );
        final conversation = await conversationRepository.createConversation(
          ConversationToCreate(
            title: 'Test Conversation',
            workspaceId: workspace.id,
          ),
        );
        final skill = await createSkillUsecase.call(
          workspace.id,
          const SkillToCreate(
            kind: SkillKind.template,
            title: 'Example Services',
            description: 'Call Example APIs',
            content: 'Use Example Services for company data.',
          ),
        );

        final loadedUserSkill = await conversationSkillsRepository
            .setWorkspaceSkillLoaded(
              conversation.id,
              skill.id,
              isLoaded: true,
            );
        final loadedAppSkill = await conversationSkillsRepository
            .setAppSkillLoaded(
              conversation.id,
              'skills_manager',
              isLoaded: true,
            );
        final conversationSkills = await conversationSkillsRepository
            .getConversationSkills(conversation.id);

        expect(loadedUserSkill.workspaceSkillId, skill.id);
        expect(loadedAppSkill.appSkillIdentifier, 'skills_manager');
        expect(conversationSkills, hasLength(2));
      },
    );

    test('app skill disablement is scoped to workspace', () async {
      final firstWorkspace = await workspaceRepository.createWorkspace(
        const WorkspaceToCreate(
          name: 'First Workspace',
          type: WorkspaceType.local,
        ),
      );
      final secondWorkspace = await workspaceRepository.createWorkspace(
        const WorkspaceToCreate(
          name: 'Second Workspace',
          type: WorkspaceType.local,
        ),
      );

      await appSkillSettingsRepository.setAppSkillEnabled(
        firstWorkspace.id,
        'skills_manager',
        isEnabled: false,
      );

      expect(
        await appSkillSettingsRepository.isAppSkillEnabled(
          firstWorkspace.id,
          'skills_manager',
        ),
        false,
      );
      expect(
        await appSkillSettingsRepository.isAppSkillEnabled(
          secondWorkspace.id,
          'skills_manager',
        ),
        true,
      );
    });

    test('builds dynamic load and unload skill tool specs', () async {
      final workspace = await workspaceRepository.createWorkspace(
        const WorkspaceToCreate(
          name: 'Test Workspace',
          type: WorkspaceType.local,
        ),
      );
      final conversation = await conversationRepository.createConversation(
        ConversationToCreate(
          title: 'Test Conversation',
          workspaceId: workspace.id,
        ),
      );
      final skill = await createSkillUsecase.call(
        workspace.id,
        const SkillToCreate(
          kind: SkillKind.template,
          title: 'Example Services',
          description: 'Call Example APIs',
          content: 'Use Example Services for company data.',
        ),
      );
      final loadSkillUsecase = LoadConversationSkillUsecase(
        skillsRepository,
        conversationSkillsRepository,
        const AppSkillRegistry(),
      );
      final unloadSkillUsecase = UnloadConversationSkillUsecase(
        skillsRepository,
        conversationSkillsRepository,
        const AppSkillRegistry(),
      );
      final buildSpecsUsecase = BuildDynamicSkillToolSpecsUsecase(
        listAvailableSkillsUsecase,
      );

      var specs = await buildSpecsUsecase.call(
        conversationId: conversation.id,
        workspaceId: workspace.id,
      );
      expect(
        _slugEnumFor(specs, loadSkillToolName),
        containsAll(['example_services', 'skills_manager']),
      );

      await loadSkillUsecase.call(
        conversationId: conversation.id,
        workspaceId: workspace.id,
        slug: skill.slug,
      );
      specs = await buildSpecsUsecase.call(
        conversationId: conversation.id,
        workspaceId: workspace.id,
      );

      expect(
        _slugEnumFor(specs, loadSkillToolName),
        isNot(contains('example_services')),
      );
      expect(
        _slugEnumFor(specs, unloadSkillToolName),
        contains('example_services'),
      );

      await unloadSkillUsecase.call(
        conversationId: conversation.id,
        workspaceId: workspace.id,
        slug: skill.slug,
      );
      final loadableSkills = await listAvailableSkillsUsecase.call(
        conversationId: conversation.id,
        workspaceId: workspace.id,
        filter: SkillLoadFilter.loadable,
      );

      expect(
        loadableSkills.map((skill) => skill.slug),
        contains('example_services'),
      );
    });

    test('builds loaded skill content as XML user context messages', () async {
      final workspace = await workspaceRepository.createWorkspace(
        const WorkspaceToCreate(
          name: 'Test Workspace',
          type: WorkspaceType.local,
        ),
      );
      final conversation = await conversationRepository.createConversation(
        ConversationToCreate(
          title: 'Test Conversation',
          workspaceId: workspace.id,
        ),
      );
      final skill = await createSkillUsecase.call(
        workspace.id,
        const SkillToCreate(
          kind: SkillKind.template,
          title: 'Example Services',
          description: 'Call Example APIs',
          content: 'Use <company> & account data.',
        ),
      );
      final _ = await conversationSkillsRepository.setWorkspaceSkillLoaded(
        conversation.id,
        skill.id,
        isLoaded: true,
      );
      final usecase = BuildSkillContextMessagesUsecase(
        listAvailableSkillsUsecase,
      );

      final messages = await usecase.call(
        conversationId: conversation.id,
        workspaceId: workspace.id,
      );

      expect(messages.single.role, ChatMessageRole.user);
      expect(messages.single.metadata['kind'], skillContextMetadataKind);
      expect(messages.single.toolResults, isEmpty);
      expect(messages.single.text, contains('<name>Example Services'));
      expect(
        messages.single.text,
        contains('<content>Use &lt;company&gt; &amp; account data.'),
      );
    });

    test('blocks credential-backed skills without credentials', () async {
      final workspace = await workspaceRepository.createWorkspace(
        const WorkspaceToCreate(
          name: 'Test Workspace',
          type: WorkspaceType.local,
        ),
      );
      final conversation = await conversationRepository.createConversation(
        ConversationToCreate(
          title: 'Test Conversation',
          workspaceId: workspace.id,
        ),
      );
      final definition = await skillCredentialDefinitionsRepository
          .createDefinition(
            workspace.id,
            const SkillCredentialDefinitionToCreate(
              title: 'Example Service',
              attributesJson: '{"api_key":{"description":"API key"}}',
            ),
          );
      final skill = await createSkillUsecase.call(
        workspace.id,
        SkillToCreate(
          kind: SkillKind.template,
          title: 'Example Services',
          description: 'Call Example APIs',
          content: 'Use Example Services for company data.',
          credentialDefinitionId: definition.id,
        ),
      );
      final loadSkillUsecase = LoadConversationSkillUsecase(
        skillsRepository,
        conversationSkillsRepository,
        const AppSkillRegistry(),
        CheckSkillCredentialReadinessUsecase(skillCredentialsRepository),
      );

      final loadableSkills = await listAvailableSkillsUsecase.call(
        conversationId: conversation.id,
        workspaceId: workspace.id,
        filter: SkillLoadFilter.loadable,
      );

      expect(
        loadableSkills.map((skill) => skill.slug),
        isNot(contains('example_services')),
      );
      final optionalSkill = await createSkillUsecase.call(
        workspace.id,
        SkillToCreate(
          kind: SkillKind.template,
          title: 'Optional Example Services',
          description: 'Call Example APIs without requiring credentials.',
          content: 'Use Example Services for public company data.',
          credentialDefinitionId: definition.id,
          isCredentialOptional: true,
        ),
      );
      final optionalLoadableSkills = await listAvailableSkillsUsecase.call(
        conversationId: conversation.id,
        workspaceId: workspace.id,
        filter: SkillLoadFilter.loadable,
      );

      expect(
        optionalLoadableSkills.map((skill) => skill.slug),
        contains(optionalSkill.slug),
      );
      await expectLater(
        loadSkillUsecase.call(
          conversationId: conversation.id,
          workspaceId: workspace.id,
          slug: skill.slug,
        ),
        throwsA(isA<StateError>()),
      );

      final _ = await skillCredentialsRepository.createCredential(
        workspace.id,
        SkillCredentialToCreate(
          credentialDefinitionId: definition.id,
          name: 'Example Credential',
          attributes: const {'api_key': 'secret-token'},
        ),
      );
      final readySkills = await listAvailableSkillsUsecase.call(
        conversationId: conversation.id,
        workspaceId: workspace.id,
        filter: SkillLoadFilter.loadable,
      );

      expect(
        readySkills.map((skill) => skill.slug),
        contains('example_services'),
      );
    });

    test(
      'keeps loaded skills visible after required credential is deleted',
      () async {
        final workspace = await workspaceRepository.createWorkspace(
          const WorkspaceToCreate(
            name: 'Test Workspace',
            type: WorkspaceType.local,
          ),
        );
        final conversation = await conversationRepository.createConversation(
          ConversationToCreate(
            title: 'Test Conversation',
            workspaceId: workspace.id,
          ),
        );
        final definition = await skillCredentialDefinitionsRepository
            .createDefinition(
              workspace.id,
              const SkillCredentialDefinitionToCreate(
                title: 'Example Service',
                attributesJson: '{"api_key":{"description":"API key"}}',
              ),
            );
        final credential = await skillCredentialsRepository.createCredential(
          workspace.id,
          SkillCredentialToCreate(
            credentialDefinitionId: definition.id,
            name: 'Example Credential',
            attributes: const {'api_key': 'secret-token'},
          ),
        );
        final skill = await createSkillUsecase.call(
          workspace.id,
          SkillToCreate(
            kind: SkillKind.template,
            title: 'Example Services',
            description: 'Call Example APIs',
            content: 'Use Example Services for company data.',
            credentialDefinitionId: definition.id,
          ),
        );
        final _ = await conversationSkillsRepository.setWorkspaceSkillLoaded(
          conversation.id,
          skill.id,
          isLoaded: true,
        );

        await skillCredentialsRepository.deleteCredential(credential.id);

        final loadedSkills = await listAvailableSkillsUsecase.call(
          conversationId: conversation.id,
          workspaceId: workspace.id,
          filter: SkillLoadFilter.loaded,
        );
        final loadableSkills = await listAvailableSkillsUsecase.call(
          conversationId: conversation.id,
          workspaceId: workspace.id,
          filter: SkillLoadFilter.loadable,
        );

        expect(loadedSkills.map((skill) => skill.slug), contains(skill.slug));
        expect(
          loadableSkills.map((skill) => skill.slug),
          isNot(contains(skill.slug)),
        );
      },
    );

    test('builds and runs loaded URL template skill tool', () async {
      final workspace = await workspaceRepository.createWorkspace(
        const WorkspaceToCreate(
          name: 'Test Workspace',
          type: WorkspaceType.local,
        ),
      );
      final conversation = await conversationRepository.createConversation(
        ConversationToCreate(
          title: 'Test Conversation',
          workspaceId: workspace.id,
        ),
      );
      final definition = await database.skillCredentialDefinitionsDao
          .createDefinition(
            SkillCredentialDefinitionsCompanion.insert(
              workspaceId: workspace.id,
              title: 'Example Service',
              slug: 'example_service',
              attributesJson: jsonEncode({
                'api_key': {
                  'description': 'API key',
                  'optional': true,
                },
                'user_id': {
                  'description': 'User id',
                  'optional': true,
                },
              }),
            ),
          );
      final credential = await skillCredentialsRepository.createCredential(
        workspace.id,
        SkillCredentialToCreate(
          credentialDefinitionId: definition.id,
          name: 'Example Credential',
          attributes: const {'api_key': 'secret-token'},
        ),
      );
      final skill = await createSkillUsecase.call(
        workspace.id,
        SkillToCreate(
          kind: SkillKind.template,
          title: 'Example Services',
          description: 'Call Example APIs',
          content: 'Use Example Services for company data.',
          credentialDefinitionId: definition.id,
        ),
      );
      final _ = await toolsRepository.createTool(
        skill.id,
        SkillTemplateToolToCreate(
          templateType: SkillTemplateToolType.url,
          title: 'Find Company',
          description: 'Find company records.',
          templateJson: jsonEncode({
            'url': 'https://example.com/company',
            'method': 'POST',
            'query': {
              'token': [
                '{% if credential.api_key %}',
                '{{ credential.api_key }}',
                '{% endif %}',
              ].join(),
            },
            'headers': {
              'X-Token': [
                '{% if credential.api_key %}',
                '{{ credential.api_key }}',
                '{% endif %}',
              ].join(),
            },
            'body':
                '{"company_id":"{input:company_id}",'
                '"user_id":"{credential:user_id}"}',
          }),
          inputsJson:
              '{"company_id":{"description":"Company id","type":"string"}}',
        ),
      );
      final _ = await conversationSkillsRepository.setWorkspaceSkillLoaded(
        conversation.id,
        skill.id,
        isLoaded: true,
      );
      final buildSpecsUsecase = BuildSkillTemplateToolSpecsUsecase(
        listAvailableSkillsUsecase,
        toolsRepository,
        skillCredentialsRepository,
      );
      final requests = <RequestOptions>[];
      final runUsecase = RunSkillTemplateToolUsecase(
        toolsRepository,
        skillsRepository,
        skillCredentialDefinitionsRepository,
        skillCredentialsRepository,
        const ResolveSkillUrlTemplateUsecase(),
        UrlService(dio: _dioWithBody('ok', requests: requests)),
      );

      var specs = await buildSpecsUsecase.call(
        conversationId: conversation.id,
        workspaceId: workspace.id,
      );
      var spec = specs.single;
      final singleCredentialProperties =
          spec.inputJsonSchema['properties'] as Map<String, dynamic>;
      final result = await runUsecase.call(
        workspaceId: workspace.id,
        skillSlug: skill.slug,
        toolSlug: 'find_company',
        arguments: {'company_id': 'acme'},
      );
      final _ = await skillCredentialsRepository.createCredential(
        workspace.id,
        SkillCredentialToCreate(
          credentialDefinitionId: definition.id,
          name: 'Backup Credential',
          attributes: const {'api_key': 'backup-token'},
        ),
      );
      specs = await buildSpecsUsecase.call(
        conversationId: conversation.id,
        workspaceId: workspace.id,
      );
      spec = specs.single;
      final credentialEnum = _propertyEnumFor(spec, 'credentialId');
      final selectedCredentialResult = await runUsecase.call(
        workspaceId: workspace.id,
        skillSlug: skill.slug,
        toolSlug: 'find_company',
        arguments: {
          'company_id': 'acme',
          'credentialId': credential.id,
        },
      );

      expect(spec.name, 'skill__user__example_services__find_company');
      expect(spec.description, 'Find company records.');
      expect(singleCredentialProperties, contains('credentialId'));
      expect(credentialEnum, contains(credential.id));
      expect(result, 'ok');
      expect(selectedCredentialResult, 'ok');
      expect(
        requests.firstOrNull?.uri.queryParameters,
        isNot(contains('token')),
      );
      expect(requests.firstOrNull?.headers, isNot(contains('X-Token')));
      expect(
        requests.last.uri.queryParameters,
        containsPair('token', 'secret-token'),
      );
      expect(requests.last.headers, containsPair('X-Token', 'secret-token'));
    });

    test('builds credentialId schema from credential requirement', () async {
      final workspace = await workspaceRepository.createWorkspace(
        const WorkspaceToCreate(
          name: 'Test Workspace',
          type: WorkspaceType.local,
        ),
      );
      final conversation = await conversationRepository.createConversation(
        ConversationToCreate(
          title: 'Test Conversation',
          workspaceId: workspace.id,
        ),
      );
      final definition = await skillCredentialDefinitionsRepository
          .createDefinition(
            workspace.id,
            const SkillCredentialDefinitionToCreate(
              title: 'Example Service',
              attributesJson: '{"api_key":{"description":"API key"}}',
            ),
          );
      final skill = await createSkillUsecase.call(
        workspace.id,
        SkillToCreate(
          kind: SkillKind.template,
          title: 'Example Services',
          description: 'Call Example APIs',
          content: 'Use Example Services for company data.',
          credentialDefinitionId: definition.id,
          isCredentialOptional: true,
        ),
      );
      final _ = await toolsRepository.createTool(
        skill.id,
        SkillTemplateToolToCreate(
          templateType: SkillTemplateToolType.url,
          title: 'Public Search',
          description: 'Search public records.',
          templateJson: jsonEncode({'url': 'https://example.com/public'}),
          inputsJson: '{}',
        ),
      );
      final _ = await toolsRepository.createTool(
        skill.id,
        SkillTemplateToolToCreate(
          templateType: SkillTemplateToolType.url,
          title: 'Private Search',
          description: 'Search private records.',
          templateJson: jsonEncode({'url': 'https://example.com/private'}),
          inputsJson: '{}',
          requiresCredential: true,
        ),
      );
      final _ = await conversationSkillsRepository.setWorkspaceSkillLoaded(
        conversation.id,
        skill.id,
        isLoaded: true,
      );
      final buildSpecsUsecase = BuildSkillTemplateToolSpecsUsecase(
        listAvailableSkillsUsecase,
        toolsRepository,
        skillCredentialsRepository,
      );

      var specs = await buildSpecsUsecase.call(
        conversationId: conversation.id,
        workspaceId: workspace.id,
      );

      expect(
        specs.map((spec) => spec.name),
        contains('skill__user__example_services__public_search'),
      );
      expect(
        specs.map((spec) => spec.name),
        isNot(contains('skill__user__example_services__private_search')),
      );

      final credential = await skillCredentialsRepository.createCredential(
        workspace.id,
        SkillCredentialToCreate(
          credentialDefinitionId: definition.id,
          name: 'Example Credential',
          attributes: const {'api_key': 'secret-token'},
        ),
      );
      specs = await buildSpecsUsecase.call(
        conversationId: conversation.id,
        workspaceId: workspace.id,
      );
      final publicSpec = specs.singleWhere(
        (spec) => spec.name.endsWith('__public_search'),
      );
      final privateSpec = specs.singleWhere(
        (spec) => spec.name.endsWith('__private_search'),
      );

      expect(_propertyEnumFor(publicSpec, 'credentialId'), [credential.id]);
      expect(
        publicSpec.inputJsonSchema['required'] as List<Object?>,
        isNot(contains('credentialId')),
      );
      expect(_propertyEnumFor(privateSpec, 'credentialId'), [credential.id]);
      expect(
        privateSpec.inputJsonSchema['required'] as List<Object?>,
        contains('credentialId'),
      );
    });

    test('lists loaded skill credential ids and names only', () async {
      final workspace = await workspaceRepository.createWorkspace(
        const WorkspaceToCreate(
          name: 'Test Workspace',
          type: WorkspaceType.local,
        ),
      );
      final conversation = await conversationRepository.createConversation(
        ConversationToCreate(
          title: 'Test Conversation',
          workspaceId: workspace.id,
        ),
      );
      final definition = await skillCredentialDefinitionsRepository
          .createDefinition(
            workspace.id,
            const SkillCredentialDefinitionToCreate(
              title: 'Example Service',
              attributesJson: '{"api_key":{"description":"API key"}}',
            ),
          );
      final skill = await createSkillUsecase.call(
        workspace.id,
        SkillToCreate(
          kind: SkillKind.template,
          title: 'Example Services',
          description: 'Call Example APIs',
          content: 'Use Example Services for company data.',
          credentialDefinitionId: definition.id,
        ),
      );
      final credential = await skillCredentialsRepository.createCredential(
        workspace.id,
        SkillCredentialToCreate(
          credentialDefinitionId: definition.id,
          name: 'Example Credential',
          attributes: const {'api_key': 'secret-token'},
        ),
      );
      final _ = await conversationSkillsRepository.setWorkspaceSkillLoaded(
        conversation.id,
        skill.id,
        isLoaded: true,
      );
      final runUsecase = RunResolvedToolUsecase(
        agentCancellationRuntime: AgentCancellationRuntime(),
        mcpToolCaller:
            ({
              required mcpServerId,
              required toolIdentifier,
              required arguments,
            }) async => '',
        conversationRepository: conversationRepository,
        listAvailableSkillsUsecase: listAvailableSkillsUsecase,
        skillCredentialsRepository: skillCredentialsRepository,
      );

      final output = await runUsecase.call(
        conversationId: conversation.id,
        tool: ResolvedTool.skillControl(
          toolIdentifier: listSkillCredentialsToolName,
        ),
        arguments: {'skillSlug': skill.slug},
      );
      final result =
          (output ?? fail('skill control result missing'))
              as Map<String, Object?>;

      expect(result, containsPair('skillSlug', skill.slug));
      expect(result['credentials'], [
        {'id': credential.id, 'name': 'Example Credential'},
      ]);
    });

    test(
      'renders optional Liquid fields in JSON template fields',
      () {
        const usecase = ResolveSkillUrlTemplateUsecase();

        final request = usecase.call(
          template: SkillUrlTemplate(
            url: 'https://example.com',
            headers: {
              'X-User': [
                '{% if credential.user_id %}',
                '{{ credential.user_id }}',
                '{% endif %}',
              ].join(),
            },
            query: {
              'user_id': [
                '{% if credential.user_id %}',
                '{{ credential.user_id }}',
                '{% endif %}',
              ].join(),
            },
            body: [
              '{"level":2',
              '{% if credential.user_id %},',
              '"user_id":{{ credential.user_id | json }}',
              '{% endif %}}',
            ].join(),
          ),
          inputs: const {},
          credentials: const {},
          inputDefinitions: const {},
          credentialDefinitions: const {
            'user_id': SkillCredentialAttributeDefinition(
              description: 'Optional user id',
              optional: true,
            ),
          },
        );

        expect(request.url, 'https://example.com');
        expect(request.headers, isNot(contains('X-User')));
        final body = request.body ?? fail('body missing');
        expect(jsonDecode(body), {'level': 2});
      },
    );

    test('resolves typed JSON body placeholders', () {
      const usecase = ResolveSkillUrlTemplateUsecase();

      final request = usecase.call(
        template: SkillUrlTemplate(
          url: 'https://example.com',
          body: [
            '{"filters":{{ input.filters | json }},',
            '"limit":{{ input.limit | json }},',
            '"enabled":{{ input.enabled | json }},',
            '"q":"name:{{ input.name }}"',
            '{% if input.missing %},',
            '"missing":{{ input.missing | json }}',
            '{% endif %}}',
          ].join(),
        ),
        inputs: const {
          'filters': [
            {'field': 'species', 'op': 'equals', 'value': 'dog'},
          ],
          'limit': 25,
          'enabled': true,
          'name': 'buddy',
        },
        credentials: const {},
        inputDefinitions: const {
          'filters': SkillTemplateInputDefinition(
            description: 'Filter list',
            type: 'array',
          ),
          'limit': SkillTemplateInputDefinition(
            description: 'Limit',
            type: 'number',
          ),
          'enabled': SkillTemplateInputDefinition(
            description: 'Enabled',
            type: 'boolean',
          ),
          'name': SkillTemplateInputDefinition(description: 'Name'),
          'missing': SkillTemplateInputDefinition(
            description: 'Optional missing value',
            optional: true,
          ),
        },
      );

      final body = request.body ?? fail('body missing');
      expect(jsonDecode(body), {
        'filters': [
          {'field': 'species', 'op': 'equals', 'value': 'dog'},
        ],
        'limit': 25,
        'enabled': true,
        'q': 'name:buddy',
      });
    });

    test('validates skill template placeholders before saving', () {
      const usecase = ValidateSkillTemplateToolUsecase();

      expect(
        () => usecase.call(
          templateJson: jsonEncode({
            'url': 'https://example.com',
            'body': '{"filters":{{filters}}}',
          }),
          inputsJson: jsonEncode({
            'filters': {'description': 'Filters', 'type': 'array'},
          }),
          credentialDefinitions: const {},
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Unsupported Liquid reference'),
          ),
        ),
      );
      expect(
        () => usecase.call(
          templateJson: jsonEncode({
            'url': 'https://example.com',
            'body': '{"filters":{input:filters}}',
          }),
          inputsJson: jsonEncode({
            'filters': {'description': 'Filters', 'type': 'array'},
          }),
          credentialDefinitions: const {},
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => usecase.call(
          templateJson: jsonEncode({
            'url': 'https://example.com',
            'body': '{"filters":"{input:missing}"}',
          }),
          inputsJson: jsonEncode({
            'filters': {'description': 'Filters', 'type': 'array'},
          }),
          credentialDefinitions: const {},
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Unknown input placeholder: missing'),
          ),
        ),
      );
      expect(
        () => usecase.call(
          templateJson: jsonEncode({
            'url': 'https://example.com',
            'body': '{"filters":"{{ input.filters }}"}',
          }),
          inputsJson: jsonEncode({
            'filters': {'description': 'Filters', 'type': 'array'},
          }),
          credentialDefinitions: const {},
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('must use the json filter'),
          ),
        ),
      );
      expect(
        () => usecase.call(
          templateJson: jsonEncode({
            'url': 'https://example.com',
            'bodyFormat': 'json',
            'body': [
              '{"q":"cats",',
              '{% if input.location %}',
              '"location":{{ input.location | json }}',
              '{% endif %}',
              '}',
            ].join(),
          }),
          inputsJson: jsonEncode({
            'location': {
              'description': 'Optional location',
              'optional': true,
            },
          }),
          credentialDefinitions: const {},
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Rendered JSON body is invalid'),
          ),
        ),
      );
      expect(
        () => usecase.call(
          templateJson: jsonEncode({
            'url': 'https://example.com/{{ input.credentialId }}',
          }),
          inputsJson: jsonEncode({
            'credentialId': {'description': 'Credential id'},
          }),
          credentialDefinitions: const {},
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('credentialId is reserved'),
          ),
        ),
      );
    });

    test('deletes skill credential', () async {
      final workspace = await workspaceRepository.createWorkspace(
        const WorkspaceToCreate(
          name: 'Test Workspace',
          type: WorkspaceType.local,
        ),
      );
      final definition = await skillCredentialDefinitionsRepository
          .createDefinition(
            workspace.id,
            const SkillCredentialDefinitionToCreate(
              title: 'Example Service',
              attributesJson: '{"api_key":{"description":"API key"}}',
            ),
          );
      final credential = await skillCredentialsRepository.createCredential(
        workspace.id,
        SkillCredentialToCreate(
          credentialDefinitionId: definition.id,
          name: 'Example Credential',
          attributes: const {'api_key': 'secret-token'},
        ),
      );

      await skillCredentialsRepository.deleteCredential(credential.id);

      final credentials = await skillCredentialsRepository
          .getCredentialsForDefinition(
            workspaceId: workspace.id,
            credentialDefinitionId: definition.id,
          );
      expect(credentials, isEmpty);
    });

    test('stores and edits secret-aware skill credentials', () async {
      final workspace = await workspaceRepository.createWorkspace(
        const WorkspaceToCreate(
          name: 'Test Workspace',
          type: WorkspaceType.local,
        ),
      );
      final definition = await skillCredentialDefinitionsRepository
          .createDefinition(
            workspace.id,
            const SkillCredentialDefinitionToCreate(
              title: 'Example Service',
              attributesJson: '''
                  {
                    "api_key":{"description":"API key"},
                    "account_id":{"description":"Account","secret":false},
                    "optional_token":{"description":"Token","optional":true}
                  }
                  ''',
            ),
          );
      expect(
        SkillCredentialAttributeDefinition.parseMap(
          definition.attributesJson,
        )['api_key']?.secret,
        isTrue,
      );
      expect(
        SkillCredentialAttributeDefinition.parseMap(
          definition.attributesJson,
        )['account_id']?.secret,
        isFalse,
      );
      await expectLater(
        skillCredentialsRepository.createCredential(
          workspace.id,
          SkillCredentialToCreate(
            credentialDefinitionId: definition.id,
            name: 'Invalid Credential',
            attributes: const {
              'api_key': '',
              'account_id': 'acct-123',
            },
          ),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Credential attribute is required: api_key'),
          ),
        ),
      );
      final credential = await skillCredentialsRepository.createCredential(
        workspace.id,
        SkillCredentialToCreate(
          credentialDefinitionId: definition.id,
          name: 'Example Credential',
          attributes: const {
            'api_key': 'secret-token',
            'account_id': 'acct-123',
            'optional_token': 'optional-secret',
          },
        ),
      );
      final row = await database.skillCredentialsDao.getCredentialById(
        credential.id,
      );
      final encrypted = row?.encryptedAuthValue;
      expect(encrypted == null, isFalse);
      expect(encrypted, isNot(contains('secret-token')));
      expect(row?.metadataJson, contains('acct-123'));

      final executionCredential = await skillCredentialsRepository
          .getCredentialById(credential.id);
      expect(executionCredential?.attributes, {
        'account_id': 'acct-123',
        'api_key': 'secret-token',
        'optional_token': 'optional-secret',
      });
      final editCredential = await skillCredentialsRepository
          .getCredentialForEdit(credential.id);
      expect(editCredential?.nonSecretAttributes, {'account_id': 'acct-123'});
      expect(editCredential?.secretAttributes['api_key']?.hasValue, isTrue);
      expect(editCredential?.secretAttributes['api_key']?.keySuffix, '-token');
      expect(
        editCredential?.secretAttributes['optional_token']?.keySuffix,
        'secret',
      );

      final updated = await skillCredentialsRepository.updateCredential(
        credential.id,
        const SkillCredentialToUpdate(
          name: 'Updated Credential',
          nonSecretAttributes: {'account_id': 'acct-999'},
          secretAttributes: {'api_key': 'new-secret'},
          clearSecretAttributeNames: {'optional_token'},
        ),
      );

      expect(updated.name, 'Updated Credential');
      expect(updated.attributes, {
        'account_id': 'acct-999',
        'api_key': 'new-secret',
      });
      final updatedForEdit = await skillCredentialsRepository
          .getCredentialForEdit(credential.id);
      expect(updatedForEdit?.secretAttributes['api_key']?.hasValue, isTrue);
      expect(
        updatedForEdit?.secretAttributes['optional_token']?.hasValue,
        isFalse,
      );
      final secretOnlyUpdate = await skillCredentialsRepository
          .updateCredential(
            credential.id,
            const SkillCredentialToUpdate(
              secretAttributes: {'api_key': 'second-secret'},
            ),
          );
      expect(secretOnlyUpdate.attributes, {
        'account_id': 'acct-999',
        'api_key': 'second-secret',
      });
      await expectLater(
        skillCredentialsRepository.updateCredential(
          credential.id,
          const SkillCredentialToUpdate(
            clearSecretAttributeNames: {'api_key'},
          ),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Credential attribute is required: api_key'),
          ),
        ),
      );
    });

    test('watches skill credential definitions changes', () async {
      final workspace = await workspaceRepository.createWorkspace(
        const WorkspaceToCreate(
          name: 'Test Workspace',
          type: WorkspaceType.local,
        ),
      );
      final stream = StreamQueue(
        skillCredentialDefinitionsRepository.watchDefinitions(workspace.id),
      );
      addTearDown(stream.cancel);

      expect(await stream.next, isEmpty);
      final definition = await skillCredentialDefinitionsRepository
          .createDefinition(
            workspace.id,
            const SkillCredentialDefinitionToCreate(
              title: 'Example Service',
              attributesJson: '{"api_key":{"description":"API key"}}',
            ),
          );
      expect((await stream.next).map((item) => item.id), [definition.id]);

      final updated = await skillCredentialDefinitionsRepository
          .updateDefinition(
            definition.id,
            const SkillCredentialDefinitionToUpdate(
              title: 'Renamed Service',
            ),
          );
      expect((await stream.next).map((item) => item.title), [updated.title]);

      final _ = await skillCredentialDefinitionsRepository.deleteDefinition(
        definition.id,
      );
      expect(await stream.next, isEmpty);
    });

    test('watches skill credential workspace changes', () async {
      final workspace = await workspaceRepository.createWorkspace(
        const WorkspaceToCreate(
          name: 'Test Workspace',
          type: WorkspaceType.local,
        ),
      );
      final definition = await skillCredentialDefinitionsRepository
          .createDefinition(
            workspace.id,
            const SkillCredentialDefinitionToCreate(
              title: 'Example Service',
              attributesJson: '{"api_key":{"description":"API key"}}',
            ),
          );
      final stream = StreamQueue(
        skillCredentialsRepository.watchCredentialsForWorkspace(workspace.id),
      );
      addTearDown(stream.cancel);

      expect(await stream.next, isEmpty);
      final credential = await skillCredentialsRepository.createCredential(
        workspace.id,
        SkillCredentialToCreate(
          credentialDefinitionId: definition.id,
          name: 'Example Credential',
          attributes: const {'api_key': 'secret-token'},
        ),
      );
      expect((await stream.next).map((item) => item.id), [credential.id]);

      await skillCredentialsRepository.deleteCredential(credential.id);
      expect(await stream.next, isEmpty);
    });

    test('builds and runs loaded skills manager native tools', () async {
      final workspace = await workspaceRepository.createWorkspace(
        const WorkspaceToCreate(
          name: 'Test Workspace',
          type: WorkspaceType.local,
        ),
      );
      final conversation = await conversationRepository.createConversation(
        ConversationToCreate(
          title: 'Test Conversation',
          workspaceId: workspace.id,
        ),
      );
      final _ = await conversationSkillsRepository.setAppSkillLoaded(
        conversation.id,
        'skills_manager',
        isLoaded: true,
      );
      final buildSpecsUsecase = BuildAppSkillNativeToolSpecsUsecase(
        listAvailableSkillsUsecase,
      );
      final runUsecase = runSkillsManagerToolUsecase();

      final specs = await buildSpecsUsecase.call(
        conversationId: conversation.id,
        workspaceId: workspace.id,
      );
      final definitionResult =
          await runUsecase.call(
                workspaceId: workspace.id,
                toolSlug: createSkillCredentialDefinitionToolSlug,
                arguments: {
                  'title': 'Example Service',
                  'attributes': {
                    'api_key': {'description': 'API key'},
                    'account_id': {
                      'description': 'Account id',
                      'secret': false,
                    },
                  },
                },
              )
              as Map<String, Object?>;
      final skillResult = await runUsecase.call(
        workspaceId: workspace.id,
        toolSlug: createUserSkillToolSlug,
        arguments: {
          'title': 'Example Services',
          'description': 'Call Example APIs',
          'content': 'Use Example Services for company data.',
          'credentialDefinitionId': definitionResult['definitionId'],
          'isCredentialOptional': true,
        },
      );
      final toolResult = await runUsecase.call(
        workspaceId: workspace.id,
        toolSlug: createSkillTemplateToolSlug,
        arguments: {
          'skillSlug': 'example_services',
          'title': 'Find Company',
          'description': 'Find company records.',
          'template': {
            'url': 'https://example.com/company',
            'query': {'token': '{credential:api_key}'},
          },
          'inputs': {
            'company_id': {
              'description': 'Company id',
              'type': 'string',
            },
          },
          'requiresCredential': true,
        },
      );
      final clearCredentialResult = await runUsecase.call(
        workspaceId: workspace.id,
        toolSlug: updateUserSkillToolSlug,
        arguments: {
          'skillSlug': 'example_services',
          'credentialDefinitionId': '',
        },
      );
      final updatedSkill = await skillsRepository.getSkillBySlug(
        workspace.id,
        'example_services',
      );

      expect(
        specs.map((spec) => spec.name),
        containsAll([
          'skill__app__skills_manager__list_user_skills',
          'skill__app__skills_manager__get_user_skill',
          'skill__app__skills_manager__create_user_skill',
          'skill__app__skills_manager__update_user_skill',
          'skill__app__skills_manager__delete_user_skill',
          'skill__app__skills_manager__list_skill_template_tools',
          'skill__app__skills_manager__get_skill_template_tool',
          'skill__app__skills_manager__create_skill_template_tool',
          'skill__app__skills_manager__update_skill_template_tool',
          'skill__app__skills_manager__delete_skill_template_tool',
          'skill__app__skills_manager__list_skill_credential_definitions',
          'skill__app__skills_manager__get_skill_credential_definition',
          'skill__app__skills_manager__create_skill_credential_definition',
          'skill__app__skills_manager__update_skill_credential_definition',
          'skill__app__skills_manager__delete_skill_credential_definition',
        ]),
      );
      final createSkillSpec = specs.singleWhere(
        (spec) => spec.name == 'skill__app__skills_manager__create_user_skill',
      );
      final createSkillProperties =
          createSkillSpec.inputJsonSchema['properties'] as Map;
      expect(createSkillProperties, contains('credentialDefinitionId'));
      expect(createSkillProperties, contains('isCredentialOptional'));
      expect(
        createSkillProperties,
        isNot(contains('credentialDefinitionSlug')),
      );
      final createToolSpec = specs.singleWhere(
        (spec) =>
            spec.name ==
            'skill__app__skills_manager__create_skill_template_tool',
      );
      final createToolProperties =
          createToolSpec.inputJsonSchema['properties'] as Map;
      expect(createToolProperties, contains('requiresCredential'));
      expect(definitionResult, containsPair('slug', 'example_service'));
      expect(
        definitionResult['attributes'],
        containsPair(
          'account_id',
          containsPair('secret', false),
        ),
      );
      expect(skillResult, containsPair('slug', 'example_services'));
      expect(skillResult, containsPair('isCredentialOptional', true));
      expect(
        skillResult,
        containsPair(
          'credentialDefinitionId',
          definitionResult['definitionId'],
        ),
      );
      expect(toolResult, containsPair('slug', 'find_company'));
      expect(toolResult, containsPair('requiresCredential', true));
      expect(clearCredentialResult, containsPair('status', 'updated'));
      expect(updatedSkill?.credentialDefinitionId, null);
      expect(updatedSkill?.isCredentialOptional, true);

      final listedSkills =
          await runUsecase.call(
                workspaceId: workspace.id,
                toolSlug: listUserSkillsToolSlug,
                arguments: const {},
              )
              as Map<String, Object?>;
      final foundSkill =
          await runUsecase.call(
                workspaceId: workspace.id,
                toolSlug: getUserSkillToolSlug,
                arguments: {'skillSlug': 'example_services'},
              )
              as Map<String, Object?>;
      final listedTools =
          await runUsecase.call(
                workspaceId: workspace.id,
                toolSlug: listSkillTemplateToolsToolSlug,
                arguments: {'skillSlug': 'example_services'},
              )
              as Map<String, Object?>;
      final foundTool =
          await runUsecase.call(
                workspaceId: workspace.id,
                toolSlug: getSkillTemplateToolToolSlug,
                arguments: {
                  'skillSlug': 'example_services',
                  'toolSlug': 'find_company',
                },
              )
              as Map<String, Object?>;
      final updatedTool =
          await runUsecase.call(
                workspaceId: workspace.id,
                toolSlug: updateSkillTemplateToolSlug,
                arguments: {
                  'skillSlug': 'example_services',
                  'toolSlug': 'find_company',
                  'title': 'Find Organization',
                  'description': 'Find organization records.',
                },
              )
              as Map<String, Object?>;
      final listedDefinitions =
          await runUsecase.call(
                workspaceId: workspace.id,
                toolSlug: listSkillCredentialDefinitionsToolSlug,
                arguments: const {},
              )
              as Map<String, Object?>;
      final foundDefinition =
          await runUsecase.call(
                workspaceId: workspace.id,
                toolSlug: getSkillCredentialDefinitionToolSlug,
                arguments: {'definitionSlug': 'example_service'},
              )
              as Map<String, Object?>;
      final updatedDefinition =
          await runUsecase.call(
                workspaceId: workspace.id,
                toolSlug: updateSkillCredentialDefinitionToolSlug,
                arguments: {
                  'definitionSlug': 'example_service',
                  'title': 'Example Service Credentials',
                  'attributes': {
                    'api_key': {'description': 'API key'},
                    'account_id': {
                      'description': 'Account id',
                      'optional': true,
                      'secret': false,
                    },
                  },
                },
              )
              as Map<String, Object?>;
      await expectLater(
        runUsecase.call(
          workspaceId: workspace.id,
          toolSlug: createUserSkillToolSlug,
          arguments: const {
            'title': 'Bad Credential Skill',
            'description': 'Bad credential definition id',
            'content': 'Use a bad credential definition.',
            'credentialDefinitionId': 'missing-definition-id',
          },
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains(
              'Skill credential definition not found: missing-definition-id',
            ),
          ),
        ),
      );
      await expectLater(
        runUsecase.call(
          workspaceId: workspace.id,
          toolSlug: createUserSkillToolSlug,
          arguments: const {
            'title': 'Old Slug Skill',
            'description': 'Old credential slug field',
            'content': 'Use the old credential slug field.',
            'credentialDefinitionSlug': 'example_service',
          },
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('credentialDefinitionSlug is unsupported'),
          ),
        ),
      );
      final deletedTool =
          await runUsecase.call(
                workspaceId: workspace.id,
                toolSlug: deleteSkillTemplateToolSlug,
                arguments: {
                  'skillSlug': 'example_services',
                  'toolSlug': 'find_company',
                },
              )
              as Map<String, Object?>;
      final deletedSkill =
          await runUsecase.call(
                workspaceId: workspace.id,
                toolSlug: deleteUserSkillToolSlug,
                arguments: {'skillSlug': 'example_services'},
              )
              as Map<String, Object?>;
      final deletedDefinition =
          await runUsecase.call(
                workspaceId: workspace.id,
                toolSlug: deleteSkillCredentialDefinitionToolSlug,
                arguments: {'definitionSlug': 'example_service'},
              )
              as Map<String, Object?>;

      expect(
        listedSkills['skills'],
        isA<List<Object?>>().having((skills) => skills.length, 'length', 1),
      );
      expect(foundSkill, containsPair('slug', 'example_services'));
      expect(foundSkill, containsPair('description', 'Call Example APIs'));
      expect(
        foundSkill,
        containsPair('content', 'Use Example Services for company data.'),
      );
      expect(foundSkill, containsPair('isEnabled', true));
      expect(foundSkill, containsPair('isCredentialOptional', true));
      expect(
        listedTools['tools'],
        isA<List<Object?>>().having((tools) => tools.length, 'length', 1),
      );
      expect(foundTool, containsPair('slug', 'find_company'));
      expect(foundTool, containsPair('description', 'Find company records.'));
      expect(
        foundTool['template'],
        containsPair('url', 'https://example.com/company'),
      );
      expect(
        foundTool['inputs'],
        containsPair('company_id', containsPair('type', 'string')),
      );
      expect(foundTool, containsPair('isEnabled', true));
      expect(foundTool, containsPair('requiresCredential', true));
      expect(updatedTool, containsPair('status', 'updated'));
      expect(updatedTool, containsPair('requiresCredential', true));
      expect(
        listedDefinitions['definitions'],
        isA<List<Object?>>().having(
          (definitions) => definitions.length,
          'length',
          1,
        ),
      );
      expect(foundDefinition, containsPair('slug', 'example_service'));
      expect(
        foundDefinition['attributes'],
        containsPair(
          'account_id',
          containsPair('secret', false),
        ),
      );
      expect(updatedDefinition, containsPair('status', 'updated'));
      expect(
        updatedDefinition['attributes'],
        containsPair(
          'account_id',
          allOf(
            containsPair('optional', true),
            containsPair('secret', false),
          ),
        ),
      );
      expect(deletedTool, containsPair('status', 'deleted'));
      expect(deletedSkill, containsPair('status', 'deleted'));
      expect(deletedDefinition, containsPair('status', 'deleted'));
      expect(
        await skillsRepository.getSkillBySlug(
          workspace.id,
          'example_services',
        ),
        null,
      );
      expect(
        await skillCredentialDefinitionsRepository.getDefinitionBySlug(
          workspace.id,
          'example_service',
        ),
        null,
      );
    });

    test(
      'skills manager validates and runs JSON object input template tools',
      () async {
        final workspace = await workspaceRepository.createWorkspace(
          const WorkspaceToCreate(
            name: 'Test Workspace',
            type: WorkspaceType.local,
          ),
        );
        final runUsecase = runSkillsManagerToolUsecase();
        final definitionResult =
            await runUsecase.call(
                  workspaceId: workspace.id,
                  toolSlug: createSkillCredentialDefinitionToolSlug,
                  arguments: {
                    'title': 'RescueGroups API',
                    'attributes': {
                      'api_key': {'description': 'API key'},
                    },
                  },
                )
                as Map<String, Object?>;
        final skillResult = await runUsecase.call(
          workspaceId: workspace.id,
          toolSlug: createUserSkillToolSlug,
          arguments: {
            'title': 'RescueGroups',
            'description': 'Call RescueGroups APIs',
            'content': 'Use RescueGroups for animal data.',
            'credentialDefinitionId': definitionResult['definitionId'],
          },
        );

        expect(definitionResult, containsPair('slug', 'rescuegroups_api'));
        expect(skillResult, containsPair('slug', 'rescuegroups'));
        await expectLater(
          runUsecase.call(
            workspaceId: workspace.id,
            toolSlug: createSkillTemplateToolSlug,
            arguments: {
              'skillSlug': 'rescuegroups',
              'title': 'Bad Search',
              'description': 'Bad search tool.',
              'template': {
                'url': 'https://api.rescuegroups.org/http/v2.json',
                'method': 'POST',
                'body': '{"filters":{{filters}}}',
              },
              'inputs': {
                'filters': {
                  'description': 'Search filters',
                  'type': 'array',
                },
              },
            },
          ),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains('Unsupported Liquid reference'),
            ),
          ),
        );

        final toolResult =
            await runUsecase.call(
                  workspaceId: workspace.id,
                  toolSlug: createSkillTemplateToolSlug,
                  arguments: {
                    'skillSlug': 'rescuegroups',
                    'title': 'Search Animals',
                    'description': 'Search animal records.',
                    'template': {
                      'url': 'https://api.rescuegroups.org/http/v2.json',
                      'method': 'POST',
                      'headers': {
                        'Authorization': 'Bearer {{ credential.api_key }}',
                      },
                      'bodyFormat': 'json',
                      'body': [
                        '{"objectType":"animals",',
                        '"objectAction":"search",',
                        '"search":{"filters":{{ input.filters | json }}},',
                        '"fields":{{ input.fields | json }}}',
                      ].join(),
                    },
                    'inputs': {
                      'filters': {
                        'description': 'Search filters',
                        'type': 'array',
                      },
                      'fields': {
                        'description': 'Fields object',
                        'type': 'object',
                      },
                    },
                  },
                )
                as Map<String, Object?>;
        final definition = await skillCredentialDefinitionsRepository
            .getDefinitionBySlug(
              workspace.id,
              'rescuegroups_api',
            );
        final definitionId = (definition ?? fail('definition missing')).id;
        final credential = await skillCredentialsRepository.createCredential(
          workspace.id,
          SkillCredentialToCreate(
            credentialDefinitionId: definitionId,
            name: 'RescueGroups Credential',
            attributes: const {'api_key': 'secret-token'},
          ),
        );
        final requests = <RequestOptions>[];
        final runTemplateUsecase = RunSkillTemplateToolUsecase(
          toolsRepository,
          skillsRepository,
          skillCredentialDefinitionsRepository,
          skillCredentialsRepository,
          const ResolveSkillUrlTemplateUsecase(),
          UrlService(dio: _dioWithBody('ok', requests: requests)),
        );
        final result = await runTemplateUsecase.call(
          workspaceId: workspace.id,
          skillSlug: 'rescuegroups',
          toolSlug: 'search_animals',
          arguments: {
            'filters': [
              {
                'fieldName': 'animalGeneralSpecies',
                'operation': 'equals',
                'criteria': 'Dog',
              },
            ],
            'fields': {
              'animalGeneralSpecies': <String, Object?>{},
            },
            'credentialId': credential.id,
          },
        );

        expect(toolResult, containsPair('slug', 'search_animals'));
        expect(result, 'ok');
        expect(jsonDecode(await _requestBody(requests.single)), {
          'objectType': 'animals',
          'objectAction': 'search',
          'search': {
            'filters': [
              {
                'fieldName': 'animalGeneralSpecies',
                'operation': 'equals',
                'criteria': 'Dog',
              },
            ],
          },
          'fields': {
            'animalGeneralSpecies': <String, Object?>{},
          },
        });
      },
    );

    test('renders optional Liquid text body values as blank', () {
      const usecase = ResolveSkillUrlTemplateUsecase();

      final request = usecase.call(
        template: const SkillUrlTemplate(
          url: 'https://example.com',
          body: 'token={{ input.maybe_token }}',
          bodyFormat: SkillUrlTemplateBodyFormat.text,
        ),
        inputs: const {},
        credentials: const {},
        inputDefinitions: const {
          'maybe_token': SkillTemplateInputDefinition(
            description: 'Optional token',
            optional: true,
          ),
        },
      );

      expect(request.body, 'token=');
    });
  });
}

List<Object?> _slugEnumFor(List<ToolSpec> specs, String toolName) {
  final schema = specs
      .firstWhere((spec) => spec.name == toolName)
      .inputJsonSchema;
  final properties = schema['properties'] as Map<String, dynamic>;
  final slugSchema = properties['slug'] as Map<String, dynamic>;

  return slugSchema['enum'] as List<Object?>;
}

List<Object?> _propertyEnumFor(ToolSpec spec, String propertyName) {
  final properties = spec.inputJsonSchema['properties'] as Map<String, dynamic>;
  final propertySchema = properties[propertyName] as Map<String, dynamic>;

  return propertySchema['enum'] as List<Object?>;
}

Dio _dioWithBody(String body, {List<RequestOptions>? requests}) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        requests?.add(options);
        handler.resolve(
          Response<ResponseBody>(
            data: ResponseBody.fromString(body, 200),
            requestOptions: options,
            statusCode: 200,
          ),
        );
      },
    ),
  );

  return dio;
}

Future<String> _requestBody(RequestOptions options) async {
  final data = options.data;
  if (data is Stream<List<int>>) {
    final bytes = <int>[];
    await data.forEach(bytes.addAll);

    return utf8.decode(bytes);
  }

  return '$data';
}

class _FakeSecretKeyManager extends SecretKeyManager {
  _FakeSecretKeyManager() : super();

  @override
  Future<SecretKey> getOrCreateSecretKey() async {
    return SecretKey(List<int>.generate(32, (index) => index));
  }
}
