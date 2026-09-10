// ignore_for_file: implementation_imports
import 'package:auravibes_app/data/repositories/agent_tools_repository.dart';
import 'package:auravibes_app/domain/entities/agent_tool_override_entity.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:riverpod/src/providers/provider.dart';

class const SaveAgentToolOverridesUsecase(
  final AgentToolsRepositoryContract _repository,
) {
  Future<void> call({
    required String agentId,
    required Map<String, AgentToolPermissionMode> permissionsByToolId,
  }) async {
    final existing = await _repository.getAgentTools(agentId);
    await _clearRemoved(agentId, permissionsByToolId, existing);
    await _savePermissions(agentId, permissionsByToolId);
  }

  Future<void> _clearRemoved(
    String agentId,
    Map<String, AgentToolPermissionMode> permissionsByToolId,
    List<AgentToolOverrideEntity> existing,
  ) async {
    for (final override in existing) {
      if (permissionsByToolId.containsKey(override.toolId)) continue;

      final _ = await _repository.clearAgentToolPermission(
        agentId,
        override.toolId,
      );
    }
  }

  Future<void> _savePermissions(
    String agentId,
    Map<String, AgentToolPermissionMode> permissionsByToolId,
  ) async {
    for (final entry in permissionsByToolId.entries) {
      await _savePermission(agentId, entry);
    }
  }

  Future<void> _savePermission(
    String agentId,
    MapEntry<String, AgentToolPermissionMode> entry,
  ) async {
    final permission = entry.value.overridePermission;
    if (permission == null) {
      final _ = await _repository.clearAgentToolPermission(agentId, entry.key);
      return;
    }

    final _ = await _repository.setAgentToolPermission(
      agentId,
      entry.key,
      permissionMode: permission,
    );
  }
}

final ProviderFamily<SaveAgentToolOverridesUsecase, String>
saveAgentToolOverridesUsecaseProvider =
    Provider.family<SaveAgentToolOverridesUsecase, String>((ref, workspaceId) {
      return SaveAgentToolOverridesUsecase(
        ref.watch(agentToolsRepositoryProvider(workspaceId)),
      );
    });
