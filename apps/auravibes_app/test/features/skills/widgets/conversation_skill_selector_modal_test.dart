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
  testWidgets('shows selected skill and current context separately', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        conversationSkillSelectorProvider(
          'workspace',
          'conversation',
        ).overrideWith(
          (ref) async => const ConversationSkillSelectorState(
            loaded: [
              AvailableSkill(
                source: SkillSource.user,
                id: 'research',
                slug: 'research',
                title: 'Research',
                description: 'Find sources',
                content: '',
                kind: .template,
                credentialReadiness: .ready,
              ),
            ],
            loadable: [],
            contextStatusBySlug: {'research': .needsContext},
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          child: Builder(
            builder: (context) => UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                home: AuraThemeScope(
                  theme: .light,
                  child: const Scaffold(
                    body: ConversationSkillSelectorModal(
                      workspaceId: 'workspace',
                      conversationId: 'conversation',
                    ),
                  ),
                ),
                locale: context.locale,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
              ),
            ),
          ),
          supportedLocales: const [Locale('en')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          useOnlyLangCode: true,
          useFallbackTranslations: true,
        ),
      );
    });
    final _ = await tester.pumpAndSettle();

    expect(find.text('Research'), findsOneWidget);
    expect(find.text('Needs context'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
  });
}
