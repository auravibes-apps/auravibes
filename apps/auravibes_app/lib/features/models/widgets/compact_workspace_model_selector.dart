import 'dart:async';

import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/models/providers/recent_model_selections_notifier.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const CompactWorkspaceModelSelector({
  required final String workspaceId,
  required final String? workspaceModelSelectionId,
  required final ValueChanged<String?> onChanged,
  final bool compactMode = false,
  final bool sheetMode = false,
  final bool modelUnavailable = false,
  super.key,
}) extends HookConsumerWidget {
  static const _selectorWidth = 220.0;
  @override
  Widget build(BuildContext _, WidgetRef ref) {
    final recentModelIds = compactMode && !sheetMode
        ? const <String>[]
        : _recentModelIds(ref);

    return _ModelSelectorView(
      models: ref.watch(
        listModelsGroupedByProviderProvider(workspaceId: workspaceId),
      ),
      config: (
        selectedId: workspaceModelSelectionId,
        onChanged: _onModelChanged(ref),
        compactMode: compactMode,
        sheetMode: sheetMode,
        modelUnavailable: modelUnavailable,
        recentModelIds: recentModelIds,
      ),
    );
  }

  List<String> _recentModelIds(WidgetRef ref) =>
      ref.watch(recentModelSelectionsProvider(workspaceId)).value ??
      const <String>[];

  ValueChanged<String?> _onModelChanged(WidgetRef ref) =>
      (selectionId) => _recordAndChangeModel(
        ref: ref,
        workspaceId: workspaceId,
        onChanged: onChanged,
        selectionId: selectionId,
      );
}

void _recordAndChangeModel({
  required WidgetRef ref,
  required String workspaceId,
  required ValueChanged<String?> onChanged,
  required String? selectionId,
}) {
  if (selectionId != null) {
    unawaited(
      ref
          .read(recentModelSelectionsProvider(workspaceId).notifier)
          .record(selectionId),
    );
  }
  onChanged(selectionId);
}

class const _ModelSelectorView({
  required final AsyncValue<
    Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
  >
  models,
  required final _SelectorConfig config,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => switch (models) {
    AsyncLoading() => _ModelSelectorLoading(sheetMode: config.sheetMode),
    AsyncError(:final error, :final stackTrace) => _ModelSelectorError(
      sheetMode: config.sheetMode,
      error: error,
      stackTrace: stackTrace,
    ),
    AsyncData(:final value) => _CompactModelSelectorBody(
      groupedModels: value,
      config: config,
    ),
  };
}

typedef _SelectorConfig = ({
  String? selectedId,
  ValueChanged<String?> onChanged,
  bool compactMode,
  bool sheetMode,
  bool modelUnavailable,
  List<String> recentModelIds,
});

class const _ModelSelectorLoading({required final bool sheetMode})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => sheetMode
      ? const Center(child: AuraSpinner(size: .small))
      : const SizedBox(
          width: 180,
          child: AuraDropdownSelector<String>(
            options: [],
            placeholder: AuraSpinner(size: .small),
            isEnabled: false,
          ),
        );
}

