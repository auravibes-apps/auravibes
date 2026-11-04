import 'dart:async';

import 'package:auravibes_ui/src/organisms/aura_confirm_dialog.dart';
import 'package:auravibes_ui/src/organisms/aura_date_time_input.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('picker uses host labels and honors individual overrides', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _LocalizedApp(
        child: Scaffold(
          body: AuraDateTimeInput(
            value: .new(2024, 1, 15),
            labels: const AuraDateTimeInputLabels(done: 'Aplicar'),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AuraDateTimeInput));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Elegir fecha, Elegir hora'), findsOneWidget);
    expect(find.text('Aplicar'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.bySemanticsLabel('Mes anterior'), findsOneWidget);
    expect(find.bySemanticsLabel('Mes siguiente'), findsOneWidget);
    expect(find.bySemanticsLabel('+ Hora'), findsOneWidget);
    expect(find.bySemanticsLabel('- Minuto'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('dialogs use host labels and honor caller overrides', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      _LocalizedApp(
        child: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => unawaited(() async {
                    result = await AuraDialogs.confirm(
                      context: context,
                      title: const Text('Title'),
                      message: const Text('Message'),
                    );
                  }()),
                  child: const Text('Default'),
                ),
                TextButton(
                  onPressed: () => unawaited(
                    AuraDialogs.confirm(
                      context: context,
                      title: const Text('Title'),
                      message: const Text('Message'),
                      actions: const AuraConfirmDialogActions(
                        confirmLabel: Text('Guardar'),
                      ),
                    ),
                  ),
                  child: const Text('Custom'),
                ),
                TextButton(
                  onPressed: () => unawaited(
                    AuraDialogs.alert(
                      context: context,
                      title: const Text('Alert'),
                      message: const Text('Message'),
                    ),
                  ),
                  child: const Text('Alert'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Default'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Aceptar'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    await tester.tap(find.text('Aceptar'));
    final _ = await tester.pumpAndSettle();
    expect(result, isTrue);

    await tester.tap(find.text('Custom'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Guardar'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.text('Alert'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Aceptar'), findsOneWidget);
    await tester.tap(find.text('Aceptar'));
    final _ = await tester.pumpAndSettle();
  });
}

class _LocalizedApp extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: child,
    locale: const Locale('en'),
    localizationsDelegates: const [_TestLocalizationsDelegate()],
    supportedLocales: const [Locale('en')],
  );
}

class _TestLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const new();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture(const _TestMaterialLocalizations());

  @override
  bool shouldReload(_TestLocalizationsDelegate old) => false;
}

class _TestMaterialLocalizations extends DefaultMaterialLocalizations {
  const new();

  @override
  String get datePickerHelpText => 'Elegir fecha';
  @override
  String get timePickerDialHelpText => 'Elegir hora';
  @override
  String get timePickerHourLabel => 'Hora';
  @override
  String get timePickerMinuteLabel => 'Minuto';
  @override
  String get cancelButtonLabel => 'Cancelar';
  @override
  String get okButtonLabel => 'Aceptar';
  @override
  String get previousMonthTooltip => 'Mes anterior';
  @override
  String get nextMonthTooltip => 'Mes siguiente';
}
