import 'package:auravibes_app/domain/entities/agent_visibility.dart';

class const AgentListQuery({
  required final String workspaceId,
  final String search = '',
  final AgentListType? type,
  final AgentListStatus? status,
  final int limit = 20,
  final String? cursor,
});

enum AgentListType { chatSelector, subAgentList }

enum AgentListStatus { enabled, disabled }

class const AgentListItem({
  required final String id,
  required final String name,
  required final String description,
  required final bool isEnabled,
  required final AgentVisibility visibility,
  required final int skillCount,
});

class const AgentListPage({
  required final List<AgentListItem> agents,
  final String? nextCursor,
});