class const _ModelSelectorError({
  required final bool sheetMode,
  required final Object error,
  required final StackTrace stackTrace,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => sheetMode
      ? AppErrorWidget(error: error, stackTrace: stackTrace)
      : SizedBox(
          width: CompactWorkspaceModelSelector._selectorWidth,
          child: AppErrorWidget(error: error, stackTrace: stackTrace),
        );
}

class const _CompactModelSelectorBody({
  required final Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
  groupedModels,
  required final _SelectorConfig config,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (config.compactMode && !config.sheetMode) {
      return _ModelCompactChip(
        groupedModels: groupedModels,
        workspaceModelSelectionId: config.selectedId,
        modelUnavailable: config.modelUnavailable,
      );
    }

    return _SearchableModelSelectorBody(
      groupedModels: groupedModels,
      config: config,
    );
  }
}

class const _SearchableModelSelectorBody({
  required final Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
  groupedModels,
  required final _SelectorConfig config,
}) extends HookWidget {
  @override
  Widget build(BuildContext _) {
    final search = _useModelSearch(
      groupedModels,
      config.selectedId,
      config.recentModelIds,
    );

    return config.sheetMode
        ? _ModelSheetSelector.fromSearch(
            groupedModels: groupedModels,
            config: config,
            search: search,
          )
        : _CompactModelDropdown.fromSearch(
            groupedModels: groupedModels,
            config: config,
            search: search,
          );
  }
}

typedef _ModelSearch = ({
  TextEditingController controller,
  List<WorkspaceModelSelectionWithConnectionEntity> models,
  List<WorkspaceModelSelectionWithConnectionEntity> recentModels,
  ValueChanged<String> onChanged,
});

typedef _ModelSearchResults = ({
  List<WorkspaceModelSelectionWithConnectionEntity> models,
  List<WorkspaceModelSelectionWithConnectionEntity> recentModels,
});

_ModelSearch _useModelSearch(
  Map<String, List<WorkspaceModelSelectionWithConnectionEntity>> groupedModels,
  String? selectedId,
  List<String> recentModelIds,
) {
  final search = useState<String>('');
  final results = _modelSearchResults(
    groupedModels,
    selectedId,
    recentModelIds,
    search.value,
  );

  return _buildModelSearch(
    controller: useTextEditingController(),
    models: results.models,
    recentModels: results.recentModels,
    onChanged: (value) => search.value = value,
  );
}

_ModelSearchResults _modelSearchResults(
  Map<String, List<WorkspaceModelSelectionWithConnectionEntity>> groupedModels,
  String? selectedId,
  List<String> recentModelIds,
  String searchValue,
) => _searchResultsForModels(
  _allModels(groupedModels),
  selectedId,
  recentModelIds,
  searchValue.trim().toLowerCase(),
);

_ModelSearchResults _searchResultsForModels(
  List<WorkspaceModelSelectionWithConnectionEntity> allModels,
  String? selectedId,
  List<String> recentModelIds,
  String searchTerm,
) {
  final recentModels = _recentModelsForSearch(
    allModels,
    recentModelIds,
    searchTerm,
  );

  return (
    models: _modelsForSearch(allModels, recentModels, selectedId, searchTerm),
    recentModels: recentModels,
  );
}

_ModelSearch _buildModelSearch({
  required TextEditingController controller,
  required List<WorkspaceModelSelectionWithConnectionEntity> models,
  required List<WorkspaceModelSelectionWithConnectionEntity> recentModels,
  required ValueChanged<String> onChanged,
}) => (
  controller: controller,
  models: models,
  recentModels: recentModels,
  onChanged: onChanged,
);

List<WorkspaceModelSelectionWithConnectionEntity> _recentModelsForSearch(
  List<WorkspaceModelSelectionWithConnectionEntity> models,
  List<String> recentModelIds,
  String searchTerm,
) => searchTerm.isEmpty
    ? _modelsForRecentSelectionIds(models, recentModelIds)
    : const <WorkspaceModelSelectionWithConnectionEntity>[];

List<WorkspaceModelSelectionWithConnectionEntity> _modelsForSearch(
  List<WorkspaceModelSelectionWithConnectionEntity> allModels,
  List<WorkspaceModelSelectionWithConnectionEntity> recentModels,
  String? selectedId,
  String searchTerm,
) {
  if (searchTerm.isNotEmpty) {
    return allModels
        .where((model) => _isVisibleModel(model, selectedId, searchTerm))
        .toList();
  }

  final recentIds = {
    for (final model in recentModels) model.workspaceModelSelection.id,
  };

  return allModels
      .where((model) => !recentIds.contains(model.workspaceModelSelection.id))
      .toList();
}

List<WorkspaceModelSelectionWithConnectionEntity> _allModels(
  Map<String, List<WorkspaceModelSelectionWithConnectionEntity>> grouped,
) => grouped.values.expand((group) => group).toList();

bool _isVisibleModel(
  WorkspaceModelSelectionWithConnectionEntity model,
  String? selectedId,
  String searchTerm,
) =>
    model.workspaceModelSelection.id == selectedId ||
    _matchesSearch(model, searchTerm);

List<WorkspaceModelSelectionWithConnectionEntity> _modelsForRecentSelectionIds(
  List<WorkspaceModelSelectionWithConnectionEntity> models,
  List<String> recentModelIds,
) {
  final modelsById = {
    for (final model in models) model.workspaceModelSelection.id: model,
  };
  final seen = <String>{};
  final result = <WorkspaceModelSelectionWithConnectionEntity>[];

  for (final recentModelId in recentModelIds) {
    if (!seen.add(recentModelId)) continue;
    final model = modelsById[recentModelId];
    if (model != null) result.add(model);
  }

  return result;
}

class const _ModelSheetSelector({
  required final TextEditingController controller,
  required final Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
  groupedModels,
  required final List<WorkspaceModelSelectionWithConnectionEntity>
  filteredModels,
  required final List<WorkspaceModelSelectionWithConnectionEntity> recentModels,
  required final String? workspaceModelSelectionId,
  required final ValueChanged<String?> onChanged,
  required final ValueChanged<String> onSearchChanged,
}) extends StatelessWidget {
  new fromSearch({
    required Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
    groupedModels,
    required _SelectorConfig config,
    required _ModelSearch search,
  }) : this(
         controller: search.controller,
         groupedModels: groupedModels,
         filteredModels: search.models,
         recentModels: search.recentModels,
         workspaceModelSelectionId: config.selectedId,
         onChanged: config.onChanged,
         onSearchChanged: search.onChanged,
       );

  @override
  Widget build(BuildContext context) {
    if (groupedModels.isEmpty) {
      return const Center(
        child: TextLocale(LocaleKeys.models_screens_select_model),
      );
    }

    return _ModelSheetContent(
      controller: controller,
      filteredModels: filteredModels,
      recentModels: recentModels,
      workspaceModelSelectionId: workspaceModelSelectionId,
      onChanged: onChanged,
      onSearchChanged: onSearchChanged,
    );
  }
}

class _ModelSheetContent extends Column {
  new({
    required TextEditingController controller,
    required List<WorkspaceModelSelectionWithConnectionEntity> filteredModels,
    required List<WorkspaceModelSelectionWithConnectionEntity> recentModels,
    required String? workspaceModelSelectionId,
    required ValueChanged<String?> onChanged,
    required ValueChanged<String> onSearchChanged,
  }) : super(
         mainAxisSize: .min,
         children: [
           _ModelSearchInput(
             controller: controller,
             onChanged: onSearchChanged,
           ),
           const AuraSizedBox(height: .sm),
           Flexible(
             child: _ModelSheetOptions(
               models: filteredModels,
               recentModels: recentModels,
               workspaceModelSelectionId: workspaceModelSelectionId,
               onChanged: onChanged,
             ),
           ),
         ],
       );
}

class const _ModelSearchInput({
  required final TextEditingController controller,
  required final ValueChanged<String> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: controller,
    prefixIcon: const AuraIcon(Icons.search),
    onChanged: onChanged,
  );
}

typedef _ModelSheetItemConfig = ({
  List<WorkspaceModelSelectionWithConnectionEntity> models,
  List<WorkspaceModelSelectionWithConnectionEntity> recentModels,
  String? workspaceModelSelectionId,
  ValueChanged<String?> onChanged,
});

class _ModelSheetOptions extends ListView {
  static const _sectionTitleCount = 2;
  static const _recentTitleIndex = 0;
  static const _recentModelIndexOffset = 1;
  static const int _allModelsIndexOffset = _sectionTitleCount;

  new({
    required List<WorkspaceModelSelectionWithConnectionEntity> models,
    required List<WorkspaceModelSelectionWithConnectionEntity> recentModels,
    required String? workspaceModelSelectionId,
    required ValueChanged<String?> onChanged,
  }) : super.separated(
         itemBuilder: (context, index) => _ModelSheetItem(
           config: (
             models: models,
             recentModels: recentModels,
             workspaceModelSelectionId: workspaceModelSelectionId,
             onChanged: onChanged,
           ),
           index: index,
         ),
         separatorBuilder: (context, index) => const AuraSizedBox(height: .sm),
         itemCount:
             models.length +
             recentModels.length +
             (recentModels.isEmpty ? 0 : _sectionTitleCount),
       );
}

class const _ModelSheetItem({
  required final _ModelSheetItemConfig config,
  required final int index,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    final recentCount = config.recentModels.length;
    if (recentCount > 0 && index == _ModelSheetOptions._recentTitleIndex) {
      return const _RecentModelsSectionTitle();
    }
    if (recentCount > 0 &&
        index == recentCount + _ModelSheetOptions._recentModelIndexOffset) {
      return const _AllModelsSectionTitle();
    }

    return _ModelSheetTile(
      model: _modelForIndex(config, index),
      workspaceModelSelectionId: config.workspaceModelSelectionId,
      onChanged: config.onChanged,
    );
  }

  WorkspaceModelSelectionWithConnectionEntity _modelForIndex(
    _ModelSheetItemConfig config,
    int index,
  ) {
    final recentModels = config.recentModels;
    if (recentModels.isEmpty) return config.models[index];
    if (index <= recentModels.length) {
      return recentModels[index - _ModelSheetOptions._recentModelIndexOffset];
    }

    return config.models[index -
        recentModels.length -
        _ModelSheetOptions._allModelsIndexOffset];
  }
}

class const _ModelSheetTile({
  required final WorkspaceModelSelectionWithConnectionEntity model,
  required final String? workspaceModelSelectionId,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selection = model.workspaceModelSelection;
    final isSelected = selection.id == workspaceModelSelectionId;

    return _SelectableModelTile(
      model: model,
      isSelected: isSelected,
      onTap: () => _select(context, selection.id),
    );
  }

  void _select(BuildContext context, String id) {
    onChanged(id);
    final _ = Navigator.maybePop(context);
  }
}

class const _SelectableModelTile({
  required final WorkspaceModelSelectionWithConnectionEntity model,
  required final bool isSelected,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraTile(
    child: _ModelSheetOptionContent(model: model),
    onTap: onTap,
    variant: isSelected ? AuraTileVariant.selected : AuraTileVariant.surface,
    trailing: isSelected ? const AuraIcon(Icons.check, tint: .primary) : null,
  );
}

class const _CompactModelDropdown({
  required final Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
  groupedModels,
  required final List<WorkspaceModelSelectionWithConnectionEntity>
  filteredModels,
  required final List<WorkspaceModelSelectionWithConnectionEntity> recentModels,
  required final String? workspaceModelSelectionId,
  required final ValueChanged<String?> onChanged,
  required final TextEditingController controller,
  required final ValueChanged<String> onSearchChanged,
}) extends StatelessWidget {
  new fromSearch({
    required Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
    groupedModels,
    required _SelectorConfig config,
    required _ModelSearch search,
  }) : this(
         groupedModels: groupedModels,
         filteredModels: search.models,
         recentModels: search.recentModels,
         workspaceModelSelectionId: config.selectedId,
         onChanged: config.onChanged,
         controller: search.controller,
         onSearchChanged: search.onChanged,
       );

  @override
  Widget build(BuildContext context) {
    if (groupedModels.isEmpty) {
      return const _EmptyModelDropdown();
    }

    return _ModelDropdown(
      filteredModels: filteredModels,
      recentModels: recentModels,
      workspaceModelSelectionId: workspaceModelSelectionId,
      onChanged: onChanged,
      controller: controller,
      onSearchChanged: onSearchChanged,
    );
  }
}

class const _EmptyModelDropdown() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: CompactWorkspaceModelSelector._selectorWidth,
    child: AuraDropdownSelector<String>(
      options: [],
      placeholder: TextLocale(
        LocaleKeys.models_screens_select_model,
        softWrap: false,
        overflow: .ellipsis,
        maxLines: 1,
      ),
      isEnabled: false,
    ),
  );
}

