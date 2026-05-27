// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: no-equal-arguments
// Required: Existing argument values intentionally repeat.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

String? findProviderForModelId(
  Map<String, List<WorkspaceModelSelectionWithConnectionEntity>> groupedModels,
  String? workspaceModelSelectionId,
) {
  if (workspaceModelSelectionId == null) {
    return null;
  }

  for (final entry in groupedModels.entries) {
    final hasModel = entry.value.any(
      (model) => model.workspaceModelSelection.id == workspaceModelSelectionId,
    );
    if (hasModel) {
      return entry.key;
    }
  }

  return null;
}

/// Two-step model selector: Provider first, then Model.
/// Follows user mental model of selecting provider before model.
class SelectWorkspaceModelSelectionWidget extends HookConsumerWidget
    implements PreferredSizeWidget {
  const SelectWorkspaceModelSelectionWidget({
    required this.workspaceId,
    required this.selectWorkspaceModelSelectionId,
    required this.onProviderChanged,
    super.key,
    this.workspaceModelSelectionId,
    this.selectedProviderId,
  });

  final String workspaceId;
  final String? workspaceModelSelectionId;
  final void Function(String?) selectWorkspaceModelSelectionId;

  /// Currently selected provider name (not ID).
  final String? selectedProviderId;

  /// Callback when provider selection changes.
  final void Function(String?) onProviderChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedModelsAsync = ref.watch(
      listModelsGroupedByProviderProvider(workspaceId: workspaceId),
    );

    final onSelectProvider = useCallback<void Function(String?)>(
      (provider) {
        onProviderChanged(provider);
        selectWorkspaceModelSelectionId(null);
      },
      [onProviderChanged, selectWorkspaceModelSelectionId],
    );

    return switch (groupedModelsAsync) {
      AsyncLoading() => const AuraPadding(
        child: AuraSpinner(),
        padding: AuraEdgeInsetsGeometry.vertical(.md),
      ),
      AsyncError(:final error, :final stackTrace) => AppErrorWidget(
        error: error,
        stackTrace: stackTrace,
      ),
      AsyncData(:final value) => SelectChatData(
        groupedModels: value,
        workspaceModelSelectionId: workspaceModelSelectionId,
        selectedProviderId: selectedProviderId,
        onSelectProvider: onSelectProvider,
        selectWorkspaceModelSelectionId: selectWorkspaceModelSelectionId,
      ),
    };
  }

  @override
  // Use 120 to accommodate both Row (60) and Column (stacked) layouts
  Size get preferredSize => const Size.fromHeight(120);
}

class SelectChatData extends HookWidget {
  const SelectChatData({
    required this.groupedModels,
    required this.workspaceModelSelectionId,
    required this.selectedProviderId,
    required this.onSelectProvider,
    required this.selectWorkspaceModelSelectionId,
    super.key,
  });

  final Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
  groupedModels;
  final String? workspaceModelSelectionId;
  final String? selectedProviderId;
  final void Function(String?) onSelectProvider;
  final void Function(String?) selectWorkspaceModelSelectionId;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();

    // Responsive layout - stacked below md breakpoint (768px)
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < DesignBreakpoints.md;

    final searchValue = useState<String>('');

    // Internal provider state if no external control
    final internalProviderId = useState<String?>(null);
    final derivedProviderId = useMemoized(
      () => findProviderForModelId(groupedModels, workspaceModelSelectionId),
      [groupedModels, workspaceModelSelectionId],
    );
    final effectiveProviderId =
        selectedProviderId ?? internalProviderId.value ?? derivedProviderId;

    useEffect(
      () {
        if (selectedProviderId == null && internalProviderId.value != null) {
          internalProviderId.value = null;
        }
        return null;
      },
      [selectedProviderId],
    );

    useEffect(
      () {
        if (selectedProviderId != null || internalProviderId.value != null) {
          return null;
        }

        if (derivedProviderId != null) {
          internalProviderId.value = derivedProviderId;
        }

        return null;
      },
      [selectedProviderId, internalProviderId.value, derivedProviderId],
    );

    final onSelectProviderCallback = useCallback<void Function(String?)>(
      (
        provider,
      ) {
        if (selectedProviderId == null) {
          internalProviderId.value = provider;
        }
        onSelectProvider(provider);
      },
      [onSelectProvider, selectedProviderId],
    );

