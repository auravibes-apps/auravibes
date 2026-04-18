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
    required this.workspaceId,
    required this.selectCredentialsModelId,
    required this.onProviderChanged,
    super.key,
    this.credentialsModelId,
    this.selectedProviderId,
  });

  final String workspaceId;
  final String? credentialsModelId;
  final void Function(String?) selectCredentialsModelId;

  /// Currently selected provider name (not ID).
  final String? selectedProviderId;

  /// Callback when provider selection changes.
  final void Function(String?) onProviderChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedModelsAsync = ref.watch(
      listModelsGroupedByProviderProvider(workspaceId: workspaceId),
    );

    void onSelectProvider(String? provider) {
      onProviderChanged(provider);
      selectCredentialsModelId(null);
    }

    return switch (groupedModelsAsync) {
      AsyncLoading() => const AuraPadding(
        padding: AuraEdgeInsetsGeometry.vertical(.md),
        child: AuraSpinner(),
      ),
      AsyncError(:final error, :final stackTrace) => AppErrorWidget(
        error: error,
        stackTrace: stackTrace,
      ),
      AsyncData(:final value) => SelectChatData(
        groupedModels: value,
        credentialsModelId: credentialsModelId,
        selectedProviderId: selectedProviderId,
        onSelectProvider: onSelectProvider,
        selectCredentialsModelId: selectCredentialsModelId,
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
    required this.credentialsModelId,
    required this.selectedProviderId,
    required this.onSelectProvider,
    required this.selectCredentialsModelId,
    super.key,
  });

  final Map<String, List<CredentialsModelWithProviderEntity>> groupedModels;
  final String? credentialsModelId;
  final String? selectedProviderId;
  final void Function(String?) onSelectProvider;
  final void Function(String?) selectCredentialsModelId;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();

    // Responsive layout - stacked below md breakpoint (768px)
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < DesignBreakpoints.md;

    final searchValue = useState<String>('');

    // Internal provider state if no external control
    final internalProviderId = useState<String?>(null);
    final effectiveProviderId = selectedProviderId ?? internalProviderId.value;

    final _onSelectProvider = useCallback<void Function(String?)>((provider) {
      internalProviderId.value = provider;
      onSelectProvider(provider);
    }, [onSelectProvider]);

    // Filter models by search - computed unconditionally (not in hook)
    final modelsForProvider = effectiveProviderId != null
        ? groupedModels[effectiveProviderId] ??
              <CredentialsModelWithProviderEntity>[]
        : <CredentialsModelWithProviderEntity>[];
    final filteredModels = searchValue.value.isEmpty
        ? modelsForProvider
        : modelsForProvider.where((model) {
            final searchTerm = model.credentialsModel.modelId.toLowerCase();
            return searchTerm.contains(searchValue.value.toLowerCase());
          }).toList();

    if (groupedModels.isEmpty) {
      return const AuraPadding(
        padding: AuraEdgeInsetsGeometry.vertical(.md),
        child: TextLocale(
          LocaleKeys.models_screens_no_providers_configured,
        ),
      );
    }

    final providerNames = groupedModels.keys.toList();

    final provider = _ProviderDropdown(
      providerNames: providerNames,
      selectedProvider: effectiveProviderId,
      onChanged: _onSelectProvider,
    );
    final modelDropdown = _ModelDropdown(
      models: filteredModels,
      selectedModelId: credentialsModelId,
      providerSelected: effectiveProviderId != null,
      onChanged: selectCredentialsModelId,
      searchValue: searchValue,
      controller: controller,
    );

    return AuraPadding(
      padding: const AuraEdgeInsetsGeometry.only(
        bottom: .sm,
        left: .md,
        right: .md,
      ),
      child: isCompact
          ? AuraColumn(
              spacing: .sm,
              mainAxisSize: MainAxisSize.min,
              children: [
                provider,
                modelDropdown,
              ],
            )
          : AuraRow(
              spacing: .sm,
              children: [
                Expanded(
                  child: provider,
                ),
                Expanded(
                  child: modelDropdown,
                ),
              ],
            ),
    );
  }
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
