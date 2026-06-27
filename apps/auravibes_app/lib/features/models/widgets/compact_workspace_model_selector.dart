import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CompactWorkspaceModelSelector extends HookConsumerWidget {
  const CompactWorkspaceModelSelector({
    required this.workspaceId,
    required this.workspaceModelSelectionId,
    required this.onChanged,
    super.key,
  });

  final String workspaceId;
  final String? workspaceModelSelectionId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedModelsAsync = ref.watch(
      listModelsGroupedByProviderProvider(workspaceId: workspaceId),
    );

    return switch (groupedModelsAsync) {
      AsyncLoading() => const SizedBox(
        width: 180,
        child: AuraDropdownSelector<String>(
          options: [],
          placeholder: AuraSpinner(size: AuraSpinnerSize.small),
          isEnabled: false,
        ),
      ),
      AsyncError(:final error, :final stackTrace) => SizedBox(
        width: 220,
        child: AppErrorWidget(error: error, stackTrace: stackTrace),
      ),
      AsyncData(:final value) => _CompactModelDropdown(
        groupedModels: value,
        workspaceModelSelectionId: workspaceModelSelectionId,
        onChanged: onChanged,
      ),
    };
  }
}

class _CompactModelDropdown extends HookWidget {
  const _CompactModelDropdown({
    required this.groupedModels,
    required this.workspaceModelSelectionId,
    required this.onChanged,
  });

  final Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
  groupedModels;
  final String? workspaceModelSelectionId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final controller = useTextEditingController();
    final searchValue = useState<String>('');
    final radius = BorderRadius.all(
      Radius.circular(context.auraTheme.fromBorderRadius(.xl)),
    );
    OutlineInputBorder outline(Color color) => OutlineInputBorder(
      borderSide: BorderSide(color: color),
      borderRadius: radius,
    );

    final models = groupedModels.values.expand((group) => group);
    final searchTerm = searchValue.value.trim().toLowerCase();
    final filteredModels = searchTerm.isEmpty
        ? models
        : models.where(
            (model) =>
                model.workspaceModelSelection.id == workspaceModelSelectionId ||
                _matchesSearch(model, searchTerm),
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
            onChanged: (value) => searchValue.value = value,
          ),
          padding: AuraEdgeInsetsGeometry.small,
        ),
      ),
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
