import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/workspaces/usecases/select_workspace_usecase.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef MarionetteNavigation = void Function(String location);
typedef MarionetteModelSelection = void Function(
  String workspaceId,
  String modelSelectionId,
);

class MarionetteDevelopmentState({
  required final AppDatabase database,
  required final WorkspaceRepository workspaceRepository,
  required final SelectWorkspaceUsecase selectWorkspaceUsecase,
  required final WorkspaceModelSelectionRepository modelSelectionRepository,
  required final Future<SharedPreferences> preferences,
  required final MarionetteNavigation navigateTo,
  required final MarionetteModelSelection setNewChatModel,
}) implements MarionetteExtensionActions {
  static const allowedRouteValues = <String>[
    'new_chat',
    'chats',
    'tools',
    'models',
    'service_connections',
    'skills',
    'agents',
    'settings',
  ];
  static const allowedRoutes = <String>{...allowedRouteValues};

  static const allowedFeatureFlagValues = <String>[
    'a2ui',
    'agent_tools',
    'model_sync',
  ];
  static const allowedFeatureFlags = <String>{...allowedFeatureFlagValues};
  static const maxIdentifierLength = 128;

  static const demoWorkspaceId = 'marionette-demo-workspace';
  static const demoConnectionId = 'marionette-demo-connection';
  static const demoModelSelectionId = 'marionette-demo-model-selection';
  static const demoConversationId = 'marionette-demo-conversation';
  static const demoMessageId = 'marionette-demo-message';
  static const _featureFlagPrefix = 'auravibes.marionette.feature.';
  static final _demoTimestamp = DateTime.utc(2026);

  @override
  Future<Map<String, dynamic>> navigate({
    required String route,
    required String workspaceId,
  }) async {
    if (!allowedRoutes.contains(route)) {
      throw ArgumentError.value(route, 'route', 'is not allowlisted');
    }

    await _requireLocalWorkspace(workspaceId);
    final location = _routeLocation(route, workspaceId);
    navigateTo(location);

    return {'route': route, 'workspaceId': workspaceId, 'location': location};
  }

  @override
  Future<Map<String, dynamic>> selectWorkspace({
    required String workspaceId,
  }) async {
    await _requireLocalWorkspace(workspaceId);
    final selectedWorkspaceId = await selectWorkspaceUsecase.call(
      workspaceId: workspaceId,
    );
    final location = _routeLocation('new_chat', selectedWorkspaceId);
    navigateTo(location);

    return {'workspaceId': selectedWorkspaceId, 'location': location};
  }

  @override
  Future<Map<String, dynamic>> selectModel({
    required String workspaceId,
    required String modelSelectionId,
  }) async {
    await _requireLocalWorkspace(workspaceId);
    _requireStableIdentifier(modelSelectionId, 'modelSelectionId');

    await _requireMarionetteModelSelection(
      modelSelectionRepository,
      workspaceId,
      modelSelectionId,
    );

    await database.recentModelSelectionsDao.recordSelection(
      workspaceId,
      modelSelectionId,
    );
    setNewChatModel(workspaceId, modelSelectionId);
    final location = _routeLocation('new_chat', workspaceId);
    navigateTo(location);

    return {
      'workspaceId': workspaceId,
      'modelSelectionId': modelSelectionId,
      'location': location,
    };
  }

  @override
  Future<Map<String, dynamic>> seedDemoData() async {
    await database.transaction(() => _seedMarionetteDemoData(database));

    return const {
      'workspaceId': demoWorkspaceId,
      'connectionId': demoConnectionId,
      'modelSelectionId': demoModelSelectionId,
      'conversationId': demoConversationId,
      'messageId': demoMessageId,
    };
  }

  @override
  Future<Map<String, dynamic>> clearDevelopmentState() async {
    final deletedWorkspace = await workspaceRepository.deleteWorkspace(
      demoWorkspaceId,
    );
    final deletedRecentSelections = await (database.delete(
      database.recentModelSelections,
    )..where((table) => table.workspaceId.equals(demoWorkspaceId))).go();
    final clearedFeatureFlags = await _clearFeatureFlags();

    return {
      'deletedWorkspace': deletedWorkspace,
      'deletedRecentSelections': deletedRecentSelections,
      'clearedFeatureFlags': clearedFeatureFlags,
    };
  }

  @override
  Future<Map<String, dynamic>> setDevelopmentFeatureFlag({
    required String flag,
    required bool enabled,
  }) async {
    if (!allowedFeatureFlags.contains(flag)) {
      throw ArgumentError.value(flag, 'flag', 'is not allowlisted');
    }

    final preferences = await this.preferences;
    final key = '$_featureFlagPrefix$flag';
    if (enabled) {
      final saved = await preferences.setBool(key, true);
      if (!saved) throw StateError('Unable to save development feature flag');
    } else {
      final _ = await preferences.remove(key);
    }

    return {'flag': flag, 'enabled': enabled, 'cleared': !enabled};
  }

  Future<int> _clearFeatureFlags() async {
    final preferences = await this.preferences;
    var cleared = 0;
    for (final key in preferences.getKeys()) {
      if (!key.startsWith(_featureFlagPrefix)) continue;
      if (await preferences.remove(key)) cleared++;
    }

    return cleared;
  }

  Future<void> _requireLocalWorkspace(String workspaceId) async {
    _requireStableIdentifier(workspaceId, 'workspaceId');
    final workspace = await workspaceRepository.getWorkspaceById(workspaceId);
    if (workspace == null || workspace.type != .local) {
      throw ArgumentError.value(
        workspaceId,
        'workspaceId',
        'must identify an existing local workspace',
      );
    }
  }

  void _requireStableIdentifier(String value, String parameter) {
    if (value.isEmpty ||
        value.length > maxIdentifierLength ||
        value == '.' ||
        value == '..' ||
        value != Uri.encodeComponent(value)) {
      throw ArgumentError.value(
        value,
        parameter,
        'must be a stable identifier',
      );
    }
  }

  String _routeLocation(String route, String workspaceId) => switch (route) {
    'new_chat' => NewChatRoute(workspaceId: workspaceId).location,
    'chats' => ChatsRoute(workspaceId: workspaceId).location,
    'tools' => ToolsRoute(workspaceId: workspaceId).location,
    'models' => ModelsRoute(workspaceId: workspaceId).location,
    'service_connections' => ServiceConnectionsRoute(
      workspaceId: workspaceId,
    ).location,
    'skills' => SkillsRoute(workspaceId: workspaceId).location,
    'agents' => AgentsRoute(workspaceId: workspaceId).location,
    'settings' => SettingsRoute(workspaceId: workspaceId).location,
    _ => throw ArgumentError.value(route, 'route', 'is not allowlisted'),
  };
}

