import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([])
class CompactWorkspaceModelSelector extends HookConsumerWidget {
  const CompactWorkspaceModelSelector({
    required this.workspaceId,
    required this.workspaceModelSelectionId,
    required this.onChanged,
    this.compactMode = false,
    this.sheetMode = false,
    super.key,
  });

  final String workspaceId;
  final String? workspaceModelSelectionId;
  final ValueChanged<String?> onChanged;
  final bool compactMode;
  final bool sheetMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedModelsAsync = ref.watch(
      listModelsGroupedByProviderProvider(workspaceId: workspaceId),
    );

    return switch (groupedModelsAsync) {
      AsyncLoading() =>
        sheetMode
            ? const Center(child: AuraSpinner(size: AuraSpinnerSize.small))
            : const SizedBox(
                width: 180,
                child: AuraDropdownSelector<String>(
                  options: [],
                  placeholder: AuraSpinner(size: AuraSpinnerSize.small),
                  isEnabled: false,
                ),
              ),
      AsyncError(:final error, :final stackTrace) =>
        sheetMode
            ? AppErrorWidget(error: error, stackTrace: stackTrace)
            : SizedBox(
                width: 220,
                child: AppErrorWidget(error: error, stackTrace: stackTrace),
              ),
      AsyncData(:final value) => _CompactModelSelectorBody(
        groupedModels: value,
        workspaceModelSelectionId: workspaceModelSelectionId,
        onChanged: onChanged,
        compactMode: compactMode,
        sheetMode: sheetMode,
      ),
    };
  }
}

class _CompactModelSelectorBody extends StatelessWidget {
  const _CompactModelSelectorBody({
    required this.groupedModels,
    required this.workspaceModelSelectionId,
    required this.onChanged,
    required this.compactMode,
    required this.sheetMode,
  });

  final Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
  groupedModels;
  final String? workspaceModelSelectionId;
  final ValueChanged<String?> onChanged;
  final bool compactMode;
  final bool sheetMode;

  @override
  Widget build(BuildContext context) {
    if (compactMode && !sheetMode) {
      return _ModelCompactChip(
        groupedModels: groupedModels,
        workspaceModelSelectionId: workspaceModelSelectionId,
      );
    }

    return _SearchableModelSelectorBody(
      groupedModels: groupedModels,
      workspaceModelSelectionId: workspaceModelSelectionId,
      onChanged: onChanged,
      sheetMode: sheetMode,
    );
  }
}

class _SearchableModelSelectorBody extends HookWidget {
  const _SearchableModelSelectorBody({
    required this.groupedModels,
    required this.workspaceModelSelectionId,
    required this.onChanged,
    required this.sheetMode,
  });

  final Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
  groupedModels;
  final String? workspaceModelSelectionId;
  final ValueChanged<String?> onChanged;
  final bool sheetMode;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final searchValue = useState<String>('');

    final models = groupedModels.values.expand((group) => group).toList();
    final searchTerm = searchValue.value.trim().toLowerCase();
    final filteredModels = searchTerm.isEmpty
        ? models
        : models
              .where(
                (model) =>
                    model.workspaceModelSelection.id ==
                        workspaceModelSelectionId ||
                    _matchesSearch(model, searchTerm),
              )
              .toList();

    if (sheetMode) {
      return _ModelSheetSelector(
        controller: controller,
        groupedModels: groupedModels,
        filteredModels: filteredModels,
        workspaceModelSelectionId: workspaceModelSelectionId,
        onChanged: onChanged,
        onSearchChanged: (value) => searchValue.value = value,
      );
    }

    return _CompactModelDropdown(
      groupedModels: groupedModels,
      filteredModels: filteredModels,
      workspaceModelSelectionId: workspaceModelSelectionId,
      onChanged: onChanged,
      controller: controller,
      onSearchChanged: (value) => searchValue.value = value,
    );
  }
}

