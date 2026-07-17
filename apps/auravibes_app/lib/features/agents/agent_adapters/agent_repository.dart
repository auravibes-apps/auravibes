import 'package:auravibes_app/domain/entities/agent_entity.dart';

abstract interface class AgentRepository {
  Stream<List<AgentEntity>> watchAgentsByWorkspace(String workspaceId);
  Future<List<AgentEntity>> getAgentsByWorkspace(String workspaceId);
  Future<AgentEntity?> getAgentById(String agentId);
  Future<AgentEntity> createAgent(String workspaceId, AgentToCreate agent);
  Future<AgentEntity> updateAgent(String agentId, AgentToUpdate agent);
  Future<bool> deleteAgent(String agentId);
}
