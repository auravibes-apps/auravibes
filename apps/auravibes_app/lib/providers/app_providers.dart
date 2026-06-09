// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_providers.g.dart';

@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(Ref _) =>
    SharedPreferences.getInstance();

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref _) {
  const dbPrefix = String.fromEnvironment('DB_PREFIX');

  return AppDatabase(
    dbPrefix: dbPrefix.isNotEmpty ? dbPrefix : null,
  );
}
