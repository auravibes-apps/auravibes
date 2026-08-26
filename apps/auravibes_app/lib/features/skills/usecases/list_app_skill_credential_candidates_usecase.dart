import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/features/service_connections/models/cloud_service_connection.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_repository_provider.dart';
import 'package:auravibes_app/features/service_connections/usecases/cloud_service_connection_usecases.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/riverpod.dart';

typedef CloudServiceConnectionsReader =
    Future<List<CloudServiceConnection>?> Function(String workspaceId);

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
    this._serviceConnectionRepository, {
    this._cloudServiceConnectionsReader,
  });

  final ServiceConnectionRepository Function() _serviceConnectionRepository;
  final CloudServiceConnectionsReader? _cloudServiceConnectionsReader;

  Future<List<AppSkillCredentialCandidate>> call({
    required String workspaceId,
    required AppSkillDefinition skill,
  }) async {
    final cloudConnections = await _cloudServiceConnectionsReader?.call(
      workspaceId,
    );
    if (cloudConnections != null) {
      return [
        for (final connection in cloudConnections)
          if (connection.kind == 'appSkillCredential' &&
              connection.serviceId == skill.identifier &&
              connection.isEnabled &&
              connection.hasSecret)
            AppSkillCredentialCandidate(
              id: 'service:${connection.id}',
              name: connection.name,
            ),
      ];
    }

    final candidates = await _serviceConnectionRepository()
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
    if (skill.identifier == agentsSkillSlug) return true;

    final isServiceSkill = serviceSkillDefinitions.any(
      (candidate) => candidate.identifier == skill.identifier,
    );
    final usableNativeTools = skill.nativeTools
        .where(
          (tool) =>
              tool.urlTemplate != null ||
              (isServiceSkill && tool.callback != null),
        )
        .toList(growable: false);
    if (usableNativeTools.isEmpty) return false;

    if (usableNativeTools.any((tool) => !tool.requiresCredential)) {
      return true;
    }

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
        () => ref.read(serviceConnectionRepositoryProvider),
        cloudServiceConnectionsReader: (workspaceId) async {
          final session = await ref.read(
            workspaceSessionForRouteProvider(workspaceId).future,
          );
          if (session.cloud == null) return null;

          final gateway = await ref.read(
            cloudWorkspaceStateGatewayProvider(session).future,
          );
          if (gateway == null) {
            throw StateError('Cloud workspace gateway is unavailable.');
          }

          return CloudServiceConnectionUsecases(
            CloudWorkspaceResourceStore(gateway),
          ).watch().first;
        },
      );
    });
