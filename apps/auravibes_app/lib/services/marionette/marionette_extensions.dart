import 'package:auravibes_app/features/chats/notifiers/new_chat_state.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/usecases/select_workspace_usecase.dart';
import 'package:auravibes_app/flavor.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/services/marionette/marionette_development_state.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:riverpod/riverpod.dart';

bool shouldEnableMarionette({
  required bool isDebugMode,
  required bool requested,
  required Flavor flavor,
  required String dbHashSource,
}) =>
    isDebugMode && requested && flavor == Flavor.dev && dbHashSource.isNotEmpty;

MarionetteDevelopmentState createMarionetteDevelopmentState(
  ProviderContainer container,
) {
  final router = container.read(routerProvider);

  return MarionetteDevelopmentState(
    database: container.read(appDatabaseProvider),
    workspaceRepository: container.read(workspaceRepositoryProvider),
    selectWorkspaceUsecase: container.read(selectWorkspaceUsecaseProvider),
    modelSelectionRepository: container.read(
      workspaceModelSelectionRepositoryProvider,
    ),
    preferences: container.read(sharedPreferencesProvider.future),
    navigateTo: router.go,
    setNewChatModel: (workspaceId, modelSelectionId) => container
        .read(newChatProvider(workspaceId).notifier)
        .setModelId(modelSelectionId),
  );
}

class const MarionetteExtensions(final MarionetteExtensionActions _actions) {
  Future<MarionetteExtensionResult> navigate(Map<String, String> params) =>
      _invoke(params, const {'route', 'workspaceId'}, () {
        final route = _enumValue(
          params,
          'route',
          MarionetteDevelopmentState.allowedRoutes,
        );
        final workspaceId = _identifier(params, 'workspaceId');

        return _actions.navigate(route: route, workspaceId: workspaceId);
      });

  Future<MarionetteExtensionResult> selectWorkspace(
    Map<String, String> params,
  ) => _invoke(params, const {'workspaceId'}, () {
    return _actions.selectWorkspace(
      workspaceId: _identifier(params, 'workspaceId'),
    );
  });

  Future<MarionetteExtensionResult> selectModel(Map<String, String> params) =>
      _invoke(params, const {'workspaceId', 'modelSelectionId'}, () {
        return _actions.selectModel(
          workspaceId: _identifier(params, 'workspaceId'),
          modelSelectionId: _identifier(params, 'modelSelectionId'),
        );
      });

  Future<MarionetteExtensionResult> seedDemoData(Map<String, String> params) =>
      _invoke(params, const {}, _actions.seedDemoData);

  Future<MarionetteExtensionResult> clearDevelopmentState(
    Map<String, String> params,
  ) => _invoke(params, const {}, _actions.clearDevelopmentState);

  Future<MarionetteExtensionResult> setDevelopmentFeatureFlag(
    Map<String, String> params,
  ) => _invoke(params, const {'flag', 'enabled'}, () {
    return _actions.setDevelopmentFeatureFlag(
      flag: _enumValue(
        params,
        'flag',
        MarionetteDevelopmentState.allowedFeatureFlags,
      ),
      enabled: _booleanValue(params, 'enabled', defaultValue: true),
    );
  });

  Future<MarionetteExtensionResult> _invoke(
    Map<String, String> params,
    Set<String> allowedParameters,
    Future<Map<String, dynamic>> Function() action,
  ) async {
    try {
      _validateParameterNames(params, allowedParameters);
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

  void _validateParameterNames(
    Map<String, String> params,
    Set<String> allowedParameters,
  ) {
    final unknown = params.keys
        .where((parameter) => !allowedParameters.contains(parameter))
        .toList();
    if (unknown.isNotEmpty) {
      throw ArgumentError.value(
        unknown.join(', '),
        'parameters',
        'contains unsupported values',
      );
    }
  }

  String _identifier(Map<String, String> params, String name) {
    final value = params[name];
    if (value == null || value.isEmpty || value.length > 128) {
      throw ArgumentError.value(value, name, 'must be a stable identifier');
    }
    if (value == '.' || value == '..' || value != Uri.encodeComponent(value)) {
      throw ArgumentError.value(value, name, 'must be a stable identifier');
    }

    return value;
  }

  String _enumValue(
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

  bool _booleanValue(
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
}

void registerAuravibesMarionetteExtensions(MarionetteExtensionActions actions) {
  final dispatcher = MarionetteExtensions(actions);

  registerMarionetteExtension(
    name: 'auravibes.navigate',
    description:
        'Navigate to an allowlisted route in an existing local workspace.',
    inputSchema: const ExtensionInputSchema(
      required: ['route', 'workspaceId'],
      properties: {
        'route': ExtensionParam.string(
          description: 'One of the allowlisted workspace routes.',
          enumValues: MarionetteDevelopmentState.allowedRouteValues,
        ),
        'workspaceId': ExtensionParam.string(
          description: 'Stable identifier of an existing local workspace.',
          minLength: 1,
          maxLength: 128,
        ),
      },
      title: 'AuraVibes Development Navigation',
      description:
          'Debug-only navigation. Remote workspaces and arbitrary paths '
          'are rejected.',
    ),
    callback: dispatcher.navigate,
  );

  registerMarionetteExtension(
    name: 'auravibes.selectWorkspace',
    description: 'Select an existing local workspace by stable identifier.',
    inputSchema: const ExtensionInputSchema(
      required: ['workspaceId'],
      properties: {
        'workspaceId': ExtensionParam.string(
          description: 'Stable identifier of an existing local workspace.',
          minLength: 1,
          maxLength: 128,
        ),
      },
    ),
    callback: dispatcher.selectWorkspace,
  );

  registerMarionetteExtension(
    name: 'auravibes.selectModel',
    description:
        'Select a model in an existing local workspace by stable identifier.',
    inputSchema: const ExtensionInputSchema(
      required: ['workspaceId', 'modelSelectionId'],
      properties: {
        'workspaceId': ExtensionParam.string(
          description: 'Stable identifier of an existing local workspace.',
          minLength: 1,
          maxLength: 128,
        ),
        'modelSelectionId': ExtensionParam.string(
          description:
              'Stable identifier of a model selection in that workspace.',
          minLength: 1,
          maxLength: 128,
        ),
      },
    ),
    callback: dispatcher.selectModel,
  );

  registerMarionetteExtension(
    name: 'auravibes.seedDemoData',
    description:
        'Seed deterministic, credential-free data in the isolated '
        'development database.',
    inputSchema: const ExtensionInputSchema(
      title: 'AuraVibes Demo Data Seed',
      description: 'No arguments. Writes only fixed local development records.',
    ),
    callback: dispatcher.seedDemoData,
  );

  registerMarionetteExtension(
    name: 'auravibes.clearDevelopmentState',
    description:
        'Clear only the fixed Marionette demo workspace and development '
        'feature flags.',
    inputSchema: const ExtensionInputSchema(
      title: 'AuraVibes Development State Clear',
      description:
          'No arguments. Does not touch other workspaces or preferences.',
    ),
    callback: dispatcher.clearDevelopmentState,
  );

  registerMarionetteExtension(
    name: 'auravibes.setDevelopmentFeatureFlag',
    description: 'Set or clear an allowlisted development feature flag.',
    inputSchema: const ExtensionInputSchema(
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
    ),
    callback: dispatcher.setDevelopmentFeatureFlag,
  );
}
