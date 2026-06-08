// ignore_for_file: prefer-async-await
// Required: Existing Future chains preserve callback flow.
// ignore_for_file: no-magic-number
// Required: Existing thresholds and limits use numeric values.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
import 'package:auravibes_app/data/database/drift/daos/api_model_providers_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/api_models_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/app_skill_workspace_settings_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/conversation_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/conversation_skills_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/conversation_tools_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/mcp_servers_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/message_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/model_connections_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/skill_credential_definitions_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/skill_credentials_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/skill_template_tools_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/skills_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/tools_groups_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_compaction_settings_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_model_selection_with_connection.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_tools_dao.dart';
import 'package:auravibes_app/data/database/drift/tables/api_models.dart';
import 'package:auravibes_app/data/database/drift/tables/app_skill_workspace_settings.dart';
import 'package:auravibes_app/data/database/drift/tables/conversation_skills.dart';
import 'package:auravibes_app/data/database/drift/tables/conversation_tools.dart';
import 'package:auravibes_app/data/database/drift/tables/conversations.dart';
import 'package:auravibes_app/data/database/drift/tables/mcp_servers.dart';
import 'package:auravibes_app/data/database/drift/tables/messages.dart';
import 'package:auravibes_app/data/database/drift/tables/model_providers_table_type.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/database/drift/tables/skill_credential_definitions.dart';
import 'package:auravibes_app/data/database/drift/tables/skill_template_tools.dart';
import 'package:auravibes_app/data/database/drift/tables/skills.dart';
import 'package:auravibes_app/data/database/drift/tables/tools.dart';
import 'package:auravibes_app/data/database/drift/tables/tools_groups.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_compaction_settings.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_model_selections.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
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
    ServiceConnections,
    WorkspaceModelSelections,
    ApiModelProviders,
    ApiModels,
    Conversations,
    Messages,
    Tools,
    ToolsGroups,
    ConversationTools,
    McpServers,
    WorkspaceCompactionSettings,
    SkillCredentialDefinitions,
    Skills,
    SkillTemplateTools,
    ConversationSkills,
    AppSkillWorkspaceSettings,
  ],
  daos: [
    WorkspaceDao,
    ModelConnectionsDao,
    WorkspaceModelSelectionsDao,
    ApiModelProvidersDao,
    ApiModelsDao,
    ConversationDao,
    MessageDao,
    WorkspaceToolsDao,
    ToolsGroupsDao,
    ConversationToolsDao,
    McpServersDao,
    WorkspaceCompactionSettingsDao,
    SkillCredentialsDao,
    SkillCredentialDefinitionsDao,
    SkillsDao,
    SkillTemplateToolsDao,
    ConversationSkillsDao,
    AppSkillWorkspaceSettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Creates a new [AppDatabase] instance.
  ///
  /// If [connection] is provided, uses that connection.
  /// Otherwise, creates a default SQLite database connection.
  /// When [connection] is null, [dbPrefix] is used to prefix the underlying
  /// database name for the default connection. If [connection] is provided,
  /// [dbPrefix] has no effect.
  AppDatabase({QueryExecutor? connection, String? dbPrefix})
    : super(connection ?? _openConnection(dbPrefix: dbPrefix));

  /// Database schema version.
  @override
  int get schemaVersion => 7;

  /// Migration logic for database schema upgrades.
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.createTable(workspaceCompactionSettings);
        }
        if (from < 3) {
          await m.addColumn(apiModels, apiModels.supportsReasoning);
        }
        if (from < 4) {
          await m.createTable(serviceConnections);
          await customStatement(
            '''
            INSERT INTO service_connections (
              id,
              created_at,
              updated_at,
              name,
              service_id,
              kind,
              authentication_type,
              url,
              encrypted_auth_value,
              key_suffix,
              metadata_json,
              workspace_id,
              is_enabled
            )
            SELECT
              id,
              created_at,
              updated_at,
              name,
              model_id,
              'modelProvider',
              'apiKey',
              url,
              key_value,
              key_suffix,
              NULL,
              workspace_id,
              1
            FROM model_connections
            ''',
          );
          await m.alterTable(TableMigration(workspaceModelSelections));
          await m.deleteTable('model_connections');
        }
        if (from < 5) {
          await m.createTable(skillCredentialDefinitions);
          await m.createTable(skills);
          await m.createTable(skillTemplateTools);
          await m.createTable(conversationSkills);
          await m.createTable(appSkillWorkspaceSettings);
        }
        if (from >= 5 && from < 6) {
          await m.addColumn(skillTemplateTools, skillTemplateTools.description);
        }
        if (from >= 5 && from < 7) {
          await m.addColumn(skills, skills.isCredentialOptional);
          await m.addColumn(
            skillTemplateTools,
            skillTemplateTools.requiresCredential,
          );
        }
      },
    );
  }

  /// Creates a database connection using drift_flutter.
  ///
  /// This method sets up a cross-platform SQLite database connection
  /// with proper configuration for mobile and desktop platforms.
  static QueryExecutor _openConnection({String? dbPrefix}) {
    return driftDatabase(
      name: '${dbPrefix ?? ''}auravibes_app',
      web: .new(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
      ),
      native: const DriftNativeOptions(shareAcrossIsolates: true),
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
      final _ = await into(workspaces).insert(
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
