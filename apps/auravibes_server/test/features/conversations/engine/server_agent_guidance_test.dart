import 'dart:convert';
import 'dart:io';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_agent_guidance.dart';
import 'package:test/test.dart';

void main() {
  test('server agent guidance mirrors app localization resources', () async {
    for (final language in ['en', 'es']) {
      final catalog = Map<String, dynamic>.from(
        jsonDecode(
          await File(
            '../auravibes_app/assets/i18n/$language.json',
          ).readAsString(),
        ) as Map,
      );

      expect(
        serverAgentsSkillContentForLanguageCode(language),
        _catalogValue(catalog, 'app_skills.agents.content'),
      );
      expect(
        serverGeneralSubAgentHintForLanguageCode(language),
        _catalogValue(catalog, 'agents.model_guidance.general_sub_agent_hint'),
      );
      expect(
        serverListAgentsToolSpecForLanguageCode(language).description,
        _catalogValue(catalog, 'agents.model_guidance.list_agents_description'),
      );
      expect(
        serverRunSubAgentToolSpecForLanguageCode(language).description,
        _catalogValue(
          catalog,
          'agents.model_guidance.run_sub_agent_description',
        ),
      );
    }

    expect(
      serverListAgentsToolSpecForLanguageCode('es-MX').inputJsonSchema,
      listAgentsToolSpec.inputJsonSchema,
    );
    expect(
      serverRunSubAgentToolSpecForLanguageCode('es-MX').inputJsonSchema,
      runSubAgentToolSpec.inputJsonSchema,
    );
  });
}

String _catalogValue(Map<String, dynamic> catalog, String key) {
  dynamic value = catalog;
  for (final part in key.split('.')) {
    value = (value as Map<String, dynamic>)[part];
  }

  return value as String;
}
