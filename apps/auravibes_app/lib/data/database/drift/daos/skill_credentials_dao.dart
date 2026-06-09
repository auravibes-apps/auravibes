// ignore_for_file: prefer-async-await
// Required: Existing Future chains preserve callback flow.
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:drift/drift.dart';
import 'package:logging/logging.dart';

part 'skill_credentials_dao.g.dart';

final _logger = Logger('dao:skill_credentials');

@DriftAccessor(tables: [ServiceConnections])
class SkillCredentialsDao extends DatabaseAccessor<AppDatabase>
    with _$SkillCredentialsDaoMixin {
  SkillCredentialsDao(super.attachedDatabase);

  Future<List<ServiceConnectionTable>> getCredentialsForDefinition({
    required String workspaceId,
    required String credentialDefinitionId,
  }) {
    return (select(serviceConnections)
          ..where(
            (tbl) =>
                tbl.workspaceId.equals(workspaceId) &
                tbl.serviceId.equals(credentialDefinitionId) &
                tbl.kind.equals(
                  ServiceConnectionKindTable.skillCredential.name,
                ) &
                tbl.isEnabled.equals(true),
          )
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.name)]))
        .get();
  }

  Stream<List<ServiceConnectionTable>> watchCredentialsForWorkspace(
    String workspaceId,
  ) {
    return (select(serviceConnections)
          ..where(
            (tbl) =>
                tbl.workspaceId.equals(workspaceId) &
                tbl.kind.equals(
                  ServiceConnectionKindTable.skillCredential.name,
                ) &
                tbl.isEnabled.equals(true),
          )
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.name)]))
        .watch();
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
  ) {
    return (update(serviceConnections)..where(
          (tbl) =>
              tbl.id.equals(credentialId) &
              tbl.kind.equals(ServiceConnectionKindTable.skillCredential.name),
        ))
        .writeReturning(credential)
        .then((rows) => rows.firstOrNull);
  }

  Future<int> deleteCredential(String credentialId) {
    return (delete(serviceConnections)..where(
          (tbl) =>
              tbl.id.equals(credentialId) &
              tbl.kind.equals(ServiceConnectionKindTable.skillCredential.name),
        ))
        .go()
        .then((count) {
          _logger.info(
            'debug:skill credential dao delete complete '
            'credentialId=$credentialId deletedRows=$count',
          );

          return count;
        });
  }
}
