import 'package:auravibes_engine/src/tool_spec.dart';

const agentsSkillSlug = 'agents';
const agentsSkillTitle = 'Agents';
const agentsSkillContent =
    'Use this skill to list enabled agents and filter them by type.';
const listAgentsToolName = 'list_agents';
const runSubAgentToolName = 'run_sub_agent';

final listAgentsToolSpec = ToolSpec(
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

final List<ToolSpec> subAgentToolSpecs = List.unmodifiable([
  listAgentsToolSpec,
  runSubAgentToolSpec,
]);
