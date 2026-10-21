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
  description:
      'Run a sub-agent in an isolated child conversation. Set agentId to null '
      'to run a general sub-agent; older calls may omit agentId. '
      'This works when list_agents returns no agents. '
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
