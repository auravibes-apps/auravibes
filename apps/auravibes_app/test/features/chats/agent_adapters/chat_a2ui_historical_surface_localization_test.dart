import 'package:auravibes_app/features/chats/widgets/chat_a2ui_warning.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('historical read-only status is localized for Spanish', (
    tester,
  ) async {
    String? directTranslation;
    String? directTranslationError;

    await tester.pumpWidget(
      TestableApp(
        startLocale: const Locale('es'),
        child: Builder(
          builder: (context) {
            try {
              directTranslation = LocaleKeys
                  .chats_screens_chat_conversation_a2ui_read_only
                  .tr(context: context);
            } on Object catch (error) {
              directTranslationError = '$error';
            }
            final label = chatA2uiText(
              context,
              LocaleKeys.chats_screens_chat_conversation_a2ui_read_only,
              'Read only',
            );
            return AuraBadge.text(
              variant: AuraBadgeVariant.neutral,
              size: AuraBadgeSize.small,
              semanticLabel: label,
              child: Text(label),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(directTranslationError, isNull, reason: directTranslationError);
    expect(directTranslation, 'Solo lectura');
    expect(find.text('Solo lectura'), findsOneWidget);
    expect(tester.getSemantics(find.byType(AuraBadge)).label, 'Solo lectura');
  });
}
