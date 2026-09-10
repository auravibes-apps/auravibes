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
  late final modelProvider = text().references(
    ApiModelProviders,
    #id,
    onDelete: .cascade,
  )();

  // Model id.
  late final id = text()();

  /// Human-readable name of the model.
  late final name = text()();

  late final family = text().nullable()();

  /// Type of chat model (local or remote). Stored as a string to handle enum
  /// conversion.

  late final modalitiesInput = text().map(stringListConverter).nullable()();
  late final modalitiesOutput = text().map(stringListConverter).nullable()();

  late final openWeights = boolean().nullable()();

  late final supportsReasoning = boolean().withDefault(const Constant(false))();

  late final isCanonical = boolean().withDefault(const Constant(true))();

  late final supportsPriorityMode = boolean().withDefault(
    const Constant(false),
  )();

  late final supportsToolCalls = boolean().withDefault(const Constant(false))();

  // Cost.
  late final costInput = real().nullable()();
  late final costOutput = real().nullable()();
  late final costCacheRead = real().nullable()();

  late final limitContext = integer()();

  late final limitOutput = integer()();

  @override
  late final Set<Column> primaryKey = {id, modelProvider};
}
