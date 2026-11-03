// ignore_for_file: avoid-late-keyword - async setUp needs fixtures

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_verification_repository.dart';
import 'package:auravibes_app/features/settings/providers/scoped_verification_settings_provider.dart';
import 'package:auravibes_app/features/settings/services/scoped_verification_configuration.dart';
import 'package:auravibes_app/features/settings/usecases/save_scoped_verification_settings_usecase.dart';
import 'package:auravibes_app/features/settings/widgets/scoped_verification_section.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  late AppDatabase database;
  late WorkspaceVerificationRepository repository;
  late DraftExitGuard guard;
  late ScopedVerificationSettings initial;
  var probes = 0;
  var failProbe = false;

  setUp(() async {
    database = AppDatabase(connection: NativeDatabase.memory());
    repository = WorkspaceVerificationRepository(database);
    guard = DraftExitGuard();
    initial = _settings();
    probes = 0;
    failProbe = false;
    final _ = await database
        .into(database.workspaces)
        .insert(
          WorkspacesCompanion.insert(
            id: const Value('local'),
            name: 'Local',
            type: .local,
          ),
        );
  });
  tearDown(() async {
    guard.dispose();
    await database.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    bool cloud = false,
    bool emptyTools = false,
    bool spanish = false,
  }) async {
    final save = SaveScopedVerificationSettingsUsecase(
      repository: repository,
      validateBindings: (_, _) async => !emptyTools,
      probeCapabilities: (_, _, _) async {
        probes++;
        if (failProbe) throw StateError('Disconnected');

        return ScopedVerificationCapabilities(
          protocol: ScopedVerificationLimits.protocol,
          features: ScopedVerificationCapabilities.requiredFeatures,
        );
      },
    );
    await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: Scaffold(
            body: SingleChildScrollView(
              child: ScopedVerificationSection(
                workspaceId: 'local',
                guard: guard,
              ),
            ),
          ),
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            scopedVerificationSettingsProvider('local')
                .overrideWith((_) => Stream.value(initial)),
            scopedVerificationToolsProvider(
              'local',
            ).overrideWith((_) => Stream.value(emptyTools ? const [] : _tools)),
            saveScopedVerificationSettingsUsecaseProvider('local')
                .overrideWithValue(save),
          ],
          workspaceId: 'local',
          workspaceSession: cloud
              ? const WorkspaceSession(
                  CloudWorkspaceRef(
                    localWorkspaceId: 'local',
                    serverUrl: 'https://cloud.example',
                    accountId: 'account',
                    cloudWorkspaceId: 1,
                  ),
                )
              : null,
          startLocale: .new(spanish ? 'es' : 'en'),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester, {bool spanish = false}) async {
    await tester.tap(
      find.text(
        spanish ? 'Configurar verificaci\u00f3n' : 'Configure verification',
      ),
    );
    final _ = await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    final button = find.byKey(const ValueKey('verification-save'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    final _ = await tester.pumpAndSettle();
  }

  testWidgets(
    'starts off and collapsed without probing; explicit enable saves',
    (tester) async {
      await pump(tester);
      expect(find.text('Off'), findsOneWidget);
      expect(find.byKey(const ValueKey('verification-root')), findsNothing);
      expect(probes, 0);
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('verification-enable')));
      await tester.pump();
      expect(guard.isDirty, isTrue);
      await save(tester);
      expect(probes, 1);
      expect((await repository.getSettings('local')).enabled, isTrue);
      expect(guard.isDirty, isFalse);
    },
  );

  testWidgets('disabling a saved policy needs no available runner or probe', (
    tester,
  ) async {
    initial = _settings(enabled: true);
    await repository.saveSettings('local', initial);
    initial = await repository.getSettings('local');
    await pump(tester, emptyTools: true);
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('verification-enable')));
    await save(tester);
    expect(probes, 0);
    expect((await repository.getSettings('local')).enabled, isFalse);
  });

  testWidgets('invalid enabled configuration cannot probe or save', (
    tester,
  ) async {
    initial = ScopedVerificationSettings();
    await pump(tester);
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('verification-enable')));
    await save(tester);
    expect(probes, 0);
    expect(find.textContaining('Check every field'), findsOneWidget);
    expect(guard.isDirty, isTrue);
  });

  testWidgets('failed probe keeps draft and a second save can recover', (
    tester,
  ) async {
    failProbe = true;
    await pump(tester);
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('verification-enable')));
    await save(tester);
    expect(find.textContaining('Could not check the runner'), findsOneWidget);
    expect(guard.isDirty, isTrue);
    failProbe = false;
    await save(tester);
    expect(probes, 2);
    expect(guard.isDirty, isFalse);
  });

  testWidgets('cloud settings show unavailable and offer no execution switch', (
    tester,
  ) async {
    await pump(tester, cloud: true);
    expect(
      find.text('Verification is available only in local workspaces.'),
      findsOneWidget,
    );
    expect(find.text('Configure verification'), findsNothing);
    expect(probes, 0);
  });

  testWidgets('Spanish compact form remains scrollable to save and discard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pump(tester, spanish: true);
    await open(tester, spanish: true);
    await tester.tap(find.byKey(const ValueKey('verification-enable')));
    await tester.pump();
    final discard = find.byKey(const ValueKey('verification-discard'));
    await tester.ensureVisible(discard);
    await tester.tap(discard);
    final _ = await tester.pumpAndSettle();
    expect(guard.isDirty, isFalse);
    expect(tester.takeException(), isNull);
  });
}

ScopedVerificationSettings _settings({bool enabled = false}) =>
    ScopedVerificationSettings(
      enabled: enabled,
      runnerToolId: 'runner',
      mcpServerId: 'server',
      workspaceRoot: 'checkout',
      editToolIds: const {'edit'},
      checks: [
        ScopedVerificationCheck(
          id: 'analyze',
          executable: 'dart',
          arguments: const ['analyze'],
          pathSuffixes: const ['.dart'],
        ),
      ],
    );

const _tools = [
  ScopedVerificationToolOption(
    id: 'runner',
    serverId: 'server',
    toolIdentifier: 'verify',
    label: 'Local: verify',
    canRunUnattended: true,
  ),
  ScopedVerificationToolOption(
    id: 'edit',
    serverId: 'server',
    toolIdentifier: 'edit_file',
    label: 'Local: edit_file',
    canRunUnattended: false,
  ),
];
