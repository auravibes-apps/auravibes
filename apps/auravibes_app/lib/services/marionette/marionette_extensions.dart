import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/agents/agent_adapters/app_sub_agent_catalog.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/chats/notifiers/new_chat_state.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/usecases/select_workspace_usecase.dart';
import 'package:auravibes_app/flavor.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/services/marionette/marionette_development_state.dart';
import 'package:auravibes_app/services/marionette/marionette_sub_agent_smoke_fixture.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class const MarionetteExtensions(final MarionetteExtensionActions _actions) {
  Future<MarionetteExtensionResult> navigate(Map<String, String> params) =>
      _invoke(params, const {'route', 'workspaceId'}, () {
        final route = _marionetteEnumValue(
          params,
          'route',
          MarionetteDevelopmentState.allowedRoutes,
        );
        final workspaceId = _marionetteIdentifier(params, 'workspaceId');

        return _actions.navigate(route: route, workspaceId: workspaceId);
      });

  Future<MarionetteExtensionResult> selectWorkspace(
    Map<String, String> params,
  ) => _invoke(params, const {'workspaceId'}, () {
    return _actions.selectWorkspace(
      workspaceId: _marionetteIdentifier(params, 'workspaceId'),
    );
  });

  Future<MarionetteExtensionResult> selectModel(Map<String, String> params) =>
      _invoke(params, const {'workspaceId', 'modelSelectionId'}, () {
        return _actions.selectModel(
          workspaceId: _marionetteIdentifier(params, 'workspaceId'),
          modelSelectionId: _marionetteIdentifier(params, 'modelSelectionId'),
        );
      });

  Future<MarionetteExtensionResult> seedDemoData(Map<String, String> params) =>
      _invoke(params, const {}, _actions.seedDemoData);

  Future<MarionetteExtensionResult> startSubAgentSmokeFixture(
    Map<String, String> params,
  ) => _invoke(params, const {'count'}, () {
    final count = _marionetteEnumValue(
      params,
      'count',
      MarionetteDevelopmentState.allowedSubAgentSmokeCountValues.toSet(),
    );

    return _actions.startSubAgentSmokeFixture(count: .parse(count));
  });

  Future<MarionetteExtensionResult> finishSubAgentSmokeFixture(
    Map<String, String> params,
  ) => _invoke(params, const {'childId'}, () {
    return _actions.finishSubAgentSmokeFixture(
      childId: _marionetteIdentifier(params, 'childId'),
    );
  });

  Future<MarionetteExtensionResult> clearDevelopmentState(
    Map<String, String> params,
  ) => _invoke(params, const {}, _actions.clearDevelopmentState);

  Future<MarionetteExtensionResult> setDevelopmentFeatureFlag(
    Map<String, String> params,
  ) => _invoke(params, const {'flag', 'enabled'}, () {
    return _actions.setDevelopmentFeatureFlag(
      flag: _marionetteEnumValue(
        params,
        'flag',
        MarionetteDevelopmentState.allowedFeatureFlags,
      ),
      enabled: _marionetteBooleanValue(params, 'enabled', defaultValue: true),
    );
  });

  Future<MarionetteExtensionResult> _invoke(
    Map<String, String> params,
    Set<String> allowedParameters,
    Future<Map<String, dynamic>> Function() action,
  ) async {
    try {
      _validateMarionetteParameterNames(params, allowedParameters);
      final result = await action();

      return MarionetteExtensionResult.success(result);
    } on Object catch (error) {
      if (error is ArgumentError) {
        return MarionetteExtensionResult.invalidParams(
          error.message?.toString() ?? error.toString(),
        );
      }

      return const MarionetteExtensionResult.error(
        0,
        'AuraVibes development extension failed',
      );
    }
  }
}

final class MarionetteExtensionBootstrap {
  static const _workspaceIdDescription =
      'Stable identifier of an existing local workspace.';

