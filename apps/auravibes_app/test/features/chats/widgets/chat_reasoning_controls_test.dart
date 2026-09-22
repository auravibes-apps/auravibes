import 'package:auravibes_app/features/chats/widgets/chat_reasoning_control.dart';
import 'package:auravibes_app/features/chats/widgets/chat_reasoning_controls.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
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

    expect(find.byType(ChatReasoningControls), findsOneWidget);
    expect(find.byType(AuraSwitch), findsNothing);
    expect(find.text('Reasoning'), findsNothing);
    expect(changed, isNull);
  });

  testWidgets('summarizes off, effort, and budget states', (tester) async {
    await _pumpLocalized(
      tester,
      ChatReasoningControl(
        options: options,
        value: const ReasoningConfiguration(enabled: false),
        onChanged: _noop,
      ),
    );
    expect(find.text('Off', findRichText: true), findsOneWidget);

    await _pumpLocalized(
      tester,
      ChatReasoningControl(
        options: options,
        value: const ReasoningConfiguration(effort: 'high'),
        onChanged: _noop,
      ),
    );
    expect(find.text('high', findRichText: true), findsOneWidget);

    await _pumpLocalized(
      tester,
      ChatReasoningControl(
        options: options,
        value: const ReasoningConfiguration(budgetTokens: 8192),
        onChanged: _noop,
      ),
    );
    expect(find.text('8192', findRichText: true), findsOneWidget);
  });

  testWidgets('renders the default state as an icon-only trigger', (
    tester,
  ) async {
    await _pumpLocalized(
      tester,
      ChatReasoningControl(options: options, value: null, onChanged: _noop),
    );

    expect(
      find.byKey(const ValueKey<String>('chat_reasoning_selector')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.psychology_outlined), findsOneWidget);
    expect(find.text('Provider default', findRichText: true), findsNothing);
  });

  testWidgets('hides the trigger when no supported option is available', (
    tester,
  ) async {
    await _pumpLocalized(
      tester,
      ChatReasoningControl(
        options: [ReasoningOption.unknown('future', const {})],
        value: null,
        onChanged: _noop,
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('chat_reasoning_selector')),
      findsNothing,
    );
  });

  testWidgets('summarizes customized reasoning states compactly', (
    tester,
  ) async {
    await _pumpLocalized(
      tester,
      ChatReasoningControl(
        options: options,
        value: const ReasoningConfiguration(effort: 'high', budgetTokens: 8192),
        onChanged: _noop,
      ),
    );

    expect(find.text('Custom', findRichText: true), findsOneWidget);
  });

  testWidgets('opens wide editor with in-panel Effort choices', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await _pumpLocalized(
      tester,
      ChatReasoningControl(options: options, value: null, onChanged: _noop),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('chat_reasoning_selector')),
    );
    await tester.pump();

    expect(find.text('Reasoning', findRichText: true), findsOneWidget);
    expect(find.byType(AuraSwitch), findsOneWidget);
    final popupRect = tester.getRect(find.byType(AuraCard));
    final controlsRect = tester.getRect(find.byType(ChatReasoningControls));
    expect(controlsRect.left, greaterThan(popupRect.left));
    expect(controlsRect.right, lessThan(popupRect.right));
    expect(
      find.byKey(const ValueKey<String>('chat_reasoning_effort_disclosure')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('chat_reasoning_effort_choices')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('chat_reasoning_effort_disclosure')),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('chat_reasoning_effort_choices')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('chat_reasoning_effort_choice_low')),
      findsOneWidget,
    );
    expect(find.byType(AuraDropdownSelector<String>), findsNothing);
  });

  testWidgets('opens a narrow layout editor in a bottom sheet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await _pumpLocalized(
      tester,
      ChatReasoningControl(options: options, value: null, onChanged: _noop),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('chat_reasoning_selector')),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(ModalBarrier), findsOneWidget);
    expect(find.byType(ChatReasoningControls), findsOneWidget);
    expect(find.text('Reasoning', findRichText: true), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('chat_reasoning_effort_choices')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('chat_reasoning_effort_disclosure')),
    );
    final _ = await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('chat_reasoning_effort_choice_high')),
      findsOneWidget,
    );

    expect(await tester.sendKeyEvent(.escape), isTrue);
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('chat_reasoning_effort_choices')),
      findsNothing,
    );
    expect(find.byType(ChatReasoningControls), findsOneWidget);

    expect(await tester.sendKeyEvent(.escape), isTrue);
    final _ = await tester.pumpAndSettle();
    expect(find.byType(ChatReasoningControls), findsNothing);
  });

  testWidgets('selection collapses choices and keeps editor open', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    ReasoningConfiguration? changed;
    await _pumpLocalized(
      tester,
      ChatReasoningControl(
        options: [
          ReasoningOption.effort(['none', 'low']),
        ],
        value: null,
        onChanged: (value) => changed = value,
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('chat_reasoning_selector')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('chat_reasoning_effort_disclosure')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('chat_reasoning_effort_choice_none')),
    );
    await tester.pump();

    expect(changed?.effort, 'none');
    expect(find.text('none', findRichText: true), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('chat_reasoning_effort_choices')),
      findsNothing,
    );
    expect(find.byType(ChatReasoningControls), findsOneWidget);
    expect(find.text('Reasoning', findRichText: true), findsOneWidget);
  });

  testWidgets('Escape collapses Effort before closing the popup', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await _pumpLocalized(
      tester,
      ChatReasoningControl(options: options, value: null, onChanged: _noop),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('chat_reasoning_selector')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('chat_reasoning_effort_disclosure')),
    );
    await tester.pump();

    expect(await tester.sendKeyEvent(.escape), isTrue);
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('chat_reasoning_effort_choices')),
      findsNothing,
    );
    expect(find.byType(ChatReasoningControls), findsOneWidget);

    expect(await tester.sendKeyEvent(.escape), isTrue);
    await tester.pump();
    expect(find.byType(ChatReasoningControls), findsNothing);
  });

  testWidgets('narrow sheet scrolls expanded Effort choices', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    final manyEfforts = List.generate(16, (index) => 'level-$index');
    ReasoningConfiguration? changed;
    await _pumpLocalized(
      tester,
      ChatReasoningControl(
        options: [ReasoningOption.effort(manyEfforts)],
        value: null,
        onChanged: (value) => changed = value,
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('chat_reasoning_selector')),
    );
    final _ = await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('chat_reasoning_effort_disclosure')),
    );
    final _ = await tester.pumpAndSettle();

    final lastEffort = find.byKey(
      const ValueKey<String>('chat_reasoning_effort_choice_level-15'),
    );
    expect(lastEffort, findsOneWidget);
    await tester.ensureVisible(lastEffort);
    final _ = await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();
    final disclosure = tester.getSemantics(
      find.byKey(const ValueKey<String>('chat_reasoning_effort_disclosure')),
    );
    expect(disclosure.label.toLowerCase(), contains('effort'));
    expect(disclosure.value, 'Default');
    expect(find.bySemanticsLabel('level-15'), findsOneWidget);
    semantics.dispose();

    await tester.tap(lastEffort);
    final _ = await tester.pumpAndSettle();

    expect(changed?.effort, 'level-15');
    expect(find.byType(ChatReasoningControls), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('chat_reasoning_effort_choices')),
      findsNothing,
    );
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
    expect(
      tester.getSemantics(find.byType(AuraSwitch)).label,
      startsWith('Enable reasoning'),
    );
    semantics.dispose();

    await tester.enterText(find.byType(TextFormField), '32769');
    await tester.pump();
    expect(
      find.text('Enter a whole number from 1024 to 32768.', findRichText: true),
      findsOneWidget,
    );
    expect(changed, isNull);

    await tester.enterText(find.byType(TextFormField), '4096');
    await tester.pump();
    expect(changed?.budgetTokens, 4096);

    await tester.tap(
      find.byKey(const ValueKey<String>('chat_reasoning_reset')),
    );
    await tester.pump();
    expect(changed, isNull);
  });

  testWidgets('exposes stable labels and hides reset for default state', (
    tester,
  ) async {
    await _pumpLocalized(
      tester,
      ChatReasoningControl(options: options, value: null, onChanged: _noop),
    );

    final semantics = tester.ensureSemantics();
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey<String>('chat_reasoning_selector')),
          )
          .label,
      contains('Provider default'),
    );
    semantics.dispose();

    await tester.tap(
      find.byKey(const ValueKey<String>('chat_reasoning_selector')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('chat_reasoning_reset')),
      findsNothing,
    );
  });
}

class const _LocalizedApp({required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => EasyLocalization(
    key: UniqueKey(),
    child: Builder(
      builder: (context) => MaterialApp(
        home: Theme(
          data: .new(extensions: [AuraTheme.light]),
          child: Material(child: Portal(child: child)),
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
  await tester.runAsync(() async {
    await tester.pumpWidget(_LocalizedApp(child: child));
    await tester.pump();
    await tester.pump();
    await tester.pump();
  });
}

void _noop(ReasoningConfiguration? value) {
  if (value == null) return;
}
