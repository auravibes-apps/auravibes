// Required: Existing thresholds and limits use numeric values.
import 'package:auravibes_app/app_storage_namespace.dart';
import 'package:auravibes_app/data/database/drift/daos/agent_tools_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/agents_dao.dart';
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
import 'package:auravibes_app/data/database/drift/tables/agent_skills.dart';
import 'package:auravibes_app/data/database/drift/tables/agent_tools.dart';
import 'package:auravibes_app/data/database/drift/tables/agents.dart';
import 'package:auravibes_app/data/database/drift/tables/api_models.dart';
import 'package:auravibes_app/data/database/drift/tables/app_skill_workspace_settings.dart';
import 'package:auravibes_app/data/database/drift/tables/conversation_skills.dart';
import 'package:auravibes_app/data/database/drift/tables/conversation_tools.dart';
import 'package:auravibes_app/data/database/drift/tables/conversations.dart';
import 'package:auravibes_app/data/database/drift/tables/mcp_servers.dart';
import 'package:auravibes_app/data/database/drift/tables/message_attachments.dart';
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
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/v7.dart';

export 'daos/agents_dao.dart';
export 'daos/api_model_providers_dao.dart';
export 'daos/api_models_dao.dart';
export 'daos/app_skill_workspace_settings_dao.dart';
export 'daos/conversation_skills_dao.dart';
export 'daos/conversation_tools_dao.dart';
export 'daos/message_dao.dart';
export 'daos/model_connections_dao.dart';
export 'daos/skill_credentials_dao.dart';
export 'daos/workspace_compaction_settings_dao.dart';
export 'daos/workspace_dao.dart';
export 'daos/workspace_tools_dao.dart';

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
    Agents,
    AgentSkills,
    AgentTools,
    Messages,
    MessageAttachments,
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
    AgentsDao,
    AgentToolsDao,
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
  static const _agentsSchemaVersion = 2;
  static const _agentToolsSchemaVersion = 3;
  static const _splitSchemaVersion = 4;
  static const _cloudWorkspaceSchemaVersion = 5;
  static const _cloudWorkspaceColumnsSchemaVersion = 6;
  static const _currentSchemaVersion = 7;

  /// Creates a new [AppDatabase] instance.
  ///
  /// If [connection] is provided, uses that connection.
  /// Otherwise, creates a default SQLite database connection.
  /// When [connection] is null, [dbHashSource] is hashed to isolate the
  /// database name for the default connection. If [connection] is provided,
  /// [dbHashSource] has no effect.
  new({QueryExecutor? connection, String? dbHashSource})
    : super(connection ?? _openConnection(dbHashSource: dbHashSource));

  /// Database schema version.
  @override
  final int schemaVersion = _currentSchemaVersion;

  /// Database creation strategy.
  @override
  MigrationStrategy get migration => _migrationStrategy();

  /// Builds the Drift database name for a hash source.
  static String databaseNameForHashSource(String? dbHashSource) =>
      AppStorageNamespace.forHashSource(dbHashSource);
}

extension on AppDatabase {
  MigrationStrategy _migrationStrategy() {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: _runUpgrades,
    );
  }

  Future<void> _runUpgrades(Migrator m, int from, int _) async {
    await _upgradeAgentsSchema(m, from);
    await _upgradeAgentToolsSchema(m, from);
    await _upgradeAttachmentSchema(m, from);
    await _upgradeCloudAgentSchema(m, from);
    await _backfillAgentDescriptions(from);
    await _upgradeCloudWorkspaceSchema(m, from);
    await _upgradeAgentCatalogSchema(from);
  }

  Future<void> _upgradeAgentsSchema(Migrator m, int from) async {
    if (from >= AppDatabase._agentsSchemaVersion) return;
    await m.createTable(agents);
    await m.createTable(agentSkills);
    await m.addColumn(conversations, conversations.agentId);
  }

  Future<void> _upgradeAgentToolsSchema(Migrator m, int from) async {
    if (from < AppDatabase._agentToolsSchemaVersion) {
      await m.createTable(agentTools);
    }
  }

  Future<void> _upgradeAttachmentSchema(Migrator m, int from) async {
    if (from < AppDatabase._splitSchemaVersion) {
      await _upgradeToSchema4(m);

      return;
    }
    if (from == AppDatabase._splitSchemaVersion) {
      await _upgradeSplitSchema4(m);
    }
  }

  Future<void> _upgradeCloudAgentSchema(Migrator m, int from) async {
    if (from < AppDatabase._agentsSchemaVersion ||
        from >= AppDatabase._cloudWorkspaceSchemaVersion) {
      return;
    }
    await _upgradeAgentsToSchema5(m);
  }

  Future<void> _upgradeCloudWorkspaceSchema(Migrator m, int from) async {
    if (from >= AppDatabase._cloudWorkspaceColumnsSchemaVersion) return;
    await m.addColumn(workspaces, workspaces.cloudWorkspaceId);
    await m.addColumn(workspaces, workspaces.cloudAccountId);
  }

  Future<void> _upgradeAgentCatalogSchema(int from) async {
    if (from >= AppDatabase._currentSchemaVersion) return;
    await customStatement(
      'CREATE INDEX IF NOT EXISTS agents_workspace_name_id '
      'ON agents (workspace_id, name COLLATE NOCASE, id)',
    );
  }

  Future<void> _backfillAgentDescriptions(int from) async {
    if (from >= AppDatabase._cloudWorkspaceSchemaVersion) return;
    await customStatement(
      'UPDATE agents SET description = substr(trim(content), 1, 512) '
      'WHERE length(description) = 0',
    );
  }
}

extension on AppDatabase {
  Future<void> _upgradeToSchema4(Migrator m) async {
    await m.addColumn(conversations, conversations.parentConversationId);
    await m.createTable(messageAttachments);
  }

  Future<void> _upgradeSplitSchema4(Migrator m) async {
    if (!await _tableExists('message_attachments')) {
      await m.createTable(messageAttachments);

      return;
    }
    if (!await _columnExists('message_attachments', 'display_name')) {
      await m.addColumn(messageAttachments, messageAttachments.displayName);
    }
    await _backfillAttachmentDisplayNames();
  }

  Future<void> _backfillAttachmentDisplayNames() => customStatement(
    'UPDATE message_attachments SET display_name = file_name '
    'WHERE display_name IS NULL OR length(display_name) = 0;',
  );

  Future<void> _upgradeAgentsToSchema5(Migrator m) async {
    await m.addColumn(agents, agents.description);
    await m.addColumn(agents, agents.isEnabled);
    await m.addColumn(agents, agents.visibility);
  }

  Future<bool> _tableExists(String tableName) async {
    final rows = await customSelect(
      'SELECT 1 FROM sqlite_master WHERE type = ? AND name = ?',
      variables: [const Variable<String>('table'), Variable<String>(tableName)],
    ).get();

    return rows.isNotEmpty;
  }

  Future<bool> _columnExists(String tableName, String columnName) async {
    final columns = await customSelect('PRAGMA table_info($tableName)').get();

    return columns.any((column) => column.read<String>('name') == columnName);
  }
}

/// Creates a database connection using drift_flutter.
///
/// This function sets up a cross-platform SQLite database connection
/// with proper configuration for mobile and desktop platforms.
QueryExecutor _openConnection({String? dbHashSource}) {
  return driftDatabase(
    native: const DriftNativeOptions(shareAcrossIsolates: true),
    name: AppDatabase.databaseNameForHashSource(dbHashSource),
    web: .new(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.dart.js'),
    ),
  );
}
