import 'package:auravibes_app/data/repositories/credentials_model_repository_impl.dart';
import 'package:auravibes_app/data/repositories/credentials_repository_impl.dart';
import 'package:auravibes_app/domain/repositories/chat_models_repository.dart';
import 'package:auravibes_app/domain/repositories/model_providers_repository.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'model_providers_repository_providers.g.dart';

@Riverpod(keepAlive: true)
CredentialsRepository modelProvidersRepository(Ref ref) {
  return CredentialsRepositoryImpl(
    database: ref.watch(appDatabaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
}

@Riverpod(keepAlive: true)
CredentialsModelsRepository credentialsModelsRepository(Ref ref) {
  final appDatabase = ref.watch(appDatabaseProvider);

  return CredentialsModelsRepositoryImpl(appDatabase);
}
