import 'dart:convert';

import 'package:auravibes_app/features/agents/agent_guidance.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart' show Locale, SizedBox;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

import '../../helpers/test_app.dart';

void main() {
  testWidgets('localizes agent guidance without changing tool schemas', (
    tester,
  ) async {
    await tester.pumpWidget(
      const TestableApp(child: SizedBox.shrink(), startLocale: .new('es')),
    );
    final _ = await tester.pumpAndSettle();
    await _waitForSpanishTranslations(tester);

    final englishListAgents = AgentGuidance.listAgentsToolSpecForLanguageCode(
      'en',
    );
    final spanishListAgents = AgentGuidance.listAgentsToolSpecForLanguageCode(
      'es-MX',
    );
    final englishRunSubAgent = AgentGuidance.runSubAgentToolSpecForLanguageCode(
      'en',
    );
    final spanishRunSubAgent = AgentGuidance.runSubAgentToolSpecForLanguageCode(
      'es-MX',
    );

    expect(spanishListAgents.name, englishListAgents.name);
    expect(spanishListAgents.name, listAgentsToolName);
    expect(spanishListAgents.description, contains('agentes configurados'));
    expect(
      spanishListAgents.inputJsonSchema,
      englishListAgents.inputJsonSchema,
    );
    expect(spanishRunSubAgent.name, englishRunSubAgent.name);
    expect(spanishRunSubAgent.name, runSubAgentToolName);
    expect(spanishRunSubAgent.description, contains('subagente'));
    expect(
      spanishRunSubAgent.inputJsonSchema,
      englishRunSubAgent.inputJsonSchema,
    );
    expect(
      AgentGuidance.agentsSkillContentForLanguageCode('es'),
      contains('Usa list_agents'),
    );
    expect(
      AgentGuidance.generalSubAgentHintForLanguageCode('es'),
      contains('agentes'),
    );
  });

  testWidgets('uses conversation locale when app locale differs', (
    tester,
  ) async {
    await tester.pumpWidget(const TestableApp(child: SizedBox.shrink()));
    final _ = await tester.pumpAndSettle();
    final _ = await _waitForEnglishTranslations(tester);

    final spanishListAgents = AgentGuidance.listAgentsToolSpecForLanguageCode(
      'es',
    );
    final spanishRunSubAgent = AgentGuidance.runSubAgentToolSpecForLanguageCode(
      'es',
    );
    final spanishSkillContent = AgentGuidance.agentsSkillContentForLanguageCode(
      'es',
    );
    final spanishHint = AgentGuidance.generalSubAgentHintForLanguageCode('es');
    final spanishCatalogJson = await tester.runAsync(
      () => rootBundle.loadString('assets/i18n/es.json'),
    );
    if (spanishCatalogJson == null) {
      fail('Spanish localization catalog did not load');
    }
    final spanishCatalog =
        jsonDecode(spanishCatalogJson) as Map<String, dynamic>;

    expect(
      spanishListAgents.description,
      _translationAt(
        spanishCatalog,
        'agents.model_guidance.list_agents_description',
      ),
    );
    expect(
      spanishRunSubAgent.description,
      _translationAt(
        spanishCatalog,
        'agents.model_guidance.run_sub_agent_description',
      ),
    );
    expect(
      spanishSkillContent,
      _translationAt(spanishCatalog, 'app_skills.agents.content'),
    );
    expect(
      spanishHint,
      _translationAt(
        spanishCatalog,
        'agents.model_guidance.general_sub_agent_hint',
      ),
    );
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('en'),
    );
  });

  test('falls back to English for unsupported agent guidance locales', () {
    expect(
      AgentGuidance.agentsSkillContentForLanguageCode('fr-CA'),
      agentsSkillContent,
    );
    expect(
      AgentGuidance.generalSubAgentHintForLanguageCode('fr-CA'),
      generalSubAgentHint,
    );
    expect(
      AgentGuidance.listAgentsToolSpecForLanguageCode('fr-CA').description,
      listAgentsToolSpec.description,
    );
    expect(
      AgentGuidance.runSubAgentToolSpecForLanguageCode('fr-CA').description,
      runSubAgentToolSpec.description,
    );
  });

  test('localizes list result hint without changing its JSON shape', () {
    final englishResult = jsonEncode({
      'agents': const <Map<String, Object?>>[],
      'nextCursor': null,
      'hint': 'Configured agents are optional.',
    });
    final spanishResult = jsonDecode(
      AgentGuidance.localizeListAgentsResult(englishResult, 'es'),
    ) as Map<String, dynamic>;

    expect(spanishResult.keys, const <String>['agents', 'nextCursor', 'hint']);
    expect(
      spanishResult['hint'],
      AgentGuidance.generalSubAgentHintForLanguageCode('es'),
    );
  });
}

String _translationAt(Map<String, dynamic> translations, String key) {
  final segments = key.split('.');
  var current = translations;
  for (final segment in segments.take(segments.length - 1)) {
    final value = current[segment];
    if (value is! Map<String, dynamic>) {
      throw StateError('Missing translation map at $segment');
    }
    current = value;
  }
  final translation = current[segments.last];
  if (translation is! String) {
    throw StateError('Missing translation for $key');
  }

  return translation;
}

Future<void> _waitForSpanishTranslations(WidgetTester tester) async {
  final _ = await tester.runAsync(() async {
    for (var attempt = 0; attempt < 50; attempt++) {
      if (LocaleKeys.agents_model_guidance_list_agents_description.trExists()) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });

  expect(
    LocaleKeys.agents_model_guidance_list_agents_description.trExists(),
    isTrue,
  );
}

Future<void> _waitForEnglishTranslations(WidgetTester tester) async {
  final _ = await tester.runAsync(() async {
    for (var attempt = 0; attempt < 50; attempt++) {
      if (LocaleKeys.app_skills_agents_content.trExists()) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });

  expect(LocaleKeys.app_skills_agents_content.trExists(), isTrue);
}
