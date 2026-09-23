import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_provider.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_state.dart';
import 'package:auravibes_app/features/skills/widgets/conversation_skill_selector_modal.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const loaded = AvailableSkill(
    id: 'loaded',
    slug: 'loaded',
    title: 'Research',
    description: 'Look up sources',
    content: '',
    source: SkillSource.user,
    kind: SkillKind.native,
  );
  const available = AvailableSkill(
    id: 'available',
    slug: 'available',
    title: 'Writer',
    description: 'Draft research reports',
    content: '',
    source: SkillSource.user,
    kind: SkillKind.native,
  );

  testWidgets('filters loaded and available skills by title and description', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          useOnlyLangCode: true,
          useFallbackTranslations: true,
          child: ProviderScope(
            overrides: [
              conversationSkillSelectorProvider.overrideWith(
                (ref, workspaceId, conversationId) async =>
                    const ConversationSkillSelectorState(
                      loaded: [loaded],
                      loadable: [available],
                    ),
              ),
            ],
            child: Builder(
              builder: (context) => MaterialApp(
                home: Theme(
                  data: ThemeData(extensions: [AuraTheme.light]),
                  child: const Material(
                    child: ConversationSkillSelectorModal(
                      workspaceId: 'ws-1',
                      conversationId: 'conv-1',
                    ),
                  ),
                ),
                locale: context.locale,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
              ),
            ),
          ),
        ),
      );
    });
    await tester.pump();
    await tester.pump();

    expect(find.text('Research'), findsOneWidget);
    expect(find.text('Writer'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '  RESEARCH  ');
    await tester.pump();
    expect(find.text('Research'), findsOneWidget);
    expect(find.text('Writer'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'look up');
    await tester.pump();
    expect(find.text('Research'), findsOneWidget);
    expect(find.text('Writer'), findsNothing);

    await tester.enterText(find.byType(TextFormField), 'missing');
    await tester.pump();
    expect(find.text('Research'), findsNothing);
    expect(find.text('Writer'), findsNothing);
    expect(find.text('No skills loaded'), findsOneWidget);
    expect(find.text('No skills available'), findsOneWidget);
  });
}
