import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/domain/models/credential_dependency.dart';
import 'package:drift/drift.dart';
import 'package:logging/logging.dart';

part 'skill_credentials_dao.g.dart';

final _logger = Logger('dao:skill_credentials');

@DriftAccessor(tables: [ServiceConnections])
class SkillCredentialsDao(super.attachedDatabase)
    extends DatabaseAccessor<AppDatabase>
    with _$SkillCredentialsDaoMixin;

extension SkillCredentialsDaoMethods on SkillCredentialsDao {
  Future<List<ServiceConnectionTable>> getCredentialsForDefinition({
    required String workspaceId,
    required String credentialDefinitionId,
    bool requireSecret = false,
  }) {
    return _credentialsForDefinitionQuery(
      workspaceId,
      credentialDefinitionId,
      requireSecret: requireSecret,
    ).get();
  }

  Future<List<CredentialDependency>> getLinkedCredentialSummaries({
    required String workspaceId,
    required String credentialDefinitionId,
  }) async {
    final table = serviceConnections;
    final query = selectOnly(table)
      ..addColumns([table.id, table.name, table.isEnabled])
      ..where(_linkedCredentialFilter(workspaceId, credentialDefinitionId));
    final rows = await query.get();

    return rows.map(_credentialSummary).toList();
  }

  Future<int> countLinkedCredentials({
    required String workspaceId,
    required String credentialDefinitionId,
  }) async {
    final count = serviceConnections.id.count();
    final query = selectOnly(serviceConnections)
      ..addColumns([count])
      ..where(_linkedCredentialFilter(workspaceId, credentialDefinitionId));

    final row = await query.getSingle();

    return await row.read(count) ?? 0;
  }

  Stream<List<ServiceConnectionTable>> watchCredentialsForWorkspace(
    String workspaceId,
  ) {
    return _credentialsForWorkspaceQuery(workspaceId).watch();
  }

  Future<ServiceConnectionTable?> getCredentialById(String credentialId) {
    return (select(serviceConnections)..where(
          (tbl) =>
              tbl.id.equals(credentialId) &
              tbl.kind.equals(ServiceConnectionKindTable.skillCredential.name),
        ))
        .getSingleOrNull();
  }

  Future<ServiceConnectionTable> createCredential(
    ServiceConnectionsCompanion credential,
  ) => transaction(() async {
    await _requireDefinition(
      credential.workspaceId.value,
      credential.serviceId.value,
    );

    return await into(serviceConnections).insertReturning(credential);
  });

  Future<ServiceConnectionTable?> updateCredential(
    String credentialId,
    ServiceConnectionsCompanion credential,
  ) => transaction(() async {
    final current = await getCredentialById(credentialId);
    if (current == null) return null;
    await _requireUpdatedDefinition(current, credential);

    return await _writeCredential(credentialId, credential);
  });

  Future<int> deleteCredential(String credentialId) async {
    final count = await _deleteCredentialRows(credentialId);

    _logger.info(
      'debug:skill credential dao delete complete '
      'credentialId=$credentialId deletedRows=$count',
    );

    return count;
  }
}

extension SkillCredentialMetadataWrites on SkillCredentialsDao {
  CredentialDependency _credentialSummary(TypedResult row) =>
      CredentialDependency(
        id: row.read(serviceConnections.id) ?? '',
        title: row.read(serviceConnections.name) ?? '',
        isEnabled: row.read(serviceConnections.isEnabled) ?? false,
      );

  Future<void> _requireUpdatedDefinition(
    ServiceConnectionTable current,
    ServiceConnectionsCompanion credential,
  ) async {
    await _requireDefinition(
      credential.workspaceId.present
          ? credential.workspaceId.value
          : current.workspaceId,
      credential.serviceId.present
          ? credential.serviceId.value
          : current.serviceId,
    );
  }

  Future<ServiceConnectionTable?> _writeCredential(
    String credentialId,
    ServiceConnectionsCompanion credential,
  ) async {
    final rows =
        await (update(serviceConnections)
              ..where((tbl) => _credentialIdFilter(tbl, credentialId)))
            .writeReturning(credential);

    return rows.firstOrNull;
  }

  Future<void> _requireDefinition(
    String workspaceId,
    String definitionId,
  ) async {
    final definition = await attachedDatabase.skillCredentialDefinitionsDao
        .getDefinitionById(definitionId);
    if (definition == null || definition.workspaceId != workspaceId) {
      throw StateError('Credential definition unavailable in this workspace');
    }
  }
}

extension SkillCredentialsDaoQueries on SkillCredentialsDao {
  SimpleSelectStatement<$ServiceConnectionsTable, ServiceConnectionTable>
  _credentialsForDefinitionQuery(
    String workspaceId,
    String credentialDefinitionId, {
    bool requireSecret = false,
  }) {
    final statement = select(serviceConnections)
      ..where(
        (tbl) =>
            _credentialDefinitionFilter(
              tbl,
              workspaceId,
              credentialDefinitionId,
            ) &
            (requireSecret
                ? tbl.encryptedAuthValue.isNotNull()
                : const Constant(true)),
      );

    return statement..orderBy(_credentialNameOrdering());
  }

  SimpleSelectStatement<$ServiceConnectionsTable, ServiceConnectionTable>
  _credentialsForWorkspaceQuery(String workspaceId) {
    final statement = select(serviceConnections)
      ..where((tbl) => _workspaceCredentialFilter(tbl, workspaceId));

    return statement..orderBy(_credentialNameOrdering());
  }

  Future<int> _deleteCredentialRows(String credentialId) => (delete(
    serviceConnections,
  )..where((tbl) => _credentialIdFilter(tbl, credentialId))).go();

  Expression<bool> _credentialDefinitionFilter(
    $ServiceConnectionsTable tbl,
    String workspaceId,
    String credentialDefinitionId,
  ) =>
      _workspaceCredentialFilter(tbl, workspaceId) &
      tbl.serviceId.equals(credentialDefinitionId);

  Expression<bool> _linkedCredentialFilter(
    String workspaceId,
    String credentialDefinitionId,
  ) =>
      serviceConnections.workspaceId.equals(workspaceId) &
      serviceConnections.kind.equals(
        ServiceConnectionKindTable.skillCredential.name,
      ) &
      serviceConnections.serviceId.equals(credentialDefinitionId);

  Expression<bool> _workspaceCredentialFilter(
    $ServiceConnectionsTable tbl,
    String workspaceId,
  ) =>
      tbl.workspaceId.equals(workspaceId) &
      tbl.kind.equals(ServiceConnectionKindTable.skillCredential.name) &
      tbl.isEnabled.equals(true);

  Expression<bool> _credentialIdFilter(
    $ServiceConnectionsTable tbl,
    String credentialId,
  ) =>
      tbl.id.equals(credentialId) &
      tbl.kind.equals(ServiceConnectionKindTable.skillCredential.name);

  List<OrderingTerm Function($ServiceConnectionsTable)>
  _credentialNameOrdering() => [(tbl) => OrderingTerm(expression: tbl.name)];
}
