import 'package:auravibes_app/features/chats/providers/context_usage_level.dart';
import 'package:auravibes_app/features/chats/widgets/conversation_context_usage_pill.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  Widget buildSubject({required ContextUsageData data}) {
    return EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      useFallbackTranslations: true,
      useOnlyLangCode: true,
      child: ProviderScope(
        overrides: [
          contextUsageProvider.overrideWithValue(data),
        ],
        child: MaterialApp(
          home: Theme(
            data: ThemeData(extensions: [AuraTheme.light]),
            child: const Material(
              child: ConversationContextUsagePill(),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders normal usage level', (tester) async {
    final data = ContextUsageData.compute(
      usedTokens: 50,
      limitTokens: 100,
    );

    await tester.pumpWidget(buildSubject(data: data));
    await tester.pump();
    await tester.pump();

    expect(find.byType(ConversationContextUsagePill), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('renders elevated usage level', (tester) async {
    final data = ContextUsageData.compute(
      usedTokens: 7500,
      limitTokens: 10000,
    );

    await tester.pumpWidget(buildSubject(data: data));
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
  });

  testWidgets('renders warning usage level', (tester) async {
    final data = ContextUsageData.compute(
      usedTokens: 8500,
      limitTokens: 10000,
    );

    await tester.pumpWidget(buildSubject(data: data));
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    expect(find.text('85%'), findsOneWidget);
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
    final data = ContextUsageData.compute(
      usedTokens: 500,
      limitTokens: null,
    );

    await tester.pumpWidget(buildSubject(data: data));
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    expect(find.text('--'), findsWidgets);
  });

  testWidgets('renders progress indicator', (tester) async {
    final data = ContextUsageData.compute(
      usedTokens: 50,
      limitTokens: 100,
    );

    await tester.pumpWidget(buildSubject(data: data));
    await tester.pump();
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
