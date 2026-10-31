import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('defines A2UI as a content-only capability', () {
    expect(a2uiSkillDefinition.identifier, 'a2ui');
    expect(a2uiSkillDefinition.slug, 'a2ui');
    expect(a2uiSkillDefinition.contentOnly, isTrue);
    expect(a2uiSkillDefinition.tools, isEmpty);
    expect(a2uiSkillDefinition.connectorToolIds, isEmpty);
    expect(a2uiSkillDefinition.resources.map((resource) => resource.slug), [
      'a2ui-core',
      'a2ui-forms',
      'a2ui-passive',
      'a2ui-views',
    ]);
    expect(a2uiSkillDefinition.content, contains('load_skill_resource'));
  });

  test('generates mode-specific resources from the chat contract', () {
    final resources = {
      for (final resource in a2uiSkillDefinition.resources)
        resource.slug: resource.content,
    };

    expect(resources['a2ui-core'], contains('A2UI_CORE_INSTRUCTIONS_START'));
    expect(resources['a2ui-core'], isNot(contains('CATALOG_SCHEMA_START')));
    expect(resources['a2ui-core'], contains(a2uiChatCatalogId));
    expect(resources['a2ui-core'], contains(a2uiChatFormCatalogId));

    expect(resources['a2ui-passive'], contains(a2uiChatCatalogId));
    expect(resources['a2ui-passive'], isNot(contains(a2uiChatFormCatalogId)));
    expect(resources['a2ui-passive'], contains('CATALOG_SCHEMA_START'));
    expect(resources['a2ui-passive'], contains('"Text"'));
    expect(
      resources['a2ui-passive'],
      isNot(contains('A2UI_CORE_INSTRUCTIONS_START')),
    );

    expect(resources['a2ui-forms'], contains(a2uiChatFormCatalogId));
    expect(resources['a2ui-forms'], isNot(contains(a2uiChatCatalogId)));
    expect(resources['a2ui-forms'], contains('CATALOG_SCHEMA_START'));
    expect(resources['a2ui-forms'], contains('"TextField"'));
    expect(
      resources['a2ui-forms'],
      isNot(contains('A2UI_CORE_INSTRUCTIONS_START')),
    );

    expect(resources['a2ui-views'], contains('workspace_create_view'));
    expect(resources['a2ui-views'], contains('workspace_save_view'));
    expect(resources['a2ui-views'], contains('updateComponents'));
    expect(resources['a2ui-views'], contains('/fieldLabels/'));
    expect(resources['a2ui-views'], isNot(contains('"Image":')));
    expect(resources['a2ui-views'], isNot(contains('"SkillSuggestion":')));
  });

  test('filters generated resources to negotiated components', () {
    final definition = a2uiSkillDefinitionForComponents(const {'Text'});
    final resources = {
      for (final resource in definition.resources)
        resource.slug: resource.content,
    };

    expect(resources[a2uiPassiveResourceSlug], contains('"Text"'));
    expect(resources[a2uiPassiveResourceSlug], isNot(contains('"TextField"')));
    expect(resources[a2uiFormsResourceSlug], contains('"Text"'));
    expect(resources[a2uiFormsResourceSlug], isNot(contains('"TextField"')));
    expect(resources[a2uiViewsResourceSlug], contains('"Text"'));
    expect(resources[a2uiViewsResourceSlug], isNot(contains('"TextField"')));
  });

  test('exposes skill suggestions in passive resource only', () {
    final resources = {
      for (final resource in a2uiSkillDefinition.resources)
        resource.slug: resource.content,
    };

    expect(resources[a2uiPassiveResourceSlug], contains('"SkillSuggestion"'));
    expect(
      resources[a2uiFormsResourceSlug],
      isNot(contains('"SkillSuggestion"')),
    );
    expect(
      resources[a2uiCoreResourceSlug],
      isNot(contains('"SkillSuggestion"')),
    );
    expect(
      resources[a2uiViewsResourceSlug],
      isNot(contains('"SkillSuggestion":')),
    );
  });

  test('keeps the A2UI definition separate from service definitions', () {
    expect(serviceSkillDefinitions, isNot(contains(a2uiSkillDefinition)));
    expect(internalAppSkillDefinitions, contains(a2uiSkillDefinition));
  });
}
