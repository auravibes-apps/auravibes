import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/features/service_connections/models/cloud_service_connection.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_repository_provider.dart';
import 'package:auravibes_app/features/service_connections/usecases/cloud_service_connection_usecases.dart';
import 'package:auravibes_app/features/skills/models/app_skill_credential_candidate.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/riverpod.dart';

export '../models/app_skill_credential_candidate.dart';

typedef CloudServiceConnectionsReader =
    Future<List<CloudServiceConnection>?> Function(String workspaceId);

class const ListAppSkillCredentialCandidatesUsecase(
  final ServiceConnectionRepository Function() _serviceConnectionRepository, {
  final CloudServiceConnectionsReader? _cloudServiceConnectionsReader,
}) {
  Future<List<AppSkillCredentialCandidate>> call({
    required String workspaceId,
    required AppSkillDefinition skill,
  }) async {
    final cloudConnections = await _cloudServiceConnectionsReader?.call(
      workspaceId,
    );
    if (cloudConnections != null) {
      return _cloudCandidates(cloudConnections, skill.identifier);
    }

    return _localCandidates(workspaceId, skill);
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

    final usableNativeTools = _usableNativeTools(skill);
    if (usableNativeTools.isEmpty) return false;

    if (_hasCredentiallessTool(usableNativeTools)) return true;

    return (await call(workspaceId: workspaceId, skill: skill)).isNotEmpty;
  }

  Future<List<AppSkillCredentialCandidate>> _localCandidates(
    String workspaceId,
    AppSkillDefinition skill,
  ) async {
    final candidates = await _serviceConnectionRepository()
        .listAppSkillCredentialCandidates((
          workspaceId: workspaceId,
          appSkillServiceId: skill.identifier,
          compatibleModelProviderIds: skill.compatibleModelProviderIds,
        ));

    return [
      for (final candidate in candidates)
        AppSkillCredentialCandidate(
          id: _prefixedId(candidate),
          name: candidate.name,
        ),
    ];
  }

  List<AppSkillCredentialCandidate> _cloudCandidates(
    List<CloudServiceConnection> connections,
    String serviceId,
  ) => [
    for (final connection in connections)
      if (_isUsableCloudCredential(connection, serviceId))
        AppSkillCredentialCandidate(
          id: 'service:${connection.id}',
          name: connection.name,
        ),
  ];

  List<AppSkillToolDefinition> _usableNativeTools(AppSkillDefinition skill) {
    final isServiceSkill = _isServiceSkill(skill);

    return skill.nativeTools
        .where((tool) => _isUsableNativeTool(tool, isServiceSkill))
        .toList(growable: false);
  }

  bool _hasCredentiallessTool(List<AppSkillToolDefinition> tools) =>
      tools.any((tool) => !tool.requiresCredential);

  String _prefixedId(ServiceConnectionCandidate candidate) {
    if (candidate.kind == ServiceConnectionKindTable.modelProvider) {
      return 'model:${candidate.id}';
    }

    return 'service:${candidate.id}';
  }
}

bool _isUsableCloudCredential(
  CloudServiceConnection connection,
  String serviceId,
) =>
    connection.kind == 'appSkillCredential' &&
    connection.serviceId == serviceId &&
    connection.isEnabled &&
    connection.hasSecret;

bool _isServiceSkill(AppSkillDefinition skill) => serviceSkillDefinitions.any(
  (candidate) => candidate.identifier == skill.identifier,
);

bool _isUsableNativeTool(AppSkillToolDefinition tool, bool isServiceSkill) =>
    tool.urlTemplate != null || (isServiceSkill && tool.callback != null);

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

          return await CloudServiceConnectionUsecases(.new(gateway))
              .watch()
              .first;
        },
      );
    });
