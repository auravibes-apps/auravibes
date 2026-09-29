import 'package:auravibes_app/features/models/providers/add_model_provider_state.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/widgets/add_model_provider_widget.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _workspaceId = 'test-workspace';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('prompts before closing and discards a dirty form', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        apiModelProvidersProvider.overrideWith((_, _) async => const []),
        workspaceSessionForRouteProvider(_workspaceId).overrideWithValue(
          const AsyncData(
            WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: _workspaceId)),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final _ = await container.read(
      apiModelProvidersProvider(workspaceId: _workspaceId).future,
    );
    final stateSubscription = container.listen(
      addModelProviderStateProvider(_workspaceId),
      (_, next) => next,
    );
    addTearDown(stateSubscription.close);
    container
        .read(addModelProviderStateProvider(_workspaceId).notifier)
        .setModel('openai');

    final didPump = await tester.runAsync(() async {
      expect(await rootBundle.loadString('assets/i18n/en.json'), isNotEmpty);
      await tester.pumpWidget(
        EasyLocalization(
          child: UncontrolledProviderScope(
            container: container,
            child: Builder(
              builder: (context) {
                return MaterialApp(
                  routes: {
                    '/': (_) => const SizedBox.shrink(),
                    '/provider': (_) => AuraThemeScope(
                      theme: .light,
                      child: Theme(
                        data: .new(),
                        child: const Scaffold(
                          body: AddModelProviderWidget(
                            workspaceId: _workspaceId,
                          ),
                        ),
                      ),
                    ),
                  },
                  initialRoute: '/provider',
                  builder: (_, child) => AuraLegacyMaterialBridge(
                    child: AuraSnackBarHost(
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                  locale: context.locale,
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                );
              },
            ),
          ),
          supportedLocales: const [Locale('en')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          useOnlyLangCode: true,
          useFallbackTranslations: true,
        ),
      );

      return true;
    });
    expect(didPump, isTrue);
    final _ = await tester.pumpAndSettle();

    final _ = await tester.tap(find.byIcon(Icons.close));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Discard unsaved changes?'), findsOneWidget);
    expect(
      find.text('You have unsaved changes. Do you want to discard them?'),
      findsOneWidget,
    );

    final _ = await tester.tap(find.text('Keep editing'));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Discard unsaved changes?'), findsNothing);
    expect(find.byIcon(Icons.close), findsOneWidget);

    final _ = await tester.tap(find.byIcon(Icons.close));
    final _ = await tester.pumpAndSettle();
    final _ = await tester.tap(find.text('Discard'));
    final _ = await tester.pumpAndSettle();

    expect(find.byIcon(Icons.close), findsNothing);
    expect(
      container
          .read(addModelProviderStateProvider(_workspaceId))
          .hasUnsavedChanges,
      isFalse,
    );
  });
}
