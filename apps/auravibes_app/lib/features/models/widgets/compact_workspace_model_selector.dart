import 'dart:async';

import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/models/providers/recent_model_selections_notifier.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
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
  final VoidCallback? onCompactTap,
  super.key,
}) extends HookConsumerWidget {
  static const _selectorWidth = 220.0;
  @override
  Widget build(BuildContext _, WidgetRef ref) => _ModelSelectorView(
    models: ref.watch(
      listModelsGroupedByProviderProvider(workspaceId: workspaceId),
    ),
    config: _selectorConfig(ref),
  );

  _SelectorConfig _selectorConfig(WidgetRef ref) => (
    selectedId: workspaceModelSelectionId,
    onChanged: _onModelChanged(ref),
    compactMode: compactMode,
    sheetMode: sheetMode,
    modelUnavailable: modelUnavailable,
    onCompactTap: onCompactTap,
    recentModelIds: compactMode && !sheetMode
        ? const <String>[]
        : _recentModelIds(ref),
  );

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
    AsyncLoading() => _ModelSelectorLoading(
      compactMode: config.compactMode,
      sheetMode: config.sheetMode,
      onCompactTap: config.onCompactTap,
    ),
    AsyncError(:final error, :final stackTrace) => _ModelSelectorError(
      compactMode: config.compactMode,
      sheetMode: config.sheetMode,
      error: error,
      stackTrace: stackTrace,
      onCompactTap: config.onCompactTap,
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
  VoidCallback? onCompactTap,
  List<String> recentModelIds,
});

class const _ModelSelectorLoading({
  required final bool compactMode,
  required final bool sheetMode,
  required final VoidCallback? onCompactTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (sheetMode) return const Center(child: AuraSpinner(size: .small));
    if (compactMode) {
      return _ModelChip(
        label: const AuraSpinner(size: .small),
        onTap: onCompactTap,
      );
    }

    return const SizedBox(
      width: 180,
      child: AuraDropdownSelector<String>(
        options: [],
        placeholder: AuraSpinner(size: .small),
        isEnabled: false,
      ),
    );
  }
}

class const _ModelSelectorError({
  required final bool compactMode,
  required final bool sheetMode,
  required final Object error,
  required final StackTrace stackTrace,
  required final VoidCallback? onCompactTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (sheetMode) return AppErrorWidget(error: error, stackTrace: stackTrace);
    if (compactMode) {
      return _ModelChip(
        label: AppErrorWidget(error: error, stackTrace: stackTrace),
        onTap: onCompactTap,
      );
    }

    return SizedBox(
      width: CompactWorkspaceModelSelector._selectorWidth,
      child: AppErrorWidget(error: error, stackTrace: stackTrace),
    );
  }
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
        onCompactTap: config.onCompactTap,
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
    textInputAction: .search,
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

    return _ModelSheetRow(
      model: model,
      isSelected: isSelected,
      onChanged: onChanged,
    );
  }
}

class const _ModelSheetRow({
  required final WorkspaceModelSelectionWithConnectionEntity model,
  required final bool isSelected,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _ModelSheetSelection(
          model: model,
          isSelected: isSelected,
          onChanged: onChanged,
        ),
      ),
      _ModelToolSamplingMenu(model: model),
    ],
  );
}

