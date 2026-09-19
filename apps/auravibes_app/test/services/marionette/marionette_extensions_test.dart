import 'package:auravibes_app/flavor.dart';
import 'package:auravibes_app/services/marionette/marionette_development_state.dart';
import 'package:auravibes_app/services/marionette/marionette_extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

void main() {
  group('MarionetteExtensions', () {
    var actions = _FakeActions();
    var dispatcher = MarionetteExtensions(actions);

    setUp(() {
      actions = _FakeActions();
      dispatcher = MarionetteExtensions(actions);
    });

    test('rejects invalid values before invoking actions', () async {
      final results = [
        await dispatcher.navigate({
          'route': '/arbitrary',
          'workspaceId': 'local-workspace',
        }),
        await dispatcher.navigate({
          'route': 'new_chat',
          'workspaceId': 'workspace/id',
        }),
        await dispatcher.selectModel({
          'workspaceId': 'local-workspace',
          'modelSelectionId': 'model/id',
        }),
        await dispatcher.setDevelopmentFeatureFlag({'flag': 'shell'}),
        await dispatcher.setDevelopmentFeatureFlag({
          'flag': 'a2ui',
          'enabled': 'yes',
        }),
        await dispatcher.seedDemoData({'unexpected': 'value'}),
      ];

      expect(results, everyElement(isA<MarionetteExtensionInvalidParams>()));
      expect(actions.actionCalls, 0);
    });

    test('dispatches allowlisted values and schema defaults', () async {
      final navigation = await dispatcher.navigate({
        'route': 'settings',
        'workspaceId': 'local-workspace',
      });
      final workspace = await dispatcher.selectWorkspace({
        'workspaceId': 'local-workspace',
      });
      final model = await dispatcher.selectModel({
        'workspaceId': 'local-workspace',
        'modelSelectionId': 'model-selection',
      });
      final seed = await dispatcher.seedDemoData({});
      final clear = await dispatcher.clearDevelopmentState({});
      final flag = await dispatcher.setDevelopmentFeatureFlag({'flag': 'a2ui'});

      expect(navigation, isA<MarionetteExtensionSuccess>());
      expect(workspace, isA<MarionetteExtensionSuccess>());
      expect(model, isA<MarionetteExtensionSuccess>());
      expect(seed, isA<MarionetteExtensionSuccess>());
      expect(clear, isA<MarionetteExtensionSuccess>());
      expect(flag, isA<MarionetteExtensionSuccess>());
      expect(actions.actionCalls, 6);
      expect(actions.lastFeatureFlag, (flag: 'a2ui', enabled: true));
    });

    test('ignores the VM service isolate parameter', () async {
      final result = await dispatcher.seedDemoData({'isolateId': 'isolate-1'});

      expect(result, isA<MarionetteExtensionSuccess>());
      expect(actions.actionCalls, 1);
    });
  });

  test('registration exposes only schema-backed allowlisted tools', () {
    MarionetteExtensionRegistration.register(_FakeActions());

    final details = {
      for (final extension in customExtensionRegistry)
        extension.name: extension,
    };
    const names = [
      'auravibes.navigate',
      'auravibes.selectWorkspace',
      'auravibes.selectModel',
      'auravibes.seedDemoData',
      'auravibes.clearDevelopmentState',
      'auravibes.setDevelopmentFeatureFlag',
    ];

    expect(details.keys, containsAll(names));
    for (final name in names) {
      expect(details[name]?.inputSchema, isNotNull, reason: name);
    }

    final navigateDetails = details['auravibes.navigate'];
    final navigateInputSchema = navigateDetails?.inputSchema;
    if (navigateInputSchema == null) {
      fail('auravibes.navigate schema was not registered');
    }
    final navigateSchema = navigateInputSchema.toJson();
    expect(navigateSchema['required'], ['route', 'workspaceId']);
    expect(
      (navigateSchema['properties'] as Map<String, dynamic>)['route'],
      containsPair('enum', MarionetteDevelopmentState.allowedRouteValues),
    );

    final flagDetails = details['auravibes.setDevelopmentFeatureFlag'];
    final flagInputSchema = flagDetails?.inputSchema;
    if (flagInputSchema == null) {
      fail('auravibes.setDevelopmentFeatureFlag schema was not registered');
    }
    final flagSchema = flagInputSchema.toJson();
    final flagProperties = flagSchema['properties'] as Map<String, dynamic>;
    expect(
      flagProperties['flag'],
      containsPair('enum', MarionetteDevelopmentState.allowedFeatureFlagValues),
    );
    expect(flagProperties['enabled'], containsPair('default', true));
  });

  group('MarionetteExtensionBootstrap.shouldEnable', () {
    test('requires debug mode, explicit request, dev flavor, and db scope', () {
      expect(
        MarionetteExtensionBootstrap.shouldEnable(
          isDebugMode: true,
          requested: true,
          flavor: .dev,
          dbHashSource: '/workspace',
        ),
        isTrue,
      );

      for (final values in [
        (
          isDebugMode: false,
          requested: true,
          flavor: Flavor.dev,
          db: '/workspace',
        ),
        (
          isDebugMode: true,
          requested: false,
          flavor: Flavor.dev,
          db: '/workspace',
        ),
        (
          isDebugMode: true,
          requested: true,
          flavor: Flavor.prod,
          db: '/workspace',
        ),
        (isDebugMode: true, requested: true, flavor: Flavor.dev, db: ''),
      ]) {
        expect(
          MarionetteExtensionBootstrap.shouldEnable(
            isDebugMode: values.isDebugMode,
            requested: values.requested,
            flavor: values.flavor,
            dbHashSource: values.db,
          ),
          isFalse,
        );
      }
    });
  });
}

final class _FakeActions implements MarionetteExtensionActions {
  int actionCalls = 0;
  ({String flag, bool enabled})? lastFeatureFlag;

  @override
  Future<Map<String, dynamic>> navigate({
    required String route,
    required String workspaceId,
  }) async {
    actionCalls++;

    return {'route': route, 'workspaceId': workspaceId};
  }

  @override
  Future<Map<String, dynamic>> selectWorkspace({
    required String workspaceId,
  }) async {
    actionCalls++;

    return {'workspaceId': workspaceId};
  }

  @override
  Future<Map<String, dynamic>> selectModel({
    required String workspaceId,
    required String modelSelectionId,
  }) async {
    actionCalls++;

    return {'workspaceId': workspaceId, 'modelSelectionId': modelSelectionId};
  }

  @override
  Future<Map<String, dynamic>> seedDemoData() async {
    actionCalls++;

    return const {};
  }

  @override
  Future<Map<String, dynamic>> clearDevelopmentState() async {
    actionCalls++;

    return const {};
  }

  @override
  Future<Map<String, dynamic>> setDevelopmentFeatureFlag({
    required String flag,
    required bool enabled,
  }) async {
    actionCalls++;
    lastFeatureFlag = (flag: flag, enabled: enabled);

    return {'flag': flag, 'enabled': enabled};
  }
}
