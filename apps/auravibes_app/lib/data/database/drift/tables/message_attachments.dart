// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
import 'package:auravibes_app/data/database/drift/tables/messages.dart';
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:drift/drift.dart';

@DataClassName('MessageAttachmentsTable')
class MessageAttachments extends Table with TableMixin {
  late final messageId = text().references(Messages, #id, onDelete: .cascade)();
  late final localPath = text()();
  late final fileName = text()();
  late final displayName = text().withDefault(const Constant(''))();
  late final mimeType = text()();
  late final modality = text()();
  late final sizeBytes = integer()();
}
