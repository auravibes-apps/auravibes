import 'package:auravibes_app/features/chats/widgets/chat_reasoning_controls.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  final options = [
    const ReasoningOption.toggle(),
    ReasoningOption.effort(['low', 'high']),
    ReasoningOption.budgetTokens(1024, 32768),
  ];

  testWidgets('hides controls when model exposes no supported options', (
    tester,
  ) async {
    ReasoningConfiguration? changed;
    await _pumpLocalized(
      tester,
      ChatReasoningControls(
        options: [ReasoningOption.unknown('future', const {})],
        value: null,
        onChanged: (value) => changed = value,
      ),
    );

    expect(find.byType(AuraSwitch), findsNothing);
    expect(find.text('Reasoning'), findsNothing);
    expect(changed, isNull);
  });

  testWidgets('renders controls, validates bounds, and resets to default', (
    tester,
  ) async {
    ReasoningConfiguration? changed;
    await _pumpLocalized(
      tester,
      ChatReasoningControls(
        options: options,
        value: const ReasoningConfiguration(budgetTokens: 2048),
        onChanged: (value) => changed = value,
      ),
    );
    expect(find.text('Reasoning', findRichText: true), findsOneWidget);
    expect(find.byType(AuraSwitch), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('chat_reasoning_effort_disclosure')),
      findsOneWidget,
    );
    expect(find.byType(AuraInput), findsOneWidget);
    final semantics = tester.ensureSemantics();
    await tester.pump();
    expect(
      tester.getSemantics(find.byType(AuraSwitch)).label,
      startsWith('Enable reasoning'),
    );
    semantics.dispose();

    await tester.enterText(find.byType(AuraInput), '32768');
    await tester.pump();
    expect(changed?.budgetTokens, 32768);

    await tester.enterText(find.byType(AuraInput), '32769');
    await tester.pump();
    final input = tester.widget<AuraInput>(find.byType(AuraInput));
    expect(input.controller?.text, '32768');
    expect(
      find.text('Enter a whole number from 1024 to 32768.', findRichText: true),
      findsNothing,
    );
    expect(changed?.budgetTokens, 32768);

    await tester.enterText(find.byType(AuraInput), '12');
    await tester.pump();
    expect(
      find.text('Enter a whole number from 1024 to 32768.', findRichText: true),
      findsOneWidget,
    );

    await tester.enterText(find.byType(AuraInput), '4096');
    await tester.pump();
    expect(changed?.budgetTokens, 4096);

    await tester.enterText(find.byType(AuraInput), '');
    await tester.pump();
    expect(
      tester.widget<AuraInput>(find.byType(AuraInput)).controller?.text,
      isEmpty,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('chat_reasoning_reset')),
    );
    await tester.pump();
    expect(changed, isNull);
  });
}

class const _LocalizedApp({required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => EasyLocalization(
    child: Builder(
      builder: (context) => MaterialApp(
        home: Theme(
          data: .new(),
          child: Material(child: Portal(child: child)),
        ),
        builder: (_, child) => AuraThemeScope(
          theme: .light,
          child: AuraLegacyMaterialBridge(
            child: AuraSnackBarHost(child: child ?? const SizedBox.shrink()),
          ),
        ),
        locale: context.locale,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
      ),
    ),
    supportedLocales: const [Locale('en')],
    path: 'assets/i18n',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    useOnlyLangCode: true,
    useFallbackTranslations: true,
  );
}

Future<void> _pumpLocalized(WidgetTester tester, Widget child) async {
  final _ = await tester.runAsync(() async {
    await tester.pumpWidget(_LocalizedApp(child: child));
  });
  final _ = await tester.pumpAndSettle();
}
