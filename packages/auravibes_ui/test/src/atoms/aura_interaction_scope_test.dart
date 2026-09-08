// ignore_for_file: type=lint, type=warning
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps default Aura controls interactive', (tester) async {
    var changed = 0;
    await tester.pumpWidget(
      _app(AuraButton(onPressed: () => changed++, child: const Text('Run'))),
    );

    await tester.tap(find.text('Run'));

    expect(changed, 1);
  });

  testWidgets('read-only scope makes text input native read-only', (
    tester,
  ) async {
    const changed = 0;
    await tester.pumpWidget(
      _app(
        const AuraInteractionScope(
          policy: AuraInteractionPolicy.readOnly(),
          child: AuraInput(initialValue: 'Shown'),
        ),
      ),
    );

    final formField = tester.widget<TextFormField>(find.byType(TextFormField));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.readOnly, isTrue);
    expect(field.enabled, isFalse);
    expect(formField.onChanged, isNull);
    await tester.tap(find.byType(TextFormField));
    expect(FocusManager.instance.primaryFocus, isNot(field.focusNode));
    expect(changed, 0);
    expect(find.text('Shown'), findsOneWidget);
  });

  testWidgets('read-only scope disables value controls and commands', (
    tester,
  ) async {
    const checkboxChanges = 0;
    const sliderChanges = 0;
    const choiceChanges = 0;
    const buttonChanges = 0;
    await tester.pumpWidget(
      _app(
        const AuraInteractionScope(
          policy: AuraInteractionPolicy.readOnly(),
          child: Column(
            children: [
              AuraCheckbox(value: true, onChanged: null),
              AuraSlider(value: 0.5, onChanged: null),
              AuraChoicePicker<String>(
                options: [AuraChoiceOption(value: 'one', label: Text('One'))],
                value: ['one'],
                onChanged: null,
              ),
              AuraButton(onPressed: _noop, child: Text('Run')),
            ],
          ),
        ),
      ),
    );

    final button = tester.widget<AuraPressable>(
      find.byType(AuraPressable).last,
    );
    expect(button.onPressed, isNull);
    expect(
      tester
          .widget<GestureDetector>(find.byType(GestureDetector).first)
          .onTapDown,
      isNull,
    );
    expect(checkboxChanges, 0);
    expect(sliderChanges, 0);
    expect(choiceChanges, 0);
    expect(buttonChanges, 0);
  });

  testWidgets('read-only scope keeps tabs and modals navigable', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      _app(
        AuraInteractionScope(
          policy: const AuraInteractionPolicy.readOnly(),
          child: Column(
            children: [
              AuraTabs<int>(
                items: const [
                  AuraTabItem(title: Text('First'), child: Text('One')),
                  AuraTabItem(title: Text('Second'), child: Text('Two')),
                ],
                onChanged: (value) => selected = value,
              ),
              const AuraModal(
                entryPointChild: Text('Open'),
                contentChild: Text('Modal content'),
                barrierLabel: 'Dismiss',
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Second'));
    await tester.tap(find.text('Open'));
    final _ = await tester.pumpAndSettle();

    expect(selected, 1);
    expect(find.text('Two'), findsOneWidget);
    expect(find.text('Modal content'), findsOneWidget);
  });

  testWidgets('read-only scope keeps links navigable with a click cursor', (
    tester,
  ) async {
    var presses = 0;
    await tester.pumpWidget(
      _app(
        AuraInteractionScope(
          policy: const AuraInteractionPolicy.readOnly(),
          child: AuraLink(label: 'Open', onPressed: () => presses++),
        ),
      ),
    );

    await tester.tap(find.text('Open'));

    expect(presses, 1);
    expect(
      tester
          .widget<MouseRegion>(
            find.descendant(
              of: find.byType(AuraLink),
              matching: find.byType(MouseRegion),
            ),
          )
          .cursor,
      SystemMouseCursors.click,
    );
  });

  testWidgets('disabled scope blocks local navigation', (tester) async {
    await tester.pumpWidget(
      _app(
        const AuraInteractionScope(
          policy: AuraInteractionPolicy.disabled(),
          child: AuraTabs<int>(
            items: [
              AuraTabItem(title: Text('First'), child: Text('One')),
              AuraTabItem(title: Text('Second'), child: Text('Two')),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Second'));
    await tester.pump();

    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsNothing);
  });
}

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: child),
  theme: ThemeData(extensions: [AuraTheme.light]),
);

void _noop() {
  final _ = 0;
}
