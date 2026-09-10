// Required: Existing UI spacing uses small numeric values.
// Required: Modal keeps small private row widgets together.
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_provider.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_state.dart';
import 'package:auravibes_app/features/skills/usecases/load_conversation_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/unload_conversation_skill_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class const ConversationSkillSelectorModal({
  required final String workspaceId,
  required final String conversationId,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectorAsync = ref.watch(
      conversationSkillSelectorProvider(workspaceId, conversationId),
    );

    return _ConversationSkillSelectorDialog(
      selectorAsync: selectorAsync,
      onLoad: (skill) => _load(ref, skill),
      onUnload: (skill) => _unload(ref, skill),
    );
  }

  Future<void> _load(WidgetRef ref, AvailableSkill skill) async {
    final usecase = ref.read(loadConversationSkillUsecaseProvider(workspaceId));
    final _ = await usecase.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
      slug: skill.slug,
    );
    ref.invalidate(
      conversationSkillSelectorProvider(workspaceId, conversationId),
    );
  }

  Future<void> _unload(WidgetRef ref, AvailableSkill skill) async {
    final usecase = ref.read(
      unloadConversationSkillUsecaseProvider(workspaceId),
    );
    final _ = await usecase.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
      slug: skill.slug,
    );
    ref.invalidate(
      conversationSkillSelectorProvider(workspaceId, conversationId),
    );
  }
}

class const _ConversationSkillSelectorDialog({
  required final AsyncValue<ConversationSkillSelectorState> selectorAsync,
  required final ValueChanged<AvailableSkill> onLoad,
  required final ValueChanged<AvailableSkill> onUnload,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraAlertDialog(
      title: const TextLocale(LocaleKeys.skills_selector_title),
      message: SizedBox(
        width: 520,
        child: _SelectorMessage(
          selectorAsync: selectorAsync,
          onLoad: onLoad,
          onUnload: onUnload,
        ),
      ),
      dismissLabel: const TextLocale(LocaleKeys.common_close),
    );
  }
}

class const _SelectorMessage({
  required final AsyncValue<ConversationSkillSelectorState> selectorAsync,
  required final ValueChanged<AvailableSkill> onLoad,
  required final ValueChanged<AvailableSkill> onUnload,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return switch (selectorAsync) {
      AsyncData(:final value) => _SelectorContent(
        state: value,
        onLoad: onLoad,
        onUnload: onUnload,
      ),
      AsyncLoading(
        value: final ConversationSkillSelectorState value,
        hasValue: true,
      ) =>
        _SelectorContent(state: value, onLoad: onLoad, onUnload: onUnload),
      AsyncLoading() => const SizedBox(
        height: 120,
        child: Center(child: AuraSpinner()),
      ),
      AsyncError() => const TextLocale(LocaleKeys.skills_selector_error),
    };
  }
}

class const _SelectorContent({
  required final ConversationSkillSelectorState state,
  required final ValueChanged<AvailableSkill> onLoad,
  required final ValueChanged<AvailableSkill> onUnload,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: _SelectorSections(
        state: state,
        onLoad: onLoad,
        onUnload: onUnload,
      ),
    );
  }
}

class const _SelectorSections({
  required final ConversationSkillSelectorState state,
  required final ValueChanged<AvailableSkill> onLoad,
  required final ValueChanged<AvailableSkill> onUnload,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _LoadedSkillSection(state: state, onUnload: onUnload),
        _AvailableSkillSection(state: state, onLoad: onLoad),
      ],
      spacing: .md,
      crossAxisAlignment: .start,
    );
  }
}

class const _LoadedSkillSection({
  required final ConversationSkillSelectorState state,
  required final ValueChanged<AvailableSkill> onUnload,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SkillSection(
      titleKey: LocaleKeys.skills_selector_loaded_title,
      emptyKey: LocaleKeys.skills_selector_loaded_empty,
      skills: state.loaded,
      actionIcon: Icons.remove_circle_outline,
      onPressed: onUnload,
    );
  }
}

class const _AvailableSkillSection({
  required final ConversationSkillSelectorState state,
  required final ValueChanged<AvailableSkill> onLoad,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SkillSection(
      titleKey: LocaleKeys.skills_selector_available_title,
      emptyKey: LocaleKeys.skills_selector_available_empty,
      skills: state.loadable,
      actionIcon: Icons.add_circle_outline,
      onPressed: onLoad,
    );
  }
}

class const _SkillSection({
  required final String titleKey,
  required final String emptyKey,
  required final List<AvailableSkill> skills,
  required final IconData actionIcon,
  required final ValueChanged<AvailableSkill> onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _SkillSectionTitle(titleKey: titleKey),
        _SkillSectionContent(
          emptyKey: emptyKey,
          skills: skills,
          actionIcon: actionIcon,
          onPressed: onPressed,
        ),
      ],
      spacing: .sm,
      crossAxisAlignment: .start,
    );
  }
}

class const _SkillSectionTitle({required final String titleKey})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraText(child: TextLocale(titleKey), style: .heading4);
  }
}

class const _SkillSectionContent({
  required final String emptyKey,
  required final List<AvailableSkill> skills,
  required final IconData actionIcon,
  required final ValueChanged<AvailableSkill> onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) return AuraText(child: TextLocale(emptyKey));

    return _SkillSectionList(
      skills: skills,
      actionIcon: actionIcon,
      onPressed: onPressed,
    );
  }
}

class const _SkillSectionList({
  required final List<AvailableSkill> skills,
  required final IconData actionIcon,
  required final ValueChanged<AvailableSkill> onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        for (final skill in skills)
          _SkillSelectorTile(
            skill: skill,
            actionIcon: actionIcon,
            onPressed: onPressed,
          ),
      ],
      spacing: .xs,
      crossAxisAlignment: .start,
    );
  }
}

class const _SkillSelectorTile({
  required final AvailableSkill skill,
  required final IconData actionIcon,
  required final ValueChanged<AvailableSkill> onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraTile(
      child: AuraColumn(
        children: [
          AuraText(child: Text(skill.title)),
          AuraText(child: Text(skill.description)),
        ],
        spacing: .xs,
        crossAxisAlignment: .start,
      ),
      variant: .ghost,
      trailing: AuraIconButton(
        icon: actionIcon,
        onPressed: () => onPressed(skill),
      ),
    );
  }
}
