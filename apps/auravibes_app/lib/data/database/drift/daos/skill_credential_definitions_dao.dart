import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/skill_credential_definitions.dart';
import 'package:auravibes_app/domain/models/credential_definition_schema.dart';
import 'package:auravibes_app/domain/models/credential_definition_usage.dart';
import 'package:auravibes_app/domain/models/credential_dependency.dart';
import 'package:drift/drift.dart';

part 'skill_credential_definitions_dao.g.dart';

@DriftAccessor(tables: [SkillCredentialDefinitions])
class SkillCredentialDefinitionsDao(super.attachedDatabase)
    extends DatabaseAccessor<AppDatabase>
    with _$SkillCredentialDefinitionsDaoMixin {
  Future<List<SkillCredentialDefinitionsTable>> getDefinitions(
    String workspaceId,
  ) =>
      (select(skillCredentialDefinitions)
            ..where((tbl) => tbl.workspaceId.equals(workspaceId))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.title)]))
          .get();

  Stream<List<SkillCredentialDefinitionsTable>> watchDefinitions(
    String workspaceId,
  ) =>
      (select(skillCredentialDefinitions)
            ..where((tbl) => tbl.workspaceId.equals(workspaceId))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.title)]))
          .watch();

  Future<SkillCredentialDefinitionsTable?> getDefinitionById(
    String definitionId,
  ) => (select(
    skillCredentialDefinitions,
  )..where((tbl) => tbl.id.equals(definitionId))).getSingleOrNull();

  Future<SkillCredentialDefinitionsTable?> getDefinitionBySlug(
    String workspaceId,
    String slug,
  ) =>
      (select(skillCredentialDefinitions)..where(
            (tbl) =>
                tbl.workspaceId.equals(workspaceId) & tbl.slug.equals(slug),
          ))
          .getSingleOrNull();

  Future<SkillCredentialDefinitionsTable> createDefinition(
    SkillCredentialDefinitionsCompanion definition,
  ) => into(skillCredentialDefinitions).insertReturning(definition);

  Future<SkillCredentialDefinitionsTable> updateDefinition(
    String definitionId,
    SkillCredentialDefinitionsCompanion definition,
  ) => transaction(() async {
    final current = await getDefinitionById(definitionId);
    if (current == null) throw StateError('Credential definition not found');
    await _ensureCompatible(current, definition);

    return await _writeDefinition(definitionId, definition);
  });

  Future<bool> deleteDefinition(String definitionId) => transaction(() async {
    final current = await getDefinitionById(definitionId);
    if (current == null) return false;
    await _ensureUnreferenced(current);

    return await _deleteRows(definitionId);
  });

  Future<SkillCredentialDefinitionsTable> _writeDefinition(
    String definitionId,
    SkillCredentialDefinitionsCompanion definition,
  ) async {
    final _ = await (update(
      skillCredentialDefinitions,
    )..where((tbl) => tbl.id.equals(definitionId))).write(definition);
    final updated = await getDefinitionById(definitionId);
    if (updated == null) {
      throw StateError('Updated skill credential definition was not found');
    }

    return updated;
  }

  Future<bool> _deleteRows(String definitionId) async {
    final count = await (delete(
      skillCredentialDefinitions,
    )..where((tbl) => tbl.id.equals(definitionId))).go();

    return count > 0;
  }
}

extension CredentialDefinitionSafety on SkillCredentialDefinitionsDao {
  Future<void> _ensureCompatible(
    SkillCredentialDefinitionsTable current,
    SkillCredentialDefinitionsCompanion definition,
  ) async {
    if (!definition.attributesJson.present) return;
    final next = CredentialDefinitionSchema.validate(
      definition.attributesJson.value,
    );
    final count = await attachedDatabase.skillCredentialsDao
        .countLinkedCredentials(
          workspaceId: current.workspaceId,
          credentialDefinitionId: current.id,
        );
    CredentialDefinitionSchema.ensureCompatible(
      current.attributesJson,
      next,
      count,
    );
  }

