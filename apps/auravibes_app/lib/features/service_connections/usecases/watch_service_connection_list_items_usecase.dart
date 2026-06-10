import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/domain/repositories/model_connection_repository.dart';
import 'package:auravibes_app/domain/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/domain/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

final _logger = Logger('watch_service_connection_list_items_usecase');

class WatchServiceConnectionListItemsUsecase {
  const WatchServiceConnectionListItemsUsecase(
    this._database,
    this._modelConnectionRepository,
    this._credentialDefinitionsRepository,
    this._credentialsRepository,
    this._now,
  );

  final AppDatabase _database;
  final ModelConnectionRepository _modelConnectionRepository;
  final SkillCredentialDefinitionsRepository _credentialDefinitionsRepository;
  final SkillCredentialsRepository _credentialsRepository;
  final DateTime Function() _now;

  Stream<List<ServiceConnectionListItem>> call(String workspaceId) {
    return Rx.combineLatest4(
      _modelConnectionRepository.watchModelConnections(
        ModelConnectionFilter(workspaces: [workspaceId]),
      ),
      _credentialDefinitionsRepository.watchDefinitions(workspaceId),
      _credentialsRepository.watchCredentialsForWorkspace(workspaceId),
      _watchMcpCredentialItems(workspaceId),
      _buildItems,
    );
  }

  List<ServiceConnectionListItem> _buildItems(
    List<ModelConnectionEntity> modelConnections,
    List<SkillCredentialDefinitionEntity> definitions,
    List<SkillCredentialEntity> credentials,
    List<ServiceConnectionListItem> mcpCredentials,
  ) {
    final definitionsById = {
      for (final definition in definitions) definition.id: definition,
    };
    final skillCredentialItems = credentials.map((credential) {
      final definition = definitionsById[credential.credentialDefinitionId];

      return ServiceConnectionListItem.fromSkillCredential(
        credential: credential,
        definition: definition,
      );
    });

    return [
      ...modelConnections.map(ServiceConnectionListItem.fromModelConnection),
      ...skillCredentialItems,
      ...mcpCredentials,
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  Stream<List<ServiceConnectionListItem>> _watchMcpCredentialItems(
    String workspaceId,
  ) {
    final query = _database.select(_database.mcpServers).join([
      innerJoin(
        _database.serviceConnections,
        _database.serviceConnections.id.equalsExp(
          _database.mcpServers.serviceConnectionId,
        ),
      ),
    ])..where(_database.mcpServers.workspaceId.equals(workspaceId));

    return query.watch().map((rows) {
      return rows.map(_mcpCredentialItem).toList();
    });
  }

  ServiceConnectionListItem _mcpCredentialItem(TypedResult row) {
    final server = row.readTable(_database.mcpServers);
    final credential = row.readTable(_database.serviceConnections);
    final metadataResult = _decodeMetadata(credential);

    return ServiceConnectionListItem.fromMcpCredential(
      id: credential.id,
      workspaceId: credential.workspaceId,
      name: server.name,
      url: server.url,
      mcpServerId: server.id,
      authenticationType: credential.authenticationType.value,
      isEnabled: credential.isEnabled,
      authStatus: credential.authStatus,
      expiresAt: credential.expiresAt,
      lastRefreshedAt: credential.lastRefreshedAt,
      lastAuthError: credential.lastAuthError,
      metadata: metadataResult.metadata,
      canRefresh:
          credential.authenticationType ==
          ServiceAuthenticationTypeTable.oauth2,
      now: _now(),
      hasMetadataError: metadataResult.hasError,
    );
  }

  ({ServiceConnectionMetadata metadata, bool hasError}) _decodeMetadata(
    ServiceConnectionTable credential,
  ) {
    try {
      return (
        metadata: ServiceConnectionAuthCodec.decodeMetadata(
          credential.metadataJson,
        ),
        hasError: false,
      );
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Invalid service connection metadata '
        'connectionId=${credential.id} workspace=${credential.workspaceId}',
        error,
        stackTrace,
      );

      return (metadata: const ServiceConnectionMetadata(), hasError: true);
    }
  }
}
