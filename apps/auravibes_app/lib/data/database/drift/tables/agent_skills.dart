// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
import 'package:auravibes_app/data/database/drift/tables/agents.dart';
import 'package:auravibes_app/data/database/drift/tables/skills.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:drift/drift.dart';

@DataClassName('AgentSkillsTable')
@TableIndex.sql('''
CREATE UNIQUE INDEX agent_skills_workspace_skill
ON agent_skills (agent_id, workspace_skill_id)
WHERE workspace_skill_id IS NOT NULL
''')
@TableIndex.sql('''
CREATE UNIQUE INDEX agent_skills_app_skill
ON agent_skills (agent_id, app_skill_identifier)
WHERE app_skill_identifier IS NOT NULL
''')
class AgentSkills extends Table with TableMixin {
  late final agentId = text().references(Agents, #id, onDelete: .cascade)();

  late final workspaceSkillId = text().nullable().references(
    Skills,
    #id,
    onDelete: .cascade,
  )();

  late final appSkillIdentifier = text().nullable()();

  @override
  late final List<String> customConstraints = [
    'CHECK ((workspace_skill_id IS NULL) != (app_skill_identifier IS NULL))',
  ];
}
