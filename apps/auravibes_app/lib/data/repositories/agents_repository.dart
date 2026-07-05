import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:drift/drift.dart';

const _agentContentEmpty = 'Agent content cannot be empty';
const _agentNameEmpty = 'Agent name cannot be empty';
const _unknownAgentValidationError = 'Unknown validation error';

class AgentsRepository {
  AgentsRepository(this._database);

  final AppDatabase _database;

  Stream<List<AgentEntity>> watchAgentsByWorkspace(String workspaceId) {
    return _database.agentsDao
        .watchAgentsByWorkspace(workspaceId)
        .asyncMap(
          (rows) => Future.wait(rows.map(_mapToAgent)),
        );
  }

  Future<AgentEntity?> getAgentById(String agentId) async {
    final row = await _database.agentsDao.getAgentById(agentId);
    if (row == null) return null;

    return _mapToAgent(row);
  }

  Future<AgentEntity> createAgent(
    String workspaceId,
    AgentToCreate agent,
  ) async {
    _validateAgentToCreate(agent);

    final created = await _database.agentsDao.createAgent(
      AgentsCompanion(
        workspaceId: Value(workspaceId),
        name: Value(agent.name.trim()),
        content: Value(agent.content.trim()),
      ),
      agent.skills.map(_mapSkillRefToCompanion).toList(),
    );

    return _mapToAgent(created);
  }

  Future<AgentEntity> updateAgent(String agentId, AgentToUpdate agent) async {
    _validateAgentToUpdate(agent);

    final updated = await _database.agentsDao.updateAgent(
      agentId,
      AgentsCompanion(
        updatedAt: Value(DateTime.now()),
        name: Value(agent.name.trim()),
        content: Value(agent.content.trim()),
      ),
      agent.skills.map(_mapSkillRefToCompanion).toList(),
    );

    return _mapToAgent(updated);
  }

  Future<bool> deleteAgent(String agentId) => _database.agentsDao.deleteAgent(
    agentId,
  );

  void _validateAgentToCreate(AgentToCreate agent) {
    if (!agent.isValid) {
      throw AgentValidationException(_agentCreateValidationMessage(agent));
    }
  }

  String _agentCreateValidationMessage(AgentToCreate agent) {
    if (agent.name.trim().isEmpty) return _agentNameEmpty;
    if (agent.content.trim().isEmpty) return _agentContentEmpty;

    return _unknownAgentValidationError;
  }

  void _validateAgentToUpdate(AgentToUpdate agent) {
    if (!agent.isValid) {
      throw AgentValidationException(_agentUpdateValidationMessage(agent));
    }
  }

  String _agentUpdateValidationMessage(AgentToUpdate agent) {
    if (agent.name.trim().isEmpty) return _agentNameEmpty;

    if (agent.content.trim().isEmpty) return _agentContentEmpty;

    return _unknownAgentValidationError;
  }

  Future<AgentEntity> _mapToAgent(AgentsTable table) async {
    final skills = await _database.agentsDao.getAgentSkills(table.id);

    return AgentEntity(
      id: table.id,
      workspaceId: table.workspaceId,
      name: table.name,
      content: table.content,
      skills: skills.map(_mapSkillRef).toList(),
      createdAt: table.createdAt,
      updatedAt: table.updatedAt,
    );
  }

  AgentSkillRef _mapSkillRef(AgentSkillsTable table) {
    final workspaceSkillId = table.workspaceSkillId;
    if (workspaceSkillId != null) return AgentSkillRef.user(workspaceSkillId);

    final appSkillIdentifier = table.appSkillIdentifier;
    if (appSkillIdentifier == null) throw StateError('Agent skill is invalid');

    return AgentSkillRef.app(appSkillIdentifier);
  }

  AgentSkillsCompanion _mapSkillRefToCompanion(AgentSkillRef ref) {
    return switch (ref) {
      UserAgentSkillRef(:final skillId) => AgentSkillsCompanion(
        workspaceSkillId: Value(skillId),
      ),
      AppAgentSkillRef(:final identifier) => AgentSkillsCompanion(
        appSkillIdentifier: Value(identifier),
      ),
    };
  }
}

class AgentException implements Exception {
  const AgentException(this.message, [this.cause]);

  final String message;
  final Exception? cause;

  @override
  String toString() {
    final causedBy = ' (Caused by: $cause)';

    return 'AgentException: $message${cause != null ? causedBy : ''}';
  }
}

class AgentValidationException extends AgentException {
  const AgentValidationException(super.message, [super.cause]);
}