  Future<CredentialDefinitionUsage> getUsage(
    String workspaceId,
    String definitionId,
  ) async {
    final credentials = await attachedDatabase.skillCredentialsDao
        .getLinkedCredentialSummaries(
          workspaceId: workspaceId,
          credentialDefinitionId: definitionId,
        );
    final skills = await _workspaceSkills(workspaceId);
    final tools = await _skillTools(skills);

    return CredentialDefinitionUsage(
      credentials: credentials,
      skills: _skillDependencies(skills, definitionId),
      tools: _toolDependencies(tools, skills, definitionId),
    );
  }

  Future<List<SkillsTable>> _workspaceSkills(String workspaceId) {
    final table = attachedDatabase.skills;

    return (select(
      table,
    )..where((t) => t.workspaceId.equals(workspaceId))).get();
  }

  Future<List<SkillTemplateToolsTable>> _skillTools(List<SkillsTable> skills) {
    final table = attachedDatabase.skillTemplateTools;

    return (select(
      table,
    )..where((t) => t.skillId.isIn(skills.map((s) => s.id)))).get();
  }

  List<CredentialDependency> _skillDependencies(
    List<SkillsTable> skills,
    String id,
  ) => [
    for (final skill in skills)
      if (skill.credentialDefinitionId == id)
        CredentialDependency(
          id: skill.id,
          title: skill.title,
          isEnabled: skill.isEnabled,
        ),
  ];

  List<CredentialDependency> _toolDependencies(
    List<SkillTemplateToolsTable> tools,
    List<SkillsTable> skills,
    String id,
  ) {
    final parents = {
      for (final skill in skills) skill.id: skill.credentialDefinitionId,
    };

    return tools
        .where(
          (tool) =>
              (tool.credentialDefinitionId ?? parents[tool.skillId]) == id,
        )
        .map(_toolDependency)
        .toList();
  }

  CredentialDependency _toolDependency(SkillTemplateToolsTable tool) =>
      CredentialDependency(
        id: tool.id,
        title: tool.title,
        isEnabled: tool.isEnabled,
        parentSkillId: tool.skillId,
      );
}

extension CredentialDefinitionOwnership on SkillCredentialDefinitionsDao {
  Future<void> requireOwnedReference(
    String workspaceId,
    String? definitionId,
  ) async {
    if (definitionId == null) return;
    final definition = await getDefinitionById(definitionId);
    if (definition == null || definition.workspaceId != workspaceId) {
      throw StateError('Credential definition unavailable in this workspace');
    }
  }

  Future<void> _ensureUnreferenced(
    SkillCredentialDefinitionsTable definition,
  ) async {
    final usage = await getUsage(definition.workspaceId, definition.id);
    usage.ensureCanDelete();
    await _rejectHiddenReferences(definition.id);
  }

  Future<void> _rejectHiddenReferences(String definitionId) async {
    if (await _hasSkillReference(definitionId) ||
        await _hasToolReference(definitionId) ||
        await _hasCredentialReference(definitionId)) {
      // Do not expose another workspace's counts or identifying metadata.
      throw const CredentialDefinitionConflictException(
        reason: .deletion,
        credentialCount: 0,
      );
    }
  }

  Future<bool> _hasSkillReference(String id) {
    final table = attachedDatabase.skills;

    return _hasReference(table, table.credentialDefinitionId.equals(id));
  }

  Future<bool> _hasToolReference(String id) {
    final table = attachedDatabase.skillTemplateTools;

    return _hasReference(table, table.credentialDefinitionId.equals(id));
  }

  Future<bool> _hasCredentialReference(String id) {
    final table = attachedDatabase.serviceConnections;

    return _hasReference(
      table,
      table.kind.equals('skillCredential') & table.serviceId.equals(id),
    );
  }

  Future<bool> _hasReference<T extends Table, D>(
    TableInfo<T, D> table,
    Expression<bool> filter,
  ) async {
    final query = selectOnly(table)
      ..addColumns([const Constant(1)])
      ..where(filter)
      ..limit(1);

    return (await query.get()).isNotEmpty;
  }
}