    // Filter models by search - computed unconditionally (not in hook)
    final modelsForProvider = effectiveProviderId != null
        ? groupedModels[effectiveProviderId] ??
              <WorkspaceModelSelectionWithConnectionEntity>[]
        : <WorkspaceModelSelectionWithConnectionEntity>[];
    final filteredModels = searchValue.value.isEmpty
        ? modelsForProvider
        : modelsForProvider.where((model) {
            final searchTerm = model.workspaceModelSelection.modelId
                .toLowerCase();
            return searchTerm.contains(searchValue.value.toLowerCase());
          }).toList();

    if (groupedModels.isEmpty) {
      return const AuraPadding(
        child: TextLocale(
          LocaleKeys.models_screens_no_providers_configured,
        ),
        padding: AuraEdgeInsetsGeometry.vertical(.md),
      );
    }

    final providerNames = groupedModels.keys.toList();

    final provider = _ProviderDropdown(
      providerNames: providerNames,
      selectedProvider: effectiveProviderId,
      onChanged: onSelectProviderCallback,
    );
    final modelDropdown = _ModelDropdown(
      models: filteredModels,
      hasModelsForProvider: modelsForProvider.isNotEmpty,
      selectedModelId: workspaceModelSelectionId,
      providerSelected: effectiveProviderId != null,
      onChanged: selectWorkspaceModelSelectionId,
      searchValue: searchValue.value,
      onSearchChanged: (value) {
        searchValue.value = value;
      },
      controller: controller,
    );

    return AuraPadding(
      child: isCompact
          ? AuraColumn(
              children: [
                provider,
                modelDropdown,
              ],
              spacing: .sm,
              mainAxisSize: MainAxisSize.min,
            )
          : AuraRow(
              children: [
                Expanded(
                  child: provider,
                ),
                Expanded(
                  child: modelDropdown,
                ),
              ],
              spacing: .sm,
            ),
      padding: const AuraEdgeInsetsGeometry.only(
        left: .md,
        right: .md,
        bottom: .sm,
      ),
    );
  }
}

/// Provider dropdown widget - first step in two-step selection.
class _ProviderDropdown extends StatelessWidget {
  const _ProviderDropdown({
    required this.providerNames,
    required this.selectedProvider,
    required this.onChanged,
  });

  final List<String> providerNames;
  final String? selectedProvider;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return AuraDropdownSelector<String>(
      options: providerNames
          .map(
            (name) => AuraDropdownOption(
              value: name,
              child: Text(name),
            ),
          )
          .toList(),
      value: selectedProvider,
      onChanged: onChanged,
      placeholder: const TextLocale(LocaleKeys.models_screens_select_provider),
    );
  }
}

/// Model dropdown widget - second step, disabled until provider selected.
class _ModelDropdown extends StatelessWidget {
  const _ModelDropdown({
    required this.models,
    required this.hasModelsForProvider,
    required this.selectedModelId,
    required this.providerSelected,
    required this.onChanged,
    required this.searchValue,
    required this.onSearchChanged,
    required this.controller,
  });

  final List<WorkspaceModelSelectionWithConnectionEntity> models;
  final bool hasModelsForProvider;
  final String? selectedModelId;
  final bool providerSelected;
  final void Function(String?) onChanged;
  final String searchValue;
  final ValueChanged<String> onSearchChanged;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    if (!providerSelected) {
      // Disabled state - show placeholder (FR-002)
      return const AuraDropdownSelector<String>(
        options: [],
        placeholder: TextLocale(
          LocaleKeys.models_screens_select_provider_first,
        ),
        isEnabled: false, // Empty when disabled
      );
    }

    return AuraDropdownSelector<String>(
      options: models
          .map(
            (model) => AuraDropdownOption(
              value: model.workspaceModelSelection.id,
              child: Text(model.workspaceModelSelection.modelId),
            ),
          )
          .toList(),
      value: selectedModelId,
      onChanged: onChanged,
      placeholder: const TextLocale(LocaleKeys.models_screens_select_model),
      header: !hasModelsForProvider
          ? const AuraPadding(
              child: TextLocale(LocaleKeys.models_screens_no_models_available),
              padding: AuraEdgeInsetsGeometry.medium,
            )
          : AuraPadding(
              child: AuraInput(
                controller: controller,
                onChanged: onSearchChanged,
              ),
              padding: AuraEdgeInsetsGeometry.medium,
            ),
    );
  }
}
