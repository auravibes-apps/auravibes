import 'package:auravibes_app/app_storage_namespace.dart';
import 'package:auravibes_app/data/database/drift/daos/agent_tools_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/agents_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/api_model_providers_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/api_models_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/app_skill_workspace_settings_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/background_works_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/conversation_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/conversation_skills_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/conversation_tools_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/mcp_servers_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/message_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/model_connections_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/model_usage_records_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/recent_model_selections_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/skill_resources_dao.dart';
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
import 'package:auravibes_app/data/database/drift/tables/background_works.dart';
import 'package:auravibes_app/data/database/drift/tables/connector_writes.dart';
import 'package:auravibes_app/data/database/drift/tables/conversation_skills.dart';
import 'package:auravibes_app/data/database/drift/tables/conversation_tools.dart';
import 'package:auravibes_app/data/database/drift/tables/conversations.dart';
import 'package:auravibes_app/data/database/drift/tables/mcp_servers.dart';
import 'package:auravibes_app/data/database/drift/tables/message_attachments.dart';
import 'package:auravibes_app/data/database/drift/tables/message_bookmarks.dart';
import 'package:auravibes_app/data/database/drift/tables/messages.dart';
import 'package:auravibes_app/data/database/drift/tables/model_providers_table_type.dart';
import 'package:auravibes_app/data/database/drift/tables/model_usage_records.dart';
import 'package:auravibes_app/data/database/drift/tables/recent_model_selections.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/database/drift/tables/skill_resources.dart';
import 'package:auravibes_app/data/database/drift/tables/skills.dart';
import 'package:auravibes_app/data/database/drift/tables/tools.dart';
import 'package:auravibes_app/data/database/drift/tables/tools_groups.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_compaction_settings.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_assets.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_folders.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_model_selections.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_record_batch_receipts.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_tables.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_trash_batches.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_views.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/v7.dart';

// Required: Existing thresholds and limits use numeric values.

