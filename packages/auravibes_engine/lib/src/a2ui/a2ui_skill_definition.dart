import 'package:auravibes_engine/src/a2ui/a2ui_chat_contract.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';

const a2uiSkillSlug = 'a2ui';
const a2uiCoreResourceSlug = 'a2ui-core';
const a2uiPassiveResourceSlug = 'a2ui-passive';
const a2uiFormsResourceSlug = 'a2ui-forms';
const a2uiViewsResourceSlug = 'a2ui-views';

const _excludedViewComponents = <String>{
  'Image',
  'Avatar',
  'AvatarGroup',
  'Link',
  'SkillSuggestion',
};

AppSkillDefinition a2uiSkillDefinitionForComponents(
  Iterable<String> supportedComponents,
) {
  final componentIds = Set<String>.unmodifiable(supportedComponents);

  return AppSkillDefinition(
    identifier: a2uiSkillSlug,
    slug: a2uiSkillSlug,
    title: 'A2UI',
    description: 'Generate interactive UI surfaces when the user needs them.',
    content:
        'Activate this capability, then load a2ui-core and one mode resource '
        '(or a2ui-views for saved workspace Views) with load_skill_resource '
        'before emitting A2UI definitions.',
    contentOnly: true,
    resources: [
      _coreResource(componentIds),
      _formsResource(componentIds),
      _passiveResource(componentIds),
      _viewsResource(componentIds),
    ],
  );
}

AppSkillResourceDefinition _coreResource(Set<String> componentIds) =>
    AppSkillResourceDefinition(
      slug: a2uiCoreResourceSlug,
      title: 'A2UI core protocol',
      description: 'Common A2UI protocol and surface lifecycle instructions.',
      content: A2uiChatContract.systemPromptForProfile(
        A2uiChatPromptProfile(
          supportedComponentIds: componentIds,
          interactionModes: a2uiChatInteractionModes,
        ),
        includeCatalogSchemas: false,
      ),
    );

AppSkillResourceDefinition _formsResource(Set<String> componentIds) =>
    AppSkillResourceDefinition(
      slug: a2uiFormsResourceSlug,
      title: 'A2UI form surfaces',
      description: 'Schemas and instructions for user-action form surfaces.',
      content: A2uiChatContract.systemPromptForProfile(
        A2uiChatPromptProfile(
          supportedComponentIds: componentIds.difference({
            a2uiChatSkillSuggestionComponentId,
          }),
          interactionModes: const {'requiresUserAction'},
        ),
        includeCore: false,
      ),
    );

AppSkillResourceDefinition _passiveResource(Set<String> componentIds) =>
    AppSkillResourceDefinition(
      slug: a2uiPassiveResourceSlug,
      title: 'A2UI passive surfaces',
      description: 'Schemas and instructions for read-only UI surfaces.',
      content: A2uiChatContract.systemPromptForProfile(
        A2uiChatPromptProfile(
          supportedComponentIds: componentIds,
          interactionModes: const {'passive'},
        ),
        includeCore: false,
      ),
    );

AppSkillResourceDefinition _viewsResource(Set<String> componentIds) =>
    AppSkillResourceDefinition(
      slug: a2uiViewsResourceSlug,
      title: 'A2UI saved workspace views',
      description:
          'Schemas, host data-model bindings, and patch instructions for '
          'workspace Views.',
      content: _savedViewsPrompt(
        A2uiChatPromptProfile(
          supportedComponentIds: componentIds.difference(
            _excludedViewComponents,
          ),
          interactionModes: a2uiChatInteractionModes,
        ),
      ),
    );

String _savedViewsPrompt(A2uiChatPromptProfile profile) =>
    '''
Saved workspace Views persist an A2uiSavedDefinition in workspace_create_view
or workspace_save_view instead of emitting chat protocol envelopes:
- Full definition shape: {"version": 1, "components": [{"id": "root", ...}]}
- Incremental patch in workspace_save_view: pass updateComponents (changed or
  added component maps by id) and/or removeComponentIds without resending
  unchanged components.
- Excluded components in saved Views: ${_excludedViewComponents.join(', ')}.
- Never include action, actions, onSubmittedAction, url, href, or script keys
  inside components.
- Map binding keys to table column IDs in bindings (e.g. {"field0": "col_1"}).
- Host-provided data-model paths available to components:
  - Table: {"path": "/columns"} and {"path": "/rows"}
  - Selected record fields: {"path": "/<bindingKey>"} (formatted text, or typed
    num/bool when bound only to CheckBox/Slider/Rating/Progress),
    {"path": "/<bindingKey>_raw"} (raw num/bool scalar), and
    {"path": "/fieldLabels/<bindingKey>"} (column label)
  - Numeric column summaries: {"path": "/summary/<columnId>"} (binds to a column
    listed in summaryColumnIds)
  - Charts: {"path": "/chartLabels"} and {"path": "/chartSeries"}
- Optional host action on the View (viewAction parameter):
  {"version": 1, "type": "updateSelectedRecord",
   "inputs": {"<columnId>": "/<bindingKey>"}}
  When viewAction is set, form input components must bind to the paths in
  viewAction.inputs values.
${A2uiChatContract.systemPromptForProfile(profile, includeCore: false)}''';

final AppSkillDefinition a2uiSkillDefinition = a2uiSkillDefinitionForComponents(
  supportedA2uiChatComponents,
);

final List<AppSkillDefinition> internalAppSkillDefinitions = List.unmodifiable([
  a2uiSkillDefinition,
]);
