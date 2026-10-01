// Required: Existing UI spacing uses small numeric values.
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_definitions_provider.dart';
import 'package:auravibes_app/features/skills/usecases/duplicate_credential_definition_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/bottom_padding.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (definitionsAsync) {
        AsyncData(:final value) => _CredentialDefinitionsData(
          definitions: value,
          workspaceId: workspaceId,
        ),
        AsyncLoading(value: final value?, hasValue: true) =>
          _CredentialDefinitionsLoading(definitions: value),
        AsyncLoading() => const Center(child: AuraSpinner()),
        AsyncError() => _CredentialDefinitionsError(workspaceId: workspaceId),
      };
}

class const _CredentialDefinitionsError({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: AuraColumn(
      children: [
        const TextLocale(LocaleKeys.skill_credentials_definitions_error),
        _CredentialDefinitionsRetryButton(workspaceId: workspaceId),
        _CredentialDefinitionsReturnButton(workspaceId: workspaceId),
      ],
    ),
  );
}

class const _CredentialDefinitionsRetryButton({
  required final String workspaceId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraButton(
    onPressed: () =>
        ref.invalidate(skillCredentialDefinitionsProvider(workspaceId)),
    child: const TextLocale(LocaleKeys.route_state_retry),
  );
}

class const _CredentialDefinitionsReturnButton({
  required final String workspaceId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => ServiceConnectionsRoute(
      workspaceId: workspaceId,
      view: 'credentials',
    ).go(context),
    child: const TextLocale('connection_setup.return_connections'),
  );
}

class const _CredentialDefinitionsData({
  required final List<SkillCredentialDefinitionEntity> definitions,
  required final String workspaceId,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CredentialDefinitionsData> createState() =>
      _CredentialDefinitionsDataState();
}

class _CredentialDefinitionsDataState
    extends ConsumerState<_CredentialDefinitionsData> {
  final _duplicatingIds = <String>{};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filteredDefinitions = _filteredDefinitions();

    return Column(
      children: [
        _CredentialDefinitionsSearch(onChanged: _updateQuery),
        Expanded(
          child: _CredentialDefinitionsResults(
            definitions: widget.definitions,
            filteredDefinitions: filteredDefinitions,
            workspaceId: widget.workspaceId,
            duplicatingIds: _duplicatingIds,
            onDuplicate: (definition) => _duplicate(context, definition),
          ),
        ),
      ],
    );
  }

  List<SkillCredentialDefinitionEntity> _filteredDefinitions() {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.definitions;

    return widget.definitions
        .where(
          (definition) =>
              definition.title.toLowerCase().contains(query) ||
              definition.slug.toLowerCase().contains(query),
        )
        .toList();
  }

  void _updateQuery(String value) => setState(() => _query = value);

  Future<void> _duplicate(
    BuildContext context,
    SkillCredentialDefinitionEntity definition,
  ) async {
    if (!_startDuplicate(definition.id)) return;
    final success = await _tryDuplicate(definition.id);
    _finishDuplicate(definition.id);
    if (!context.mounted) return;

    _showDuplicateFeedback(context, success: success);
  }

  bool _startDuplicate(String definitionId) {
    if (_duplicatingIds.contains(definitionId)) return false;
    setState(() => _duplicatingIds.add(definitionId));

    return true;
  }

  Future<bool> _tryDuplicate(String definitionId) async {
    try {
      final usecase = ref.read(
        duplicateCredentialDefinitionUsecaseProvider(widget.workspaceId),
      );
      final _ = await usecase.call(definitionId);
      ref.invalidate(skillCredentialDefinitionsProvider(widget.workspaceId));

      return true;
    } on Object {
      return false;
    }
  }

  void _finishDuplicate(String definitionId) {
    if (mounted) setState(() => _duplicatingIds.remove(definitionId));
  }

  void _showDuplicateFeedback(BuildContext context, {required bool success}) {
    final _ = AuraSnackBars.show(
      context: context,
      content: Text(
        (success
                ? LocaleKeys.skill_credentials_definitions_duplicate_success
                : LocaleKeys.skill_credentials_definitions_duplicate_error)
            .tr(context: context),
      ),
      variant: success ? .success : .error,
    );
  }
}

class const _CredentialDefinitionsSearch({
  required final ValueChanged<String> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final label = LocaleKeys.skill_credentials_definitions_search.tr(
      context: context,
    );

    return Padding(
      padding: const EdgeInsets.all(8),
      child: AuraInput(
        placeholder: const TextLocale(
          LocaleKeys.skill_credentials_definitions_search,
        ),
        prefixIcon: const AuraIcon(Icons.search),
        size: .small,
        textInputAction: .search,
        onChanged: onChanged,
        semanticLabel: label,
      ),
    );
  }
}

class const _CredentialDefinitionsResults({
  required final List<SkillCredentialDefinitionEntity> definitions,
  required final List<SkillCredentialDefinitionEntity> filteredDefinitions,
  required final String workspaceId,
  required final Set<String> duplicatingIds,
  required final ValueChanged<SkillCredentialDefinitionEntity> onDuplicate,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (definitions.isEmpty) {
      return const Center(
        child: TextLocale(LocaleKeys.skill_credentials_definitions_empty),
      );
    }
    if (filteredDefinitions.isEmpty) {
      return const Center(
        child: TextLocale(
          LocaleKeys.skill_credentials_definitions_search_empty,
        ),
      );
    }

    return _CredentialDefinitionsList(
      definitions: filteredDefinitions,
      workspaceId: workspaceId,
      duplicatingIds: duplicatingIds,
      onDuplicate: onDuplicate,
    );
  }
}

class const _CredentialDefinitionsList({
  required final List<SkillCredentialDefinitionEntity> definitions,
  required final String workspaceId,
  required final Set<String> duplicatingIds,
  required final ValueChanged<SkillCredentialDefinitionEntity> onDuplicate,
}) extends StatelessWidget {
  static const _contentPadding = 8.0;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(
        _contentPadding,
      ).copyWith(bottom: BottomPadding.of(context, minimum: _contentPadding)),
      itemBuilder: _itemBuilder,
      separatorBuilder: _separatorBuilder,
      itemCount: definitions.length,
    );
  }

  Widget _itemBuilder(BuildContext _, int index) {
    return _CredentialDefinitionCard(
      definition: definitions[index],
      workspaceId: workspaceId,
      isDuplicating: duplicatingIds.contains(definitions[index].id),
      onDuplicate: onDuplicate,
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
  required final bool isDuplicating,
  required final ValueChanged<SkillCredentialDefinitionEntity> onDuplicate,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCard(
    child: _CredentialDefinitionTile(
      definition: definition,
      workspaceId: workspaceId,
      isDuplicating: isDuplicating,
      onDuplicate: onDuplicate,
    ),
    style: .border,
  );
}

class const _CredentialDefinitionTile({
  required final SkillCredentialDefinitionEntity definition,
  required final String workspaceId,
  required final bool isDuplicating,
  required final ValueChanged<SkillCredentialDefinitionEntity> onDuplicate,
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
    trailing: _CredentialDefinitionActions(
      definition: definition,
      isDuplicating: isDuplicating,
      onDuplicate: onDuplicate,
    ),
  );
}

class const _CredentialDefinitionActions({
  required final SkillCredentialDefinitionEntity definition,
  required final bool isDuplicating,
  required final ValueChanged<SkillCredentialDefinitionEntity> onDuplicate,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
      AuraPopupMenuButton(
        items: [
          AuraPopupMenuItem(
            title: const TextLocale(
              LocaleKeys.skill_credentials_definitions_duplicate,
            ),
            onTap: isDuplicating ? null : () => onDuplicate(definition),
            leading: const AuraIcon(Icons.copy_outlined),
          ),
        ],
        tooltip: LocaleKeys.common_show_more.tr(context: context),
      ),
      const AuraIcon(Icons.chevron_right),
    ],
    mainAxisSize: .min,
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
  Widget build(BuildContext context) => AuraAppBarWithDrawer(
    title: const TextLocale(LocaleKeys.skill_credentials_definitions_title),
    actions: [_SkillCredentialDefinitionAddButton(workspaceId: workspaceId)],
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
