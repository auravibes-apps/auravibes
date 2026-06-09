// ignore_for_file: no-magic-number
// Required: Existing UI spacing uses small numeric values.
import 'package:auravibes_app/features/skills/providers/skill_credential_definitions_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SkillCredentialDefinitionsScreen extends ConsumerWidget {
  const SkillCredentialDefinitionsScreen({
    required this.workspaceId,
    super.key,
  });

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definitionsAsync = ref.watch(
      skillCredentialDefinitionsProvider(workspaceId),
    );

    return AuraScreen(
      child: switch (definitionsAsync) {
        AsyncData(:final value) =>
          value.isEmpty
              ? const Center(
                  child: TextLocale(
                    LocaleKeys.skill_credentials_definitions_empty,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: value.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final definition = value[index];
                    return AuraCard(
                      child: AuraTile(
                        variant: AuraTileVariant.ghost,
                        leading: const AuraIcon(Icons.key_outlined),
                        trailing: const AuraIcon(Icons.chevron_right),
                        onTap: () => context.push(
                          '/workspaces/$workspaceId/more/'
                          'skill-credential-definitions/${definition.id}',
                        ),
                        child: AuraColumn(
                          spacing: AuraSpacing.xs,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AuraText(child: Text(definition.title)),
                            AuraText(
                              child: Text(definition.slug),
                              color: AuraColorVariant.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        AsyncLoading(:final value, hasValue: true) => ListView(
          children: [
            for (final definition in value!)
              AuraTile(
                variant: AuraTileVariant.ghost,
                child: AuraColumn(
                  spacing: AuraSpacing.xs,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuraText(child: Text(definition.title)),
                    AuraText(
                      child: Text(definition.slug),
                      color: AuraColorVariant.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
          ],
        ),
        AsyncLoading() => const Center(child: AuraSpinner()),
        AsyncError() => const Center(
          child: TextLocale(LocaleKeys.skill_credentials_definitions_error),
        ),
      },
      appBar: AuraAppBar(
        title: const TextLocale(LocaleKeys.skill_credentials_definitions_title),
        leading: AuraIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          AuraIconButton(
            icon: Icons.add,
            onPressed: () => context.push(
              '/workspaces/$workspaceId/more/skill-credential-definitions/new',
            ),
          ),
        ],
      ),
    );
  }
}
