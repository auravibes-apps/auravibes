import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';
import 'package:widgetbook_workspace/main.dart';

void main() {
  testWidgets('locale and theme addons preserve SDK Material widgets', (
    tester,
  ) async {
    const locales = [Locale('en'), Locale('es'), Locale('ar')];
    final addon = LocaleAddon(locales, StoryHelpers.auraLocalizationDelegates);

    await tester.pumpWidget(
      Builder(
        builder: (context) => WidgetbookConfig.applyApp(
          context,
          Builder(
            builder: (context) => Column(
              children: [
                Expanded(
                  child: addon.apply(
                    context,
                    Navigator(
                      onGenerateInitialRoutes: (_, _) => [
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const Scaffold(body: SizedBox.shrink()),
                        ),
                        MaterialPageRoute<void>(
                          builder: (_) => const Scaffold(
                            appBar: AuraAppBar(
                              title: Text('Localized app bar'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Locale('en'),
                  ),
                ),
                Expanded(
                  child: WidgetbookConfig.applyTheme(
                    .new(),
                    const AuraInput(placeholder: Text('Input')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraAppBar), findsOneWidget);
    expect(find.byType(AuraInput), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(addon.locales, locales);
  });
}