class _ModelDropdown extends SizedBox {
  new({
    required List<WorkspaceModelSelectionWithConnectionEntity> filteredModels,
    required List<WorkspaceModelSelectionWithConnectionEntity> recentModels,
    required String? workspaceModelSelectionId,
    required ValueChanged<String?> onChanged,
    required TextEditingController controller,
    required ValueChanged<String> onSearchChanged,
  }) : super(
         width: CompactWorkspaceModelSelector._selectorWidth,
         child: AuraDropdownSelector<String>(
           options: [
             if (recentModels.isNotEmpty)
               const AuraDropdownOption<String>(
                 value: _recentModelsSectionValue,
                 child: _RecentModelsSectionTitle(),
                 isEnabled: false,
               ),
             for (final model in recentModels) _ModelDropdownOption(model),
             if (recentModels.isNotEmpty)
               const AuraDropdownOption<String>(
                 value: _allModelsSectionValue,
                 child: _AllModelsSectionTitle(),
                 isEnabled: false,
               ),
             for (final model in filteredModels) _ModelDropdownOption(model),
           ],
           value: workspaceModelSelectionId,
           onChanged: onChanged,
           placeholder: const TextLocale(
             LocaleKeys.models_screens_select_model,
             softWrap: false,
             overflow: .ellipsis,
             maxLines: 1,
           ),
           header: _DropdownSearchHeader(
             controller: controller,
             onChanged: onSearchChanged,
           ),
         ),
       );
}

