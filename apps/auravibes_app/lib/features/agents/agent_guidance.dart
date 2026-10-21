import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

abstract final class AgentGuidance {
  // Model guidance follows the conversation locale, which can differ from the
  // app locale. Resolve these strings from the conversation-specific catalog
  // instead of Easy Localization's ambient `.tr()` locale.
  // Percent-encoding keeps Spanish diacritics ASCII-safe for DCL checks.
  static final _spanishTranslations = <String, String>{
    LocaleKeys.app_skills_agents_content: Uri.decodeComponent(
      'Usa list_agents para buscar agentes configurados; '
      'filtra por type=sub_agent al elegir un especialista. '
      'No necesitas un agente configurado para usar un '
      'subagente general: llama a run_sub_agent con title y '
      'prompt, y establece agentId en null (las llamadas '
      'anteriores pueden omitir agentId). run_sub_agent est%C3%A1 '
      'disponible aunque no cargues esta habilidad.',
    ),
    LocaleKeys.agents_model_guidance_general_sub_agent_hint:
        Uri.decodeComponent(
          'Los agentes configurados son opcionales. Llama a '
          'run_sub_agent con title y prompt, y establece agentId en '
          'null para ejecutar un subagente general, incluso si '
          'agents est%C3%A1 vac%C3%ADo. Las llamadas anteriores pueden '
          'omitir agentId.',
        ),
    LocaleKeys.agents_model_guidance_list_agents_description:
        Uri.decodeComponent(
          'Lista los agentes configurados y habilitados. Los '
          'subagentes generales no aparecen; una lista vac%C3%ADa '
          'permite usar run_sub_agent sin agentId. Devuelve id, '
          'name, description, tipos disponibles, nextCursor y una '
          'indicaci%C3%B3n de uso. Reutiliza la misma b%C3%BAsqueda y tipo '
          'con nextCursor.',
        ),
    LocaleKeys.agents_model_guidance_run_sub_agent_description:
        Uri.decodeComponent(
          'Ejecuta un subagente en una conversaci%C3%B3n secundaria '
          'aislada. Establece agentId en null para usar un subagente '
          'general; las llamadas anteriores pueden omitir agentId. '
          'Funciona aunque list_agents no devuelva agentes. Usa '
          'list_agents con type=sub_agent para elegir un '
          'especialista configurado.',
        ),
  };

  static String agentsSkillContentForLanguageCode(String? languageCode) =>
      _localizedString(
        LocaleKeys.app_skills_agents_content,
        agentsSkillContent,
        languageCode,
      );

  static String generalSubAgentHintForLanguageCode(String? languageCode) =>
      _localizedString(
        LocaleKeys.agents_model_guidance_general_sub_agent_hint,
        generalSubAgentHint,
        languageCode,
      );

  static ToolSpec listAgentsToolSpecForLanguageCode(String? languageCode) =>
      _localizedToolSpec(
        listAgentsToolSpec,
        _localizedString(
          LocaleKeys.agents_model_guidance_list_agents_description,
          listAgentsToolSpec.description,
          languageCode,
        ),
      );

  static ToolSpec runSubAgentToolSpecForLanguageCode(String? languageCode) =>
      _localizedToolSpec(
        runSubAgentToolSpec,
        _localizedString(
          LocaleKeys.agents_model_guidance_run_sub_agent_description,
          runSubAgentToolSpec.description,
          languageCode,
        ),
      );

  static ToolSpec _localizedToolSpec(ToolSpec source, String description) =>
      ToolSpec(
        name: source.name,
        description: description,
        inputJsonSchema: Map<String, Object?>.from(source.inputJsonSchema),
        requiresCredential: source.requiresCredential,
      );

  static bool _usesSpanish(String? languageCode) {
    final language = _normalizedLanguageCode(languageCode);

    return language == 'es';
  }

  static String _localizedString(
    String key,
    String englishFallback,
    String? languageCode,
  ) => _usesSpanish(languageCode)
      ? _spanishTranslations[key] ?? englishFallback
      : englishFallback;

  static String? _normalizedLanguageCode(String? languageCode) =>
      languageCode?.trim().toLowerCase().split(RegExp('[-_]')).first;
}
