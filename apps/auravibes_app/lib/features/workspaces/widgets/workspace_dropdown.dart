import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Data class for a workspace entry shown in the dropdown.
@immutable
class WorkspaceDropdownItem {
  /// Creates a new [WorkspaceDropdownItem].
  const WorkspaceDropdownItem({required this.id, required this.name});

  /// Unique identifier of the workspace.
  final String id;

  /// Human-readable name of the workspace.
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkspaceDropdownItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// A workspace dropdown component that displays the active workspace and
/// allows switching between workspaces.
///
/// Uses [AuraDropdownSelector] for consistent design-system styling.
class WorkspaceDropdown extends StatelessWidget {
  // Null active workspace ID means no active workspace is selected.
  // ignore: unnecessary-nullable
  /// Creates a [WorkspaceDropdown].
  const WorkspaceDropdown({
    required this.workspaces,
    required this.activeWorkspaceId,
    required this.onSelected,
    this.isLoading = false,
    this.errorLocalizationKey,
    super.key,
  });

  /// All available workspaces to display in the dropdown.
  final List<WorkspaceDropdownItem> workspaces;

  /// ID of the currently active workspace.
  final String? activeWorkspaceId;

  /// Callback when a workspace is selected.
  final ValueChanged<WorkspaceDropdownItem> onSelected;

  /// Whether a switch is currently in progress.
  final bool isLoading;

  /// Optional error localization key to display below the dropdown.
  final String? errorLocalizationKey;

  @override
  Widget build(BuildContext context) {
    final activeWorkspace = workspaces
        .where((w) => w.id == activeWorkspaceId)
        .firstOrNull;

    return AuraDropdownSelector<WorkspaceDropdownItem>(
      value: activeWorkspace,
      options: workspaces
          .map(
            (w) => AuraDropdownOption<WorkspaceDropdownItem>(
              value: w,
              semanticLabel:
                  '${LocaleKeys.workspace_management_title.tr()}: ${w.name}',
              child: Text(w.name),
            ),
          )
          .toList(),
      onChanged: isLoading
          ? null
          : (item) {
              if (item != null) onSelected(item);
            },
      placeholder: Text(
        LocaleKeys.workspace_management_dropdown_placeholder.tr(),
      ),
      error: errorLocalizationKey != null
          ? Text(errorLocalizationKey!.tr())
          : null,
      semanticLabel: LocaleKeys.workspace_management_title.tr(),
    );
  }
}
