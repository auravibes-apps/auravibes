import 'dart:async';

import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_provider.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_state.dart';
import 'package:auravibes_app/features/skills/usecases/apply_conversation_skill_action_usecase.dart';
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
    expect(find.text('Use now'), findsOneWidget);
    expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
  });

  testWidgets('search filters both sections by description', (tester) async {
    final container = _container(
      state: const ConversationSkillSelectorState(
        loaded: [_research],
        loadable: [_weather],
      ),
    );
    addTearDown(container.dispose);
    await _pumpModal(tester, container);

    final _ = await tester.enterText(find.byType(EditableText), 'forecast');
    final _ = await tester.pumpAndSettle();

    expect(find.text('Research'), findsNothing);
    expect(find.text('Weather'), findsOneWidget);
    final _ = await tester.enterText(find.byType(EditableText), 'no match');
    final _ = await tester.pumpAndSettle();
    expect(find.text('No skills match your search'), findsNWidgets(2));
  });

  testWidgets('shows preparing while context retry is in progress', (
    tester,
  ) async {
    final container = _container(
      state: const ConversationSkillSelectorState(
        loaded: [_research],
        loadable: [],
        contextStatusBySlug: {'research': .preparing},
      ),
    );
    addTearDown(container.dispose);
    await _pumpModal(tester, container);

    expect(find.text('Preparing context…'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('Add stays promptless and shows pending state', (tester) async {
    final loadStarted = Completer<void>();
    final finishLoad = Completer<void>();
    var sends = 0;
    final container = _container(
      state: const ConversationSkillSelectorState(
        loaded: [],
        loadable: [_research],
      ),
      actionUsecase: _actionUsecase(
        load: (_, _, _) {
          loadStarted.complete();

          return finishLoad.future;
        },
        send: (_, _, _) async => sends++,
      ),
    );
    addTearDown(container.dispose);
    await _pumpModal(tester, container);

    final _ = await tester.tap(find.text('Add'));
    await tester.pump();

    expect(find.textContaining('Adding'), findsOneWidget);
    expect(sends, 0);
    expect(loadStarted.isCompleted, isTrue);

    finishLoad.complete();
    final _ = await tester.pumpAndSettle();
    expect(sends, 0);
    expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
  });

  testWidgets('Use now sends one localized visible request', (tester) async {
    final drafts = <ChatDraft>[];
    final container = _container(
      state: const ConversationSkillSelectorState(
        loaded: [_research],
        loadable: [],
      ),
      actionUsecase: _actionUsecase(
        send: (_, _, draft) async => drafts.add(draft),
      ),
    );
    addTearDown(container.dispose);
    await _pumpModal(tester, container);

    final _ = await tester.tap(find.text('Use now'));
    final _ = await tester.pumpAndSettle();

    expect(drafts.map((draft) => draft.text), [
      'Use the Research skill to answer my latest request.',
    ]);
  });
}

ProviderContainer _container({
  required ConversationSkillSelectorState state,
  ApplyConversationSkillActionUsecase? actionUsecase,
}) => ProviderContainer(
  overrides: [
    conversationSkillSelectorProvider(
      'workspace',
      'conversation',
    ).overrideWith((_) async => state),
    if (actionUsecase != null)
      applyConversationSkillActionUsecaseProvider.overrideWithValue(
        actionUsecase,
      ),
  ],
);

ApplyConversationSkillActionUsecase _actionUsecase({
  Future<void> Function(String workspaceId, String conversationId, String slug)?
  load,
  Future<void> Function(
    String workspaceId,
    String conversationId,
    ChatDraft draft,
  )?
  send,
}) => ApplyConversationSkillActionUsecase(
  workspaceIdForConversation: (_) async => 'workspace',
  listSkills: (_, _, filter) async => switch (filter) {
    .loaded => const [],
    _ => const [_research],
  },
  buildContextMessages: (_, _) async => const [],
  loadSkill: load ?? (_, _, _) => Future<void>.value(),
  sendMessage: send ?? (_, _, _) => Future<void>.value(),
);

Future<void> _pumpModal(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final _ = await tester.runAsync(() async {
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
}

const _research = AvailableSkill(
  source: SkillSource.user,
  id: 'research',
  slug: 'research',
  title: 'Research',
  description: 'Find sources for a topic.',
  content: 'Use research',
  kind: .template,
  credentialReadiness: .ready,
);

const _weather = AvailableSkill(
  source: SkillSource.user,
  id: 'weather',
  slug: 'weather',
  title: 'Weather',
  description: 'Forecast details for today.',
  content: 'Use weather',
  kind: .template,
  credentialReadiness: .ready,
);
