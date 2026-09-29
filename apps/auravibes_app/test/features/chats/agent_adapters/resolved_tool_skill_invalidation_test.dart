import 'package:auravibes_app/features/chats/agent_adapters/resolved_tool_service.dart';
import 'package:auravibes_app/features/chats/providers/conversation_skill_context_runtime.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_provider.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_state.dart';
import 'package:auravibes_app/features/skills/usecases/skill_tool_slugs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('each Skills Manager mutation refreshes a mounted selector', () async {
    final selector = conversationSkillSelectorProvider(
      'workspace',
      'conversation',
    );
    var loads = 0;
    final container = ProviderContainer(
      overrides: [
        selector.overrideWith((ref) async {
          loads++;

          return const ConversationSkillSelectorState(loaded: [], loadable: []);
        }),
      ],
    );
    addTearDown(container.dispose);
    final observed = <AsyncValue<ConversationSkillSelectorState>>[];
    final subscription = container.listen(
      selector,
      (_, next) => observed.add(next),
    );
    addTearDown(subscription.close);
    expect(
      await container.read(selector.future),
      isA<ConversationSkillSelectorState>(),
    );
    final runtime = container.read(
      conversationSkillContextRuntimeProvider.notifier,
    );

    for (final slug in [
      SkillToolSlugs.createUserSkill,
      SkillToolSlugs.updateUserSkill,
      SkillToolSlugs.deleteUserSkill,
      SkillToolSlugs.createSkillCredentialDefinition,
      SkillToolSlugs.updateSkillCredentialDefinition,
      SkillToolSlugs.deleteSkillCredentialDefinition,
      SkillToolSlugs.createSkillTemplateTool,
      SkillToolSlugs.updateSkillTemplateTool,
      SkillToolSlugs.deleteSkillTemplateTool,
    ]) {
      final generation = runtime.begin('conversation');
      runtime.ready(
        'conversation',
        generation,
        selectedRevisions: const {},
        canActivate: true,
      );
      final before = loads;
      SkillsManagerToolStateInvalidator.invalidate((
        container: container,
        conversationId: 'conversation',
        workspaceId: 'workspace',
        toolSlug: slug,
        result: const <String, Object?>{},
      ));
      expect(
        await container.read(selector.future),
        isA<ConversationSkillSelectorState>(),
      );

      expect(loads, before + 1, reason: slug);
      expect(
        container
            .read(conversationSkillContextRuntimeProvider)['conversation']
            ?.phase,
        ConversationSkillContextPhase.needsContext,
        reason: slug,
      );
    }
    expect(observed, isNotEmpty);
  });

  test(
    'mutation without an active conversation leaves selector untouched',
    () async {
      final selector = conversationSkillSelectorProvider(
        'workspace',
        'conversation',
      );
      var loads = 0;
      final container = ProviderContainer(
        overrides: [
          selector.overrideWith((ref) async {
            loads++;

            return const ConversationSkillSelectorState(
              loaded: [],
              loadable: [],
            );
          }),
        ],
      );
      addTearDown(container.dispose);
      final observed = <AsyncValue<ConversationSkillSelectorState>>[];
      final subscription = container.listen(
        selector,
        (_, next) => observed.add(next),
      );
      addTearDown(subscription.close);
      expect(
        await container.read(selector.future),
        isA<ConversationSkillSelectorState>(),
      );

      SkillsManagerToolStateInvalidator.invalidate((
        container: container,
        conversationId: '',
        workspaceId: 'workspace',
        toolSlug: SkillToolSlugs.createUserSkill,
        result: const <String, Object?>{},
      ));

      expect(loads, 1);
      expect(observed, isNotEmpty);
      expect(container.read(conversationSkillContextRuntimeProvider), isEmpty);
    },
  );
}