const _recentModelsSectionValue = '__recent_models__';
const _allModelsSectionValue = '__all_models__';

class const _RecentModelsSectionTitle() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraText(
    child: TextLocale(LocaleKeys.models_screens_recent_models),
    style: .heading6,
  );
}

class const _AllModelsSectionTitle() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraDivider.withLabel(
    label: TextLocale(LocaleKeys.models_screens_all_models),
  );
}

BorderRadius _inputRadius(BuildContext context) =>
    BorderRadius.all(.circular(context.auraTheme.fromBorderRadius(.xl)));

class _ModelDropdownOption extends AuraDropdownOption<String> {
  new(WorkspaceModelSelectionWithConnectionEntity model)
    : super(
        value: model.workspaceModelSelection.id,
        child: Text(
          model.workspaceModelSelection.modelName ??
              model.workspaceModelSelection.modelId,
          overflow: .ellipsis,
          maxLines: 1,
        ),
        trailing: _ModelOptionSubtitle(model: model),
      );
}

class const _DropdownSearchHeader({
  required final TextEditingController controller,
  required final ValueChanged<String> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraPadding(
    child: TextField(
      controller: controller,
      decoration: _searchDecoration(context),
      style: .new(color: context.auraColors.onSurface),
      onChanged: onChanged,
    ),
    padding: .small,
  );
}

InputDecoration _searchDecoration(BuildContext context) {
  final colors = context.auraColors;
  final radius = _inputRadius(context);

  return InputDecoration(
    isDense: true,
    contentPadding: _searchPadding(context),
    focusedBorder: _inputOutline(radius, colors.primary),
    enabledBorder: _inputOutline(radius, colors.outline),
    border: _inputOutline(radius, colors.outline),
  );
}

EdgeInsets _searchPadding(BuildContext context) => EdgeInsets.symmetric(
  vertical: context.auraTheme.fromSpacing(.sm),
  horizontal: context.auraTheme.fromSpacing(.md),
);

OutlineInputBorder _inputOutline(BorderRadius radius, Color color) =>
    OutlineInputBorder(
      borderSide: .new(color: color),
      borderRadius: radius,
    );

class const _ModelCompactChip({
  required final Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
  groupedModels,
  required final String? workspaceModelSelectionId,
  required final bool modelUnavailable,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (modelUnavailable) {
      return const _ModelChip(
        label: TextLocale(
          LocaleKeys.models_screens_model_unavailable,
          softWrap: false,
          overflow: .ellipsis,
          maxLines: 1,
        ),
        trailing: AuraIcon(Icons.warning_amber_rounded, tint: .warning),
      );
    }

    if (groupedModels.isEmpty) {
      return const _ModelChip(
        label: TextLocale(
          LocaleKeys.models_screens_select_model,
          softWrap: false,
          overflow: .ellipsis,
          maxLines: 1,
        ),
      );
    }

    return _SelectedModelChip(
      selectedModel: _selectedModel(groupedModels, workspaceModelSelectionId),
    );
  }
}

class _SelectedModelChip extends _ModelChip {
  new({required WorkspaceModelSelectionWithConnectionEntity? selectedModel})
    : super(
        label: switch (selectedModel?.workspaceModelSelection.modelName ??
            selectedModel?.workspaceModelSelection.modelId) {
          final name? => Text(name, overflow: .ellipsis, maxLines: 1),
          null => const TextLocale(
            LocaleKeys.models_screens_select_model,
            softWrap: false,
            overflow: .ellipsis,
            maxLines: 1,
          ),
        },
      );
}

WorkspaceModelSelectionWithConnectionEntity? _selectedModel(
  Map<String, List<WorkspaceModelSelectionWithConnectionEntity>> groupedModels,
  String? workspaceModelSelectionId,
) => groupedModels.values
    .expand((group) => group)
    .where(
      (model) => model.workspaceModelSelection.id == workspaceModelSelectionId,
    )
    .firstOrNull;

class const _ModelChip({required final Widget label, final Widget? trailing})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _DecoratedModelChip(
      label: label,
      borderColor: context.auraColors.outline,
      radius: context.auraTheme.fromBorderRadius(.xl),
      trailing: trailing,
    );
  }
}

