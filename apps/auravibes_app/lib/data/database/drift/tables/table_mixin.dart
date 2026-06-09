// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime
// (see api_models.dart).
import 'package:drift/drift.dart';
import 'package:uuid/v7.dart';

mixin TableMixin on Table {
  ///Primary key column as string
  TextColumn get id => text().clientDefault(
    () => const UuidV7().generate(),
  )();

  /// when was created timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(
    currentDateAndTime,
  )();

  /// when was last updated timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(
    currentDateAndTime,
  )();
}
