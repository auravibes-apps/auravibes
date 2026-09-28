import 'package:auravibes_engine/src/a2ui/a2ui_chat_contract.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';

const a2uiSkillSlug = 'a2ui';
const a2uiCoreResourceSlug = 'a2ui-core';
const a2uiPassiveResourceSlug = 'a2ui-passive';
const a2uiFormsResourceSlug = 'a2ui-forms';

AppSkillDefinition a2uiSkillDefinitionForComponents(
  Iterable<String> supportedComponents,
) {
  final componentIds = Set<String>.unmodifiable(supportedComponents);
  final coreProfile = A2uiChatPromptProfile(
    supportedComponentIds: componentIds,
    interactionModes: a2uiChatInteractionModes,
  );
  final passiveProfile = A2uiChatPromptProfile(
    supportedComponentIds: componentIds,
    interactionModes: const {'passive'},
  );
  final formsProfile = A2uiChatPromptProfile(
    supportedComponentIds: componentIds,
    interactionModes: const {'requiresUserAction'},
  );

  return AppSkillDefinition(
    identifier: a2uiSkillSlug,
    slug: a2uiSkillSlug,
    title: 'A2UI',
    description: 'Generate interactive UI surfaces when the user needs them.',
    content:
        'Activate this capability, then load a2ui-core and one mode resource '
        'with load_skill_resource before emitting A2UI protocol JSON.',
    contentOnly: true,
    resources: [
      AppSkillResourceDefinition(
        slug: a2uiCoreResourceSlug,
        title: 'A2UI core protocol',
        description: 'Common A2UI protocol and surface lifecycle instructions.',
        content: A2uiChatContract.systemPromptForProfile(
          coreProfile,
          includeCatalogSchemas: false,
        ),
      ),
      AppSkillResourceDefinition(
        slug: a2uiFormsResourceSlug,
        title: 'A2UI form surfaces',
        description: 'Schemas and instructions for user-action form surfaces.',
        content: A2uiChatContract.systemPromptForProfile(
          formsProfile,
          includeCore: false,
        ),
      ),
      AppSkillResourceDefinition(
        slug: a2uiPassiveResourceSlug,
        title: 'A2UI passive surfaces',
        description: 'Schemas and instructions for read-only UI surfaces.',
        content: A2uiChatContract.systemPromptForProfile(
          passiveProfile,
          includeCore: false,
        ),
      ),
    ],
  );
}

final AppSkillDefinition a2uiSkillDefinition = a2uiSkillDefinitionForComponents(
  supportedA2uiChatComponents,
);

final List<AppSkillDefinition> internalAppSkillDefinitions = List.unmodifiable([
  a2uiSkillDefinition,
]);
