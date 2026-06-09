
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/messages.dart';
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

final class _DatabaseFixture {
  _DatabaseFixture(this.createConnection);

  final QueryExecutor Function() createConnection;
  AppDatabase? _database;

  AppDatabase get database =>
      _database ?? fail('Database fixture not initialized');

  void reset() {
    _database = AppDatabase(connection: createConnection());
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

void main() {
  group('MessagesTableType', () {
    test('text value', () {
      expect(MessagesTableType.text.value, 'text');
    });

    test('image value', () {
      expect(MessagesTableType.image.value, 'image');
    });

    test('toolCall value', () {
      expect(MessagesTableType.toolCall.value, 'tool_call');
    });

    test('system value', () {
      expect(MessagesTableType.system.value, 'system');
    });
  });

  group('MessageTableStatus', () {
    test('fromString returns sending', () {
      expect(
        MessageTableStatus.fromString('sending'),
        MessageTableStatus.sending,
      );
    });

    test('fromString returns sent', () {
      expect(
        MessageTableStatus.fromString('sent'),
        MessageTableStatus.sent,
      );
    });

    test('fromString returns unfinished', () {
      expect(
        MessageTableStatus.fromString('unfinished'),
        MessageTableStatus.unfinished,
      );
    });

    test('fromString returns error', () {
      expect(
        MessageTableStatus.fromString('error'),
        MessageTableStatus.error,
      );
    });

    test('fromString is case insensitive', () {
      expect(
        MessageTableStatus.fromString('SENT'),
        MessageTableStatus.sent,
      );
    });

    test('fromString throws on invalid', () {
      expect(
        () => MessageTableStatus.fromString('invalid'),
        throwsArgumentError,
      );
    });

    test('sending value', () {
      expect(MessageTableStatus.sending.value, 'sending');
    });

    test('sent value', () {
      expect(MessageTableStatus.sent.value, 'sent');
    });

    test('unfinished value', () {
      expect(MessageTableStatus.unfinished.value, 'unfinished');
    });

    test('error value', () {
      expect(MessageTableStatus.error.value, 'error');
    });
  });

  group('Messages schema', () {
    final fixture = _DatabaseFixture(_testConnection);
    var columns = <QueryRow>[];

    setUp(() async {
      fixture.reset();
      columns = await fixture.database
          .customSelect(
            'PRAGMA table_info(messages)',
          )
          .get();
    });

    tearDown(fixture.close);

    test('has expected columns', () {
      final names = columns.map((r) => r.read<String>('name')).toSet();
      expect(
        names,
        containsAll([
          'id',
          'created_at',
          'updated_at',
          'conversation_id',
          'content',
          'message_type',
          'is_user',
          'status',
          'metadata',
        ]),
      );
    });

    test('has 9 columns', () {
      expect(columns.length, 9);
    });

    test('conversation_id is not null', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'conversation_id',
      );
      expect(col.read<int>('notnull'), 1);
    });

    test('content is not null', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'content',
      );
      expect(col.read<int>('notnull'), 1);
    });

    test('is_user is not null', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'is_user',
      );
      expect(col.read<int>('notnull'), 1);
    });

    test('status is not null', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'status',
      );
      expect(col.read<int>('notnull'), 1);
    });

    test('metadata is nullable', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'metadata',
      );
      expect(col.read<int>('notnull'), 0);
    });
  });

  group('Messages column accessors', () {
    final fixture = _DatabaseFixture(_testConnection);

    setUp(fixture.reset);

    tearDown(fixture.close);

    test('all column getters are accessible', () {
      final table = fixture.database.messages;
      expect(table.conversationId, isNotNull);
      expect(table.content, isNotNull);
      expect(table.messageType, isNotNull);
      expect(table.isUser, isNotNull);
      expect(table.status, isNotNull);
      expect(table.metadata, isNotNull);
    });

    test('column names match expected snake_case', () {
      final table = fixture.database.messages;
      expect(table.conversationId.name, 'conversation_id');
      expect(table.content.name, 'content');
      expect(table.messageType.name, 'message_type');
      expect(table.isUser.name, 'is_user');
      expect(table.status.name, 'status');
      expect(table.metadata.name, 'metadata');
    });

    test(r'$columns returns all columns including TableMixin', () {
      final table = fixture.database.messages;
      expect(table.$columns.length, 9);
    });

    test('table name is messages', () {
      expect(fixture.database.messages.actualTableName, 'messages');
    });

    test('aliasedName returns actualTableName without alias', () {
      expect(fixture.database.messages.aliasedName, 'messages');
    });

    test('createAlias returns new table with alias', () {
      final aliased = fixture.database.messages.createAlias('ma');
      expect(aliased.aliasedName, 'ma');
    });
  });
}
