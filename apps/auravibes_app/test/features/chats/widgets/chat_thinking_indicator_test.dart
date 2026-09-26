import 'package:auravibes_app/features/chats/widgets/chat_thinking_indicator.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Widget buildSubject(Widget child) {
    return EasyLocalization(
      child: MaterialApp(
        home: AuraThemeScope(
          theme: .light,
          child: Theme(
            data: .new(),
            child: Material(child: child),
          ),
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

  testWidgets('renders AuraTypingIndicator', (tester) async {
    await tester.pumpWidget(buildSubject(const ChatThinkingIndicator()));
    await tester.pump();
    await tester.pump();

    expect(find.byType(AuraTypingIndicator), findsOneWidget);
  });

  testWidgets('renders thinking text', (tester) async {
    await tester.pumpWidget(buildSubject(const ChatThinkingIndicator()));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('chats_screens.chat_conversation.thinking_status'),
      findsOneWidget,
    );
  });
}
