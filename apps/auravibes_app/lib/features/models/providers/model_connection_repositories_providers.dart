import 'package:auravibes_app/data/repositories/model_connection_repository_impl.dart';
import 'package:auravibes_app/data/repositories/workspace_model_selection_repository_impl.dart';
import 'package:auravibes_app/domain/repositories/model_connection_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'model_connection_repositories_providers.g.dart';

@Riverpod(keepAlive: true)
ModelConnectionRepository modelConnectionRepository(Ref ref) {
  return ModelConnectionRepositoryImpl(
    database: ref.watch(appDatabaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
}

@Riverpod(keepAlive: true)
WorkspaceModelSelectionRepository workspaceModelSelectionRepository(Ref ref) {
  final appDatabase = ref.watch(appDatabaseProvider);

  return WorkspaceModelSelectionRepositoryImpl(appDatabase);
}
