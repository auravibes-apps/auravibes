import 'package:auravibes_engine/src/tool_spec.dart';

const agentsSkillSlug = 'agents';
const agentsSkillTitle = 'Agents';
const agentsSkillContent =
    'Use list_agents to find configured agents; filter by type=sub_agent '
    'when selecting a specialist. A general sub-agent needs no configured '
    'agent: call run_sub_agent with title and prompt and omit agentId. '
    'run_sub_agent is available without loading this skill.';
const listAgentsToolName = 'list_agents';
const runSubAgentToolName = 'run_sub_agent';
const generalSubAgentHint =
    'Configured agents are optional. Call run_sub_agent with title and prompt '
    'and omit agentId to run a general sub-agent, even when agents is empty.';

final listAgentsToolSpec = ToolSpec(
  name: listAgentsToolName,
  description:
      'List enabled configured agents. General sub-agents are not listed; '
      'an empty list still allows run_sub_agent without agentId. Returns '
      'id, name, description, supported types, nextCursor, and a usage hint. '
      'Reuse the same query and type with nextCursor.',
  inputJsonSchema: {
    'type': 'object',
    'properties': {
      'query': {
        'type': 'string',
        'maxLength': 200,
        'description': 'Optional name or description search.',
      },
      'type': {
        'type': 'string',
        'enum': ['main', 'sub_agent'],
        'description': 'Optional agent type filter.',
      },
      'limit': {
        'type': 'integer',
        'minimum': 1,
        'maximum': 100,
        'description': 'Results per page. Defaults to 20.',
      },
      'cursor': {
        'type': 'string',
        'maxLength': 2048,
        'description': 'Opaque nextCursor from a previous call.',
      },
    },
    'required': <String>[],
    'additionalProperties': false,
  },
);

final runSubAgentToolSpec = ToolSpec(
  name: runSubAgentToolName,
  description:
      'Run a sub-agent in an isolated child conversation. Omit agentId to run '
      'a general sub-agent, including when list_agents returns no agents. '
      'Use list_agents with type=sub_agent to choose a configured specialist.',
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
        'description':
            'Optional id from list_agents with type=sub_agent. Omit for a '
            'general sub-agent.',
      },
    },
    'required': ['title', 'prompt'],
    'additionalProperties': false,
  },
);

final List<ToolSpec> subAgentToolSpecs = .unmodifiable([
  listAgentsToolSpec,
  runSubAgentToolSpec,
]);
