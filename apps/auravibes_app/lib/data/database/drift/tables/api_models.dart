// coverage:ignore-file
// Required: Drift table DSL methods (text(), real(), boolean(), integer(.))
// Call _isGenerated() which throws at runtime. The generated subclass.
// Overrides every column getter with late final GeneratedColumn fields, and.
// TableInfo mixin overrides primaryKey. No code here executes at runtime.
import 'package:auravibes_app/data/database/drift/converters/list_converter.dart';
import 'package:auravibes_app/data/database/drift/tables/model_providers_table_type.dart';
import 'package:drift/drift.dart';

export 'package:auravibes_app/data/database/drift/converters/list_converter.dart';

/// Table definition for chat models in the database.
@DataClassName('ApiModelsTable')
class ApiModels extends Table {
  TextColumn get modelProvider => text().references(ApiModelProviders, #id)();

  // Model id.
  TextColumn get id => text()();

  /// Human-readable name of the model.
  TextColumn get name => text()();

  /// Type of chat model (local or remote).
  /// Stored as string to handle enum conversion

  TextColumn get modalitiesInput =>
      text().map(stringListConverter).nullable()();
  TextColumn get modalitiesOuput =>
      text().map(stringListConverter).nullable()();

  BoolColumn get openWeights => boolean().nullable()();

  BoolColumn get supportsReasoning =>
      boolean().withDefault(const Constant(false))();

  // Cost.
  RealColumn get costInput => real().nullable()();
  RealColumn get costOutput => real().nullable()();
  RealColumn get costCacheRead => real().nullable()();

  IntColumn get limitContext => integer()();

  IntColumn get limitOutput => integer()();

  @override
  Set<Column> get primaryKey => {id, modelProvider};
}
