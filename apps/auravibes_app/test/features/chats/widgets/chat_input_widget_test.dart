// Required: Tests repeat finders and fixture lookups for clarity.
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  Widget buildSubject({
    required void Function(String) onSendMessage,
    VoidCallback onToolsPress = _noop,
    bool disabled = false,
    bool isBusy = false,
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
                  child: ChatInputWidget(
                    onSendMessage: onSendMessage,
                    onToolsPress: onToolsPress,
                    disabled: disabled,
                    isBusy: isBusy,
                    onStop: onStop,
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
}

void _noop() {
  final _ = Object();
}
