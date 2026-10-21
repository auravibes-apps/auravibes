import 'package:auravibes_app/data/database/drift/app_database.dart';

Future<void> clearAppDatabase(AppDatabase database) async {
  await database.customStatement('PRAGMA foreign_keys = OFF');
  try {
    for (final table in database.allTables) {
      final tableName = table.actualTableName.replaceAll('"', '""');
      await database.customStatement('DELETE FROM "$tableName"');
    }
  } finally {
    await database.customStatement('PRAGMA foreign_keys = ON');
  }
}
