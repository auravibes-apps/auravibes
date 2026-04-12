import 'package:auravibes_app/data/repositories/workspace_repository_impl.dart';
import 'package:auravibes_app/domain/entities/workspace.dart';
import 'package:auravibes_app/domain/repositories/workspace_repository.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_repository_providers.g.dart';

@riverpod
WorkspaceRepository workspaceRepository(Ref ref) {
  final appDatabase = ref.watch(appDatabaseProvider);

  return WorkspaceRepositoryImpl(appDatabase);
}

@Riverpod(keepAlive: true)
Future<List<WorkspaceEntity>> allWorkspaces(Ref ref) async {
  final repo = ref.watch(workspaceRepositoryProvider);
  return repo.getAllWorkspaces();
}
