// Required: Existing UI spacing uses small numeric values.
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_definitions_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class const SkillCredentialDefinitionsScreen({
  required final String workspaceId,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definitionsAsync = ref.watch(
      skillCredentialDefinitionsProvider(workspaceId),
    );

    return AuraScreen(
      child: _SkillCredentialDefinitionsBody(
        workspaceId: workspaceId,
        definitionsAsync: definitionsAsync,
      ),
      appBar: _SkillCredentialDefinitionsAppBar(workspaceId: workspaceId),
    );
  }
}

class const _SkillCredentialDefinitionsBody({
  required final String workspaceId,
  required final AsyncValue<List<SkillCredentialDefinitionEntity>>
  definitionsAsync,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (definitionsAsync) {
    AsyncData(:final value) => _CredentialDefinitionsData(
      definitions: value,
      workspaceId: workspaceId,
    ),
    AsyncLoading(value: final value?, hasValue: true) =>
      _CredentialDefinitionsLoading(definitions: value),
    AsyncLoading() => const Center(child: AuraSpinner()),
    AsyncError() => const Center(
      child: TextLocale(LocaleKeys.skill_credentials_definitions_error),
    ),
  };
}

class const _CredentialDefinitionsData({
  required final List<SkillCredentialDefinitionEntity> definitions,
  required final String workspaceId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => definitions.isEmpty
      ? const Center(
          child: TextLocale(LocaleKeys.skill_credentials_definitions_empty),
        )
      : _CredentialDefinitionsList(
          definitions: definitions,
          workspaceId: workspaceId,
        );
}

class const _CredentialDefinitionsList({
  required final List<SkillCredentialDefinitionEntity> definitions,
  required final String workspaceId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemBuilder: _itemBuilder,
      separatorBuilder: _separatorBuilder,
      itemCount: definitions.length,
    );
  }

  Widget _itemBuilder(BuildContext _, int index) {
    return _CredentialDefinitionCard(
      definition: definitions[index],
      workspaceId: workspaceId,
    );
  }

  Widget _separatorBuilder(BuildContext _, _) {
    return const SizedBox(height: 8);
  }
}

class const _CredentialDefinitionsLoading({
  required final List<SkillCredentialDefinitionEntity> definitions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      for (final definition in definitions)
        _CredentialDefinitionLoadingTile(definition: definition),
    ],
  );
}

class const _CredentialDefinitionCard({
  required final SkillCredentialDefinitionEntity definition,
  required final String workspaceId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCard(
    child: _CredentialDefinitionTile(
      definition: definition,
      workspaceId: workspaceId,
    ),
    style: .border,
  );
}

class const _CredentialDefinitionTile({
  required final SkillCredentialDefinitionEntity definition,
  required final String workspaceId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraTile(
    child: _CredentialDefinitionDetails(definition: definition),
    onTap: () => context.push(
      '/workspaces/$workspaceId/more/'
      'skill-credential-definitions/${definition.id}',
    ),
    variant: .ghost,
    leading: const AuraIcon(Icons.key_outlined),
    trailing: const AuraIcon(Icons.chevron_right),
  );
}

class const _CredentialDefinitionLoadingTile({
  required final SkillCredentialDefinitionEntity definition,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraTile(
    child: _CredentialDefinitionDetails(definition: definition),
    variant: .ghost,
  );
}

class const _CredentialDefinitionDetails({
  required final SkillCredentialDefinitionEntity definition,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      AuraText(child: Text(definition.title)),
      AuraText(child: Text(definition.slug)),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}

class const _SkillCredentialDefinitionsAppBar({
  required final String workspaceId,
}) extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AuraAppBar(
    title: const TextLocale(LocaleKeys.skill_credentials_definitions_title),
    actions: [_SkillCredentialDefinitionAddButton(workspaceId: workspaceId)],
    leading: const _SkillCredentialDefinitionsBackButton(),
  );
}

class const _SkillCredentialDefinitionAddButton({
  required final String workspaceId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.add,
    onPressed: () => context.push(
      '/workspaces/$workspaceId/more/skill-credential-definitions/new',
    ),
  );
}

class const _SkillCredentialDefinitionsBackButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.arrow_back,
    onPressed: () => Navigator.of(context).pop(),
  );
}
