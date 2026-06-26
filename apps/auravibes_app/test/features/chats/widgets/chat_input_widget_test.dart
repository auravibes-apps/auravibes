// Required: Tests repeat finders and fixture lookups for clarity.
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  Widget buildSubject({
    required void Function(String) onSendMessage,
    VoidCallback onToolsPress = _noop,
    bool disabled = false,
    bool isBusy = false,
    bool? showStopButton,
    VoidCallback? onStop,
  }) {
    return EasyLocalization(
      child: ProviderScope(
        child: Builder(
          builder: (context) {
            return MaterialApp(
              home: Theme(
                data: ThemeData(extensions: [AuraTheme.light]),
                child: Material(
                  child: Portal(
                    child: ChatInputWidget(
                      onSendMessage: onSendMessage,
                      onToolsPress: onToolsPress,
                      modelControl: const SizedBox.shrink(),
                      disabled: disabled,
                      isBusy: isBusy,
                      showStopButton: showStopButton,
                      onStop: onStop,
                    ),
                  ),
                ),
              ),
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
            );
          },
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

  Future<void> pumpAndInit(WidgetTester tester, Widget widget) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
    });
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  testWidgets('renders without error', (tester) async {
    await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
      ),
    );

    expect(find.byType(ChatInputWidget), findsOneWidget);
    expect(find.byType(AuraInput), findsOneWidget);
  });

  testWidgets('shows tools button when onToolsPress provided', (tester) async {
    await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
        onToolsPress: () {
          final _ = Object();
        },
      ),
    );

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();

    expect(find.byIcon(Icons.build_circle_outlined), findsOneWidget);
  });

  testWidgets('shows tools button by default', (tester) async {
    await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
      ),
    );

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();

    expect(find.byIcon(Icons.build_circle_outlined), findsOneWidget);
  });

  testWidgets('shows stop button when isBusy and onStop provided', (
    tester,
  ) async {
    await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
        isBusy: true,
        onStop: () {
          final _ = Object();
        },
      ),
    );

    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
  });

  testWidgets('does not expose stop button when isBusy is false', (
    tester,
  ) async {
    await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
        onStop: () {
          final _ = Object();
        },
      ),
    );

    expect(find.byIcon(Icons.stop_rounded).hitTestable(), findsNothing);
  });

  testWidgets('hides stop button while keeping input busy', (tester) async {
    await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
        isBusy: true,
        showStopButton: false,
        onStop: () {
          final _ = Object();
        },
      ),
    );

    final input = tester.widget<ChatInputWidget>(find.byType(ChatInputWidget));
    expect(input.isBusy, isTrue);
    expect(find.byIcon(Icons.stop_rounded).hitTestable(), findsNothing);
  });

  testWidgets('hides stop button when onStop is null', (tester) async {
    await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
        isBusy: true,
      ),
    );

    expect(find.byIcon(Icons.stop_rounded), findsNothing);
  });

  testWidgets('tabs from input to more button and opens with enter', (
    tester,
  ) async {
    await pumpAndInit(
      tester,
      buildSubject(
        onSendMessage: (_) {
          final _ = Object();
        },
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.pump();

    expect(await tester.sendKeyEvent(LogicalKeyboardKey.tab), isTrue);
    await tester.pump();
    expect(find.byIcon(Icons.build_circle_outlined), findsNothing);

    expect(await tester.sendKeyEvent(LogicalKeyboardKey.enter), isTrue);
    await tester.pump();

    expect(find.byIcon(Icons.build_circle_outlined), findsOneWidget);
  });
}

void _noop() {
  final _ = Object();
}
