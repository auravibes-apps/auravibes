// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

QueryExecutor _testConnection() {
  return DatabaseConnection.delayed(
    Future(
      () => DatabaseConnection(
        LazyDatabase(() async => NativeDatabase.memory()),
      ),
    ),
  );
}

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  group('sharedPreferencesProvider', () {
    test('returns SharedPreferences instance', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final prefs = await container.read(sharedPreferencesProvider.future);
      expect(prefs, isA<SharedPreferences>());
    });

    test('returns same instance on subsequent reads (keepAlive)', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final first = await container.read(sharedPreferencesProvider.future);
      final second = await container.read(sharedPreferencesProvider.future);
      expect(identical(first, second), isTrue);
    });

    test('can read and write values', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final prefs = await container.read(sharedPreferencesProvider.future);
      final _ = await prefs.setString('test_key', 'test_value');
      expect(prefs.getString('test_key'), 'test_value');
    });

    test('sync read returns AsyncData', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final _ = await container.read(sharedPreferencesProvider.future);
      final syncValue = container.read(sharedPreferencesProvider);
      expect(syncValue, isA<AsyncData<SharedPreferences>>());
    });
  });

  group('appDatabaseProvider', () {
    test('returns an AppDatabase instance', () {
      final db = AppDatabase(connection: _testConnection());
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() {
        container.dispose();
        db.close();
      });

      final result = container.read(appDatabaseProvider);
      expect(result, isA<AppDatabase>());
    });

    test('returns same instance on subsequent reads (keepAlive)', () {
      final db = AppDatabase(connection: _testConnection());
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() {
        container.dispose();
        db.close();
      });

      final first = container.read(appDatabaseProvider);
      final second = container.read(appDatabaseProvider);
      expect(identical(first, second), isTrue);
    });

    test('overridden database has correct schema version', () {
      final db = AppDatabase(connection: _testConnection());
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() {
        container.dispose();
        db.close();
      });

      final result = container.read(appDatabaseProvider);
      expect(result.schemaVersion, 7);
    });

    test('overridden database has all DAOs accessible', () {
      final db = AppDatabase(connection: _testConnection());
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() {
        container.dispose();
        db.close();
      });

      final result = container.read(appDatabaseProvider);
      expect(result.workspaceDao, isNotNull);
      expect(result.messageDao, isNotNull);
      expect(result.conversationDao, isNotNull);
    });
  });
}
