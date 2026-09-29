// Required: Widget tests override scoped providers directly.

import 'package:auravibes_app/features/chats/providers/context_usage_level.dart';
import 'package:auravibes_app/features/chats/widgets/conversation_context_usage_pill.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

void main() {
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
        child: MaterialApp(
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
          locale: locale,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('en'), Locale('es')],
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

  testWidgets('renders normal usage level', (tester) async {
    final data = ContextUsageData.compute(usedTokens: 50, limitTokens: 100);

    await tester.pumpWidget(buildSubject(data: data));
    await tester.pump();
    await tester.pump();

    expect(find.byType(ConversationContextUsagePill), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('renders elevated usage level', (tester) async {
    final data = ContextUsageData.compute(usedTokens: 7500, limitTokens: 10000);

    await tester.pumpWidget(buildSubject(data: data));
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
  });

  testWidgets('renders warning usage level', (tester) async {
    final data = ContextUsageData.compute(usedTokens: 8500, limitTokens: 10000);

    await tester.pumpWidget(buildSubject(data: data));
    await tester.pump();
    await tester.pump();

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

    await tester.pumpWidget(
      buildSubject(data: data, locale: const Locale('es')),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(data.usageLabelFor(const Locale('es'))), findsOneWidget);
  });

  testWidgets('renders overflow usage level', (tester) async {
    final data = ContextUsageData.compute(
      usedTokens: 11000,
      limitTokens: 10000,
    );

    await tester.pumpWidget(buildSubject(data: data));
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.priority_high), findsOneWidget);
  });

  testWidgets('renders unknown level when no limit', (tester) async {
    final data = ContextUsageData.compute(usedTokens: 500, limitTokens: null);

    await tester.pumpWidget(buildSubject(data: data));
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    expect(find.text('--'), findsWidgets);
  });

  testWidgets('renders progress indicator', (tester) async {
    final data = ContextUsageData.compute(usedTokens: 50, limitTokens: 100);

    await tester.pumpWidget(buildSubject(data: data));
    await tester.pump();
    await tester.pump();

    expect(find.byType(AuraLinearProgressIndicator), findsOneWidget);
  });
}
