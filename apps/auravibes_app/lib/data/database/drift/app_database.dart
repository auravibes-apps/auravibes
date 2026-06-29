// Required: Existing thresholds and limits use numeric values.
import 'dart:convert';

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
import 'package:auravibes_app/domain/entities/service_connection_auth.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:crypto/crypto.dart';
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
  /// When [connection] is null, [dbHashSource] is hashed to isolate the
  /// database name for the default connection. If [connection] is provided,
  /// [dbHashSource] has no effect.
  AppDatabase({QueryExecutor? connection, String? dbHashSource})
    : super(connection ?? _openConnection(dbHashSource: dbHashSource));

  /// Database schema version.
  @override
  int get schemaVersion => 1;

  /// Database creation strategy.
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
    );
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
  static String databaseNameForHashSource(String? dbHashSource) {
    if (dbHashSource == null || dbHashSource.isEmpty) return 'auravibes_app';

    final digest = sha256.convert(utf8.encode(dbHashSource));
    final hashPrefix = digest.bytes
        .take(8)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    return 'auravibes_app_$hashPrefix';
  }

  /// Initializes the database with default data.
  ///
  /// Workspaces are intentionally user-created during first-run onboarding.
  Future<void> initializeWithDefaults() async {
    return;
  }
}
