import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';
import 'package:widgetbook_workspace/main.dart';

void main() {
  testWidgets('locale addon keeps SDK AppBar localizations', (tester) async {
    const locales = [Locale('en'), Locale('es'), Locale('ar')];
    final addon = LocaleAddon(locales, StoryHelpers.auraLocalizationDelegates);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => addon.apply(
            context,
            Navigator(
              onGenerateInitialRoutes: (_, _) => [
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: SizedBox.shrink()),
                ),
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(
                    appBar: AuraAppBar(title: Text('Localized app bar')),
                  ),
                ),
              ],
            ),
            const Locale('en'),
          ),
        ),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: locales,
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraAppBar), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(addon.locales, locales);
  });

  testWidgets('Widgetbook theme host supports SDK Material inputs', (
    tester,
  ) async {
    await tester.pumpWidget(
      Builder(
        builder: (context) => WidgetbookConfig.applyApp(
          context,
          Builder(
            builder: (context) => WidgetbookConfig.applyTheme(
              context,
              .new(),
              const AuraInput(placeholder: Text('Input')),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AuraInput), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