class _DecoratedModelChip extends Container {
  new({
    required Widget label,
    required Color borderColor,
    required double radius,
    Widget? trailing,
  }) : super(
         padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
         decoration: BoxDecoration(
           border: Border.all(color: borderColor),
           borderRadius: BorderRadius.circular(radius),
         ),
         width: .infinity,
         child: Row(
           children: [
             const AuraIcon(Icons.memory_outlined, size: .small),
             const AuraSizedBox(width: .xs),
             Flexible(child: label),
             if (trailing case final value?) ...[
               const AuraSizedBox(width: .xs),
               value,
             ],
           ],
         ),
       );
}

class const _ModelSheetOptionContent({
  required final WorkspaceModelSelectionWithConnectionEntity model,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selection = model.workspaceModelSelection;

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        _ModelOptionTitle(selection: selection),
        const AuraSizedBox(height: .xs),
        _ModelBadges(model: model),
      ],
    );
  }
}

class const _ModelOptionTitle({
  required final WorkspaceModelSelectionEntity selection,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: Text(
      selection.modelName ?? selection.modelId,
      overflow: .ellipsis,
      maxLines: 1,
    ),
    style: .bodyLarge,
  );
}

class const _ModelBadges({
  required final WorkspaceModelSelectionWithConnectionEntity model,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: context.auraTheme.fromSpacing(.xs),
    runSpacing: context.auraTheme.fromSpacing(.xs),
    children: [
      _ModelBadge(label: model.workspaceModelSelection.modelId),
      _ModelBadge(
        label: '${model.modelsProvider.name} - ${model.modelConnection.name}',
      ),
    ],
  );
}

class const _ModelBadge({required final String label}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraBadge.text(
    child: Text(label, overflow: .ellipsis),
    variant: .soft,
    size: .small,
  );
}

bool _matchesSearch(
  WorkspaceModelSelectionWithConnectionEntity model,
  String searchTerm,
) {
  final selection = model.workspaceModelSelection;

  return [
    selection.modelName,
    selection.modelId,
    model.modelsProvider.name,
    model.modelConnection.name,
  ].any((value) => value?.toLowerCase().contains(searchTerm) ?? false);
}

class const _ModelOptionSubtitle({
  required final WorkspaceModelSelectionWithConnectionEntity model,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selection = model.workspaceModelSelection;

    return SizedBox(
      width: 120,
      child: _ModelOptionSubtitleContent(
        modelId: selection.modelId,
        connectionName:
            '${model.modelsProvider.name} - ${model.modelConnection.name}',
      ),
    );
  }
}

class const _ModelOptionSubtitleContent({
  required final String modelId,
  required final String connectionName,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .end,
    children: [_SubtitleText(modelId), _SubtitleText(connectionName)],
  );
}

class const _SubtitleText(final String value) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: Text(value, overflow: .ellipsis),
    style: .bodySmall,
  );
}
