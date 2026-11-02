import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/tools.dart';
import 'package:auravibes_app/data/repositories/mcp_servers_repository.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

import 'mcp_catalog_test_support.dart';

void main() {
  test(
    'identical catalog leaves every stored field and timestamp unchanged',
    () async {
      final fixture = McpCatalogFixture.memory();
      addTearDown(fixture.close);
      await fixture.seed(3);
      final before = await fixture.rows();
      fixture.metrics.reset();

      await fixture.refresh([
        for (var i = 0; i < 3; i++) McpCatalogFixture.tool(i),
      ]);

      expect(fixture.metrics.mutationRows, 0);
      expect(fixture.metrics.batchCalls, 0);
      expect(await fixture.rows(), before);
    },
  );

  for (final field in ['input', 'output', 'clear output']) {
    test('$field schema alone updates once then becomes a no-op', () async {
      final fixture = McpCatalogFixture.memory();
      addTearDown(fixture.close);
      await fixture.seed(1);
      final before = (await fixture.rows()).single;
      final original = McpCatalogFixture.tool(0);
      final revised = McpCatalogFixture.tool(0, version: 1);
      final changed = switch (field) {
        'input' => original.copyWith(inputSchema: revised.inputSchema),
        'output' => original.copyWith(outputSchema: revised.outputSchema),
        'clear output' => original.copyWith(outputSchema: null),
        _ => throw StateError('Unknown schema field'),
      };
      fixture.metrics.reset();

      await fixture.refresh([changed]);

      expect(fixture.metrics.updateRows, 1);
      expect(fixture.metrics.mutationRows, 1);
      final after = (await fixture.rows()).single;
      expect(
        after,
        before.copyWith(
          inputSchema: .new(jsonEncode(changed.inputSchema)),
          outputSchema: .new(
            changed.outputSchema == null
                ? null
                : jsonEncode(changed.outputSchema),
          ),
          updatedAt: after.updatedAt,
        ),
      );
      fixture.metrics.reset();

      await fixture.refresh([changed]);

      expect(fixture.metrics.mutationRows, 0);
      expect(fixture.metrics.updateRows, 0);
      expect((await fixture.rows()).single, after);
    });
  }

  test(
    'multiple changed tools retain IDs, permissions and configuration',
    () async {
      final fixture = McpCatalogFixture.memory();
      addTearDown(fixture.close);
      await fixture.seed(3);
      final before = await fixture.rows();
      final current = [
        for (var i = 0; i < 3; i++) McpCatalogFixture.tool(i, version: 1),
      ];
      fixture.metrics.reset();

      await fixture.refresh(current);

      expect(fixture.metrics.updateRows, 3);
      expect(fixture.metrics.mutationRows, 3);
      final after = await fixture.rows();
      for (var index = 0; index < before.length; index++) {
        expect(
          after[index],
          before[index].copyWith(
            description: .new(current[index].description),
            inputSchema: .new(jsonEncode(current[index].inputSchema)),
            outputSchema: .new(jsonEncode(current[index].outputSchema)),
            updatedAt: after[index].updatedAt,
          ),
        );
      }
    },
  );

  test(
    'mixed refresh changes metadata and membership while preserving identity',
    () async {
      final fixture = McpCatalogFixture.memory();
      addTearDown(fixture.close);
      await fixture.seed(3);
      final before = await fixture.rows();
      final serversBefore = await fixture.database
          .select(fixture.database.mcpServers)
          .get();
      final groupsBefore = await fixture.database
          .select(fixture.database.toolsGroups)
          .get();
      final changed = McpCatalogFixture.tool(
        0,
        version: 1,
      ).copyWith(outputSchema: null);
      fixture.metrics.reset();

      await fixture.refresh([
        changed,
        McpCatalogFixture.tool(1),
        McpCatalogFixture.tool(3),
      ]);

      expect(fixture.metrics.updateRows, 1);
      final after = await fixture.rows();
      expect(after.map((tool) => tool.toolId), [
        McpCatalogFixture.toolName(0),
        McpCatalogFixture.toolName(1),
        McpCatalogFixture.toolName(3),
      ]);
      final refreshedTool = after.singleWhere(
        (tool) => tool.toolId == McpCatalogFixture.toolName(0),
      );
      final originalTool = before.singleWhere(
        (tool) => tool.toolId == McpCatalogFixture.toolName(0),
      );
      expect(
        refreshedTool,
        originalTool.copyWith(
          description: .new(changed.description),
          inputSchema: .new(jsonEncode(changed.inputSchema)),
          outputSchema: const .new(null),
          updatedAt: refreshedTool.updatedAt,
        ),
      );
      expect(after[1], before[1]);
      expect(after.last.id, isNot(isIn(before.map((tool) => tool.id))));
      expect(after.last.permissions, PermissionAccess.ask);
      expect(after.last.isEnabled, isFalse);
      expect(after.last.workspaceId, McpCatalogFixture.workspaceId);
      expect(after.last.workspaceToolsGroupId, McpCatalogFixture.groupId);
      expect(
        await fixture.database.select(fixture.database.mcpServers).get(),
        serversBefore,
      );
      expect(
        await fixture.database.select(fixture.database.toolsGroups).get(),
        groupsBefore,
      );

      // A cleared output schema remains a no-op on the next identical refresh.
      fixture.metrics.reset();
      await fixture.refresh([
        changed,
        McpCatalogFixture.tool(1),
        McpCatalogFixture.tool(3),
      ]);
      expect(fixture.metrics.mutationRows, 0);
      expect(await fixture.rows(), after);
    },
  );

  test(
    'failure on second metadata update rolls back the successful prefix',
    () async {
      final fixture = McpCatalogFixture.memory();
      addTearDown(fixture.close);
      await fixture.seed(3);
      await fixture.database.customStatement('''
      CREATE TRIGGER reject_metadata BEFORE UPDATE ON tools
      WHEN OLD.id = 'catalog-row-1'
      BEGIN SELECT RAISE(ABORT, 'forced metadata failure'); END;
    ''');
      final observed = await _CatalogObserver.start(fixture);
      addTearDown(observed.close);
      final before = await fixture.rows();
      fixture.metrics.reset();

      await expectLater(
        fixture.refresh([
          for (var i = 0; i < 3; i++) McpCatalogFixture.tool(i, version: 1),
        ]),
        throwsA(
          isA<McpServersException>().having(
            (error) => error.cause,
            'database cause',
            isNotNull,
          ),
        ),
      );

      expect(fixture.metrics.updateRows, 2);
      expect(fixture.metrics.rollbacks, 1);
      expect(fixture.metrics.commits, 0);
      expect(await fixture.rows(), before);
      await observed.drain();
      expect(observed.snapshots, everyElement(equals(before)));
    },
  );

  test(
    'removal failure rolls back metadata and already inserted additions',
    () async {
      final fixture = McpCatalogFixture.memory();
      addTearDown(fixture.close);
      await fixture.seed(3);
      await fixture.database.customStatement('''
      CREATE TRIGGER reject_removal BEFORE DELETE ON tools
      WHEN OLD.id = 'catalog-row-2'
      BEGIN SELECT RAISE(ABORT, 'forced removal failure'); END;
    ''');
      final observed = await _CatalogObserver.start(fixture);
      addTearDown(observed.close);
      final before = await fixture.rows();
      fixture.metrics.reset();

      await expectLater(
        fixture.refresh([
          McpCatalogFixture.tool(0, version: 1),
          McpCatalogFixture.tool(1),
          McpCatalogFixture.tool(3),
        ]),
        throwsA(isA<McpServersException>()),
      );

      expect(fixture.metrics.updateRows, 1);
      expect(fixture.metrics.mutationRows, 3);
      expect(fixture.metrics.rollbacks, 1);
      expect(fixture.metrics.commits, 0);
      expect(await fixture.rows(), before);
      await observed.drain();
      expect(observed.snapshots, everyElement(equals(before)));
    },
  );
}

