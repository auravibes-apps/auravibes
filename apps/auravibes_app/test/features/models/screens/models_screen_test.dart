// ignore_for_file: scoped_providers_should_specify_dependencies
// Required: widget tests override scoped providers directly.

import 'package:auravibes_app/features/models/providers/workspace_model_connections_providers.dart';
import 'package:auravibes_app/features/models/screens/models_screen.dart';
import 'package:auravibes_app/features/models/widgets/list_model_connections_widget.dart';
import 'package:auravibes_app/widgets/app_content.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_provider_scope.dart';

void main() {
  Widget buildSubject() {
    return EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      useFallbackTranslations: true,
      useOnlyLangCode: true,
      child: TestProviderScope(
        overrides: [
          listWorkspaceModelConnectionsProvider.overrideWith(
            (ref, workspaceId) => [],
          ),
        ],
        child: Builder(
          builder: (context) {
            return MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Theme(
                data: ThemeData(extensions: [AuraTheme.light]),
                child: const Scaffold(
                  body: ModelsScreen(workspaceId: 'ws-1'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> pumpAndInit(WidgetTester tester, Widget widget) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
    });
    await tester.pump();
    await tester.pump();
  }

  testWidgets('renders ModelsScreen', (tester) async {
    await pumpAndInit(tester, buildSubject());
    expect(find.byType(ModelsScreen), findsOneWidget);
  });

  testWidgets('renders app bar', (tester) async {
    await pumpAndInit(tester, buildSubject());
    expect(find.byType(AuraAppBar), findsOneWidget);
  });

  testWidgets('renders add model button', (tester) async {
    await pumpAndInit(tester, buildSubject());
    expect(find.byType(AuraButton), findsOneWidget);
  });

  test('constructor sets workspaceId', () {
    const screen = ModelsScreen(workspaceId: 'test-ws');
    expect(screen.workspaceId, 'test-ws');
  });

  testWidgets('renders inside AuraScreen', (tester) async {
    await pumpAndInit(tester, buildSubject());
    expect(find.byType(AuraScreen), findsOneWidget);
  });

  testWidgets('renders AppContent for button', (tester) async {
    await pumpAndInit(tester, buildSubject());
    expect(find.byType(AppContent), findsOneWidget);
  });

  testWidgets('renders ListModelConnectionsWidget', (tester) async {
    await pumpAndInit(tester, buildSubject());
    expect(find.byType(ListModelConnectionsWidget), findsOneWidget);
  });

  testWidgets('button is wrapped in AuraPadding', (tester) async {
    await pumpAndInit(tester, buildSubject());
    expect(find.byType(AuraPadding), findsAtLeast(1));
  });

  testWidgets('renders AuraColumn layout', (tester) async {
    await pumpAndInit(tester, buildSubject());
    expect(find.byType(AuraColumn), findsAtLeast(1));
  });

  testWidgets('contains Expanded widget for list', (tester) async {
    await pumpAndInit(tester, buildSubject());
    expect(find.byType(Expanded), findsAtLeast(1));
  });

  testWidgets('renders Row inside AppContent', (tester) async {
    await pumpAndInit(tester, buildSubject());
    expect(find.byType(Row), findsOneWidget);
  });

  test('ModelsScreen is const constructible', () {
    const screen = ModelsScreen(workspaceId: 'ws');
    expect(screen.workspaceId, 'ws');
  });

  testWidgets('back button is present and tappable', (tester) async {
    await pumpAndInit(tester, buildSubject());
    final backButton = find.byIcon(Icons.arrow_back);
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await tester.pumpAndSettle();
  });
}
