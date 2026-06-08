// ignore_for_file: no-magic-number
// Required: Existing UI spacing uses small numeric values.
// ignore_for_file: prefer-single-widget-per-file
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

class ConversationSkillSelectorModal extends ConsumerWidget {
  const ConversationSkillSelectorModal({
    required this.workspaceId,
    required this.conversationId,
    super.key,
  });

  final String workspaceId;
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectorAsync = ref.watch(
      conversationSkillSelectorProvider(workspaceId, conversationId),
    );

    return AuraAlertDialog(
      title: const TextLocale(LocaleKeys.skills_selector_title),
      message: SizedBox(
        width: 520,
        child: switch (selectorAsync) {
          AsyncData(:final value) => _SelectorContent(
            state: value,
            onLoad: (skill) => _load(ref, skill),
            onUnload: (skill) => _unload(ref, skill),
          ),
          AsyncLoading(
            value: final ConversationSkillSelectorState value,
            hasValue: true,
          ) =>
            _SelectorContent(
              state: value,
              onLoad: (skill) => _load(ref, skill),
              onUnload: (skill) => _unload(ref, skill),
            ),
          AsyncLoading() => const SizedBox(
            height: 120,
            child: Center(child: AuraSpinner()),
          ),
          AsyncError() => const TextLocale(LocaleKeys.skills_selector_error),
        },
      ),
      dismissLabel: const TextLocale(LocaleKeys.common_close),
    );
  }

  Future<void> _load(WidgetRef ref, AvailableSkill skill) async {
    final usecase = ref.read(loadConversationSkillUsecaseProvider);
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
    final usecase = ref.read(unloadConversationSkillUsecaseProvider);
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

class _SelectorContent extends StatelessWidget {
  const _SelectorContent({
    required this.state,
    required this.onLoad,
    required this.onUnload,
  });

  final ConversationSkillSelectorState state;
  final ValueChanged<AvailableSkill> onLoad;
  final ValueChanged<AvailableSkill> onUnload;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: AuraColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AuraSpacing.md,
        children: [
          _SkillSection(
            titleKey: LocaleKeys.skills_selector_loaded_title,
            emptyKey: LocaleKeys.skills_selector_loaded_empty,
            skills: state.loaded,
            actionIcon: Icons.remove_circle_outline,
            onPressed: onUnload,
          ),
          _SkillSection(
            titleKey: LocaleKeys.skills_selector_available_title,
            emptyKey: LocaleKeys.skills_selector_available_empty,
            skills: state.loadable,
            actionIcon: Icons.add_circle_outline,
            onPressed: onLoad,
          ),
        ],
      ),
    );
  }
}

class _SkillSection extends StatelessWidget {
  const _SkillSection({
    required this.titleKey,
    required this.emptyKey,
    required this.skills,
    required this.actionIcon,
    required this.onPressed,
  });

  final String titleKey;
  final String emptyKey;
  final List<AvailableSkill> skills;
  final IconData actionIcon;
  final ValueChanged<AvailableSkill> onPressed;

  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AuraSpacing.sm,
      children: [
        AuraText(
          child: TextLocale(titleKey),
          style: AuraTextStyle.heading4,
        ),
        if (skills.isEmpty)
          AuraText(
            child: TextLocale(emptyKey),
            color: AuraColorVariant.onSurfaceVariant,
          )
        else
          for (final skill in skills)
            AuraTile(
              variant: AuraTileVariant.ghost,
              trailing: AuraIconButton(
                icon: actionIcon,
                onPressed: () => onPressed(skill),
              ),
              child: AuraColumn(
                spacing: AuraSpacing.xs,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuraText(child: Text(skill.title)),
                  AuraText(
                    child: Text(skill.description),
                    color: AuraColorVariant.onSurfaceVariant,
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
