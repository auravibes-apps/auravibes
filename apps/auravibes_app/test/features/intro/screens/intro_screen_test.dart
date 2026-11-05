import 'dart:async';
import 'dart:ui' as ui;

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_auth_content.dart';
import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_app/features/intro/screens/intro_screen.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/chat_model_connections_provider.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_creation_draft_notifier.dart';
import 'package:auravibes_app/features/workspaces/screens/create_workspace_screen.dart';
import 'package:auravibes_app/features/workspaces/usecases/create_workspace_use_case.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_app/widgets/draft_exit_scope.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    as sdk_localizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('first-use guide selects a localized editable starter', (
    tester,
  ) async {
    final useCase = _CreateWorkspaceUseCase();
    final fixture = _IntroFixture(createWorkspaceUseCase: useCase);
    addTearDown(fixture.dispose);
    final workspace = await tester.runAsync(
      () => WorkspaceRepository(fixture.database)
          .createWorkspace(
            const .new(name: 'Trabajo personal', type: .local),
          )
          .timeout(const Duration(seconds: 20)),
    );
    if (workspace == null) {
      fail('Quick-start workspace creation did not finish');
    }
    when(() => useCase.call(name: 'Trabajo personal'))
        .thenAnswer((_) async => workspace);
    final semantics = tester.ensureSemantics();
    try {
      await tester.runAsync(
        () => tester.pumpWidget(
          fixture.buildApp(startLocale: const Locale('es')),
        ),
      );
      await _pumpUntilFound(tester, find.byKey(_quickStartKey));

      expect(find.text('intro_flow.welcome.title'.tr()), findsOneWidget);
      expect(
        find.text('intro_flow.welcome.local_storage'.tr()),
        findsOneWidget,
      );
      expect(find.byKey(_dayStarterKey), findsOneWidget);
      expect(find.byKey(_shoppingStarterKey), findsOneWidget);
      expect(find.byKey(_messageStarterKey), findsOneWidget);
      expect(find.byKey(_advancedSetupKey), findsOneWidget);
      expect(
        tester.widget<AuraButton>(find.byKey(_quickStartKey)).disabled,
        isTrue,
      );

      await _tapVisible(tester, find.byKey(_shoppingStarterKey));
      final selected = find.byKey(_shoppingStarterKey);
      expect(
        tester.getSemantics(selected).flagsCollection.isSelected,
        ui.Tristate.isTrue,
      );
      expect(
        tester.widget<AuraButton>(find.byKey(_quickStartKey)).disabled,
        isFalse,
      );
      await _tapVisible(tester, find.byKey(_quickStartKey));
      await _pumpUntilFound(tester, find.textContaining('new chat:'));

      expect(
        find.textContaining(
          'draft: Prepara una lista de compras para una cena sencilla',
        ),
        findsOneWidget,
      );
      expect(workspace.name, 'Trabajo personal');
      final conversations = await tester.runAsync(() {
        final query = fixture.database.select(fixture.database.conversations)
          ..where((row) => row.workspaceId.equals(workspace.id));

        return query.get().timeout(const Duration(seconds: 20));
      });
      if (conversations == null) {
        fail('Conversation query did not complete');
      }
      expect(conversations, isEmpty);
    } finally {
      await _closeIntroWidget(tester);
      semantics.dispose();
    }
  });

  testWidgets('keyboard can select a task and reach advanced setup', (
    tester,
  ) async {
    final fixture = _IntroFixture();
    addTearDown(fixture.dispose);
    final semantics = tester.ensureSemantics();
    try {
      await tester.runAsync(() => tester.pumpWidget(fixture.buildApp()));
      await _pumpUntilFound(tester, find.byKey(_quickStartKey));

      final _ = await tester.sendKeyEvent(.tab);
      await tester.pump();
      final _ = await tester.sendKeyEvent(.enter);
      await tester.pump();
      final selectedSemantics = tester.getSemantics(find.byKey(_dayStarterKey));
      expect(selectedSemantics.flagsCollection.isSelected, ui.Tristate.isTrue);

      for (var index = 0; index < 4; index++) {
        final _ = await tester.sendKeyEvent(.tab);
        await tester.pump();
      }
      final _ = await tester.sendKeyEvent(.enter);
      await _pumpUntilFound(tester, find.byKey(_localRouteKey));
      expect(find.byKey(_cloudRouteKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await _closeIntroWidget(tester);
      semantics.dispose();
    }
  });

  testWidgets('quick start keeps the guide available after a storage failure', (
    tester,
  ) async {
    final useCase = _CreateWorkspaceUseCase();
    final fixture = _IntroFixture(createWorkspaceUseCase: useCase);
    addTearDown(fixture.dispose);
    var attempts = 0;
    late WorkspaceEntity retryWorkspace;
    when(() => useCase.call(name: 'Personal work')).thenAnswer((_) async {
      attempts++;
      if (attempts == 1) throw StateError('storage unavailable');

      return retryWorkspace;
    });
    try {
      await tester.runAsync(() => tester.pumpWidget(fixture.buildApp()));
      await _tapVisible(tester, find.byKey(_dayStarterKey));
      await _tapVisible(tester, find.byKey(_quickStartKey));
      await _pumpUntilFound(
        tester,
        find.text('An unexpected error occurred. Please try again.'),
      );
      final emptyWorkspaces = await tester.runAsync(
        () => fixture.database.workspaceDao.getAllWorkspaces().timeout(
          const Duration(seconds: 20),
        ),
      );
      if (emptyWorkspaces == null) {
        fail('Workspace query did not complete');
      }
      expect(emptyWorkspaces, isEmpty);
      expect(find.byKey(_advancedSetupKey), findsOneWidget);

      final workspace = await tester.runAsync(
        () => WorkspaceRepository(fixture.database)
            .createWorkspace(const .new(name: 'Personal work', type: .local))
            .timeout(const Duration(seconds: 20)),
      );
      if (workspace == null) {
        fail('Quick-start retry did not create a workspace');
      }
      retryWorkspace = workspace;
      await _tapVisible(tester, find.byKey(_quickStartKey));
      await _pumpUntilFound(tester, find.textContaining('new chat:'));
      expect(attempts, 2);
      expect(workspace.name, 'Personal work');
    } finally {
      await _closeIntroWidget(tester);
    }
  });

  testWidgets('quick start disables starter changes while creating workspace', (
    tester,
  ) async {
    final useCase = _CreateWorkspaceUseCase();
    final fixture = _IntroFixture(createWorkspaceUseCase: useCase);
    addTearDown(fixture.dispose);
    final workspaceCreation = Completer<WorkspaceEntity>();
    when(() => useCase.call(name: 'Personal work'))
        .thenAnswer((_) => workspaceCreation.future);
    try {
      await tester.runAsync(() => tester.pumpWidget(fixture.buildApp()));
      await _tapVisible(tester, find.byKey(_dayStarterKey));
      await _tapVisible(tester, find.byKey(_quickStartKey));
      await tester.pump();

      for (final key in [
        _dayStarterKey,
        _shoppingStarterKey,
        _messageStarterKey,
      ]) {
        final button = find.descendant(
          of: find.byKey(key),
          matching: find.byType(AuraButton),
        );
        expect(tester.widget<AuraButton>(button).disabled, isTrue);
      }

      final localWorkspace = await tester.runAsync(() {
        return WorkspaceRepository(fixture.database)
            .createWorkspace(const .new(name: 'Personal work', type: .local))
            .timeout(const Duration(seconds: 20));
      });
      if (localWorkspace == null) {
        fail('Quick-start workspace creation did not finish');
      }
      workspaceCreation.complete(localWorkspace);
      await _pumpUntilFound(tester, find.textContaining('new chat:'));
    } finally {
      await _closeIntroWidget(tester);
    }
  });

  for (final locale in [const Locale('en'), const Locale('es')]) {
    testWidgets('advanced setup stays reachable with disclosures $locale', (
      tester,
    ) async {
      final fixture = _IntroFixture();
      addTearDown(fixture.dispose);
      try {
        await tester.runAsync(
          () => tester.pumpWidget(fixture.buildApp(startLocale: locale)),
        );
        await _tapVisible(tester, find.byKey(_advancedSetupKey));
        await _pumpUntilFound(tester, find.byKey(_localRouteKey));

        expect(find.byKey(_cloudRouteKey), findsOneWidget);
        expect(find.byKey(_connectExistingKey), findsOneWidget);
        expect(
          find.textContaining('intro_flow.choice.select_hint'.tr()),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            locale.languageCode == 'es' ? 'plan de pago' : 'paid plan',
          ),
          findsWidgets,
        );
        final workspaces = await tester.runAsync(
          () => fixture.database.workspaceDao.getAllWorkspaces().timeout(
            const Duration(seconds: 20),
          ),
        );
        if (workspaces == null) {
          fail('Workspace query did not complete');
        }
        expect(workspaces, isEmpty);
      } finally {
        await _closeIntroWidget(tester);
      }
    });
  }

  for (final kind in [PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
    for (final reducedMotion in [false, true]) {
      testWidgets('reversible pager kind=$kind reducedMotion=$reducedMotion', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(520, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final fixture = _IntroFixture();
        addTearDown(fixture.dispose);
        await tester.runAsync(
          () =>
              tester.pumpWidget(fixture.buildApp(reducedMotion: reducedMotion)),
        );
        await _pumpUntilFound(tester, find.byKey(_advancedSetupKey));
        final semantics = tester.ensureSemantics();
        try {
          final pager = find.byKey(const Key('intro_welcome_pages'));
          await tester.drag(pager, const Offset(-400, 0), kind: kind);
          final _ = await tester.pumpAndSettle();
          expect(find.text('2 of 4'), findsOneWidget);
          await tester.drag(pager, const Offset(400, 0), kind: kind);
          final _ = await tester.pumpAndSettle();
          expect(find.text('1 of 4'), findsOneWidget);
          final gesture = await tester.startGesture(
            tester.getCenter(pager),
            kind: kind,
          );
          await gesture.moveBy(const Offset(-25, 0));
          await tester.pump(const Duration(milliseconds: 400));
          await gesture.up();
          final _ = await tester.pumpAndSettle();
          expect(find.text('1 of 4'), findsOneWidget);
          for (var position = 0; position < 4; position++) {
            final dot = find.byKey(.new('intro_progress_$position'));
            expect(tester.getSize(dot).width, greaterThanOrEqualTo(48));
            expect(tester.getSize(dot).height, greaterThanOrEqualTo(48));
          }
          final _ = await tester.sendKeyEvent(.arrowRight);
          final _ = await tester.pumpAndSettle();
          expect(find.text('2 of 4'), findsOneWidget);
          final dot = find.byKey(const Key('intro_progress_1'));
          expect(
            tester.getSemantics(dot).flagsCollection.isSelected,
            ui.Tristate.isTrue,
          );
          await _tapVisible(tester, find.byKey(_welcomeSkipKey));
          final _ = await tester.pumpAndSettle();
          expect(find.text('4 of 4'), findsOneWidget);
          await _chooseIntroRoute(tester, 'local');
          await tester.enterText(find.byType(AuraInput), 'Keep offscreen');
          await tester.drag(pager, const Offset(400, 0), kind: kind);
          final _ = await tester.pumpAndSettle();
          expect(find.byKey(_backToRouteChooserKey), findsOneWidget);
          await _tapVisible(tester, find.byKey(_backToRouteChooserKey));
          await _tapVisible(tester, find.byKey(const Key('intro_progress_0')));
          final _ = await tester.pumpAndSettle();
          await _tapVisible(tester, find.byKey(_advancedSetupKey));
          await _chooseIntroRoute(tester, 'local');
          expect(find.text('Keep offscreen'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        } finally {
          semantics.dispose();
        }
      });
    }
  }

  testWidgets(
    'captures compact onboarding goldens across the intro flow stages',
    (tester) async {
      await tester.binding.setSurfaceSize(const ui.Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fixture = _IntroFixture();
      addTearDown(fixture.dispose);

      await tester.runAsync(
        () => tester.pumpWidget(fixture.buildApp(reducedMotion: true)),
      );
      await _pumpUntilFound(tester, find.byKey(_quickStartKey));

      await expectLater(
        find.byType(IntroScreen),
        matchesGoldenFile('goldens/intro_welcome.png'),
      );

      await tester.tap(find.byKey(const Key('intro_progress_1')));
      final _ = await tester.pumpAndSettle();
      await expectLater(
        find.byType(IntroScreen),
        matchesGoldenFile('goldens/intro_workspace_context.png'),
      );

      await tester.tap(find.byKey(_welcomeNextKey));
      final _ = await tester.pumpAndSettle();
      expect(find.text('''Connect AI when you're ready'''), findsOneWidget);
      await tester.tap(find.byKey(_welcomeNextKey));
      await _pumpUntilFound(tester, find.byKey(_localRouteKey));
      await expectLater(
        find.byType(IntroScreen),
        matchesGoldenFile('goldens/intro_workspace_choice.png'),
      );

      await _tapVisible(tester, find.byKey(_localRouteKey));
      await _pumpUntilFound(tester, find.byKey(_createWorkspaceKey));
      await _pumpUntilFound(tester, find.byKey(_createWorkspaceKey));
      await _pumpUntilFound(tester, find.byKey(_createWorkspaceKey));
      await expectLater(
        find.byType(IntroScreen),
        matchesGoldenFile('goldens/intro_workspace_create.png'),
      );

      await tester.enterText(find.byType(AuraInput), 'Design studio');
      await _tapVisible(tester, find.byKey(_createWorkspaceKey));
      await _pumpUntilFound(tester, find.text('Workspace created'));
      await _pumpUntilFound(
        tester,
        find.text('chat_readiness.no_provider'.tr()),
      );
      final _ = await tester.pumpAndSettle();
      expect(find.text('Design studio'), findsOneWidget);
      await expectLater(
        find.byType(IntroScreen),
        matchesGoldenFile('goldens/intro_ready.png'),
      );

      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
    tags: ['golden'],
  );

  testWidgets('outgoing forms lose focus and completion slides to readiness', (
    tester,
  ) async {
    final fixture = _IntroFixture();
    addTearDown(fixture.dispose);
    await tester.runAsync(() => tester.pumpWidget(fixture.buildApp()));
    await _chooseIntroRoute(tester, 'local');
    await tester.enterText(find.byType(AuraInput), 'Motion draft');
    expect(tester.testTextInput.hasAnyClients, isTrue);
    await tester.tap(find.byKey(_backToRouteChooserKey));
    await tester.pump();
    await tester.pump();
    expect(tester.testTextInput.hasAnyClients, isFalse);
    expect(await fixture.database.workspaceDao.getAllWorkspaces(), isEmpty);
    final _ = await tester.pumpAndSettle();
    await _chooseIntroRoute(tester, 'local');
    expect(find.text('Motion draft'), findsOneWidget);
    await tester.tap(find.byKey(_createWorkspaceKey));
    await _pumpUntilFound(tester, find.text('Workspace created'));
    expect(
      tester
          .widgetList<SlideTransition>(find.byType(SlideTransition))
          .any((slide) => slide.position.value.dx != 0),
      isTrue,
    );
    final _ = await tester.pumpAndSettle();
    expect(find.byType(CreateWorkspaceForm), findsNothing);
    expect((await fixture.database.workspaceDao.getAllWorkspaces()).length, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final failing in [false, true]) {
    for (final management in [false, true]) {
      final testName =
          'local creation ignores cloud accounts '
          'failing=$failing management=$management';
      testWidgets(testName, (tester) async {
        final loading = Completer<List<CloudAccountSession>>();
        final fixture = _IntroFixture(
          accountsLoad: () => failing
              ? Future.error(StateError('account store unavailable'))
              : loading.future,
          management: management,
        );
        addTearDown(fixture.dispose);
        await tester.runAsync(() => tester.pumpWidget(fixture.buildApp()));
        if (!management) {
          await _chooseIntroRoute(tester, 'local');
        }
        await _pumpUntilFound(tester, find.byType(AuraInput));
        await tester.enterText(find.byType(AuraInput), 'Local only');
        await tester.testTextInput.receiveAction(.done);
        await _pumpUntilFound(
          tester,
          management
              ? find.textContaining('new chat:')
              : find.text('Workspace created'),
        );
        final _ = await tester.pumpAndSettle();
        expect(
          (await fixture.database.workspaceDao.getAllWorkspaces()).single.name,
          'Local only',
        );
        expect(
          find.byKey(const Key('workspace_operation_error')),
          findsNothing,
        );
        expect(find.byKey(_backToRouteChooserKey), findsNothing);
        if (!management) {
          expect(
            tester
                .widget<AuraButton>(
                  find.byKey(const Key('intro_start_chat_button')),
                )
                .disabled,
            isTrue,
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets(
    'Enter validates cloud name then opens sign-in without creating',
    (tester) async {
      final fixture = _IntroFixture();
      addTearDown(fixture.dispose);
      await tester.runAsync(() => tester.pumpWidget(fixture.buildApp()));
      await _chooseIntroRoute(tester, 'cloud');
      await tester.enterText(find.byType(AuraInput), 'ab');
      await tester.testTextInput.receiveAction(.done);
      await tester.pump();
      expect(
        find.text('Workspace name must be at least 3 characters'),
        findsOneWidget,
      );
      expect(find.byType(CloudAccountAuthContent), findsNothing);
      await tester.enterText(find.byType(AuraInput), 'Cloud project');
      await tester.testTextInput.receiveAction(.done);
      final _ = await tester.pumpAndSettle();
      expect(find.byType(CloudAccountAuthContent), findsOneWidget);
      expect(await fixture.database.workspaceDao.getAllWorkspaces(), isEmpty);
      final _ = await tester.binding.handlePopRoute();
      final _ = await tester.pumpAndSettle();
      expect(find.text('Cloud project'), findsOneWidget);
      expect(find.text('Discard unsaved changes?'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final reducedMotion in [false, true]) {
    testWidgets('welcome finishes before setup reducedMotion=$reducedMotion', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fixture = _IntroFixture();
      addTearDown(fixture.dispose);
      await tester.runAsync(
        () => tester.pumpWidget(fixture.buildApp(reducedMotion: reducedMotion)),
      );
      await _pumpUntilFound(tester, find.byKey(_quickStartKey));
      expect(find.text('What would you like help with today?'), findsOneWidget);
      expect(find.text('1 of 4'), findsOneWidget);
      expect(find.byKey(_localRouteKey).hitTestable(), findsNothing);
      expect(find.byKey(_welcomeBackKey), findsNothing);

      await tester.tap(find.byKey(const Key('intro_progress_1')));
      await tester.pump();
      final pager = tester.widget<PageView>(
        find.byKey(const Key('intro_welcome_pages')),
      );
      expect(
        pager.controller?.position.isScrollingNotifier.value,
        !reducedMotion,
      );
      final _ = await tester.pumpAndSettle();
      expect(find.text('2 of 4'), findsOneWidget);
      await tester.tap(find.byKey(const Key('intro_progress_0')));
      final _ = await tester.pumpAndSettle();
      expect(find.text('1 of 4'), findsOneWidget);

      if (reducedMotion) {
        final _ = await tester.sendKeyEvent(.arrowRight);
      } else {
        await tester.drag(
          find.byKey(const Key('intro_welcome_pages')),
          const Offset(-300, 0),
        );
      }
      final _ = await tester.pumpAndSettle();
      expect(find.text('2 of 4'), findsOneWidget);
      await tester.tap(find.byKey(_welcomeNextKey));
      final _ = await tester.pumpAndSettle();
      expect(find.text('3 of 4'), findsOneWidget);
      expect(find.text('''Connect AI when you're ready'''), findsOneWidget);
      expect(find.byKey(_localRouteKey).hitTestable(), findsNothing);
      await tester.tap(find.byKey(_welcomeNextKey));
      final _ = await tester.pumpAndSettle();
      await _pumpUntilFound(tester, find.byKey(_localRouteKey));
      expect(find.byKey(_cloudRouteKey), findsOneWidget);
      expect(find.byKey(_welcomeNextKey), findsNothing);
      expect(find.text('What would you like help with today?'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('Intro asks a route before showing its locked form', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _IntroFixture(accounts: [_account]);
    addTearDown(fixture.dispose);
    await tester.runAsync(() => tester.pumpWidget(fixture.buildApp()));
    await _completeWelcome(tester);
    await _pumpUntilFound(tester, find.byKey(_localRouteKey));

    expect(find.byKey(_cloudRouteKey), findsOneWidget);
    expect(find.text('Create local'), findsOneWidget);
    expect(find.text('Create cloud'), findsOneWidget);
    expect(find.byType(AuraInput), findsNothing);
    expect(find.byType(AuraDropdownSelector<String>), findsNothing);
    expect(find.byKey(_connectExistingKey), findsOneWidget);

    await _chooseIntroRoute(tester, 'local');
    expect(find.byType(AuraDropdownSelector<String>), findsNothing);
    expect(find.text('Add cloud account'), findsNothing);
    expect(find.byKey(_connectExistingKey), findsNothing);

    await tester.enterText(find.byType(AuraInput), 'Retained workspace');
    await _tapVisible(tester, find.byKey(_backToRouteChooserKey));
    expect(find.byType(AuraInput), findsNothing);
    final draft = fixture.container.read(
      workspaceCreationDraftProvider('intro'),
    );
    expect(draft.name, 'Retained workspace');
    expect(draft.intent.name, 'local');

    await _chooseIntroRoute(tester, 'cloud');
    expect(find.text('Retained workspace'), findsOneWidget);
    expect(find.byType(AuraDropdownSelector<String>), findsOneWidget);
    expect(
      tester
          .widget<AuraDropdownSelector<String>>(
            find.byType(AuraDropdownSelector<String>),
          )
          .value,
      CloudAccountIdentity.accountIdentity(_account.serverUrl, _account.userId),
    );
    await _tapVisible(tester, find.byKey(_backToRouteChooserKey));
    await _chooseIntroRoute(tester, 'local');
    expect(find.text('Retained workspace'), findsOneWidget);
    expect(find.byType(AuraDropdownSelector<String>), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('cloud draft and account survive chooser and connect returns', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _IntroFixture(accounts: [_account, _secondAccount]);
    addTearDown(fixture.dispose);
    await tester.runAsync(() => tester.pumpWidget(fixture.buildApp()));
    await _chooseIntroRoute(tester, 'cloud');
    await _selectCloudAccount(tester, _secondAccount);
    await tester.enterText(find.byType(AuraInput), 'Retained workspace');
    final target = CloudAccountIdentity.accountIdentity(
      _secondAccount.serverUrl,
      _secondAccount.userId,
    );

    expect(
      fixture.container.read(workspaceCreationDraftProvider('intro')).name,
      'Retained workspace',
    );
    expect(
      fixture.container.read(workspaceCreationDraftProvider('intro')).target,
      target,
    );
    await _tapVisible(tester, find.byKey(_backToRouteChooserKey));
    expect(find.byType(AuraInput), findsNothing);
    await _chooseIntroRoute(tester, 'cloud');
    expect(find.text('Retained workspace'), findsOneWidget);

    await _openConnectExisting(tester);
    expect(find.byKey(_backToCreationKey), findsOneWidget);
    expect(
      fixture.container.read(workspaceCreationDraftProvider('intro')).target,
      target,
    );
    await _tapVisible(tester, find.byKey(_backToCreationKey));
    final _ = await tester.pumpAndSettle();
    await _chooseIntroRoute(tester, 'cloud');
    final selector = tester.widget<AuraDropdownSelector<String>>(
      find.byType(AuraDropdownSelector<String>),
    );
    expect(selector.value, target);
    expect(find.text('Retained workspace'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('management setup keeps intent selector by default', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _IntroFixture(management: true);
    addTearDown(fixture.dispose);
    await tester.runAsync(() => tester.pumpWidget(fixture.buildApp()));
    await _pumpUntilFound(
      tester,
      find.byKey(const Key('workspace_intent_local')),
    );
    await _pumpUntilFound(tester, find.text('Add another account'));

    for (final intent in ['local', 'cloud', 'connect']) {
      expect(find.byKey(.new('workspace_intent_$intent')), findsOneWidget);
    }
    expect(find.text('Add another account'), findsOneWidget);
    expect(find.text('Add cloud account'), findsNothing);
    expect(find.byKey(_connectExistingKey), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('canceling connect account auth returns to discovery unchanged', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _IntroFixture();
    addTearDown(fixture.dispose);
    await tester.runAsync(() => tester.pumpWidget(fixture.buildApp()));
    await _chooseIntroRoute(tester, 'local');
    await tester.enterText(find.byType(AuraInput), 'Keep local draft');
    await _openConnectExisting(tester);
    await _tapVisible(
      tester,
      find.widgetWithText(AuraButton, 'Add cloud account'),
    );
    await _pumpUntilFound(tester, find.byType(CloudAccountAuthContent));

    tester
        .widget<CloudAccountAuthContent>(find.byType(CloudAccountAuthContent))
        .onCancel();
    final _ = await tester.pumpAndSettle();

    final draft = fixture.container.read(
      workspaceCreationDraftProvider('intro'),
    );
    expect(draft.name, 'Keep local draft');
    expect(draft.intent.name, 'local');
    expect(draft.target, isEmpty);
    expect(find.byKey(_backToCreationKey), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final management in [false, true]) {
    for (final failFirst in [false, true]) {
      testWidgets(
        'pending create keeps owner management=$management failure=$failFirst',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(1000, 1400));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final pending = Completer<CloudWorkspaceSummary>();
          final client = _Client();
          final endpoint = _CloudEndpoint();
          when(() => client.cloudWorkspace).thenReturn(endpoint);
          registerFallbackValue(
            CreateCloudWorkspaceRequest(name: 'Project', requestId: 'request'),
          );
          var requests = 0;
          when(() => endpoint.createWorkspace(any())).thenAnswer((_) {
            requests++;

            return requests == 1 ? pending.future : Future.value(_summary());
          });
          final fixture = _IntroFixture(
            accounts: [_account],
            client: client,
            management: management,
          );
          addTearDown(fixture.dispose);
          await tester.runAsync(() => tester.pumpWidget(fixture.buildApp()));
          if (management) {
            await _pumpUntilFound(tester, find.byType(AuraInput));
          } else {
            await _chooseIntroRoute(tester, 'cloud');
          }
          await tester.enterText(find.byType(AuraInput), 'Cloud draft');
          if (management) {
            await _tapVisible(
              tester,
              find.byKey(const Key('workspace_intent_cloud')),
            );
          } else {
            await _selectCloudAccount(tester, _account);
          }
          final _ = await tester.pumpAndSettle();
          final create = tester.widget<AuraButton>(
            find.byKey(_createWorkspaceKey),
          );
          final local = management
              ? tester.widget<AuraButton>(
                  find.byKey(const Key('workspace_intent_local')),
                )
              : null;
          final addAccount = tester.widget<AuraButton>(
            find.widgetWithText(AuraButton, 'Add another account'),
          );
          create.onPressed();
          // Retained callbacks model a second event before the disabled frame.
          local?.onPressed();
          // Creation branch cannot select discovery.
          addAccount.onPressed();
          create.onPressed();
          await tester.pump(const Duration(milliseconds: 100));
          expect(requests, 1);
          expect(find.byType(CloudAccountAuthContent), findsNothing);
          if (management) {
            for (final intent in ['local', 'cloud', 'connect']) {
              expect(
                tester
                    .widget<AuraButton>(
                      find.byKey(.new('workspace_intent_$intent')),
                    )
                    .disabled,
                isTrue,
              );
            }
          } else {
            expect(
              tester
                  .widget<AuraIconButton>(find.byKey(_backToRouteChooserKey))
                  .onPressed,
              isNull,
            );
          }
          expect(
            tester
                .widget<AuraButton>(
                  find.widgetWithText(AuraButton, 'Add another account'),
                )
                .disabled,
            isTrue,
          );
          final scope = find.byType(DraftExitScope).last;
          expect(
            await tester
                .widget<DraftExitScope>(scope)
                .guard
                .canExit(tester.element(scope)),
            isFalse,
          );
          if (failFirst) {
            pending.completeError(
              const AppCloudWorkspaceException('cloud_errors.unavailable'),
            );
            final _ = await tester.pumpAndSettle();
            expect(
              await fixture.database.workspaceDao.getAllWorkspaces(),
              isEmpty,
            );
            expect(find.text('Cloud draft'), findsOneWidget);
            expect(
              tester
                  .widget<AuraButton>(find.byKey(_createWorkspaceKey))
                  .disabled,
              isFalse,
            );
            if (management) {
              expect(
                tester
                    .widget<AuraButton>(
                      find.byKey(const Key('workspace_intent_cloud')),
                    )
                    .variant,
                AuraButtonVariant.primary,
              );
            }
            await tester.tap(find.text('Add another account'));
            final _ = await tester.pumpAndSettle();
            tester
                .widget<CloudAccountAuthContent>(
                  find.byType(CloudAccountAuthContent),
                )
                .onCancel();
            final _ = await tester.pumpAndSettle();
            expect(find.text('Cloud draft'), findsOneWidget);
            await tester.tap(find.byKey(_createWorkspaceKey));
          } else {
            pending.complete(_summary());
          }
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
          });
          final _ = await tester.pumpAndSettle();
          final rows = await fixture.database.workspaceDao.getAllWorkspaces();
          expect(rows, hasLength(1));
          expect(rows.single.cloudWorkspaceId, '11');
          expect(rows.single.cloudAccountId, _account.userId);
          expect(requests, failFirst ? 2 : 1);
          if (management) {
            expect(find.text('new chat: ${rows.single.id}'), findsOneWidget);
          } else {
            expect(find.text('Workspace created'), findsOneWidget);
            await _tapVisible(tester, find.byKey(_skipAiKey));
            await _pumpUntilFound(
              tester,
              find.text('new chat: ${rows.single.id}'),
            );
          }
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  testWidgets('zero-workspace discovery retries and reauth keeps its task', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var attempts = 0;
    final fixture = _IntroFixture(
      accounts: [_account],
      load: () async {
        attempts++;
        if (attempts == 1) throw StateError('offline');

        return const .authenticationRequired();
      },
    );
    addTearDown(fixture.dispose);
    await tester.runAsync(() => tester.pumpWidget(fixture.buildApp()));
    await _chooseIntroRoute(tester, 'local');
    await tester.enterText(find.byType(AuraInput), 'Keep through retry');
    await _openConnectExisting(tester);
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    final _ = await tester.pumpAndSettle();
    expect(attempts, 2);
    await tester.tap(find.text('Session expired. Sign in again.'));
    final _ = await tester.pumpAndSettle();
    final auth = tester.widget<CloudAccountAuthContent>(
      find.byType(CloudAccountAuthContent),
    );
    expect(auth.target.accountId, _account.userId);
    expect(auth.target.serverUrl, _account.serverUrl);
    auth.onCancel();
    final _ = await tester.pumpAndSettle();
    expect(
      fixture.container.read(workspaceCreationDraftProvider('intro')).name,
      'Keep through retry',
    );
    expect(
      fixture.container.read(workspaceCreationDraftProvider('intro')).target,
      isEmpty,
    );
    expect(find.byKey(_backToCreationKey), findsOneWidget);
    expect(
      fixture.container
          .read(workspaceCreationDraftProvider('intro'))
          .intent
          .name,
      'local',
    );
    expect(await fixture.database.workspaceDao.getAllWorkspaces(), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final accept in [false, true]) {
    testWidgets('zero-workspace invitation accept=$accept uses its account', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final client = _Client();
      final endpoint = _CloudEndpoint();
      when(() => client.cloudWorkspace).thenReturn(endpoint);
      registerFallbackValue(
        AcceptWorkspaceInviteRequest(
          inviteId: 7,
          requestId: 'fixture',
          expectedInviteRevision: 2,
        ),
      );
      registerFallbackValue(
        DeclineWorkspaceInviteRequest(
          inviteId: 7,
          requestId: 'fixture',
          expectedInviteRevision: 2,
        ),
      );
      var responded = false;
      when(() => endpoint.acceptInvite(any())).thenAnswer((_) async {
        responded = true;

        return _summary();
      });
      when(() => endpoint.declineInvite(any())).thenAnswer((_) {
        responded = true;

        return .value();
      });
      final fixture = _IntroFixture(
        accounts: [_account],
        client: client,
        load: () async => .new(
          workspaces: [],
          pendingInvites: responded
              ? []
              : [
                  PendingWorkspaceInviteSummary(
                    id: 7,
                    workspaceId: 11,
                    workspaceName: 'Invited project',
                    email: _account.email,
                    role: 'member',
                    revision: 2,
                    createdAt: .new(2026),
                  ),
                ],
        ),
      );
      addTearDown(fixture.dispose);
      await tester.runAsync(() => tester.pumpWidget(fixture.buildApp()));
      await _chooseIntroRoute(tester, 'local');
      await _openConnectExisting(tester);
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text(accept ? 'Accept' : 'Decline'));
      final _ = await tester.pumpAndSettle();
      expect(responded, isTrue);
      final rows = await fixture.database.workspaceDao.getAllWorkspaces();
      if (accept) {
        expect(rows, hasLength(1));
        expect(rows.single.cloudWorkspaceId, '11');
        expect(rows.single.cloudAccountId, _account.userId);
        expect(find.text('Workspace joined'), findsOneWidget);
      } else {
        expect(rows, isEmpty);
        expect(find.text('Invited project'), findsNothing);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final intent in ['cloud', 'connect']) {
    testWidgets('zero workspace $intent uses returned cloud mirror', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final accounts = <CloudAccountSession>[];
      final client = _Client();
      final endpoint = _CloudEndpoint();
      when(() => client.cloudWorkspace).thenReturn(endpoint);
      registerFallbackValue(
        CreateCloudWorkspaceRequest(name: 'Project', requestId: 'request'),
      );
      when(() => endpoint.createWorkspace(any()))
          .thenAnswer((_) async => _summary());
      final fixture = _IntroFixture(accounts: accounts, client: client);
      addTearDown(fixture.dispose);
      await tester.runAsync(() => tester.pumpWidget(fixture.buildApp()));
      await _chooseIntroRoute(tester, intent == 'cloud' ? 'cloud' : 'local');
      await tester.enterText(find.byType(AuraInput), 'Cloud draft');
      if (intent == 'cloud') {
        await _tapVisible(
          tester,
          find.widgetWithText(AuraButton, 'Sign in to continue'),
        );
      } else {
        await _openConnectExisting(tester);
        await _tapVisible(
          tester,
          find.widgetWithText(AuraButton, 'Add cloud account'),
        );
      }
      await _pumpUntilFound(tester, find.byType(CloudAccountAuthContent));
      expect(await fixture.database.workspaceDao.getAllWorkspaces(), isEmpty);
      expect(
        fixture.container.read(workspaceCreationDraftProvider('intro')).name,
        'Cloud draft',
      );
      accounts.add(_account);
      fixture.container.invalidate(cloudAccountsProvider);
      tester
          .widget<CloudAccountAuthContent>(find.byType(CloudAccountAuthContent))
          .onSignedIn(_account);
      await tester.pump();
      final _ = await tester.pumpAndSettle();
      if (intent == 'cloud') {
        expect(find.text('Cloud draft'), findsOneWidget);
        expect(
          tester
              .widget<AuraDropdownSelector<String>>(
                find.byType(AuraDropdownSelector<String>),
              )
              .value,
          CloudAccountIdentity.accountIdentity(
            _account.serverUrl,
            _account.userId,
          ),
        );
        expect(find.text('Add another account'), findsOneWidget);
        await _tapVisible(tester, find.byKey(_createWorkspaceKey));
      } else {
        final draft = fixture.container.read(
          workspaceCreationDraftProvider('intro'),
        );
        expect(draft.intent.name, 'local');
        expect(draft.target, isEmpty);
        await _tapVisible(tester, find.widgetWithText(AuraButton, 'Connect'));
      }
      await _pumpUntilFound(
        tester,
        find.text(
          intent == 'cloud' ? 'Workspace created' : 'Workspace connected',
        ),
      );
      final rows = await fixture.database.workspaceDao.getAllWorkspaces();
      expect(rows, hasLength(1));
      expect(rows.single.cloudWorkspaceId, '11');
      expect(rows.single.cloudAccountId, _account.userId);
      await _tapVisible(tester, find.byKey(_skipAiKey));
      await _pumpUntilFound(tester, find.text('new chat: ${rows.single.id}'));
      if (intent == 'connect') {
        final _ = verifyNever(() => endpoint.createWorkspace(any()));
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final mode in ['Sign in', 'Create new account', 'Forgot password?']) {
    testWidgets('Intro retains name and cloud intent after $mode cancel', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fixture = _IntroFixture();
      addTearDown(fixture.dispose);
      await tester.runAsync(() => tester.pumpWidget(fixture.buildApp()));
      await _chooseIntroRoute(tester, 'cloud');
      await tester.enterText(find.byType(AuraInput), 'Retained name');
      await _tapVisible(
        tester,
        find.widgetWithText(AuraButton, 'Sign in to continue'),
      );
      await _pumpUntilFound(tester, find.byType(CloudAccountAuthContent));
      if (mode != 'Sign in') {
        await _tapVisible(tester, find.text(mode).last);
        final _ = await tester.pumpAndSettle();
      }
      tester
          .widget<CloudAccountAuthContent>(find.byType(CloudAccountAuthContent))
          .onCancel();
      final _ = await tester.pumpAndSettle();
      expect(find.text('Retained name'), findsOneWidget);
      expect(
        fixture.container
            .read(workspaceCreationDraftProvider('intro'))
            .intent
            .name,
        'cloud',
      );
      expect(await fixture.database.workspaceDao.getAllWorkspaces(), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('creates workspace and routes skip and AI setup actions', (
    tester,
  ) async {
    final fixture = _IntroFixture();
    addTearDown(fixture.dispose);

    await tester.runAsync(() => tester.pumpWidget(fixture.buildApp()));
    await _chooseIntroRoute(tester, 'local');

    expect(find.text('Name your local workspace'), findsOneWidget);

    await _pumpUntilFound(tester, find.byKey(_createWorkspaceKey));
    await _pumpUntilFound(tester, find.byKey(_createWorkspaceKey));

    await tester.enterText(find.byType(AuraInput), 'ab');
    await _tapVisible(tester, find.byKey(_createWorkspaceKey));
    await _pumpUntilFound(
      tester,
      find.text('Workspace name must be at least 3 characters'),
    );

    await tester.enterText(find.byType(AuraInput), 'a' * 21);
    await _tapVisible(tester, find.byKey(_createWorkspaceKey));
    await _pumpUntilFound(
      tester,
      find.text('Workspace name must be at most 20 characters'),
    );

    await tester.enterText(find.byType(AuraInput), 'Project');
    await _tapVisible(tester, find.byKey(_createWorkspaceKey));
    await _pumpUntilFound(tester, find.text('Workspace created'));

    final workspaces = await fixture.database.workspaceDao.getAllWorkspaces();
    expect(workspaces.single.name, 'Project');

    await _tapVisible(tester, find.byKey(_skipAiKey));
    await _pumpUntilFound(tester, find.textContaining('new chat:'));

    final connectFixture = _IntroFixture();
    addTearDown(connectFixture.dispose);

    await tester.runAsync(() => tester.pumpWidget(connectFixture.buildApp()));
    await _createWorkspace(tester, 'Connect');
    await _tapVisible(tester, find.byKey(_connectAiKey));
    await _pumpUntilFound(tester, find.text('Connect AI'));
    expect(find.text('Select Model'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

const _connectAiKey = Key('workspace_add_model_provider');
const _createWorkspaceKey = Key('intro_create_workspace_button');
const _localRouteKey = Key('intro_route_local_button');
const _cloudRouteKey = Key('intro_route_cloud_button');
const _backToRouteChooserKey = Key('intro_back_to_route_chooser_button');
const _connectExistingKey = Key('intro_connect_existing_button');
const _backToCreationKey = Key('workspace_setup_back_to_creation_button');
const _skipAiKey = Key('intro_skip_ai_button');
const _welcomeNextKey = Key('intro_welcome_next_button');
const _welcomeBackKey = Key('intro_welcome_back_button');
const _quickStartKey = Key('intro_quick_start_button');
const _advancedSetupKey = Key('intro_advanced_setup_button');
const _welcomeSkipKey = Key('intro_welcome_skip_button');
const _dayStarterKey = ValueKey<String>('intro_starter_plan_day');
const _shoppingStarterKey = ValueKey<String>('intro_starter_shopping_list');
const _messageStarterKey = ValueKey<String>('intro_starter_personal_message');

Future<void> _pumpFrame(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _closeIntroWidget(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 10));
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await _pumpFrame(tester);
    if (finder.evaluate().isNotEmpty) return;
  }

  expect(finder, findsOneWidget);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) {
    await tester.ensureVisible(finder);
  } else {
    await tester.scrollUntilVisible(
      finder,
      100,
      scrollable: find.byType(Scrollable).first,
    );
  }
  final _ = await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _openConnectExisting(WidgetTester tester) async {
  if (find.byKey(_backToRouteChooserKey).evaluate().isNotEmpty) {
    await _tapVisible(tester, find.byKey(_backToRouteChooserKey));
    final _ = await tester.pumpAndSettle();
  }
  await _tapVisible(tester, find.byKey(_connectExistingKey));
  final _ = await tester.pumpAndSettle();
}

Future<void> _chooseIntroRoute(WidgetTester tester, String route) async {
  await _pumpFrame(tester);
  if (find.byKey(_localRouteKey).hitTestable().evaluate().isEmpty) {
    await _completeWelcome(tester);
  }
  final button = find.byKey(route == 'local' ? _localRouteKey : _cloudRouteKey);
  await _pumpUntilFound(tester, button);
  await _tapVisible(tester, button);
  await _pumpUntilFound(tester, find.byType(AuraInput));
}

Future<void> _completeWelcome(WidgetTester tester) async {
  if (find.byKey(_advancedSetupKey).evaluate().isEmpty) {
    await _tapVisible(tester, find.byKey(const Key('intro_progress_0')));
    final _ = await tester.pumpAndSettle();
  }
  await _tapVisible(tester, find.byKey(_advancedSetupKey));
  await _pumpUntilFound(tester, find.byKey(_localRouteKey));
}

Future<void> _selectCloudAccount(
  WidgetTester tester,
  CloudAccountSession account,
) async {
  await _tapVisible(tester, find.byType(AuraDropdownSelector<String>));
  final _ = await tester.pumpAndSettle();
  await tester.tap(find.text('${account.email} (${account.serverUrl})').last);
  final _ = await tester.pumpAndSettle();
}

Future<void> _createWorkspace(WidgetTester tester, String name) async {
  await _chooseIntroRoute(tester, 'local');
  await _pumpUntilFound(tester, find.byKey(_createWorkspaceKey));
  expect(find.text('Name your local workspace'), findsOneWidget);

  await _pumpUntilFound(tester, find.byKey(_createWorkspaceKey));
  await _pumpUntilFound(tester, find.byKey(_createWorkspaceKey));

  await tester.enterText(find.byType(AuraInput), name);
  await _tapVisible(tester, find.byKey(_createWorkspaceKey));
  await _pumpUntilFound(tester, find.text('Workspace created'));
}

class _IntroFixture {
  new({
    List<CloudAccountSession> accounts = const [],
    Client? client,
    Future<CloudWorkspaceViewState?> Function()? load,
    Future<List<CloudAccountSession>> Function()? accountsLoad,
    bool management = false,
    CreateWorkspaceUseCase? createWorkspaceUseCase,
  }) : this._(
         .new(connection: NativeDatabase.memory()),
         accounts,
         client,
         load,
         accountsLoad,
         management,
         createWorkspaceUseCase,
       );

  new _(
    this.database,
    List<CloudAccountSession> accounts,
    Client? client,
    Future<CloudWorkspaceViewState?> Function()? load,
    Future<List<CloudAccountSession>> Function()? accountsLoad,
    bool management,
    CreateWorkspaceUseCase? createWorkspaceUseCase,
  ) : container = .new(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          if (createWorkspaceUseCase != null)
            createWorkspaceUseCaseProvider.overrideWithValue(
              createWorkspaceUseCase,
            ),
          chatModelConnectionsProvider.overrideWith(
            (ref, workspaceId) => Stream.value([]),
          ),
          listModelsGroupedByProviderProvider.overrideWith(
            (ref, workspaceId) => Stream.value({}),
          ),
          apiModelProvidersProvider.overrideWith(
            (ref, workspaceId) async => [],
          ),
          cloudAccountsProvider.overrideWith(
            (ref) async =>
                accountsLoad != null ? await accountsLoad() : accounts,
          ),
          cloudWorkspaceStateProvider.overrideWith(
            (ref, key) async => load != null
                ? await load()
                : .new(workspaces: [_summary()], pendingInvites: []),
          ),
          if (client != null)
            cloudWorkspaceUseCasesProvider.overrideWith(
              (ref, key) async => CloudWorkspaceUseCases(
                cloudRepository: .new(client),
                workspaceRepository: .new(database),
                cloudAccountId: key.accountId,
                serverUrl: key.serverUrl,
              ),
            ),
        ],
      ),
      router = GoRouter(
        routes: [
          GoRoute(
            path: '/create',
            builder: (_, _) =>
                const CreateWorkspaceScreen(workspaceId: 'origin'),
          ),
          GoRoute(
            path: '/intro',
            builder: (context, state) => const IntroScreen(),
          ),
          GoRoute(
            path: '/workspaces/:workspaceId/chat/new',
            builder: (context, state) {
              final draft = state.extra;
              final location =
                  'new chat: ${state.pathParameters['workspaceId']}';
              if (draft is ChatDraft) {
                return Column(
                  mainAxisSize: .min,
                  children: [Text(location), Text('draft: ${draft.text}')],
                );
              }

              return Text(location);
            },
          ),
          GoRoute(
            path: '/workspaces/:workspaceId/more/service-connections/new',
            builder: (context, state) {
              return Text(
                'service connection: ${state.uri.queryParameters['type']}',
              );
            },
          ),
        ],
        initialLocation: management ? '/create' : '/intro',
      );

  final AppDatabase database;
  final ProviderContainer container;
  final GoRouter router;

  Widget buildApp({
    bool reducedMotion = false,
    Locale startLocale = const Locale('en'),
  }) {
    return EasyLocalization(
      key: UniqueKey(),
      child: Builder(
        builder: (context) {
          return UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(disableAnimations: reducedMotion),
                child: AuraLegacyMaterialBridge(
                  child: Portal(child: child ?? const SizedBox.shrink()),
                ),
              ),
              locale: context.locale,
              localizationsDelegates: [
                ...GlobalMaterialLocalizations.delegates,
                sdk_localizations.GlobalMaterialLocalizations.delegate,
                ...context.localizationDelegates,
              ],
              supportedLocales: context.supportedLocales,
            ),
          );
        },
      ),
      supportedLocales: const [Locale('en'), Locale('es')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: startLocale,
      useOnlyLangCode: true,
      useFallbackTranslations: true,
      saveLocale: false,
    );
  }

  Future<void> dispose() async {
    router.dispose();
    container.dispose();
    await database.close();
  }
}

const _account = CloudAccountSession(
  serverUrl: 'https://cloud.example',
  userId: 'account',
  email: 'cloud@example.com',
);
const _secondAccount = CloudAccountSession(
  serverUrl: 'https://another-cloud.example',
  userId: 'another-account',
  email: 'another@example.com',
);
class _Client extends Mock implements Client;
class _CloudEndpoint extends Mock implements EndpointCloudWorkspace;
class _CreateWorkspaceUseCase extends Mock implements CreateWorkspaceUseCase;
CloudWorkspaceSummary _summary() => CloudWorkspaceSummary(
  id: 11,
  name: 'Cloud draft',
  role: 'owner',
  revision: 1,
  sequence: 1,
  createdAt: .new(2026),
  updatedAt: .new(2026),
);
