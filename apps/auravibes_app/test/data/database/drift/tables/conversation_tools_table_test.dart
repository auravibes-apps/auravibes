// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

QueryExecutor _testConnection() {
  return DatabaseConnection.delayed(
    Future(() {
      return DatabaseConnection(
        LazyDatabase(() async {
          return NativeDatabase.memory();
        }),
      );
    }),
  );
}

void main() {
  group('ConversationTools schema', () {
    late AppDatabase db;
    late List<QueryRow> columns;

    setUp(() async {
      db = AppDatabase(connection: _testConnection());
      columns = await db
          .customSelect(
            'PRAGMA table_info(conversation_tools)',
          )
          .get();
    });

    tearDown(() async => db.close());

    test('has expected columns', () {
      final names = columns.map((r) => r.read<String>('name')).toSet();
      expect(
        names,
        containsAll([
          'id',
          'created_at',
          'updated_at',
          'conversation_id',
          'tool_id',
          'is_enabled',
          'permissions',
        ]),
      );
    });

    test('has 7 columns', () {
      expect(columns.length, 7);
    });

    test('composite primary key on conversation_id and tool_id', () {
      final convCol = columns.firstWhere(
        (r) => r.read<String>('name') == 'conversation_id',
      );
      final toolCol = columns.firstWhere(
        (r) => r.read<String>('name') == 'tool_id',
      );
      expect(convCol.read<int>('pk'), greaterThan(0));
      expect(toolCol.read<int>('pk'), greaterThan(0));
    });

    test('is_enabled has default', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'is_enabled',
      );
      expect(col.read<String?>('dflt_value'), isNotNull);
    });

    test('permissions has default', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'permissions',
      );
      expect(col.read<String?>('dflt_value'), isNotNull);
    });
  });

  group('ConversationTools column accessors', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(connection: _testConnection());
    });

    tearDown(() async => db.close());

    test('all column getters are accessible', () {
      final table = db.conversationTools;
      expect(table.conversationId, isNotNull);
      expect(table.toolId, isNotNull);
      expect(table.isEnabled, isNotNull);
      expect(table.permissions, isNotNull);
    });

    test('primaryKey contains conversation_id and tool_id', () {
      final table = db.conversationTools;
      expect(table.primaryKey.length, 2);
      expect(table.primaryKey, contains(table.conversationId));
      expect(table.primaryKey, contains(table.toolId));
    });

    test('column names match expected snake_case', () {
      final table = db.conversationTools;
      expect(table.conversationId.name, 'conversation_id');
      expect(table.toolId.name, 'tool_id');
      expect(table.isEnabled.name, 'is_enabled');
      expect(table.permissions.name, 'permissions');
    });

    test(r'$columns returns all columns including TableMixin', () {
      final table = db.conversationTools;
      expect(table.$columns.length, 7);
    });

    test('table name is conversation_tools', () {
      expect(db.conversationTools.actualTableName, 'conversation_tools');
    });

    test('aliasedName returns actualTableName without alias', () {
      expect(db.conversationTools.aliasedName, 'conversation_tools');
    });

    test('createAlias returns new table with alias', () {
      final aliased = db.conversationTools.createAlias('ca');
      expect(aliased.aliasedName, 'ca');
    });
  });
}
