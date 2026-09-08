// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
import 'package:auravibes_app/data/database/drift/tables/messages.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:drift/drift.dart';

@DataClassName('MessageAttachmentsTable')
class MessageAttachments extends Table with TableMixin {
  TextColumn get messageId =>
      text().references(Messages, #id, onDelete: KeyAction.cascade)();
  TextColumn get localPath => text()();
  TextColumn get fileName => text()();
  TextColumn get displayName => text().withDefault(const Constant(''))();
  TextColumn get mimeType => text()();
  TextColumn get modality => text()();
  IntColumn get sizeBytes => integer()();
}