export 'daos/agents_dao.dart';
export 'daos/api_model_providers_dao.dart';
export 'daos/api_models_dao.dart';
export 'daos/app_skill_workspace_settings_dao.dart';
export 'daos/background_works_dao.dart';
export 'daos/conversation_skills_dao.dart';
export 'daos/conversation_tools_dao.dart';
export 'daos/message_dao.dart';
export 'daos/model_connections_dao.dart';
export 'daos/model_usage_records_dao.dart';
export 'daos/recent_model_selections_dao.dart';
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
    MessageBookmarks,
    Tools,
    ToolsGroups,
    ConversationTools,
    McpServers,
    WorkspaceCompactionSettings,
    Skills,
    SkillResources,
    ConversationSkills,
    AppSkillWorkspaceSettings,
    RecentModelSelections,
    ModelUsageRecords,
    BackgroundWorks,
    WorkspaceFolders,
    WorkspaceTables,
    WorkspaceTableRecords,
    ConnectorWrites,
    WorkspaceViews,
    WorkspaceTrashBatches,
    WorkspaceRecordBatchReceipts,
    WorkspaceAssets,
    WorkspaceFiles,
  ],
  daos: [
    WorkspaceDao,
    BackgroundWorksDao,
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
    SkillsDao,
    SkillResourcesDao,
    ConversationSkillsDao,
    AppSkillWorkspaceSettingsDao,
    RecentModelSelectionsDao,
    ModelUsageRecordsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  static const _agentsSchemaVersion = 2;
  static const _agentToolsSchemaVersion = 3;
  static const _splitSchemaVersion = 4;
  static const _cloudWorkspaceSchemaVersion = 5;
  static const _cloudWorkspaceColumnsSchemaVersion = 6;
  static const _conversationListSchemaVersion = 8;
  static const int _conversationPinOrderingSchemaVersion =
      _conversationListSchemaVersion + 1;
  static const int _recentModelSelectionsSchemaVersion =
      _conversationPinOrderingSchemaVersion + 1;
  static const int _forkSchemaVersion = _recentModelSelectionsSchemaVersion + 1;
  static const int _skillResourceSchemaVersion = _forkSchemaVersion + 2;
  static const int _apiModelModalitiesSchemaVersion =
      _skillResourceSchemaVersion + 1;
  static const int _legacyStreamingStatusSchemaVersion =
      _apiModelModalitiesSchemaVersion + 1;
  static const int _reasoningControlsSchemaVersion =
      _legacyStreamingStatusSchemaVersion + 1;
  static const int _mcpOutputSchemaVersion =
      _reasoningControlsSchemaVersion + 1;
  static const int _compactionBudgetsSchemaVersion =
      _mcpOutputSchemaVersion + 1;
  static const int _compactionCheckpointSchemaVersion =
      _compactionBudgetsSchemaVersion + 1;
  static const int _modelCapabilitiesSchemaVersion =
      _compactionCheckpointSchemaVersion + 1;
  static const int _modelUsageSchemaVersion =
      _modelCapabilitiesSchemaVersion + 1;
  static const int _mcpCatalogSnapshotSchemaVersion =
      _modelUsageSchemaVersion + 1;
  static const int _mcpTestSummarySchemaVersion =
      _mcpCatalogSnapshotSchemaVersion + 1;
  static const int _toolSamplingPolicySchemaVersion =
      _mcpTestSummarySchemaVersion + 1;
  static const int _backgroundWorkSchemaVersion =
      _toolSamplingPolicySchemaVersion + 1;
  static const int _autoApproveToolsSchemaVersion =
      _backgroundWorkSchemaVersion + 1;
  static const int _toolAccessModeSchemaVersion =
      _autoApproveToolsSchemaVersion + 1;
  static const int _backgroundWorkChildLinkSchemaVersion =
      _toolAccessModeSchemaVersion + 1;
  static const int _toolCallAttachmentSchemaVersion =
      _backgroundWorkChildLinkSchemaVersion + 1;
  static const int _messageBookmarkSchemaVersion =
      _toolCallAttachmentSchemaVersion + 1;
  static const int _connectorSkillToolReferencesSchemaVersion =
      _messageBookmarkSchemaVersion + 1;
  static const int _retireSkillOwnedStorageSchemaVersion =
      _connectorSkillToolReferencesSchemaVersion + 1;
  static const int _messageBookmarkSnapshotsSchemaVersion =
      _retireSkillOwnedStorageSchemaVersion + 1;
  static const int _workspaceFoldersSchemaVersion =
      _messageBookmarkSnapshotsSchemaVersion + 1;
  static const int _workspaceTablesSchemaVersion =
      _workspaceFoldersSchemaVersion + 1;
  static const int _connectorWritesSchemaVersion =
      _workspaceTablesSchemaVersion + 1;
  static const int _workspaceViewsSchemaVersion =
      _connectorWritesSchemaVersion + 1;
  static const int _workspaceTrashSchemaVersion =
      _workspaceViewsSchemaVersion + 1;
  static const int _workspaceRecordBatchSchemaVersion =
      _workspaceTrashSchemaVersion + 1;
  // Schema 40 belongs to record/schema history (#1678).
  static const int _workspaceAssetsSchemaVersion = 41;
  static const int _currentSchemaVersion = _workspaceAssetsSchemaVersion;

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
      beforeOpen: (_) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _runUpgrades(Migrator m, int from, int _) async {
    await _upgradeApiModelModalitiesSchema(from);
    await _runCoreUpgrades(m, from);
    await _upgradeLegacyStreamingStatuses(from);
    await _runSkillUpgrades(m, from);
    await _upgradeModelSchemas(m);
    await _upgradeToolAccessModeSchema(m);
    await _upgradeToolCallAttachmentSchema(m, from);
    await _upgradeMessageBookmarkSchemas(m, from);
    await _upgradeConnectorSkillToolReferencesSchema(m, from);
    await _retireSkillOwnedStorage(from);
    await _upgradeWorkspaceContentSchema(m, from);
  }

  Future<void> _upgradeWorkspaceContentSchema(Migrator m, int from) async {
    await _upgradeWorkspaceItemsSchema(m, from);
    if (from < AppDatabase._workspaceViewsSchemaVersion) {
      await m.createTable(workspaceViews);
    }
    await _upgradeWorkspaceTrashSchema(m, from);
    if (from < AppDatabase._workspaceRecordBatchSchemaVersion) {
      await m.createTable(workspaceRecordBatchReceipts);
    }
    if (from < AppDatabase._workspaceAssetsSchemaVersion) {
      await m.createTable(workspaceAssets);
      await m.createTable(workspaceFiles);
    }
    if (from < AppDatabase._connectorWritesSchemaVersion) {
      await m.createTable(connectorWrites);
    }
  }

  Future<void> _upgradeWorkspaceTrashSchema(Migrator m, int from) async {
    if (from >= AppDatabase._workspaceTrashSchemaVersion) return;
    await m.createTable(workspaceTrashBatches);
    if (from >= AppDatabase._workspaceViewsSchemaVersion) {
      await m.addColumn(workspaceViews, workspaceViews.deletedAt);
    }
  }

  Future<void> _upgradeModelSchemas(Migrator m) async {
    await _upgradeModelCapabilitiesSchema(m);
    await _upgradeModelUsageSchema(m);
  }

  Future<void> _upgradeWorkspaceItemsSchema(Migrator m, int from) async {
    if (from < AppDatabase._workspaceTablesSchemaVersion) {
      await m.createTable(workspaceTables);
      await m.createTable(workspaceTableRecords);
    }
    if (from < AppDatabase._workspaceFoldersSchemaVersion) {
      await m.createTable(workspaceFolders);
    }
  }

  Future<void> _upgradeMessageBookmarkSchema(Migrator m, int from) async {
    if (from >= AppDatabase._messageBookmarkSchemaVersion ||
        !await _tableExists('messages') ||
        await _columnExists('messages', 'is_bookmarked')) {
      return;
    }
    await m.addColumn(messages, messages.isBookmarked);
  }

  Future<void> _upgradeMessageBookmarkSchemas(Migrator m, int from) async {
    await _upgradeMessageBookmarkSchema(m, from);
    await _upgradeMessageBookmarkSnapshotsSchema(m, from);
  }

  Future<void> _upgradeMessageBookmarkSnapshotsSchema(
    Migrator m,
    int from,
  ) async {
    if (from >= AppDatabase._messageBookmarkSnapshotsSchemaVersion) return;

    if (!await _tableExists('message_bookmarks')) {
      await m.createTable(messageBookmarks);
    }
    if (!await _tableExists('messages')) return;
    for (final columnName in [
      'id',
      'conversation_id',
      'content',
      'is_user',
      'created_at',
      'is_bookmarked',
    ]) {
      if (!await _columnExists('messages', columnName)) return;
    }

    await customStatement('''
      INSERT OR IGNORE INTO message_bookmarks (
        id,
        conversation_id,
        content_snapshot,
        is_user,
        message_created_at
      )
      SELECT
        id,
        conversation_id,
        content,
        is_user,
        created_at
      FROM messages
      WHERE is_bookmarked = 1
    ''');
  }

  Future<void> _upgradeToolAccessModeSchema(Migrator m) async {
    if (!await _tableExists('conversations')) return;
    if (!await _columnExists('conversations', 'tool_access_mode')) {
      await m.addColumn(conversations, conversations.toolAccessMode);
    }
    if (!await _columnExists('conversations', 'auto_approve_tools')) return;
    await customStatement('''
      UPDATE conversations SET tool_access_mode =
      CASE WHEN auto_approve_tools = 1 THEN 'allow_all' ELSE 'default' END''');
    await customStatement(
      'ALTER TABLE conversations DROP COLUMN auto_approve_tools',
    );
  }

  Future<void> _upgradeToolCallAttachmentSchema(Migrator m, int from) async {
    if (from >= AppDatabase._toolCallAttachmentSchemaVersion ||
        !await _tableExists('message_attachments') ||
        await _columnExists('message_attachments', 'tool_call_id')) {
      return;
    }
    await m.addColumn(messageAttachments, messageAttachments.toolCallId);
  }

  Future<void> _upgradeModelUsageSchema(Migrator m) async {
    if (await _tableExists('api_models') &&
        !await _columnExists('api_models', 'cost_cache_write')) {
      await m.addColumn(apiModels, apiModels.costCacheWrite);
    }
    if (!await _tableExists('model_usage_records')) {
      await m.createTable(modelUsageRecords);
    }
  }

  Future<void> _upgradeModelCapabilitiesSchema(Migrator m) async {
    if (!await _tableExists('api_models')) return;
    for (final column in [
      apiModels.supportsPromptCacheMarkers,
      apiModels.supportsMidConversationSystemMessages,
      apiModels.supportsToolDeltas,
      apiModels.supportsDeferredTools,
    ]) {
      if (await _columnExists('api_models', column.name)) continue;
      await m.addColumn(apiModels, column);
    }
  }

  Future<void> _runCoreUpgrades(Migrator m, int from) async {
    await _runAgentAndWorkspaceUpgrades(m, from);
    await _runCatalogAndConversationUpgrades(m, from);
  }

  Future<void> _runAgentAndWorkspaceUpgrades(Migrator m, int from) async {
    await _upgradeAgentsSchema(m, from);
    await _upgradeAgentToolsSchema(m, from);
    await _upgradeAttachmentSchema(m, from);
    await _upgradeCloudAgentSchema(m, from);
    await _backfillAgentDescriptions(from);
    await _upgradeCloudWorkspaceSchema(m, from);
  }

  Future<void> _runCatalogAndConversationUpgrades(Migrator m, int from) async {
    await _upgradeAgentCatalogSchema(from);
    await _runMcpSchemaUpgrades(m, from);
    await _runConversationUpgrades(m, from);
    await _upgradeToolSamplingPolicySchema(m);
    await _upgradeBackgroundWorkSchema(m, from);
    await _upgradeBackgroundWorkChildLinkSchema(m, from);
  }

  Future<void> _upgradeBackgroundWorkSchema(Migrator m, int from) async {
    if (from >= AppDatabase._backgroundWorkSchemaVersion) return;
    if (!await _tableExists('background_works')) {
      await m.createTable(backgroundWorks);
    }
  }

  Future<void> _upgradeBackgroundWorkChildLinkSchema(
    Migrator m,
    int from,
  ) async {
    if (from >= AppDatabase._backgroundWorkChildLinkSchemaVersion ||
        !await _tableExists('background_works') ||
        await _columnExists('background_works', 'child_conversation_id')) {
      return;
    }
    await m.addColumn(backgroundWorks, backgroundWorks.childConversationId);
  }

  Future<void> _runMcpSchemaUpgrades(Migrator m, int from) async {
    await _upgradeMcpOutputSchema(m, from);
    await _upgradeMcpCatalogSnapshot(m);
    await _upgradeMcpTestSummary(m);
  }

  Future<void> _upgradeMcpOutputSchema(Migrator m, int from) async {
    if (from >= AppDatabase._mcpOutputSchemaVersion ||
        !await _tableExists('tools') ||
        await _columnExists('tools', 'output_schema')) {
      return;
    }
    await m.addColumn(tools, tools.outputSchema);
  }

  Future<void> _upgradeMcpCatalogSnapshot(Migrator m) async {
    if (!await _tableExists('mcp_servers') ||
        await _columnExists('mcp_servers', 'catalog_snapshot_json')) {
      return;
    }
    await m.addColumn(mcpServers, mcpServers.catalogSnapshotJson);
  }

  Future<void> _upgradeMcpTestSummary(Migrator m) async {
    if (!await _tableExists('mcp_servers') ||
        await _columnExists('mcp_servers', 'test_summary_json')) {
      return;
    }
    await m.addColumn(mcpServers, mcpServers.testSummaryJson);
  }

  Future<void> _runConversationUpgrades(Migrator m, int from) async {
    await _upgradeConversationListSchema(from);
    await _upgradeRecentModelSelectionsSchema(m);
    await _upgradeForkSchema(m, from);
    await _upgradeReasoningControlsSchema(m, from);
    await _upgradeCompactionBudgetsSchema(m, from);
    await _upgradeCompactionCheckpointSchema(m, from);
  }

  Future<void> _upgradeApiModelModalitiesSchema(int from) async {
    if (from >= AppDatabase._apiModelModalitiesSchemaVersion ||
        !await _columnExists('api_models', 'modalities_ouput') ||
        await _columnExists('api_models', 'modalities_output')) {
      return;
    }
    await customStatement(
      'ALTER TABLE api_models '
      'RENAME COLUMN modalities_ouput TO modalities_output',
    );
  }

  Future<void> _runSkillUpgrades(Migrator m, int from) async {
    if (from < AppDatabase._skillResourceSchemaVersion) {
      await m.createTable(skillResources);
    }
  }

  Future<void> _upgradeConnectorSkillToolReferencesSchema(
    Migrator m,
    int from,
  ) async {
    if (from >= AppDatabase._connectorSkillToolReferencesSchemaVersion ||
        !await _tableExists('skills') ||
        await _columnExists('skills', 'connector_tool_ids_json')) {
      return;
    }
    await m.addColumn(skills, skills.connectorToolIdsJson);
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
    if (from >= AppDatabase._reasoningControlsSchemaVersion) return;
    await customStatement(
      'CREATE INDEX IF NOT EXISTS agents_workspace_name_id '
      'ON agents (workspace_id, name COLLATE NOCASE, id)',
    );
  }

  Future<void> _upgradeConversationListSchema(int from) async {
    if (from >= AppDatabase._conversationPinOrderingSchemaVersion) return;
    if (!await _tableExists('conversations')) return;
    await customStatement(
      'DROP INDEX IF EXISTS conversations_workspace_parent_updated_id',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS '
      'conversations_workspace_parent_updated_id '
      'ON conversations ( '
      'workspace_id, parent_conversation_id, is_pinned DESC, '
      'updated_at DESC, id DESC '
      ')',
    );
  }

  Future<void> _upgradeRecentModelSelectionsSchema(Migrator m) async {
    if (await _tableExists('recent_model_selections')) return;
    await m.createTable(recentModelSelections);
  }

  Future<void> _backfillAgentDescriptions(int from) async {
    if (from >= AppDatabase._cloudWorkspaceSchemaVersion) return;
    await customStatement(
      'UPDATE agents SET description = substr(trim(content), 1, 512) '
      'WHERE length(description) = 0',
    );
  }

  Future<void> _upgradeForkSchema(Migrator m, int from) async {
    if (from >= AppDatabase._forkSchemaVersion) return;
    if (!await _tableExists('conversations')) return;
    await _addConversationColumnIfMissing(
      m,
      'fork_source_conversation_id',
      conversations.forkSourceConversationId,
    );
    await _addConversationColumnIfMissing(
      m,
      'fork_source_title',
      conversations.forkSourceTitle,
    );
    await _addConversationColumnIfMissing(
      m,
      'fork_through_message_id',
      conversations.forkThroughMessageId,
    );
    await _addConversationColumnIfMissing(
      m,
      'fork_materialized_at',
      conversations.forkMaterializedAt,
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS conversations_fork_source_idx '
      'ON conversations (fork_source_conversation_id)',
    );
  }

  Future<void> _upgradeReasoningControlsSchema(Migrator m, int from) async {
    if (from >= AppDatabase._reasoningControlsSchemaVersion) return;

    if (await _tableExists('api_models') &&
        !await _columnExists('api_models', 'reasoning_options_json')) {
      await m.addColumn(apiModels, apiModels.reasoningOptionsJson);
    }
    if (await _tableExists('conversations') &&
        !await _columnExists('conversations', 'reasoning_config_json')) {
      await m.addColumn(conversations, conversations.reasoningConfigJson);
    }
  }

  Future<void> _upgradeCompactionBudgetsSchema(Migrator m, int from) async {
    if (from >= AppDatabase._compactionBudgetsSchemaVersion ||
        !await _tableExists('workspace_compaction_settings') ||
        await _columnExists(
          'workspace_compaction_settings',
          'model_overrides_json',
        )) {
      return;
    }
    await m.addColumn(
      workspaceCompactionSettings,
      workspaceCompactionSettings.modelOverridesJson,
    );
  }

  Future<void> _upgradeCompactionCheckpointSchema(Migrator m, int from) async {
    if (from >= AppDatabase._compactionCheckpointSchemaVersion ||
        !await _tableExists('conversations') ||
        await _columnExists(
          'conversations',
          'active_compaction_checkpoint_id',
        )) {
      return;
    }
    await m.addColumn(
      conversations,
      conversations.activeCompactionCheckpointId,
    );
  }

  Future<void> _upgradeToolSamplingPolicySchema(Migrator m) async {
    if (!await _tableExists('workspace_model_selections') ||
        await _columnExists(
          'workspace_model_selections',
          'tool_sampling_policy',
        )) {
      return;
    }
    await m.addColumn(
      workspaceModelSelections,
      workspaceModelSelections.toolSamplingPolicy,
    );
  }

  Future<void> _upgradeLegacyStreamingStatuses(int from) async {
    if (from >= AppDatabase._legacyStreamingStatusSchemaVersion ||
        !await _tableExists('messages')) {
      return;
    }
    await customStatement('''
      UPDATE messages SET status = 'unfinished'
      WHERE status = 'streaming'
      ''');
  }

  Future<void> _retireSkillOwnedStorage(int from) async {
    if (from >= AppDatabase._retireSkillOwnedStorageSchemaVersion) return;
    if (await _tableExists('service_connections')) {
      await customStatement(
        'DELETE FROM service_connections WHERE kind IN (?, ?)',
        const ['skillCredential', 'appSkillCredential'],
      );
    }
    await customStatement('DROP TABLE IF EXISTS skill_template_tools');
    await customStatement('DROP TABLE IF EXISTS skill_credential_definitions');
  }
}

extension on AppDatabase {
  Future<void> _addConversationColumnIfMissing<T extends Object>(
    Migrator m,
    String columnName,
    GeneratedColumn<T> column,
  ) async {
    if (await _columnExists('conversations', columnName)) return;
    await m.addColumn(conversations, column);
  }

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
    name: AppDatabase.databaseNameForHashSource(dbHashSource),
    web: .new(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.dart.js'),
    ),
    native: const DriftNativeOptions(shareAcrossIsolates: true),
  );
}
