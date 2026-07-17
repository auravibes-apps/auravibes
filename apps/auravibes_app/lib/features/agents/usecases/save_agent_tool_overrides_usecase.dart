import 'package:auravibes_app/data/repositories/agent_tools_repository.dart';
import 'package:auravibes_app/domain/entities/agent_tool_entity.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

class SaveAgentToolOverridesUsecase {
  const SaveAgentToolOverridesUsecase(this._repository);

  final AgentToolsRepositoryContract _repository;

  Future<void> call({
    required String agentId,
    required Map<String, AgentToolPermissionMode> permissionsByToolId,
  }) async {
    final existing = await _repository.getAgentTools(agentId);
    for (final override in existing) {
      if (permissionsByToolId.containsKey(override.toolId)) continue;

      final _ = await _repository.clearAgentToolPermission(
        agentId,
        override.toolId,
      );
    }

    for (final entry in permissionsByToolId.entries) {
      final permission = entry.value.overridePermission;
      if (permission == null) {
        final _ = await _repository.clearAgentToolPermission(
          agentId,
          entry.key,
        );
        continue;
      }

      final _ = await _repository.setAgentToolPermission(
        agentId,
        entry.key,
        permissionMode: permission,
      );
    }
  }
}

@Dependencies([agentToolsRepository])
final saveAgentToolOverridesUsecaseProvider =
    Provider<SaveAgentToolOverridesUsecase>(
      (ref) {
        return SaveAgentToolOverridesUsecase(
          ref.watch(agentToolsRepositoryProvider),
        );
      },
      dependencies: [agentToolsRepositoryProvider],
    );
