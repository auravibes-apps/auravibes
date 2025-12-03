import 'package:auravibes_app/data/database/drift/custom_types/permissions.dart';
import 'package:drift/drift.dart';

JsonTypeConverter2<PermissionsType, String, Object?> permissionsConverter =
    TypeConverter.json2(
      fromJson: (json) =>
          PermissionsType.fromJson(json! as Map<String, dynamic>),
      toJson: (column) => column.toJson(),
    );