Future<void> _seedMarionetteDemoData(AppDatabase database) async {
  await _seedMarionetteWorkspace(database);
  await _seedMarionetteConnection(database);
  await _seedMarionetteModelSelection(database);
  await _seedMarionetteConversation(database);
  await _seedMarionetteMessage(database);
}

Future<void> _requireMarionetteModelSelection(
  WorkspaceModelSelectionRepository repository,
  String workspaceId,
  String modelSelectionId,
) async {
  final selection = await repository.getWorkspaceModelSelectionById(
    modelSelectionId,
  );
  if (selection == null ||
      selection.modelConnection.workspaceId != workspaceId) {
    throw ArgumentError.value(
      modelSelectionId,
      'modelSelectionId',
      'does not identify a model in the selected workspace',
    );
  }
}

Future<void> _seedMarionetteWorkspace(AppDatabase database) async {
  final existing =
      await (database.select(database.workspaces)..where(
            (table) =>
                table.id.equals(MarionetteDevelopmentState.demoWorkspaceId),
          ))
          .getSingleOrNull();
  if (existing != null) {
    if (existing.type != .local) {
      throw StateError('Reserved Marionette workspace is not local');
    }

    return;
  }

  await _insertMarionetteWorkspace(database);
}

Future<void> _insertMarionetteWorkspace(AppDatabase database) async {
  final _ = await database
      .into(database.workspaces)
      .insert(
        WorkspacesCompanion.insert(
          id: const Value(MarionetteDevelopmentState.demoWorkspaceId),
          createdAt: .new(MarionetteDevelopmentState._demoTimestamp),
          updatedAt: .new(MarionetteDevelopmentState._demoTimestamp),
          name: 'Marionette Demo',
          type: .local,
        ),
      );
}

Future<void> _seedMarionetteConnection(AppDatabase database) async {
  final existing = await _findMarionetteConnection(database);
  if (existing != null) {
    _validateMarionetteConnection(
      isDemoWorkspace:
          existing.workspaceId == MarionetteDevelopmentState.demoWorkspaceId,
      isUnauthenticated: existing.authenticationType == .none,
    );

    return;
  }

  await _insertMarionetteConnection(database);
}

Future<ServiceConnectionTable?> _findMarionetteConnection(
  AppDatabase database,
) =>
    (database.select(database.serviceConnections)..where(
          (table) =>
              table.id.equals(MarionetteDevelopmentState.demoConnectionId),
        ))
        .getSingleOrNull();

Future<void> _insertMarionetteConnection(AppDatabase database) async {
  final _ = await database
      .into(database.serviceConnections)
      .insert(
        ServiceConnectionsCompanion.insert(
          id: const Value(MarionetteDevelopmentState.demoConnectionId),
          createdAt: .new(MarionetteDevelopmentState._demoTimestamp),
          updatedAt: .new(MarionetteDevelopmentState._demoTimestamp),
          name: 'Marionette Demo Provider',
          serviceId: 'marionette-demo',
          kind: .modelProvider,
          authenticationType: .none,
          workspaceId: MarionetteDevelopmentState.demoWorkspaceId,
        ),
      );
}

