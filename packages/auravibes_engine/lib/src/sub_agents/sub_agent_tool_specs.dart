import 'package:auravibes_engine/src/tool_spec.dart';

const agentsSkillSlug = 'agents';
const agentsSkillTitle = 'Agents';
const agentsSkillContent =
    'Use list_agents to find configured agents; filter by type=sub_agent '
    'when selecting a specialist. A general sub-agent needs no configured '
    'agent: call run_sub_agent with title and prompt and set agentId to null '
    '(older calls may omit agentId). '
    'run_sub_agent is available without loading this skill.';
const listAgentsToolName = 'list_agents';
const runSubAgentToolName = 'run_sub_agent';
const generalSubAgentHint =
    'Configured agents are optional. Call run_sub_agent with title and prompt '
    'and set agentId to null to run a general sub-agent, even when agents is '
    'empty. Older calls may omit agentId.';

const _spanishAgentsSkillContent =
    'Usa list_agents para buscar agentes configurados; filtra por '
    'type=sub_agent al elegir un especialista. No necesitas un agente '
    'configurado para usar un subagente general: llama a run_sub_agent con '
    'title y prompt, y establece agentId en null (las llamadas anteriores '
    'pueden omitir agentId). run_sub_agent está disponible aunque no cargues '
    'esta habilidad.';
const _spanishGeneralSubAgentHint =
    'Los agentes configurados son opcionales. Llama a run_sub_agent con '
    'title y prompt, y establece agentId en null para ejecutar un subagente '
    'general, incluso si agents está vacío. Las llamadas anteriores pueden '
    'omitir agentId.';

class const SubAgentGuidance({
  required final String agentsSkillContent,
  required final String listAgentsDescription,
  required final String runSubAgentDescription,
  required final String generalHint,
});

const _englishSubAgentGuidance = SubAgentGuidance(
  agentsSkillContent: agentsSkillContent,
  listAgentsDescription: _listAgentsDescription,
  runSubAgentDescription: _runSubAgentDescription,
  generalHint: generalSubAgentHint,
);
const _spanishSubAgentGuidance = SubAgentGuidance(
  agentsSkillContent: _spanishAgentsSkillContent,
  listAgentsDescription:
      'Lista los agentes configurados y habilitados. Los subagentes '
      'generales no aparecen; una lista vacía permite usar run_sub_agent sin '
      'agentId. Devuelve id, name, description, tipos disponibles, '
      'nextCursor y una indicación de uso. Reutiliza la misma búsqueda y '
      'tipo con nextCursor.',
  runSubAgentDescription:
      'Ejecuta un subagente en una conversación secundaria aislada. '
      'Establece agentId en null para usar un subagente general; las llamadas '
      'anteriores pueden omitir agentId. Funciona aunque list_agents no '
      'devuelva agentes. Usa list_agents con type=sub_agent para elegir un '
      'especialista configurado.',
  generalHint: _spanishGeneralSubAgentHint,
);

/// Resolves model-facing agent guidance from a BCP-47 language tag.
///
/// Only English and Spanish are currently supported. Unknown or missing tags
/// use English to preserve existing behavior.
SubAgentGuidance subAgentGuidanceForLanguageCode(String? languageCode) {
  final language = languageCode
      ?.trim()
      .toLowerCase()
      .split(RegExp('[-_]'))
      .first;
  return language == 'es' ? _spanishSubAgentGuidance : _englishSubAgentGuidance;
}

String agentsSkillContentForLanguageCode(String? languageCode) =>
    subAgentGuidanceForLanguageCode(languageCode).agentsSkillContent;

String generalSubAgentHintForLanguageCode(String? languageCode) =>
    subAgentGuidanceForLanguageCode(languageCode).generalHint;

ToolSpec listAgentsToolSpecForLanguageCode(String? languageCode) {
  final description = subAgentGuidanceForLanguageCode(languageCode)
      .listAgentsDescription;
  if (description == listAgentsToolSpec.description) return listAgentsToolSpec;
  return ToolSpec(
    name: listAgentsToolSpec.name,
    description: description,
    inputJsonSchema: Map<String, Object?>.from(
      listAgentsToolSpec.inputJsonSchema,
    ),
    requiresCredential: listAgentsToolSpec.requiresCredential,
  );
}

ToolSpec runSubAgentToolSpecForLanguageCode(String? languageCode) {
  final description = subAgentGuidanceForLanguageCode(languageCode)
      .runSubAgentDescription;
  if (description == runSubAgentToolSpec.description) {
    return runSubAgentToolSpec;
  }
  return ToolSpec(
    name: runSubAgentToolSpec.name,
    description: description,
    inputJsonSchema: Map<String, Object?>.from(
      runSubAgentToolSpec.inputJsonSchema,
    ),
    requiresCredential: runSubAgentToolSpec.requiresCredential,
  );
}

List<ToolSpec> subAgentToolSpecsForLanguageCode(String? languageCode) =>
    List<ToolSpec>.unmodifiable([
      listAgentsToolSpecForLanguageCode(languageCode),
      runSubAgentToolSpecForLanguageCode(languageCode),
    ]);

const _listAgentsDescription =
    'List enabled configured agents. General sub-agents are not listed; '
    'an empty list still allows run_sub_agent without agentId. Returns '
    'id, name, description, supported types, nextCursor, and a usage hint. '
    'Reuse the same query and type with nextCursor.';
const _runSubAgentDescription =
    'Run a sub-agent in an isolated child conversation. Set agentId to null '
    'to run a general sub-agent; older calls may omit agentId. '
    'This works when list_agents returns no agents. '
    'Use list_agents with type=sub_agent to choose a configured specialist.';

final listAgentsToolSpec = ToolSpec(
  name: listAgentsToolName,
  description: _listAgentsDescription,
  inputJsonSchema: {
    'type': 'object',
    'properties': {
      'query': {
        'type': ['string', 'null'],
        'maxLength': 200,
        'description': 'Optional name or description search.',
      },
      'type': {
        'type': ['string', 'null'],
        'enum': ['main', 'sub_agent', null],
        'description': 'Optional agent type filter.',
      },
      'limit': {
        'type': ['integer', 'null'],
        'minimum': 1,
        'maximum': 100,
        'description': 'Results per page. Defaults to 20.',
      },
      'cursor': {
        'type': ['string', 'null'],
        'maxLength': 2048,
        'description': 'Opaque nextCursor from a previous call.',
      },
    },
    'required': ['query', 'type', 'limit', 'cursor'],
    'additionalProperties': false,
  },
);

final runSubAgentToolSpec = ToolSpec(
  name: runSubAgentToolName,
  description: _runSubAgentDescription,
  inputJsonSchema: {
    'type': 'object',
    'properties': {
      'title': {
        'type': 'string',
        'description': 'Short title for the child conversation.',
      },
      'prompt': {
        'type': 'string',
        'description': 'Task prompt for the sub-agent.',
      },
      'agentId': {
        'type': ['string', 'null'],
        'description':
            'Optional id from list_agents with type=sub_agent. Set null for '
            'a general sub-agent.',
      },
    },
    'required': ['title', 'prompt', 'agentId'],
    'additionalProperties': false,
  },
);

final List<ToolSpec> subAgentToolSpecs = .unmodifiable([
  listAgentsToolSpec,
  runSubAgentToolSpec,
]);
