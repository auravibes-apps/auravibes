import 'package:auravibes_app/data/repositories/last_workspace_selection_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_selection_repository.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'last_workspace_selection_repository_provider.g.dart';

@Riverpod(keepAlive: true)
WorkspaceSelectionRepository lastWorkspaceSelectionRepository(Ref ref) {
  final preferences = ref.watch(sharedPreferencesProvider.future);
  final namespace = ref.watch(appStorageNamespaceProvider);
  final storageKey = namespace == 'auravibes_app'
      ? 'last_selected_workspace_id'
      : '$namespace.last_selected_workspace_id';

  return LastWorkspaceSelectionRepository(preferences, storageKey: storageKey);
}
