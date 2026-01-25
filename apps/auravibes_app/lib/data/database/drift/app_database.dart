import 'package:auravibes_app/data/database/drift/daos/api_model_providers_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/api_models_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/conversation_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/conversation_tools_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/credential_models_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/credentials_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/mcp_servers_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/message_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/tools_groups_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_tools_dao.dart';
import 'package:auravibes_app/data/database/drift/tables/api_model_provider_table.dart';
import 'package:auravibes_app/data/database/drift/tables/api_model_table.dart';
import 'package:auravibes_app/data/database/drift/tables/conversation_tools_table.dart';
import 'package:auravibes_app/data/database/drift/tables/conversations_table.dart';
import 'package:auravibes_app/data/database/drift/tables/credentials_models_table.dart';
import 'package:auravibes_app/data/database/drift/tables/credentials_table.dart';
import 'package:auravibes_app/data/database/drift/tables/mcp_servers_table.dart';
import 'package:auravibes_app/data/database/drift/tables/messages_table.dart';
import 'package:auravibes_app/data/database/drift/tables/tools_groups_table.dart';
import 'package:auravibes_app/data/database/drift/tables/tools_table.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces_table.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/v7.dart';

part 'app_database.g.dart';

/// Main application database using Drift.
///
/// This database manages all local data storage for the Aura application,
/// including workspaces and other application data.
@DriftDatabase(
  tables: [
    Workspaces,
    Credentials,
    CredentialModels,
    ApiModelProviders,
    ApiModels,
    Conversations,
    Messages,
    Tools,
    ToolsGroups,
    ConversationTools,
    McpServers,
  ],
  daos: [
    WorkspaceDao,
    CredentialsDao,
    CredentialModelsDao,
    ApiModelProvidersDao,
    ApiModelsDao,
    ConversationDao,
    MessageDao,
    WorkspaceToolsDao,
    ToolsGroupsDao,
    ConversationToolsDao,
    McpServersDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Creates a new [AppDatabase] instance.
  ///
  /// If [connection] is provided, uses that connection.
  /// Otherwise, creates a default SQLite database connection.
  AppDatabase({QueryExecutor? connection})
    : super(connection ?? _openConnection());

  /// Database schema version.
  @override
  int get schemaVersion => 2;

  /// Migration logic for database schema upgrades.
  ///
  /// This method handles database migrations when the schema version changes.
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1 && to == 2) {
          await customStatement(
            'ALTER TABLE credentials ADD COLUMN key_suffix TEXT',
          );
        }
      },
    );
  }

  /// Creates a database connection using drift_flutter.
  ///
  /// This method sets up a cross-platform SQLite database connection
  /// with proper configuration for mobile and desktop platforms.
  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'auravibes_app',
      web: .new(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
      ),
      native: const DriftNativeOptions(
        shareAcrossIsolates: true,
      ),
    );
  }

  /// Initializes the database with default data.
  ///
  /// This method can be called to populate the database with
  /// initial data when the app first starts.
  Future<void> initializeWithDefaults() async {
    // Check if workspaces table is empty
    final workspaceCount = await customSelect(
      'SELECT COUNT(*) as count FROM workspaces',
    ).getSingle().then((result) => result.read<int>('count'));

    if (workspaceCount == 0) {
      await into(workspaces).insert(
        WorkspacesCompanion.insert(
          name: 'Default Workspace',
          type: WorkspaceType.local,
        ),
      );
    }
  }

  /// Performs database maintenance operations.
  ///
  /// This method can be called periodically to optimize the database,
  /// clean up old data, and perform other maintenance tasks.
  Future<void> performMaintenance() async {
    // Example maintenance tasks:
    // - Vacuum the database to reclaim space
    // - Update statistics
    // - Clean up orphaned records

    await customStatement('VACUUM');
    await customStatement('ANALYZE');
  }

  /// Gets database statistics for monitoring.
  ///
  /// Returns information about the database size, row counts, etc.
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final stats = <String, dynamic>{};

    // Get workspace count
    final workspaceCount = await customSelect(
      'SELECT COUNT(*) as count FROM workspaces',
    ).getSingle().then((result) => result.read<int>('count'));
    stats['workspaceCount'] = workspaceCount;

    // Get database page count (approximate size)
    final pageCount = await customSelect(
      'SELECT page_count FROM pragma_page_count()',
    ).getSingle().then((result) => result.read<int>('page_count'));
    stats['pageCount'] = pageCount;

    // Get page size
    final pageSize = await customSelect(
      'SELECT page_size FROM pragma_page_size()',
    ).getSingle().then((result) => result.read<int>('page_size'));
    stats['pageSize'] = pageSize;

    // Calculate approximate database size
    stats['approximateSizeBytes'] = pageCount * pageSize;

    return stats;
  }
}