Future<void> _seedMarionetteModelSelection(AppDatabase database) async {
  final existing = await _findMarionetteModelSelection(database);
  if (existing != null) {
    _validateMarionetteModelSelection(
      isDemoConnection:
          existing.modelConnectionId ==
          MarionetteDevelopmentState.demoConnectionId,
      isDemoModel: existing.modelId == 'marionette-demo-model',
    );

    return;
  }

  await _insertMarionetteModelSelection(database);
}

Future<WorkspaceModelSelectionTable?> _findMarionetteModelSelection(
  AppDatabase database,
) =>
    (database.select(database.workspaceModelSelections)..where(
          (table) =>
              table.id.equals(MarionetteDevelopmentState.demoModelSelectionId),
        ))
        .getSingleOrNull();

Future<void> _insertMarionetteModelSelection(AppDatabase database) async {
  final _ = await database
      .into(database.workspaceModelSelections)
      .insert(
        WorkspaceModelSelectionsCompanion.insert(
          id: const Value(MarionetteDevelopmentState.demoModelSelectionId),
          createdAt: .new(MarionetteDevelopmentState._demoTimestamp),
          updatedAt: .new(MarionetteDevelopmentState._demoTimestamp),
          modelId: 'marionette-demo-model',
          modelConnectionId: MarionetteDevelopmentState.demoConnectionId,
        ),
      );
}

Future<void> _seedMarionetteConversation(AppDatabase database) async {
  final existing = await _findMarionetteConversation(database);
  if (existing != null) {
    _validateMarionetteConversation(
      isDemoWorkspace:
          existing.workspaceId == MarionetteDevelopmentState.demoWorkspaceId,
      isDemoModel:
          existing.modelId == MarionetteDevelopmentState.demoModelSelectionId,
    );

    return;
  }

  await _insertMarionetteConversation(database);
}

Future<ConversationsTable?> _findMarionetteConversation(AppDatabase database) =>
    (database.select(database.conversations)..where(
          (table) =>
              table.id.equals(MarionetteDevelopmentState.demoConversationId),
        ))
        .getSingleOrNull();

Future<void> _insertMarionetteConversation(AppDatabase database) async {
  final _ = await database
      .into(database.conversations)
      .insert(
        ConversationsCompanion.insert(
          id: const Value(MarionetteDevelopmentState.demoConversationId),
          createdAt: .new(MarionetteDevelopmentState._demoTimestamp),
          updatedAt: .new(MarionetteDevelopmentState._demoTimestamp),
          workspaceId: MarionetteDevelopmentState.demoWorkspaceId,
          title: 'Marionette Demo Conversation',
          modelId: const Value(MarionetteDevelopmentState.demoModelSelectionId),
        ),
      );
}

Future<void> _seedMarionetteMessage(AppDatabase database) async {
  final existing =
      await (database.select(database.messages)..where(
            (table) =>
                table.id.equals(MarionetteDevelopmentState.demoMessageId),
          ))
          .getSingleOrNull();
  if (existing != null) {
    if (existing.conversationId !=
        MarionetteDevelopmentState.demoConversationId) {
      throw StateError('Reserved Marionette message is invalid');
    }

    return;
  }

  await _insertMarionetteMessage(database);
}

Future<void> _insertMarionetteMessage(AppDatabase database) async {
  final _ = await database
      .into(database.messages)
      .insert(
        MessagesCompanion.insert(
          id: const Value(MarionetteDevelopmentState.demoMessageId),
          createdAt: .new(MarionetteDevelopmentState._demoTimestamp),
          updatedAt: .new(MarionetteDevelopmentState._demoTimestamp),
          conversationId: MarionetteDevelopmentState.demoConversationId,
          content: 'Deterministic Marionette demo message.',
          messageType: .text,
          isUser: true,
          status: .sent,
        ),
      );
}

void _validateMarionetteConnection({
  required bool isDemoWorkspace,
  required bool isUnauthenticated,
}) {
  if (!isDemoWorkspace || !isUnauthenticated) {
    throw StateError('Reserved Marionette connection is not development-only');
  }
}

void _validateMarionetteModelSelection({
  required bool isDemoConnection,
  required bool isDemoModel,
}) {
  if (!isDemoConnection || !isDemoModel) {
    throw StateError('Reserved Marionette model selection is invalid');
  }
}

void _validateMarionetteConversation({
  required bool isDemoWorkspace,
  required bool isDemoModel,
}) {
  if (!isDemoWorkspace || !isDemoModel) {
    throw StateError('Reserved Marionette conversation is invalid');
  }
}

abstract interface class MarionetteExtensionActions {
  Future<Map<String, dynamic>> navigate({
    required String route,
    required String workspaceId,
  });

  Future<Map<String, dynamic>> selectWorkspace({required String workspaceId});

  Future<Map<String, dynamic>> selectModel({
    required String workspaceId,
    required String modelSelectionId,
  });

  Future<Map<String, dynamic>> seedDemoData();

  Future<Map<String, dynamic>> clearDevelopmentState();

  Future<Map<String, dynamic>> setDevelopmentFeatureFlag({
    required String flag,
    required bool enabled,
  });
}
