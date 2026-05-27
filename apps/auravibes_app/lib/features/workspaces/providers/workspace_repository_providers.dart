// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/data/repositories/workspace_repository_impl.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/repositories/workspace_repository.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_repository_providers.g.dart';

@Riverpod(keepAlive: true)
WorkspaceRepository workspaceRepository(Ref ref) {
  final appDatabase = ref.watch(appDatabaseProvider);

  return WorkspaceRepositoryImpl(appDatabase);
}

@Riverpod(keepAlive: true)
Stream<List<WorkspaceEntity>> allWorkspaces(Ref ref) {
  final repo = ref.watch(workspaceRepositoryProvider);
  return repo.watchAllWorkspaces();
}
