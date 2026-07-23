import 'package:auravibes_app/data/repositories/last_workspace_selection_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_selection_repository.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'last_workspace_selection_repository_provider.g.dart';

@Riverpod(keepAlive: true)
WorkspaceSelectionRepository lastWorkspaceSelectionRepository(Ref ref) {
  final preferences = ref.watch(sharedPreferencesProvider.future);

  return LastWorkspaceSelectionRepository(preferences);
}
