import 'package:auravibes_engine/auravibes_engine.dart';

// Mirrors the app's agents.model_guidance and app_skills.agents catalog keys.
// Keep these server-owned strings aligned because the server cannot depend on
// Flutter's localization resources.
const _spanishAgentsSkillContent =
    'Usa list_agents para buscar agentes configurados; filtra por '
    'type=sub_agent al elegir un especialista. No necesitas un agente '
    'configurado para usar un subagente general: llama a run_sub_agent con '
    'title y prompt, y establece agentId en null (las llamadas anteriores '
    'pueden omitir agentId). run_sub_agent est\u00E1 disponible aunque no cargues '
    'esta habilidad.';
const _spanishGeneralSubAgentHint =
    'Los agentes configurados son opcionales. Llama a run_sub_agent con '
    'title y prompt, y establece agentId en null para ejecutar un subagente '
    'general, incluso si agents est\u00E1 vac\u00EDo. Las llamadas anteriores pueden '
    'omitir agentId.';
const _spanishListAgentsDescription =
    'Lista los agentes configurados y habilitados. Los subagentes '
    'generales no aparecen; una lista vacía permite usar run_sub_agent sin '
    'agentId. Devuelve id, name, description, tipos disponibles, '
    'nextCursor y una indicaci\u00F3n de uso. Reutiliza la misma b\u00FAsqueda y '
    'tipo con nextCursor.';
const _spanishRunSubAgentDescription =
    'Ejecuta un subagente en una conversaci\u00F3n secundaria aislada. '
    'Establece agentId en null para usar un subagente general; las llamadas '
    'anteriores pueden omitir agentId. Funciona aunque list_agents no '
    'devuelva agentes. Usa list_agents con type=sub_agent para elegir un '
    'especialista configurado.';

bool _usesSpanishAgentGuidance(String? languageCode) {
  final language = languageCode
      ?.trim()
      .toLowerCase()
      .split(RegExp('[-_]'))
      .first;

  return language == 'es';
}

String serverAgentsSkillContentForLanguageCode(String? languageCode) =>
    _usesSpanishAgentGuidance(languageCode)
    ? _spanishAgentsSkillContent
    : agentsSkillContent;

String serverGeneralSubAgentHintForLanguageCode(String? languageCode) =>
    _usesSpanishAgentGuidance(languageCode)
    ? _spanishGeneralSubAgentHint
    : generalSubAgentHint;

ToolSpec serverListAgentsToolSpecForLanguageCode(String? languageCode) =>
    _localizedToolSpec(
      listAgentsToolSpec,
      _usesSpanishAgentGuidance(languageCode)
          ? _spanishListAgentsDescription
          : listAgentsToolSpec.description,
    );

ToolSpec serverRunSubAgentToolSpecForLanguageCode(String? languageCode) =>
    _localizedToolSpec(
      runSubAgentToolSpec,
      _usesSpanishAgentGuidance(languageCode)
          ? _spanishRunSubAgentDescription
          : runSubAgentToolSpec.description,
    );

ToolSpec _localizedToolSpec(ToolSpec source, String description) => ToolSpec(
  name: source.name,
  description: description,
  inputJsonSchema: Map<String, Object?>.from(source.inputJsonSchema),
  requiresCredential: source.requiresCredential,
);
