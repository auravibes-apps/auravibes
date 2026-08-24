import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/features/agents/agent_adapters/agent_repository.dart';
import 'package:drift/drift.dart';

const _agentContentEmpty = 'Agent content cannot be empty';
const _agentDescriptionEmpty = 'Agent description cannot be empty';
const _agentDescriptionTooLong =
    'Agent description cannot exceed 512 characters';
const _agentNameEmpty = 'Agent name cannot be empty';
const _unknownAgentValidationError = 'Unknown validation error';

class AgentsRepository implements AgentRepository {
  AgentsRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<List<AgentEntity>> watchAgentsByWorkspace(String workspaceId) {
    return _database.agentsDao
        .watchAgentsByWorkspace(workspaceId)
        .asyncMap(
          _mapAgentRows,
        );
  }

  @override
  Future<List<AgentEntity>> getAgentsByWorkspace(String workspaceId) async {
    final rows = await _database.agentsDao.getAgentsByWorkspace(workspaceId);

    return _mapAgentRows(rows);
  }

  @override
  Future<AgentEntity?> getAgentById(String agentId) async {
    final row = await _database.agentsDao.getAgentById(agentId);
    if (row == null) return null;

    return _mapToAgent(row);
  }

  @override
  Future<AgentEntity> createAgent(
    String workspaceId,
    AgentToCreate agent,
  ) async {
    _validateAgentToCreate(agent);

    final created = await _database.agentsDao.createAgent(
      AgentsCompanion(
        workspaceId: Value(workspaceId),
        name: Value(agent.name.trim()),
        description: Value(agent.description.trim()),
        content: Value(agent.content.trim()),
        isEnabled: Value(agent.isEnabled),
        visibility: Value(agent.visibility.name),
      ),
      agent.skills.map(_mapSkillRefToCompanion).toList(),
    );

    return _mapToAgent(created);
  }

  @override
  Future<AgentEntity> updateAgent(String agentId, AgentToUpdate agent) async {
    _validateAgentToUpdate(agent);

    final updated = await _database.agentsDao.updateAgent(
      agentId,
      AgentsCompanion(
        updatedAt: Value(DateTime.now()),
        name: Value(agent.name.trim()),
        description: Value(agent.description.trim()),
        content: Value(agent.content.trim()),
        isEnabled: Value(agent.isEnabled),
        visibility: Value(agent.visibility.name),
      ),
      agent.skills.map(_mapSkillRefToCompanion).toList(),
    );

    return _mapToAgent(updated);
  }

  @override
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
    if (agent.description.trim().isEmpty) return _agentDescriptionEmpty;
    if (agent.description.trim().length > AgentLimits.descriptionMaxLength) {
      return _agentDescriptionTooLong;
    }
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
    if (agent.description.trim().isEmpty) return _agentDescriptionEmpty;
    if (agent.description.trim().length > AgentLimits.descriptionMaxLength) {
      return _agentDescriptionTooLong;
    }

    if (agent.content.trim().isEmpty) return _agentContentEmpty;

    return _unknownAgentValidationError;
  }

  Future<AgentEntity> _mapToAgent(AgentsTable table) async {
    final skills = await _database.agentsDao.getAgentSkills(table.id);

    return _mapAgentRow(table, skills);
  }

  Future<List<AgentEntity>> _mapAgentRows(List<AgentsTable> rows) async {
    final skills = await _database.agentsDao.getSkillsForAgents(
      rows.map((row) => row.id),
    );
    final skillsByAgentId = <String, List<AgentSkillsTable>>{};
    for (final skill in skills) {
      skillsByAgentId.putIfAbsent(skill.agentId, () => []).add(skill);
    }

    return [
      for (final row in rows) _mapAgentRow(row, skillsByAgentId[row.id] ?? []),
    ];
  }

  AgentEntity _mapAgentRow(
    AgentsTable table,
    List<AgentSkillsTable> skills,
  ) {
    return AgentEntity(
      id: table.id,
      workspaceId: table.workspaceId,
      name: table.name,
      content: table.content,
      skills: skills.map(_mapSkillRef).toList(),
      createdAt: table.createdAt,
      updatedAt: table.updatedAt,
      description: table.description,
      isEnabled: table.isEnabled,
      visibility: _agentVisibilityFromStorage(table.visibility),
    );
  }

  AgentSkillRef _mapSkillRef(AgentSkillsTable table) {
    final workspaceSkillId = table.workspaceSkillId;
    if (workspaceSkillId != null) return AgentSkillRef.user(workspaceSkillId);

    final appSkillIdentifier = table.appSkillIdentifier;
    if (appSkillIdentifier == null) throw StateError('Agent skill is invalid');

    return AgentSkillRef.app(appSkillIdentifier);
  }

  AgentVisibility _agentVisibilityFromStorage(String value) {
    return AgentVisibility.values.asNameMap()[value] ?? AgentVisibility.both;
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
