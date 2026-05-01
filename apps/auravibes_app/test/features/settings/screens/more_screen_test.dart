import 'package:auravibes_app/features/settings/screens/more_screen.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class _FakeGoRouter implements GoRouter {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget _buildScreen({required String workspaceId}) {
    return EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      useFallbackTranslations: true,
      useOnlyLangCode: true,
      child: Builder(
        builder: (context) {
          return ProviderScope(
            overrides: [
              routerProvider.overrideWithValue(_FakeGoRouter()),
            ],
            child: MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: MoreScreen(workspaceId: workspaceId),
            ),
          );
        },
      ),
    );
  }

  testWidgets('renders title and section tiles', (tester) async {
    await tester.pumpWidget(_buildScreen(workspaceId: 'ws-1'));
    await tester.pumpAndSettle();

    expect(find.text('More'), findsOneWidget);
    expect(find.text('Workspaces'), findsOneWidget);
    expect(find.text('Model Providers'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
  });
}