  static const _navigateSchema = ExtensionInputSchema(
    required: ['route', 'workspaceId'],
    properties: {
      'route': ExtensionParam.string(
        description: 'One of the allowlisted workspace routes.',
        enumValues: MarionetteDevelopmentState.allowedRouteValues,
      ),
      'workspaceId': ExtensionParam.string(
        description: _workspaceIdDescription,
        minLength: 1,
        maxLength: MarionetteDevelopmentState.maxIdentifierLength,
      ),
    },
    title: 'AuraVibes Development Navigation',
    description:
        'Debug-only navigation. Remote workspaces and arbitrary paths '
        'are rejected.',
  );
  static const _selectWorkspaceSchema = ExtensionInputSchema(
    required: ['workspaceId'],
    properties: {
      'workspaceId': ExtensionParam.string(
        description: _workspaceIdDescription,
        minLength: 1,
        maxLength: MarionetteDevelopmentState.maxIdentifierLength,
      ),
    },
  );
  static const _selectModelSchema = ExtensionInputSchema(
    required: ['workspaceId', 'modelSelectionId'],
    properties: {
      'workspaceId': ExtensionParam.string(
        description: _workspaceIdDescription,
        minLength: 1,
        maxLength: MarionetteDevelopmentState.maxIdentifierLength,
      ),
      'modelSelectionId': ExtensionParam.string(
        description:
            'Stable identifier of a model selection in that workspace.',
        minLength: 1,
        maxLength: MarionetteDevelopmentState.maxIdentifierLength,
      ),
    },
  );
  static const _seedDemoDataSchema = ExtensionInputSchema(
    title: 'AuraVibes Demo Data Seed',
    description: 'No arguments. Writes only fixed local development records.',
  );
  static const _startSubAgentSmokeFixtureSchema = ExtensionInputSchema(
    required: ['count'],
    properties: {
      'count': ExtensionParam.string(
        description:
            'Number of deterministic local child conversations to start.',
        enumValues: MarionetteDevelopmentState.allowedSubAgentSmokeCountValues,
      ),
    },
    title: 'Start Sub-Agent Smoke Fixture',
    description: 'Starts local child conversations awaiting tool approval.',
  );
  static const _finishSubAgentSmokeFixtureSchema = ExtensionInputSchema(
    required: ['childId'],
    properties: {
      'childId': ExtensionParam.string(
        description: 'Stable child identifier returned by the start action.',
        minLength: 1,
        maxLength: MarionetteDevelopmentState.maxIdentifierLength,
      ),
    },
    title: 'Finish Sub-Agent Smoke Fixture Child',
    description: 'Completes one active local smoke-fixture child.',
  );
  static const _clearDevelopmentStateSchema = ExtensionInputSchema(
    title: 'AuraVibes Development State Clear',
    description:
        'No arguments. Does not touch other workspaces or preferences.',
  );
  static const _setDevelopmentFeatureFlagSchema = ExtensionInputSchema(
    required: ['flag'],
    properties: {
      'flag': ExtensionParam.string(
        description: 'One of the allowlisted development flags.',
        enumValues: MarionetteDevelopmentState.allowedFeatureFlagValues,
      ),
      'enabled': ExtensionParam.boolean(
        description: 'Whether to enable the flag. Defaults to true.',
        defaultValue: true,
      ),
    },
  );

  static bool shouldEnable({
    required bool isDebugMode,
    required bool requested,
    required Flavor flavor,
    required String dbHashSource,
  }) =>
      isDebugMode &&
      requested &&
      flavor == Flavor.dev &&
      dbHashSource.isNotEmpty;

  static MarionetteDevelopmentState createState(ProviderContainer container) {
    final dependencies = _MarionetteStateDependencies(container);

    return MarionetteDevelopmentState(
      database: dependencies.database,
      workspaceRepository: dependencies.workspaceRepository,
      selectWorkspaceUsecase: dependencies.selectWorkspaceUsecase,
      modelSelectionRepository: dependencies.modelSelectionRepository,
      preferences: dependencies.preferences,
      navigateTo: dependencies.navigateTo,
      setNewChatModel: dependencies.setNewChatModel,
      subAgentSmokeFixture: dependencies.subAgentSmokeFixture,
    );
  }
}

final class _MarionetteStateDependencies(ProviderContainer container) {
  final AppDatabase database = container.read(appDatabaseProvider);
  final WorkspaceRepository workspaceRepository = container.read(
    workspaceRepositoryProvider,
  );
  final SelectWorkspaceUsecase selectWorkspaceUsecase = container.read(
    selectWorkspaceUsecaseProvider,
  );
  final WorkspaceModelSelectionRepository modelSelectionRepository = container
      .read(workspaceModelSelectionRepositoryProvider);
  final Future<SharedPreferences> preferences = container.read(
    sharedPreferencesProvider.future,
  );
  final MarionetteNavigation navigateTo = container.read(routerProvider).go;
  final MarionetteSubAgentSmokeFixture subAgentSmokeFixture = .new(
    parentConversationId: MarionetteDevelopmentState.demoConversationId,
    workspaceId: MarionetteDevelopmentState.demoWorkspaceId,
    agentCatalog: AppSubAgentCatalog(container.read(agentsRepositoryProvider)),
    conversationStore: AppSubAgentConversationStore(
      container.read(conversationRepositoryProvider),
    ),
    messageStore: AppSubAgentMessageStore(
      container.read(messageRepositoryProvider),
    ),
    activeSubAgents: container.read(activeSubAgentRuntimeProvider.notifier),
  );
  final ProviderContainer _container = container;

  void setNewChatModel(String workspaceId, String modelSelectionId) =>
      _container
          .read(newChatProvider(workspaceId).notifier)
          .setModelId(modelSelectionId);
}

final class MarionetteExtensionRegistration {
  static void register(MarionetteExtensionActions actions) {
    final dispatcher = MarionetteExtensions(actions);

    _registerNavigate(dispatcher);
    _registerSelectWorkspace(dispatcher);
    _registerSelectModel(dispatcher);
    _registerStartSubAgentSmokeFixture(dispatcher);
    _registerFinishSubAgentSmokeFixture(dispatcher);
    _registerSeedDemoData(dispatcher);
    _registerClearDevelopmentState(dispatcher);
    _registerSetDevelopmentFeatureFlag(dispatcher);
  }

