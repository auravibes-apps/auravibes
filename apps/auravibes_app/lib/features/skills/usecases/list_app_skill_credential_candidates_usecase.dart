import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_repository_provider.dart';
import 'package:auravibes_skills/auravibes_skills.dart';
import 'package:riverpod/riverpod.dart';

class AppSkillCredentialCandidate {
  const AppSkillCredentialCandidate({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

class ListAppSkillCredentialCandidatesUsecase {
  const ListAppSkillCredentialCandidatesUsecase(
    this._serviceConnectionRepository,
  );

  final ServiceConnectionRepository _serviceConnectionRepository;

  Future<List<AppSkillCredentialCandidate>> call({
    required String workspaceId,
    required AppSkillDefinition skill,
  }) async {
    final candidates = await _serviceConnectionRepository
        .listAppSkillCredentialCandidates(
          workspaceId: workspaceId,
          appSkillServiceId: skill.identifier,
          compatibleModelProviderIds: skill.compatibleModelProviderIds,
        );

    return [
      for (final candidate in candidates)
        AppSkillCredentialCandidate(
          id: _prefixedId(candidate),
          name: candidate.name,
        ),
    ];
  }

  bool isCredentialRequired(AppSkillDefinition skill) {
    return skill.requiresCredential ||
        skill.nativeTools.any((tool) => tool.requiresCredential);
  }

  Future<bool> hasUsableNativeTool({
    required String workspaceId,
    required AppSkillDefinition skill,
  }) async {
    if (skill.nativeTools.any((tool) => !tool.requiresCredential)) {
      return true;
    }

    if (!isCredentialRequired(skill)) return true;

    return (await call(workspaceId: workspaceId, skill: skill)).isNotEmpty;
  }

  String _prefixedId(ServiceConnectionCandidate candidate) {
    if (candidate.kind == ServiceConnectionKindTable.modelProvider) {
      return 'model:${candidate.id}';
    }

    return 'service:${candidate.id}';
  }
}

final listAppSkillCredentialCandidatesUsecaseProvider =
    Provider<ListAppSkillCredentialCandidatesUsecase>((ref) {
      return ListAppSkillCredentialCandidatesUsecase(
        ref.watch(serviceConnectionRepositoryProvider),
      );
    });
