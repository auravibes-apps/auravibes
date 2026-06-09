// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
import 'package:auravibes_app/features/settings/screens/more_screen.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class _FakeGoRouter implements GoRouter {
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  Widget _buildScreen({required String workspaceId}) {
    return EasyLocalization(
      child: Builder(
        builder: (context) {
          return ProviderScope(
            overrides: [
              routerProvider.overrideWithValue(_FakeGoRouter()),
            ],
            child: MaterialApp(
              home: MoreScreen(workspaceId: workspaceId),
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
            ),
          );
        },
      ),
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      useOnlyLangCode: true,
      useFallbackTranslations: true,
    );
  }

  testWidgets('renders title, tiles, and icons', (tester) async {
    await tester.pumpWidget(_buildScreen(workspaceId: 'ws-1'));
    final _ = await tester.pumpAndSettle();

    expect(find.text('More'), findsOneWidget);
    expect(find.text('Workspaces'), findsOneWidget);
    expect(find.text('Service Connections'), findsOneWidget);
    expect(find.text('Credential Definitions'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Skills'), findsOneWidget);
    expect(find.byIcon(Icons.workspaces_outlined), findsOneWidget);
    expect(find.byIcon(Icons.hub_outlined), findsOneWidget);
    expect(find.byIcon(Icons.key_outlined), findsOneWidget);
    expect(find.byIcon(Icons.build_circle_outlined), findsOneWidget);
    expect(find.byIcon(Icons.psychology_alt_outlined), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsAtLeast(5));
  });
}
