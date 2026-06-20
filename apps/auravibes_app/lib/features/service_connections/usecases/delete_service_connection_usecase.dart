import 'package:auravibes_app/domain/repositories/model_connection_repository.dart';
import 'package:auravibes_app/domain/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:riverpod/riverpod.dart';

class DeleteServiceConnectionUsecase {
  const DeleteServiceConnectionUsecase({
    required this.modelConnectionRepository,
    required this.skillCredentialsRepository,
  });

  final ModelConnectionRepository modelConnectionRepository;
  final SkillCredentialsRepository skillCredentialsRepository;

  Future<void> call({
    required String connectionId,
    required ServiceConnectionListItemKind kind,
  }) {
    return switch (kind) {
      ServiceConnectionListItemKind.modelProvider =>
        modelConnectionRepository.deleteModelConnection(connectionId),
      ServiceConnectionListItemKind.skillCredential =>
        skillCredentialsRepository.deleteCredential(connectionId),
      ServiceConnectionListItemKind.mcpServer => throw StateError(
        'MCP credentials cannot be deleted from this screen.',
      ),
    };
  }
}

// coverage:ignore-start
// Required: Riverpod provider wiring is exercised through widget tests.
final deleteServiceConnectionUsecaseProvider =
    Provider<DeleteServiceConnectionUsecase>((ref) {
      return DeleteServiceConnectionUsecase(
        modelConnectionRepository: ref.watch(modelConnectionRepositoryProvider),
        skillCredentialsRepository: ref.watch(
          skillCredentialsRepositoryProvider,
        ),
      );
    });
// coverage:ignore-end