class _ModelSheetSelector extends StatelessWidget {
  const _ModelSheetSelector({
    required this.controller,
    required this.groupedModels,
    required this.filteredModels,
    required this.workspaceModelSelectionId,
    required this.onChanged,
    required this.onSearchChanged,
  });

  final TextEditingController controller;
  final Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
  groupedModels;
  final List<WorkspaceModelSelectionWithConnectionEntity> filteredModels;
  final String? workspaceModelSelectionId;
  final ValueChanged<String?> onChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    if (groupedModels.isEmpty) {
      return const Center(
        child: TextLocale(LocaleKeys.models_screens_select_model),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AuraInput(
          controller: controller,
          prefixIcon: const AuraIcon(Icons.search),
          onChanged: onSearchChanged,
        ),
        const AuraSizedBox(height: .sm),
        Flexible(
          child: ListView.separated(
            itemBuilder: (context, index) {
              final model = filteredModels[index];
              final selection = model.workspaceModelSelection;
              final isSelected = selection.id == workspaceModelSelectionId;

              return AuraTile(
                child: _ModelSheetOptionContent(model: model),
                onTap: () {
                  onChanged(selection.id);
                  final _ = Navigator.maybePop(context);
                },
                variant: isSelected
                    ? AuraTileVariant.selected
                    : AuraTileVariant.surface,
                trailing: isSelected
                    ? const AuraIcon(Icons.check, tint: AuraTint.primary)
                    : null,
              );
            },
            separatorBuilder: (context, index) =>
                const AuraSizedBox(height: .sm),
            itemCount: filteredModels.length,
          ),
        ),
      ],
    );
  }
}

class _CompactModelDropdown extends StatelessWidget {
  const _CompactModelDropdown({
    required this.groupedModels,
    required this.filteredModels,
    required this.workspaceModelSelectionId,
    required this.onChanged,
    required this.controller,
    required this.onSearchChanged,
  });

  final Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
  groupedModels;
  final List<WorkspaceModelSelectionWithConnectionEntity> filteredModels;
  final String? workspaceModelSelectionId;
  final ValueChanged<String?> onChanged;
  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final radius = BorderRadius.all(
      Radius.circular(context.auraTheme.fromBorderRadius(.xl)),
    );
    OutlineInputBorder outline(Color color) => OutlineInputBorder(
      borderSide: BorderSide(color: color),
      borderRadius: radius,
    );

    if (groupedModels.isEmpty) {
      return const SizedBox(
        width: 220,
        child: AuraDropdownSelector<String>(
          options: [],
          placeholder: TextLocale(
            LocaleKeys.models_screens_select_model,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          isEnabled: false,
        ),
      );
    }

    return SizedBox(
      width: 220,
      child: AuraDropdownSelector<String>(
        options: filteredModels
            .map(
              (model) => AuraDropdownOption(
                value: model.workspaceModelSelection.id,
                child: Text(
                  model.workspaceModelSelection.modelName ??
                      model.workspaceModelSelection.modelId,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                trailing: _ModelOptionSubtitle(model: model),
              ),
            )
            .toList(),
        value: workspaceModelSelectionId,
        onChanged: onChanged,
        placeholder: const TextLocale(
          LocaleKeys.models_screens_select_model,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        header: AuraPadding(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                vertical: context.auraTheme.fromSpacing(.sm),
                horizontal: context.auraTheme.fromSpacing(.md),
              ),
              focusedBorder: outline(auraColors.primary),
              enabledBorder: outline(auraColors.outline),
              border: outline(auraColors.outline),
            ),
            style: TextStyle(color: auraColors.onSurface),
            onChanged: onSearchChanged,
          ),
          padding: AuraEdgeInsetsGeometry.small,
        ),
      ),
    );
  }
}

class _ModelCompactChip extends StatelessWidget {
  const _ModelCompactChip({
    required this.groupedModels,
    required this.workspaceModelSelectionId,
  });

  final Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
  groupedModels;
  final String? workspaceModelSelectionId;

