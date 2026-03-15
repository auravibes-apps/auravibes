import 'package:auravibes_app/domain/entities/credentials_models_entities.dart';
import 'package:auravibes_app/features/models/providers/list_chat_models_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_error.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Two-step model selector: Provider first, then Model.
/// Follows user mental model of selecting provider before model.
class SelectCredentialsModelWidget extends HookConsumerWidget
    implements PreferredSizeWidget {
  const SelectCredentialsModelWidget({
    required this.selectCredentialsModelId,
    super.key,
    this.credentialsModelId,
    this.selectedProviderId,
    this.onProviderChanged,
  });

  final String? credentialsModelId;
  final void Function(String?) selectCredentialsModelId;

  /// Currently selected provider name (not ID).
  final String? selectedProviderId;

  /// Callback when provider selection changes.
  final void Function(String?)? onProviderChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedModelsAsync = ref.watch(listModelsGroupedByProviderProvider);

    final searchValue = useState<String>('');
    final controller = useTextEditingController();

    // Internal provider state if no external control
    final internalProviderId = useState<String?>(null);
    final effectiveProviderId = selectedProviderId ?? internalProviderId.value;

    // Responsive layout - stacked below md breakpoint (768px)
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < DesignBreakpoints.md;
    // Show full text on narrow screens (<640px)
    final isNarrow = screenWidth < DesignBreakpoints.sm;

    // Filter models by search - computed unconditionally (not in hook)
    final groupedMap = groupedModelsAsync.hasValue
        ? groupedModelsAsync.value
        : null;
    final modelsForProvider = effectiveProviderId != null && groupedMap != null
        ? groupedMap[effectiveProviderId] ??
              <CredentialsModelWithProviderEntity>[]
        : <CredentialsModelWithProviderEntity>[];
    final filteredModels = searchValue.value.isEmpty
        ? modelsForProvider
        : modelsForProvider.where((model) {
            final searchTerm = model.credentialsModel.modelId.toLowerCase();
            return searchTerm.contains(searchValue.value.toLowerCase());
          }).toList();

    // Auto-select provider when only one exists (US3)
    useEffect(() {
      groupedModelsAsync.whenOrNull(
        data: (groupedModels) {
          // Only auto-select if:
          // 1. Exactly one provider exists
          // 2. No provider is currently selected (external or internal)
          // 3. This is internal state (not externally controlled)
          if (groupedModels.length == 1 &&
              selectedProviderId == null &&
              internalProviderId.value == null) {
            final singleProvider = groupedModels.keys.first;
            internalProviderId.value = singleProvider;
            onProviderChanged?.call(singleProvider);
            selectCredentialsModelId(null); // Reset model when auto-selecting
          }
        },
      );
      return null;
    }, [groupedModelsAsync, selectedProviderId]);

    return groupedModelsAsync.when(
      loading: () => const AuraPadding(
        padding: AuraEdgeInsetsGeometry.vertical(.md),
        child: AuraSpinner(),
      ),
      error: (error, stackTrace) => AppErrorWidget(
        error: error,
        stackTrace: stackTrace,
      ),
      data: (groupedModels) {
        if (groupedModels.isEmpty) {
          return const AuraPadding(
            padding: AuraEdgeInsetsGeometry.vertical(.md),
            child: TextLocale(
              LocaleKeys.models_screens_no_providers_configured,
            ),
          );
        }

        final providerNames = groupedModels.keys.toList();

        return AuraPadding(
          padding: const AuraEdgeInsetsGeometry.only(
            bottom: .sm,
            left: .md,
            right: .md,
          ),
          child: isCompact
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ProviderDropdown(
                      providerNames: providerNames,
                      selectedProvider: effectiveProviderId,
                      onChanged: (provider) {
                        internalProviderId.value = provider;
                        onProviderChanged?.call(provider);
                        selectCredentialsModelId(null);
                      },
                    ),
                    const SizedBox(height: DesignSpacing.sm),
                    _ModelDropdown(
                      models: filteredModels,
                      selectedModelId: credentialsModelId,
                      providerSelected: effectiveProviderId != null,
                      onChanged: selectCredentialsModelId,
                      searchValue: searchValue,
                      controller: controller,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _ProviderDropdown(
                        providerNames: providerNames,
                        selectedProvider: effectiveProviderId,
                        onChanged: (provider) {
                          internalProviderId.value = provider;
                          onProviderChanged?.call(provider);
                          selectCredentialsModelId(null);
                        },
                      ),
                    ),
                    const SizedBox(width: DesignSpacing.sm),
                    Expanded(
                      child: _ModelDropdown(
                        models: filteredModels,
                        selectedModelId: credentialsModelId,
                        providerSelected: effectiveProviderId != null,
                        onChanged: selectCredentialsModelId,
                        searchValue: searchValue,
                        controller: controller,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  @override
  // Use 120 to accommodate both Row (60) and Column (stacked) layouts
  Size get preferredSize => const Size.fromHeight(120);
}

/// Provider dropdown widget - first step in two-step selection.
class _ProviderDropdown extends HookConsumerWidget {
  const _ProviderDropdown({
    required this.providerNames,
    required this.selectedProvider,
    required this.onChanged,
  });

  final List<String> providerNames;
  final String? selectedProvider;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuraDropdownSelector<String>(
      value: selectedProvider,
      onChanged: onChanged,
      placeholder: const TextLocale(LocaleKeys.models_screens_select_provider),
      options: providerNames
          .map(
            (name) => AuraDropdownOption(
              value: name,
              child: Text(name),
            ),
          )
          .toList(),
    );
  }
}

/// Model dropdown widget - second step, disabled until provider selected.
class _ModelDropdown extends HookConsumerWidget {
  const _ModelDropdown({
    required this.models,
    required this.selectedModelId,
    required this.providerSelected,
    required this.onChanged,
    required this.searchValue,
    required this.controller,
  });

  final List<CredentialsModelWithProviderEntity> models;
  final String? selectedModelId;
  final bool providerSelected;
  final void Function(String?) onChanged;
  final ValueNotifier<String> searchValue;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!providerSelected) {
      // Disabled state - show placeholder (FR-002)
      return const AuraDropdownSelector<String>(
        isEnabled: false,
        placeholder: TextLocale(
          LocaleKeys.models_screens_select_provider_first,
        ),
        options: [], // Empty when disabled
      );
    }

    return AuraDropdownSelector<String>(
      value: selectedModelId,
      onChanged: onChanged,
      placeholder: const TextLocale(LocaleKeys.models_screens_select_model),
      options: models
          .map(
            (model) => AuraDropdownOption(
              value: model.credentialsModel.id,
              child: Text(model.credentialsModel.modelId),
            ),
          )
          .toList(),
      header: models.isEmpty
          ? const AuraPadding(
              padding: AuraEdgeInsetsGeometry.medium,
              child: TextLocale(LocaleKeys.models_screens_no_models_available),
            )
          : Padding(
              padding: EdgeInsetsGeometry.all(context.auraTheme.spacing.md),
              child: AuraInput(
                controller: controller,
                onChanged: (value) {
                  searchValue.value = value;
                },
              ),
            ),
    );
  }
}
