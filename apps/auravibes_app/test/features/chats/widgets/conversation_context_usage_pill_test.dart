// Required: Widget tests override scoped providers directly.

import 'package:auravibes_app/features/chats/providers/context_usage_level.dart';
import 'package:auravibes_app/features/chats/widgets/conversation_context_usage_pill.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Widget buildSubject({
    required ContextUsageData data,
    Locale locale = const Locale('en'),
  }) {
    final container = ProviderContainer(
      overrides: [
        contextUsageProvider('ws-1', 'conv-1').overrideWithValue(data),
      ],
    );
    addTearDown(container.dispose);

    return UncontrolledProviderScope(
      container: container,
      child: EasyLocalization(
        child: Builder(
          builder: (context) => MaterialApp(
            home: AuraThemeScope(
              theme: .light,
              child: Theme(
                data: .new(),
                child: const Material(
                  child: ConversationContextUsagePill(
                    workspaceId: 'ws-1',
                    conversationId: 'conv-1',
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
        fallbackLocale: locale,
        startLocale: locale,
        useOnlyLangCode: true,
        useFallbackTranslations: true,
      ),
    );
  }

  Future<void> pumpSubject(
    WidgetTester tester, {
    required ContextUsageData data,
    Locale locale = const Locale('en'),
  }) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(buildSubject(data: data, locale: locale));
    });
    final _ = await tester.pumpAndSettle();
  }

  testWidgets('renders normal usage level', (tester) async {
    final data = ContextUsageData.compute(usedTokens: 50, limitTokens: 100);

    await pumpSubject(tester, data: data);

    expect(find.byType(ConversationContextUsagePill), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.byType(AuraLinearProgressIndicator), findsOneWidget);
  });

  testWidgets('renders elevated usage level', (tester) async {
    final data = ContextUsageData.compute(usedTokens: 7500, limitTokens: 10000);

    await pumpSubject(tester, data: data);

    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
  });

  testWidgets('renders warning usage level', (tester) async {
    final data = ContextUsageData.compute(usedTokens: 8500, limitTokens: 10000);

    await pumpSubject(tester, data: data);

    expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    expect(find.text('85%'), findsOneWidget);
  });

  testWidgets('formats compact token counts with the app locale', (
    tester,
  ) async {
    final data = ContextUsageData.compute(
      usedTokens: 1500000,
      limitTokens: 2000000,
    );

    await pumpSubject(tester, data: data, locale: const Locale('es'));

    expect(find.text(data.usageLabelFor(const Locale('es'))), findsOneWidget);
  });

  testWidgets('renders overflow usage level', (tester) async {
    final data = ContextUsageData.compute(
      usedTokens: 11000,
      limitTokens: 10000,
    );

    await pumpSubject(tester, data: data);

    expect(find.byIcon(Icons.priority_high), findsOneWidget);
  });

  testWidgets('shows usage and missing limit without percentage or progress', (
    tester,
  ) async {
    final data = ContextUsageData.compute(usedTokens: 500, limitTokens: null);

    await pumpSubject(tester, data: data);

    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    expect(find.textContaining('500 tokens used'), findsOneWidget);
    expect(find.textContaining('limit unavailable'), findsOneWidget);
    expect(find.text('--'), findsNothing);
    expect(find.byType(AuraLinearProgressIndicator), findsNothing);
    expect(find.byType(AuraBadge), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Context window usage')).value,
      '500 tokens, context limit unavailable',
    );
  });

  testWidgets('localizes unavailable limit text and semantics', (tester) async {
    final data = ContextUsageData.compute(usedTokens: 500, limitTokens: null);

    await pumpSubject(tester, data: data, locale: const Locale('es'));

    expect(find.textContaining('500 tokens usados'), findsOneWidget);
    expect(find.textContaining('no disponible'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Uso de ventana de contexto'))
          .value,
      endsWith('de contexto no disponible'),
    );
  });
}
