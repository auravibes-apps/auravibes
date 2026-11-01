import 'package:auravibes_app/features/workspaces/models/workspace_location_info.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_location_status.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Widget buildSubject(
    WorkspaceLocationInfo info, {
    VoidCallback? onViewAccess,
    Locale locale = const Locale('en'),
  }) {
    return EasyLocalization(
      child: Builder(
        builder: (context) => MaterialApp(
          home: AuraThemeScope(
            theme: .light,
            child: AuraLegacyMaterialBridge(
              child: Material(
                child: WorkspaceLocationStatus(
                  info: info,
                  onViewAccess: onViewAccess,
                ),
              ),
            ),
          ),
          locale: context.locale,
          localizationsDelegates: [
            ...GlobalMaterialLocalizations.delegates,
            ...context.localizationDelegates,
          ],
          supportedLocales: context.supportedLocales,
        ),
      ),
      supportedLocales: const [Locale('en'), Locale('es')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: locale,
      useOnlyLangCode: true,
      useFallbackTranslations: true,
      saveLocale: false,
    );
  }

  Future<void> pumpSubject(
    WidgetTester tester,
    WorkspaceLocationInfo info, {
    VoidCallback? onViewAccess,
    Locale locale = const Locale('en'),
  }) async {
    await tester.runAsync(() async {
      expect(await rootBundle.loadString('assets/i18n/en.json'), isNotEmpty);
      await tester.pumpWidget(
        buildSubject(info, onViewAccess: onViewAccess, locale: locale),
      );
    });
    final _ = await tester.pumpAndSettle();
  }

  testWidgets('shows local storage location without an access link', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpSubject(tester, const WorkspaceLocationInfo(kind: .onDevice));

      expect(find.text('On this device'), findsOneWidget);
      expect(
        tester
            .getSemantics(
              find.bySemanticsIdentifier('workspace_location_status'),
            )
            .label,
        'On this device',
      );
      expect(
        find.byKey(const ValueKey<String>('workspace_location_access')),
        findsNothing,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('shows a personal cloud workspace type', (tester) async {
    await pumpSubject(
      tester,
      const WorkspaceLocationInfo(kind: .personalCloud),
    );

    expect(find.text('Personal cloud'), findsOneWidget);
  });

  testWidgets('team workspace links to members and access', (tester) async {
    var opened = false;
    await pumpSubject(
      tester,
      const WorkspaceLocationInfo(kind: .teamWorkspace, canViewMembers: true),
      onViewAccess: () => opened = true,
    );

    expect(find.text('Team workspace'), findsOneWidget);
    expect(find.text('Members and access'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('workspace_location_access')),
    );
    expect(opened, isTrue);
  });

  testWidgets('team member without roster access gets access details label', (
    tester,
  ) async {
    var opened = false;
    await pumpSubject(
      tester,
      const WorkspaceLocationInfo(kind: .teamWorkspace),
      onViewAccess: () => opened = true,
    );

    expect(find.text('Access details'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('workspace_location_access')),
    );
    expect(opened, isTrue);
  });

  testWidgets('workspace type uses Spanish copy', (tester) async {
    await pumpSubject(
      tester,
      const WorkspaceLocationInfo(kind: .teamWorkspace),
      locale: const Locale('es'),
    );

    expect(find.text('Espacio de equipo'), findsOneWidget);
  });
}
