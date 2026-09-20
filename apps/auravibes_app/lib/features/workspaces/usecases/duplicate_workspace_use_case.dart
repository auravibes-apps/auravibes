import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/usecases/validate_workspace_name_use_case.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:riverpod/riverpod.dart';

class const DuplicateWorkspaceUseCase({
  required final WorkspaceRepository _repository,
  required final ValidateWorkspaceNameUseCase _validateName,
}) {
  Future<WorkspaceEntity> call(String workspaceId) async {
    final source = await _repository.getWorkspaceById(workspaceId);
    if (source == null) throw WorkspaceNotFoundException(workspaceId);

    final names = (await _repository.getAllWorkspaces())
        .map((workspace) => workspace.name)
        .toSet();
    final name = _nextCopyName(source.name, names);
    _validateName.call(name: name);

    return await _repository.duplicateWorkspace(workspaceId, name: name);
  }
}

String _nextCopyName(String originalName, Set<String> existingNames) {
  for (var suffix = 1; ; suffix++) {
    final copySuffix = suffix == 1 ? ' Copy' : ' Copy $suffix';
    final baseLength =
        ValidateWorkspaceNameUseCase.maxLength - copySuffix.length;
    final base = originalName.trim().firstCharacters(baseLength).trimRight();
    final candidate = '$base$copySuffix';
    if (!existingNames.contains(candidate)) return candidate;
  }
}

final duplicateWorkspaceUseCaseProvider = Provider<DuplicateWorkspaceUseCase>(
  (ref) => DuplicateWorkspaceUseCase(
    repository: ref.watch(workspaceRepositoryProvider),
    validateName: ref.watch(validateWorkspaceNameUseCaseProvider),
  ),
);