class const _ModelSheetSelection({
  required final WorkspaceModelSelectionWithConnectionEntity model,
  required final bool isSelected,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SelectableModelTile(
    model: model,
    isSelected: isSelected,
    onTap: () {
      onChanged(model.workspaceModelSelection.id);
      final _ = Navigator.maybePop(context);
    },
    trailing: isSelected ? const AuraIcon(Icons.check, tint: .primary) : null,
  );
}

class const _ModelToolSamplingMenu({
  required final WorkspaceModelSelectionWithConnectionEntity model,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuraPopupMenuButton(
      items: _menuItems(context, ref),
      icon: Icons.tune,
      tooltip: _tooltip(context),
    );
  }

  List<AuraPopupMenuEntry> _menuItems(BuildContext context, WidgetRef ref) =>
      _toolSamplingMenuItems(
        context,
        model,
        (policy) => unawaited(_saveToolSamplingPolicy(context, ref, policy)),
      );

  String _tooltip(BuildContext context) {
    final selection = model.workspaceModelSelection;
    final modelName = selection.modelName ?? selection.modelId;

    return LocaleKeys.models_screens_tool_sampling_settings_for_model.tr(
      args: [modelName],
      context: context,
    );
  }

  Future<void> _saveToolSamplingPolicy(
    BuildContext context,
    WidgetRef ref,
    ToolSamplingPolicy? policy,
  ) async {
    final selection = model.workspaceModelSelection;
    if (policy == .require && !_canRequireStrictToolSampling(model)) return;

    try {
      await _updateToolSamplingPolicy(ref, selection.id, policy);
    } on Object catch (_) {
      if (!context.mounted) return;
      _showUpdateError(context);
    }
  }

  Future<void> _updateToolSamplingPolicy(
    WidgetRef ref,
    String selectionId,
    ToolSamplingPolicy? policy,
  ) async {
    final store = await ref.read(
      modelSelectionStoreProvider(model.modelConnection.workspaceId).future,
    );
    await store.updateToolSamplingPolicy(selectionId, policy);
  }

  void _showUpdateError(BuildContext context) {
    final _ = AuraSnackBars.show(
      context: context,
      content: const TextLocale(
        LocaleKeys.models_screens_tool_sampling_update_error,
      ),
      variant: .error,
    );
  }
}

class const _SelectableModelTile({
  required final WorkspaceModelSelectionWithConnectionEntity model,
  required final bool isSelected,
  required final VoidCallback onTap,
  required final Widget? trailing,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraTile(
    child: _ModelSheetOptionContent(model: model),
    onTap: onTap,
    variant: isSelected ? AuraTileVariant.selected : AuraTileVariant.surface,
    trailing: trailing,
  );
}

bool _canRequireStrictToolSampling(
  WorkspaceModelSelectionWithConnectionEntity model,
) {
  final selection = model.workspaceModelSelection;
  if (!selection.supportsToolCalls) return false;

  final providerId = model.modelsProvider.type?.name ?? '';
  final baseUrl = _strictToolSamplingBaseUrl(model, providerId);

  return strictToolSamplingProfile(providerId, selection.modelId, baseUrl) !=
      null;
}

String? _strictToolSamplingBaseUrl(
  WorkspaceModelSelectionWithConnectionEntity model,
  String providerId,
) {
  final connectionUrl = _nonBlank(model.modelConnection.url);
  if (connectionUrl != null) return connectionUrl;
  if (providerId == 'openrouter') return null;

  final providerUrl = _nonBlank(model.modelsProvider.url);
  if (providerUrl != null) return providerUrl;

  return providerId == 'openai' ? providerProfile('openai').defaultUrl : null;
}

String? _nonBlank(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;

  return trimmed;
}

List<AuraPopupMenuEntry> _toolSamplingMenuItems(
  BuildContext context,
  WorkspaceModelSelectionWithConnectionEntity model,
  ValueChanged<ToolSamplingPolicy?> onSelected,
) {
  final selection = model.workspaceModelSelection;
  final savedPolicy = model.workspaceModelSelection.toolSamplingPolicy;
  final canRequire = _canRequireStrictToolSampling(model);
  final effectivePolicy = _effectiveToolSamplingPolicy(selection, canRequire);

  return [
    _automaticToolSamplingItem(
      context,
      effectivePolicy,
      savedPolicy,
      onSelected,
    ),
    for (final policy in ToolSamplingPolicy.values)
      _toolSamplingPolicyItem(policy, savedPolicy, canRequire, onSelected),
  ];
}

AuraPopupMenuEntry _automaticToolSamplingItem(
  BuildContext context,
  ToolSamplingPolicy effectivePolicy,
  ToolSamplingPolicy? savedPolicy,
  ValueChanged<ToolSamplingPolicy?> onSelected,
) => AuraPopupMenuItem(
  title: TextLocale(
    LocaleKeys.models_screens_tool_sampling_automatic,
    args: [_toolSamplingPolicyLocaleKey(effectivePolicy).tr(context: context)],
  ),
  onTap: () => onSelected(null),
  trailing: savedPolicy == null ? const AuraIcon(Icons.check) : null,
);

AuraPopupMenuEntry _toolSamplingPolicyItem(
  ToolSamplingPolicy policy,
  ToolSamplingPolicy? savedPolicy,
  bool canRequire,
  ValueChanged<ToolSamplingPolicy?> onSelected,
) {
  final isEnabled = policy != .require || canRequire;
  final isSelected = savedPolicy == policy;

  return AuraPopupMenuItem(
    title: TextLocale(_toolSamplingPolicyLocaleKey(policy)),
    onTap: isEnabled ? () => onSelected(policy) : null,
    trailing: isSelected ? const AuraIcon(Icons.check) : null,
  );
}

String _toolSamplingPolicyLocaleKey(ToolSamplingPolicy policy) =>
    switch (policy) {
      .off => LocaleKeys.models_screens_tool_sampling_off,
      .prefer => LocaleKeys.models_screens_tool_sampling_prefer,
      .require => LocaleKeys.models_screens_tool_sampling_require,
    };

ToolSamplingPolicy _effectiveToolSamplingPolicy(
  WorkspaceModelSelectionEntity selection,
  bool canRequire,
) =>
    selection.toolSamplingPolicy ??
    (canRequire ? ToolSamplingPolicy.prefer : ToolSamplingPolicy.off);

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

BorderRadius _inputRadius(BuildContext context) => BorderRadius.all(
  .circular(AuraCornerRadiusScope.resolve(context, fallback: .xl)),
);

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
      textInputAction: .search,
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
  required final VoidCallback? onCompactTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selectedModel = _selectedModel(
      groupedModels,
      workspaceModelSelectionId,
    );
    final isUnavailable =
        modelUnavailable ||
        (workspaceModelSelectionId != null && selectedModel == null);
    if (isUnavailable) return _UnavailableModelChip(onTap: onCompactTap);

    return _SelectedModelChip(
      selectedModel: selectedModel,
      onTap: onCompactTap,
    );
  }
}

