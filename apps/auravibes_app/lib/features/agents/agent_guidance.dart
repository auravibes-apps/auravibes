import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:easy_localization/easy_localization.dart';

abstract final class AgentGuidance {
  static String agentsSkillContentForLanguageCode(String? languageCode) =>
      _usesSpanish(languageCode)
      ? LocaleKeys.app_skills_agents_content.tr()
      : agentsSkillContent;

  static String generalSubAgentHintForLanguageCode(String? languageCode) =>
      _usesSpanish(languageCode)
      ? LocaleKeys.agents_model_guidance_general_sub_agent_hint.tr()
      : generalSubAgentHint;

  static ToolSpec listAgentsToolSpecForLanguageCode(String? languageCode) =>
      _localizedToolSpec(
        listAgentsToolSpec,
        _usesSpanish(languageCode)
            ? LocaleKeys.agents_model_guidance_list_agents_description.tr()
            : listAgentsToolSpec.description,
      );

  static ToolSpec runSubAgentToolSpecForLanguageCode(String? languageCode) =>
      _localizedToolSpec(
        runSubAgentToolSpec,
        _usesSpanish(languageCode)
            ? LocaleKeys.agents_model_guidance_run_sub_agent_description.tr()
            : runSubAgentToolSpec.description,
      );

  static ToolSpec _localizedToolSpec(ToolSpec source, String description) =>
      ToolSpec(
        name: source.name,
        description: description,
        inputJsonSchema: Map<String, Object?>.from(source.inputJsonSchema),
        requiresCredential: source.requiresCredential,
      );

  static bool _usesSpanish(String? languageCode) {
    final language = languageCode
        ?.trim()
        .toLowerCase()
        .split(RegExp('[-_]'))
        .first;

    return language == 'es';
  }
}
