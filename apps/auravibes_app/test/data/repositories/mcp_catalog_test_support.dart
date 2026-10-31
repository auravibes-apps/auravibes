import 'dart:convert';
import 'dart:io';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/mcp_servers.dart';
import 'package:auravibes_app/data/database/drift/tables/tools.dart';
import 'package:auravibes_app/data/repositories/mcp_servers_repository.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// Real persistence shared by refresh correctness tests and measurements.
final class McpCatalogFixture {
  McpCatalogFixture._(this.database, this.metrics, this._directory)
    : repository = McpServersRepository(database);

  factory McpCatalogFixture.memory() =>
      _connect(NativeDatabase.memory(), null);

  static McpCatalogFixture _connect(
    QueryExecutor executor,
    Directory? directory,
  ) {
    final metrics = CatalogSqlMetrics();
    final database = AppDatabase(connection: executor.interceptWith(metrics));
    return McpCatalogFixture._(database, metrics, directory);
  }

  static Future<McpCatalogFixture> backgroundFile() async {
    final directory = await Directory.systemTemp.createTemp('mcp-catalog-');
    return _connect(
      NativeDatabase.createInBackground(File('${directory.path}/catalog.db')),
      directory,
    );
  }

  static const workspaceId = 'catalog-workspace';
  static const serverId = 'catalog-server';
  static const groupId = 'catalog-group';
  static final seededAt = DateTime.utc(2026);

  final Directory? _directory;
  final CatalogSqlMetrics metrics;
  final AppDatabase database;
  final McpServersRepository repository;

  static String toolName(int index) => 'tool_${index.toString().padLeft(5, '0')}';

  static McpToolInfo tool(int index, {int version = 0}) => McpToolInfo(
    toolName: toolName(index),
    description: 'Catalog tool $index version $version',
    inputSchema: {
      'type': 'object',
      'properties': {
        'query': {'type': 'string', 'description': 'Input version $version'},
      },
    },
    outputSchema: {
      'type': 'object',
      'properties': {
        'result': {'type': 'string', 'description': 'Output version $version'},
      },
    },
  );

  Future<void> seed(int toolCount) async {
    await database.batch((batch) {
      batch
        ..insert(
          database.workspaces,
          WorkspacesCompanion.insert(
            id: const Value(workspaceId),
            name: 'Catalog measurement',
            type: .local,
          ),
        )
        ..insert(
          database.mcpServers,
          McpServersCompanion.insert(
            id: const Value(serverId),
            workspaceId: workspaceId,
            name: 'Catalog server',
            url: 'https://example.invalid/mcp',
            transport: const McpTransportTypeSSE(),
          ),
        )
        ..insert(
          database.toolsGroups,
          ToolsGroupsCompanion.insert(
            id: const Value(groupId),
            workspaceId: workspaceId,
            mcpServerId: const Value(serverId),
            name: 'Catalog group',
            permissions: .granted,
          ),
        )
        ..insertAll(database.tools, [
          for (var index = 0; index < toolCount; index++) _companion(index),
        ]);
    });
    metrics.reset();
  }

  ToolsCompanion _companion(int index) {
    final metadata = tool(index);
    return ToolsCompanion.insert(
      id: Value('catalog-row-$index'),
      createdAt: Value(seededAt),
      updatedAt: Value(seededAt),
      workspaceId: workspaceId,
      workspaceToolsGroupId: const Value(groupId),
      toolId: metadata.toolName,
      description: Value(metadata.description),
      inputSchema: Value(jsonEncode(metadata.inputSchema)),
      outputSchema: Value(jsonEncode(metadata.outputSchema)),
      config: Value('{"index":$index}'),
      permissions: Value(PermissionAccess.values[index % 3]),
      isEnabled: Value(index.isEven),
    );
  }

  Future<List<ToolsTable>> rows() =>
      database.workspaceToolsDao.getToolsByGroupId(groupId);

  Future<void> refresh(List<McpToolInfo> tools) => repository.syncMcpTools(
    mcpServerId: serverId,
    currentTools: tools,
  );

  Future<void> close() async {
    await database.close();
    await _directory?.delete(recursive: true);
  }
}

/// Counts executor dispatches separately from parameterized row executions.
final class CatalogSqlMetrics extends QueryInterceptor {
  int updateRows = 0;
  int updateCalls = 0;
  int batchCalls = 0;
  int mutationRows = 0;
  int selectCalls = 0;
  int metadataExecutorUs = 0;
  int commits = 0;
  int rollbacks = 0;

  void reset() {
    updateRows = 0;
    updateCalls = 0;
    batchCalls = 0;
    mutationRows = 0;
    selectCalls = 0;
    metadataExecutorUs = 0;
    commits = 0;
    rollbacks = 0;
  }

  Map<String, int> snapshot() => {
    'updateRows': updateRows,
    'updateCalls': updateCalls,
    'batchCalls': batchCalls,
    'mutationRows': mutationRows,
    'selectCalls': selectCalls,
    'metadataExecutorUs': metadataExecutorUs,
    'commits': commits,
    'rollbacks': rollbacks,
  };

  bool _metadataUpdate(String sql) =>
      RegExp(r'^UPDATE\s+"?tools"?\s', caseSensitive: false).hasMatch(sql);

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    mutationRows++;
    final metadata = _metadataUpdate(statement);
    if (metadata) {
      updateRows++;
      updateCalls++;
    }
    final timer = Stopwatch()..start();
    try {
      return await executor.runUpdate(statement, args);
    } finally {
      if (metadata) metadataExecutorUs += timer.elapsedMicroseconds;
    }
  }

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) async {
    batchCalls++;
    var metadata = false;
    for (final invocation in statements.arguments) {
      final sql = statements.statements[invocation.statementIndex];
      if (RegExp(r'^(UPDATE|INSERT|DELETE)\s').hasMatch(sql)) mutationRows++;
      if (_metadataUpdate(sql)) {
        updateRows++;
        metadata = true;
      }
    }
    final timer = Stopwatch()..start();
    try {
      await executor.runBatched(statements);
    } finally {
      if (metadata) metadataExecutorUs += timer.elapsedMicroseconds;
    }
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    selectCalls++;
    return executor.runSelect(statement, args);
  }

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    mutationRows++;
    return executor.runInsert(statement, args);
  }

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    mutationRows++;
    return executor.runDelete(statement, args);
  }

  @override
  Future<void> commitTransaction(TransactionExecutor inner) async {
    await inner.send();
    commits++;
  }

  @override
  Future<void> rollbackTransaction(TransactionExecutor inner) async {
    await inner.rollback();
    rollbacks++;
  }
}
