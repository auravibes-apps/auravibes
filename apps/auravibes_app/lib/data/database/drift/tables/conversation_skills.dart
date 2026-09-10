// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
import 'package:auravibes_app/data/database/drift/tables/conversations.dart';
import 'package:auravibes_app/data/database/drift/tables/skills.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:drift/drift.dart';

@DataClassName('ConversationSkillsTable')
@TableIndex.sql('''
CREATE UNIQUE INDEX conversation_skills_workspace_skill
ON conversation_skills (conversation_id, workspace_skill_id)
WHERE workspace_skill_id IS NOT NULL
''')
@TableIndex.sql('''
CREATE UNIQUE INDEX conversation_skills_app_skill
ON conversation_skills (conversation_id, app_skill_identifier)
WHERE app_skill_identifier IS NOT NULL
''')
class ConversationSkills extends Table with TableMixin {
  late final conversationId = text().references(
    Conversations,
    #id,
    onDelete: .cascade,
  )();

  late final workspaceSkillId = text().nullable().references(
    Skills,
    #id,
    onDelete: .cascade,
  )();

  late final appSkillIdentifier = text().nullable()();

  late final isLoaded = boolean().withDefault(const Constant(true))();

  @override
  late final List<String> customConstraints = [
    'CHECK ((workspace_skill_id IS NULL) != (app_skill_identifier IS NULL))',
  ];
}