  @override
  Widget build(BuildContext context) {
    if (groupedModels.isEmpty) {
      return const _ModelChip(
        label: TextLocale(
          LocaleKeys.models_screens_select_model,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );
    }

    final selectedModel = _selectedModel(
      groupedModels,
      workspaceModelSelectionId,
    );
    final selectedName =
        selectedModel?.workspaceModelSelection.modelName ??
        selectedModel?.workspaceModelSelection.modelId;

    return _ModelChip(
      label: selectedName == null
          ? const TextLocale(
              LocaleKeys.models_screens_select_model,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            )
          : Text(
              selectedName,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
    );
  }
}

WorkspaceModelSelectionWithConnectionEntity? _selectedModel(
  Map<String, List<WorkspaceModelSelectionWithConnectionEntity>> groupedModels,
  String? workspaceModelSelectionId,
) {
  for (final model in groupedModels.values.expand((group) => group)) {
    if (model.workspaceModelSelection.id == workspaceModelSelectionId) {
      return model;
    }
  }

  return null;
}

class _ModelChip extends StatelessWidget {
  const _ModelChip({required this.label});

  final Widget label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: context.auraColors.outline),
        borderRadius: BorderRadius.circular(
          context.auraTheme.fromBorderRadius(.xl),
        ),
      ),
      width: double.infinity,
      child: Row(
        children: [
          const AuraIcon(Icons.memory_outlined, size: AuraIconSize.small),
          const AuraSizedBox(width: .xs),
          Flexible(child: label),
        ],
      ),
    );
  }
}

class _ModelSheetOptionContent extends StatelessWidget {
  const _ModelSheetOptionContent({required this.model});

  final WorkspaceModelSelectionWithConnectionEntity model;

  @override
  Widget build(BuildContext context) {
    final selection = model.workspaceModelSelection;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuraText(
          child: Text(
            selection.modelName ?? selection.modelId,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          style: AuraTextStyle.bodyLarge,
        ),
        const AuraSizedBox(height: .xs),
        Wrap(
          spacing: context.auraTheme.fromSpacing(.xs),
          runSpacing: context.auraTheme.fromSpacing(.xs),
          children: [
            AuraBadge.text(
              child: Text(
                selection.modelId,
                overflow: TextOverflow.ellipsis,
              ),
              variant: AuraBadgeVariant.soft,
              size: AuraBadgeSize.small,
            ),
            AuraBadge.text(
              child: Text(
                '${model.modelsProvider.name} - ${model.modelConnection.name}',
                overflow: TextOverflow.ellipsis,
              ),
              variant: AuraBadgeVariant.soft,
              size: AuraBadgeSize.small,
            ),
          ],
        ),
      ],
    );
  }
}

bool _matchesSearch(
  WorkspaceModelSelectionWithConnectionEntity model,
  String searchTerm,
) {
  final selection = model.workspaceModelSelection;
  final modelName = selection.modelName?.toLowerCase();
  final modelId = selection.modelId.toLowerCase();
  final providerName = model.modelsProvider.name.toLowerCase();
  final credentialName = model.modelConnection.name.toLowerCase();

  return modelId.contains(searchTerm) ||
      (modelName?.contains(searchTerm) ?? false) ||
      providerName.contains(searchTerm) ||
      credentialName.contains(searchTerm);
}

class _ModelOptionSubtitle extends StatelessWidget {
  const _ModelOptionSubtitle({required this.model});

  final WorkspaceModelSelectionWithConnectionEntity model;

  @override
  Widget build(BuildContext context) {
    final selection = model.workspaceModelSelection;

    return SizedBox(
      width: 120,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AuraText(
            child: Text(
              selection.modelId,
              overflow: TextOverflow.ellipsis,
            ),
            style: AuraTextStyle.bodySmall,
          ),
          AuraText(
            child: Text(
              '${model.modelsProvider.name} - ${model.modelConnection.name}',
              overflow: TextOverflow.ellipsis,
            ),
            style: AuraTextStyle.bodySmall,
          ),
        ],
      ),
    );
  }
}
