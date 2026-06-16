// Required: Existing thresholds and limits use numeric values.
import 'package:auravibes_app/domain/repositories/workspace_repository.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'validate_workspace_name_use_case.g.dart';

/// Validates a workspace name against length constraints.
///
/// Throws [WorkspaceValidationException] when the name is too short
/// or too long.
class ValidateWorkspaceNameUseCase {
  const ValidateWorkspaceNameUseCase();

  /// Minimum workspace name length.
  static const minLength = 3;

  /// Maximum workspace name length.
  static const maxLength = 20;

  /// Validates that [name] is between 3 and 20 characters.
  void call({required String name}) {
    if (name.length < minLength) {
      throw const WorkspaceValidationException(
        'Workspace name must be at least 3 characters',
        localizationKey: LocaleKeys.workspace_management_name_too_short_error,
      );
    }
    if (name.length > maxLength) {
      throw const WorkspaceValidationException(
        'Workspace name must be at most 20 characters',
        localizationKey: LocaleKeys.workspace_management_name_too_long_error,
      );
    }
  }
}

/// Provides a [ValidateWorkspaceNameUseCase] instance.
@riverpod
ValidateWorkspaceNameUseCase validateWorkspaceNameUseCase(Ref _) {
  return const ValidateWorkspaceNameUseCase();
}
