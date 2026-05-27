// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';

enum ModelProvidersTableType {
  openai('openai'),
  anthropic('anthropic');

  /// Creates a new CredentialsModelType with the given string value
  const ModelProvidersTableType(this.value);

  /// Creates a CredentialsModelType from a string value
  ///
  /// Throws [ArgumentError] if the value is not a valid chat model type
  static ModelProvidersTableType? fromString(String value) {
    final lowerValue = value.toLowerCase();
    return values.firstWhereOrNull(
      (element) => element.value == lowerValue,
    );
  }

  final String value;

  @override
  String toString() => value;
}

/// Table definition for chat models in the database.
@DataClassName('ApiModelProvidersTable')
class ApiModelProviders extends Table {
  // model id
  TextColumn get id => text()();

  /// Human-readable name of the model
  TextColumn get name => text()();

  /// Type of chat model (local or remote)
  /// Stored as string to handle enum conversion
  TextColumn get type => textEnum<ModelProvidersTableType>().nullable()();

  TextColumn get url => text().nullable()();

  TextColumn get doc => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
