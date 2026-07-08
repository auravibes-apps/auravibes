const agentsSkillSlug = 'agents';
const listAgentsToolName = 'list_agents';
const runSubAgentToolName = 'run_sub_agent';

const listAgentsToolSpec = SubAgentToolSpec(
  name: listAgentsToolName,
  description:
      'List enabled agents. Returns id, name, description, and supported '
      'types for each agent. Use type to filter by main or sub_agent.',
  inputJsonSchema: {
    'type': 'object',
    'properties': {
      'type': {
        'type': 'string',
        'enum': ['main', 'sub_agent'],
        'description': 'Optional agent type filter.',
      },
    },
    'required': <String>[],
    'additionalProperties': false,
  },
);

const runSubAgentToolSpec = SubAgentToolSpec(
  name: runSubAgentToolName,
  description:
      'Run a sub-agent in an isolated child conversation. Use an agentId '
      'from list_agents when a specialist is appropriate.',
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
        'type': 'string',
        'description': 'Optional agent id from list_agents.',
      },
    },
    'required': ['title', 'prompt'],
    'additionalProperties': false,
  },
);

const List<SubAgentToolSpec> subAgentToolSpecs = [
  listAgentsToolSpec,
  runSubAgentToolSpec,
];

class SubAgentToolSpec {
  const SubAgentToolSpec({
    required this.name,
    required this.description,
    required this.inputJsonSchema,
  });

  final String name;
  final String description;
  final Map<String, Object?> inputJsonSchema;
}
