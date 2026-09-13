import 'package:auravibes_engine/src/tool_spec.dart';

const agentsSkillSlug = 'agents';
const agentsSkillTitle = 'Agents';
const agentsSkillContent =
    'Use this skill to search enabled agents and page through results.';
const listAgentsToolName = 'list_agents';
const runSubAgentToolName = 'run_sub_agent';

final listAgentsToolSpec = ToolSpec(
  name: listAgentsToolName,
  description:
      'List enabled agents. Returns id, name, description, supported types, '
      'and nextCursor. Reuse the same query and type with nextCursor.',
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

final List<ToolSpec> subAgentToolSpecs = .unmodifiable([
  listAgentsToolSpec,
  runSubAgentToolSpec,
]);
