import 'package:auravibes_ui/src/aura_haptics.dart';
import 'package:auravibes_ui/src/molecules/aura_snack_bar_host.dart';
import 'package:auravibes_ui/src/molecules/aura_tabs.dart';
import 'package:auravibes_ui/src/organisms/aura_choice_picker.dart';
import 'package:auravibes_ui/src/organisms/aura_switch.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _hapticsChannel = MethodChannel('haptic_feedback');
final _calls = <String>[];

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _calls.clear();
    AuraHaptics.resetForTesting();
    _setHandler((call) async {
      _calls.add(call.method);
      if (call.method == 'canVibrate') return true;

      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_hapticsChannel, null);
    AuraHaptics.resetForTesting();
  });

  group('AuraHaptics', () {
    test('checks support once and vibrates once per request', () async {
      await AuraHaptics.success();
      await AuraHaptics.selection();

      expect(_calls, ['canVibrate', 'success', 'selection']);
    });

    test('skips vibration when the device does not support it', () async {
      _setHandler((call) async {
        _calls.add(call.method);

        return false;
      });

      await AuraHaptics.success();
      await AuraHaptics.error();

      expect(_calls, ['canVibrate']);
    });

    test('swallows capability and vibration platform errors', () async {
      _setHandler((call) async {
        _calls.add(call.method);
        throw PlatformException(code: 'unavailable');
      });

      await AuraHaptics.light();
      await AuraHaptics.error();

      expect(_calls, ['canVibrate']);

      _calls.clear();
      AuraHaptics.resetForTesting();
      _setHandler((call) async {
        _calls.add(call.method);
        if (call.method == 'canVibrate') return true;

        throw PlatformException(code: 'unavailable');
      });

      await AuraHaptics.light();
      await AuraHaptics.error();

      expect(_calls, ['canVibrate', 'light']);
    });
  });

  testWidgets('navigation tabs only vibrate when selection changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _TestHost(
        child: AuraTabs<void>(
          items: [
            AuraTabItem(title: Text('First'), child: Text('First content')),
            AuraTabItem(title: Text('Second'), child: Text('Second content')),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Second'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Second'));
    final _ = await tester.pumpAndSettle();

    expect(_calls.where((method) => method == 'light'), hasLength(1));
  });

  testWidgets('selector tabs use selection feedback', (tester) async {
    await tester.pumpWidget(
      _TestHost(
        child: AuraTabs<String>.selector(
          options: const [
            AuraTabOption(value: 'first', title: Text('First')),
            AuraTabOption(value: 'second', title: Text('Second')),
          ],
          initialValue: 'first',
          onChanged: (_) {
            final _ = Object();
          },
        ),
      ),
    );

    await tester.tap(find.text('Second'));
    final _ = await tester.pumpAndSettle();

    expect(_calls.where((method) => method == 'selection'), hasLength(1));
  });

  testWidgets('choice picker vibrates only when selection changes', (
    tester,
  ) async {
    var value = <String>['first'];
    await tester.pumpWidget(
      _TestHost(
        child: StatefulBuilder(
          builder: (context, setState) => AuraChoicePicker<String>(
            options: const [
              AuraChoiceOption(value: 'first', label: Text('First')),
              AuraChoiceOption(value: 'second', label: Text('Second')),
            ],
            value: value,
            onChanged: (next) => setState(() => value = next),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Second'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Second'));
    final _ = await tester.pumpAndSettle();

    expect(_calls, ['canVibrate', 'selection']);
  });

  testWidgets('switch vibrates when enabled, not when disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestHost(
        child: AuraSwitch(
          value: false,
          onChanged: (_) {
            final _ = Object();
          },
        ),
      ),
    );
    await tester.tap(find.byType(AuraSwitch));
    final _ = await tester.pumpAndSettle();
    expect(_calls.where((method) => method == 'light'), hasLength(1));

    _calls.clear();
    AuraHaptics.resetForTesting();
    await tester.pumpWidget(
      _TestHost(
        child: AuraSwitch(
          value: false,
          onChanged: (_) {
            final _ = Object();
          },
          disabled: true,
        ),
      ),
    );
    await tester.tap(find.byType(AuraSwitch));
    final _ = await tester.pumpAndSettle();

    expect(_calls, isEmpty);
  });

  testWidgets('semantic snackbar variants provide matching haptics', (
    tester,
  ) async {
    await tester.pumpWidget(
      AuraThemeScope(
        theme: .light,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                mainAxisSize: .min,
                children: [
                  TextButton(
                    onPressed: () => AuraSnackBars.show(
                      context: context,
                      content: const Text('Success'),
                      variant: .success,
                    ),
                    child: const Text('Show success'),
                  ),
                  TextButton(
                    onPressed: () => AuraSnackBars.show(
                      context: context,
                      content: const Text('Error'),
                      variant: .error,
                    ),
                    child: const Text('Show error'),
                  ),
                  TextButton(
                    onPressed: () => AuraSnackBars.show(
                      context: context,
                      content: const Text('Default'),
                    ),
                    child: const Text('Show default'),
                  ),
                ],
              ),
            ),
          ),
          builder: (context, child) =>
              AuraSnackBarHost(child: child ?? const SizedBox.shrink()),
          theme: .new(),
        ),
      ),
    );

    await tester.tap(find.text('Show success'));
    await tester.pump();
    expect(_calls, ['canVibrate', 'success']);

    _calls.clear();
    AuraHaptics.resetForTesting();
    await tester.tap(find.text('Show error'));
    await tester.pump();
    expect(_calls, ['canVibrate', 'error']);

    _calls.clear();
    AuraHaptics.resetForTesting();
    await tester.tap(find.text('Show default'));
    await tester.pump();
    expect(_calls, isEmpty);
  });
}

void _setHandler(Future<Object?> Function(MethodCall) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_hapticsChannel, handler);
}

class const _TestHost({required final Widget child}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraThemeScope(
    theme: .light,
    child: MaterialApp(
      home: Scaffold(body: SizedBox(height: 240, child: child)),
      theme: .new(),
    ),
  );
}