class const _UnavailableModelChip({required final VoidCallback? onTap})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ModelChip(
    label: const TextLocale(
      LocaleKeys.models_screens_model_unavailable,
      softWrap: false,
      overflow: .ellipsis,
      maxLines: 1,
    ),
    trailing: const AuraIcon(Icons.warning_amber_rounded, tint: .warning),
    onTap: onTap,
  );
}

class _SelectedModelChip extends _ModelChip {
  new({
    required WorkspaceModelSelectionWithConnectionEntity? selectedModel,
    required super.onTap,
  }) : super(
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

class const _ModelChip({
  required final Widget label,
  final Widget? trailing,
  final VoidCallback? onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraTile(
      child: label,
      onTap: onTap,
      variant: .outlined,
      size: .small,
      leading: const AuraIcon(Icons.memory_outlined, size: .small),
      trailing: trailing,
    );
  }
}

class const _ModelSheetOptionContent({
  required final WorkspaceModelSelectionWithConnectionEntity model,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final canRequire = _canRequireStrictToolSampling(model);

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        _ModelOptionTitle(selection: model.workspaceModelSelection),
        const AuraSizedBox(height: .xs),
        _ModelBadges(model: model),
        const AuraSizedBox(height: .xs),
        _ToolSamplingPolicyDetails(model: model, canRequire: canRequire),
      ],
    );
  }
}

class const _ToolSamplingPolicyDetails({
  required final WorkspaceModelSelectionWithConnectionEntity model,
  required final bool canRequire,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selection = model.workspaceModelSelection;

    return Column(
      crossAxisAlignment: .start,
      children: [
        TextLocale(
          LocaleKeys.models_screens_tool_sampling_policy,
          args: [_toolSamplingPolicyLabel(context, selection, canRequire)],
        ),
        TextLocale(_toolSamplingCapabilityLabel(selection, canRequire)),
        if (!canRequire)
          TextLocale(
            selection.supportsToolCalls
                ? LocaleKeys.models_screens_tool_sampling_unverified_explanation
                : LocaleKeys.models_screens_tool_sampling_unsupported,
          ),
      ],
    );
  }
}

String _toolSamplingPolicyLabel(
  BuildContext context,
  WorkspaceModelSelectionEntity selection,
  bool canRequire,
) {
  final policy = _effectiveToolSamplingPolicy(selection, canRequire);
  final policyLabel = _toolSamplingPolicyLocaleKey(policy).tr(context: context);
  if (selection.toolSamplingPolicy != null) return policyLabel;

  return LocaleKeys.models_screens_tool_sampling_automatic.tr(
    args: [policyLabel],
    context: context,
  );
}

String _toolSamplingCapabilityLabel(
  WorkspaceModelSelectionEntity selection,
  bool canRequire,
) {
  if (canRequire) return LocaleKeys.models_screens_tool_sampling_verified;
  if (selection.supportsToolCalls) {
    return LocaleKeys.models_screens_tool_sampling_unverified;
  }

  return LocaleKeys.models_screens_tool_sampling_no_tool_calls;
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
