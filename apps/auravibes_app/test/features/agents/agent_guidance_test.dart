import 'package:auravibes_app/features/agents/agent_guidance.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:flutter_test/flutter_test.dart';

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