  static void _registerNavigate(MarionetteExtensions dispatcher) {
    registerMarionetteExtension(
      name: 'auravibes.navigate',
      description:
          'Navigate to an allowlisted route in an existing local workspace.',
      inputSchema: MarionetteExtensionBootstrap._navigateSchema,
      callback: dispatcher.navigate,
    );
  }

  static void _registerSelectWorkspace(MarionetteExtensions dispatcher) {
    registerMarionetteExtension(
      name: 'auravibes.selectWorkspace',
      description: 'Select an existing local workspace by stable identifier.',
      inputSchema: MarionetteExtensionBootstrap._selectWorkspaceSchema,
      callback: dispatcher.selectWorkspace,
    );
  }

  static void _registerSelectModel(MarionetteExtensions dispatcher) {
    registerMarionetteExtension(
      name: 'auravibes.selectModel',
      description:
          'Select a model in an existing local workspace by stable identifier.',
      inputSchema: MarionetteExtensionBootstrap._selectModelSchema,
      callback: dispatcher.selectModel,
    );
  }

  static void _registerStartSubAgentSmokeFixture(
    MarionetteExtensions dispatcher,
  ) {
    registerMarionetteExtension(
      name: 'auravibes.startSubAgentSmokeFixture',
      description: 'Start one or two deterministic local child conversations.',
      inputSchema:
          MarionetteExtensionBootstrap._startSubAgentSmokeFixtureSchema,
      callback: dispatcher.startSubAgentSmokeFixture,
    );
  }

  static void _registerFinishSubAgentSmokeFixture(
    MarionetteExtensions dispatcher,
  ) {
    registerMarionetteExtension(
      name: 'auravibes.finishSubAgentSmokeFixture',
      description: 'Finish one active deterministic local child conversation.',
      inputSchema:
          MarionetteExtensionBootstrap._finishSubAgentSmokeFixtureSchema,
      callback: dispatcher.finishSubAgentSmokeFixture,
    );
  }

  static void _registerSeedDemoData(MarionetteExtensions dispatcher) {
    registerMarionetteExtension(
      name: 'auravibes.seedDemoData',
      description:
          'Seed deterministic, credential-free data in the isolated '
          'development database.',
      inputSchema: MarionetteExtensionBootstrap._seedDemoDataSchema,
      callback: dispatcher.seedDemoData,
    );
  }

  static void _registerClearDevelopmentState(MarionetteExtensions dispatcher) {
    registerMarionetteExtension(
      name: 'auravibes.clearDevelopmentState',
      description:
          'Clear only the fixed Marionette demo workspace and development '
          'feature flags.',
      inputSchema: MarionetteExtensionBootstrap._clearDevelopmentStateSchema,
      callback: dispatcher.clearDevelopmentState,
    );
  }

  static void _registerSetDevelopmentFeatureFlag(
    MarionetteExtensions dispatcher,
  ) {
    registerMarionetteExtension(
      name: 'auravibes.setDevelopmentFeatureFlag',
      description: 'Set or clear an allowlisted development feature flag.',
      inputSchema:
          MarionetteExtensionBootstrap._setDevelopmentFeatureFlagSchema,
      callback: dispatcher.setDevelopmentFeatureFlag,
    );
  }
}

void _validateMarionetteParameterNames(
  Map<String, String> params,
  Set<String> allowedParameters,
) {
  final unknown = params.keys
      .where(
        (parameter) =>
            parameter != 'isolateId' && !allowedParameters.contains(parameter),
      )
      .toList();
  if (unknown.isNotEmpty) {
    throw ArgumentError.value(
      unknown.join(', '),
      'parameters',
      'contains unsupported values',
    );
  }
}

String _marionetteIdentifier(Map<String, String> params, String name) {
  final value = params[name];
  if (value == null ||
      value.isEmpty ||
      value.length > MarionetteDevelopmentState.maxIdentifierLength) {
    throw ArgumentError.value(value, name, 'must be a stable identifier');
  }
  if (value == '.' || value == '..' || value != Uri.encodeComponent(value)) {
    throw ArgumentError.value(value, name, 'must be a stable identifier');
  }

  return value;
}

String _marionetteEnumValue(
  Map<String, String> params,
  String name,
  Set<String> allowedValues,
) {
  final value = params[name];
  if (value == null || !allowedValues.contains(value)) {
    throw ArgumentError.value(value, name, 'is not allowlisted');
  }

  return value;
}

bool _marionetteBooleanValue(
  Map<String, String> params,
  String name, {
  required bool defaultValue,
}) {
  final value = params[name];
  if (value == null) return defaultValue;
  if (value == 'true') return true;
  if (value == 'false') return false;

  throw ArgumentError.value(value, name, 'must be true or false');
}
