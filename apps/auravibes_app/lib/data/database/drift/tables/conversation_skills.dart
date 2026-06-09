// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime
// (see api_models.dart).
import 'package:auravibes_app/data/database/drift/tables/conversations.dart';
import 'package:auravibes_app/data/database/drift/tables/skills.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:drift/drift.dart';

@DataClassName('ConversationSkillsTable')
class ConversationSkills extends Table with TableMixin {
  TextColumn get conversationId => text().references(
    Conversations,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get workspaceSkillId => text().nullable().references(
    Skills,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get appSkillIdentifier => text().nullable()();

  BoolColumn get isLoaded => boolean().withDefault(const Constant(true))();
}
