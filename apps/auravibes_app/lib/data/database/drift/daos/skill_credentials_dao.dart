import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
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
  }) {
    return _credentialsForDefinitionQuery(
      workspaceId,
      credentialDefinitionId,
    ).get();
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
  ) {
    return into(serviceConnections).insertReturning(credential);
  }

  Future<ServiceConnectionTable?> updateCredential(
    String credentialId,
    ServiceConnectionsCompanion credential,
  ) async {
    final rows =
        await (update(serviceConnections)..where(
              (tbl) =>
                  tbl.id.equals(credentialId) &
                  tbl.kind.equals(
                    ServiceConnectionKindTable.skillCredential.name,
                  ),
            ))
            .writeReturning(credential);

    return rows.firstOrNull;
  }

  Future<int> deleteCredential(String credentialId) async {
    final count = await _deleteCredentialRows(credentialId);

    _logger.info(
      'debug:skill credential dao delete complete '
      'credentialId=$credentialId deletedRows=$count',
    );

    return count;
  }

  SimpleSelectStatement<$ServiceConnectionsTable, ServiceConnectionTable>
  _credentialsForDefinitionQuery(
    String workspaceId,
    String credentialDefinitionId,
  ) {
    final statement = select(serviceConnections)
      ..where(
        (tbl) => _credentialDefinitionFilter(
          tbl,
          workspaceId,
          credentialDefinitionId,
        ),
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