final class _CatalogObserver(final McpCatalogFixture fixture) {
  final List<List<ToolsTable>> snapshots = [];
  StreamSubscription<List<ToolsTable>>? _subscription;
  Completer<void>? _drained;

  static Future<_CatalogObserver> start(McpCatalogFixture fixture) async {
    final observer = _CatalogObserver(fixture);
    final first = Completer<void>();

    void onRows(List<ToolsTable> rows) {
      observer.snapshots.add(rows);
      if (!first.isCompleted) first.complete();
      final pending = observer._drained;
      if (pending != null && !pending.isCompleted) pending.complete();
    }

    observer._subscription =
        (fixture.database.select(fixture.database.tools)
              ..where(
                (row) =>
                    row.workspaceToolsGroupId.equals(McpCatalogFixture.groupId),
              )
              ..orderBy([(row) => OrderingTerm(expression: row.toolId)]))
            .watch()
            .listen(onRows, onError: first.completeError);
    await first.future;

    return observer;
  }

  Future<void> drain() async {
    final drained = Completer<void>();
    _drained = drained;
    // Force a committed query emission as a barrier without timing assumptions.
    fixture.database.markTablesUpdated({fixture.database.tools});
    await drained.future;
  }

  Future<void> close() async {
    await _subscription?.cancel();
  }
}
