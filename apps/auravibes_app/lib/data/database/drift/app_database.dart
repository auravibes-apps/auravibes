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
import 'package:auravibes_app/domain/entities/service_connection_auth.dart';
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
  /// Creates a new [AppDatabase] instance.
  ///
  /// If [connection] is provided, uses that connection.
  /// Otherwise, creates a default SQLite database connection.
  /// When [connection] is null, [dbHashSource] is hashed to isolate the
  /// database name for the default connection. If [connection] is provided,
  /// [dbHashSource] has no effect.
  AppDatabase({QueryExecutor? connection, String? dbHashSource})
    : super(connection ?? _openConnection(dbHashSource: dbHashSource));

  /// Database schema version.
  @override
  int get schemaVersion => 6;

  /// Database creation strategy.
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.createTable(agents);
          await m.createTable(agentSkills);
          await m.addColumn(conversations, conversations.agentId);
        }
        if (from < 3) {
          await m.createTable(agentTools);
        }
        if (from < 4) {
          await _upgradeToSchema4(m);
        }
        if (from == 4) {
          await _upgradeSplitSchema4(m);
        }
        if (from >= 2 && from < 5) {
          await _upgradeAgentsToSchema5(m);
        }
        if (from < 5) {
          await customStatement(
            'UPDATE agents SET description = substr(trim(content), 1, 512) '
            'WHERE length(description) = 0',
          );
        }
        if (from < 6) {
          await m.addColumn(workspaces, workspaces.cloudWorkspaceId);
          await m.addColumn(workspaces, workspaces.cloudAccountId);
        }
      },
    );
  }

  Future<void> _upgradeToSchema4(Migrator m) async {
    await m.addColumn(
      conversations,
      conversations.parentConversationId,
    );
    await m.createTable(messageAttachments);
  }

  Future<void> _upgradeSplitSchema4(Migrator m) async {
    final hasMessageAttachments = await _tableExists('message_attachments');
    if (!hasMessageAttachments) {
      await m.createTable(messageAttachments);

      return;
    }

    final hasDisplayName = await _columnExists(
      'message_attachments',
      'display_name',
    );
    if (!hasDisplayName) {
      await m.addColumn(messageAttachments, messageAttachments.displayName);
    }
    await customStatement(
      'UPDATE message_attachments SET display_name = file_name '
      'WHERE display_name IS NULL OR length(display_name) = 0;',
    );
  }

  Future<void> _upgradeAgentsToSchema5(Migrator m) async {
    await m.addColumn(agents, agents.description);
    await m.addColumn(agents, agents.isEnabled);
    await m.addColumn(agents, agents.visibility);
  }

  /// Creates a database connection using drift_flutter.
  ///
  /// This method sets up a cross-platform SQLite database connection
  /// with proper configuration for mobile and desktop platforms.
  static QueryExecutor _openConnection({String? dbHashSource}) {
    return driftDatabase(
      name: databaseNameForHashSource(dbHashSource),
      web: .new(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
      ),
      native: const DriftNativeOptions(shareAcrossIsolates: true),
    );
  }

  /// Builds the Drift database name for a hash source.
  static String databaseNameForHashSource(String? dbHashSource) =>
      appStorageNamespaceFor(dbHashSource);

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
