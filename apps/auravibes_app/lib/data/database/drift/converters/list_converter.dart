// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.
import 'package:drift/drift.dart';

final JsonTypeConverter2<List<String>, String, Object?> stringListConverter =
    TypeConverter.json2(
      fromJson: (json) => (json as List<dynamic>? ?? []).cast(),
      toJson: (column) => column,
    );
