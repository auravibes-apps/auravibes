import 'dart:async';
import 'dart:convert';

import 'package:auravibes_server/src/features/workspace_state/repositories/workspace_state_repository.dart';
import 'package:auravibes_server/src/features/workspace_state/usecases/workspace_state_usecases.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Credential definition safety', (sessionBuilder, _) {
    for (final directPatch in [false, true]) {
      test(
        'canonical reference: rejects alias-only create via direct patch $directPatch',
        () async {
          final f = await _Fixture.create(sessionBuilder.build());
          if (directPatch) {
            await f.patch(.update, schema: '{"token":{"optional":true}}');
          }
          final request = f.credentialRequest(
            secret: {'token': 'synthetic-value'},
          );
          _useCredentialAlias(request.resourceOperation);
          await expectLater(
            directPatch
                ? f.operations([request.resourceOperation])
                : f.mutate(request),
            throwsA(
              isA<CloudWorkspaceException>().having(
                (e) => e.code,
                'code',
                CloudWorkspaceErrorCode.validationFailed,
              ),
            ),
          );
          await f.expectNoCredentialWrites(eventCount: directPatch ? 1 : 0);
        },
      );
    }
    test(
      'canonical reference: rejects alias-only update without partial writes',
      () async {
        final f = await _Fixture.create(sessionBuilder.build());
        await f.mutate(
          f.credentialRequest(secret: {'token': 'synthetic-value'}),
        );
        final before = await f.writeState();
        final request = f.credentialRequest(revision: 1);
        _useCredentialAlias(request.resourceOperation);
        await expectLater(
          f.mutate(request),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (e) => e.code,
              'code',
              CloudWorkspaceErrorCode.validationFailed,
            ),
          ),
        );
        expect(await f.writeState(), before);
      },
    );
    test('canonical reference: putSecret rejects legacy alias while preserving stored reads', () async {
      final f = await _Fixture.create(sessionBuilder.build());
      final created = await f.mutate(
        f.credentialRequest(secret: {'token': 'synthetic-value'}),
      );
      final operation = f.credentialRequest().resourceOperation;
      _useCredentialAlias(operation);
      // Simulate pre-existing legacy metadata; public writes must not create it.
      await WorkspaceResource.db.updateRow(
        f.session,
        created.resource.copyWith(data: operation.data),
      );
      final before = await f.writeState();
      final read = await WorkspaceStateUseCases(WorkspaceStateRepository())
          .read(
            f.session,
            userId: f.userId,
            request: ReadWorkspaceStateRequest(
              workspaceId: f.workspaceId,
              pages: [
                WorkspaceResourcePageRequest(
                  resourceKind: .serviceConnection,
                  limit: 10,
                ),
              ],
              eventLimit: 0,
            ),
          );
      expect(
        jsonDecode(
          read.pages.single.resources.single.data,
        )['skillDefinitionId'],
        'definition',
      );
      await expectLater(
        WorkspaceStateUseCases(WorkspaceStateRepository()).putSecret(
          f.session,
          userId: f.userId,
          request: PutWorkspaceSecretRequest(
            workspaceId: f.workspaceId,
            requestId: const Uuid().v4().toString(),
            secretKind: .skillCredential,
            scope: .workspace,
            resourceId: 'prepared',
            expectedRevision: created.secretRevision,
            secret: jsonEncode({
              'set': {'token': 'replacement-value'},
              'clear': <String>[],
            }),
          ),
        ),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (e) => e.code,
            'code',
            CloudWorkspaceErrorCode.validationFailed,
          ),
        ),
      );
      expect(await f.writeState(), before);
    });
    test(
      'canonical reference: legacy skill alias still blocks deletion',
      () async {
        final f = await _Fixture.create(sessionBuilder.build());
        await f.operations([
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .skill,
            resourceId: 'legacy-skill',
            data: jsonEncode({
              'skillDefinitionId': 'definition',
              'isEnabled': false,
            }),
            fieldMask: [],
          ),
        ]);
        await expectLater(
          f.patch(.delete),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (e) => e.code,
              'code',
              CloudWorkspaceErrorCode.conflict,
            ),
          ),
        );
        expect((await f.definition()).deletedAt, isNull);
        expect(await f.events(), hasLength(1));
      },
    );

    test('current schema: legacy metadata-only definition stays readable but cannot back a new credential', () async {
      final f = await _Fixture.create(sessionBuilder.build());
      final definition = await f.definition();
      await WorkspaceResource.db.updateRow(
        f.session,
        definition.copyWith(
          data: jsonEncode({
            'title': 'Legacy',
            'attributesJson': '{"region":{"secret":false}}',
          }),
        ),
      );
      expect(jsonDecode((await f.definition()).data)['title'], 'Legacy');
      await expectLater(
        f.mutate(
          f.credentialRequest(
            secret: {'token': 'synthetic-value'},
            metadata: {'region': 'east'},
          ),
        ),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (e) => e.code,
            'code',
            CloudWorkspaceErrorCode.validationFailed,
          ),
        ),
      );
      await f.expectNoCredentialWrites(eventCount: 0);
    });

    test(
      'current schema: missing new credential secret returns typed rejection',
      () async {
        final f = await _Fixture.create(sessionBuilder.build());
        await expectLater(
          f.mutate(f.credentialRequest()),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (e) => e.code,
              'code',
              CloudWorkspaceErrorCode.validationFailed,
            ),
          ),
        );
        await f.expectNoCredentialWrites(eventCount: 0);
      },
    );
    test('current schema: putSecret cannot clear required values', () async {
      final f = await _Fixture.create(sessionBuilder.build());
      final created = await f.mutate(
        f.credentialRequest(secret: {'token': 'synthetic-value'}),
      );
      await expectLater(
        WorkspaceStateUseCases(WorkspaceStateRepository()).putSecret(
          f.session,
          userId: f.userId,
          request: PutWorkspaceSecretRequest(
            workspaceId: f.workspaceId,
            requestId: const Uuid().v4().toString(),
            secretKind: .skillCredential,
            scope: .workspace,
            resourceId: 'prepared',
            expectedRevision: created.secretRevision,
            secret: jsonEncode({
              'set': <String, String>{},
              'clear': ['token'],
            }),
          ),
        ),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (e) => e.code,
            'code',
            CloudWorkspaceErrorCode.validationFailed,
          ),
        ),
      );
      final saved = await WorkspaceSecret.db.findFirstRow(
        f.session,
        where: (t) => t.workspaceId.equals(f.workspaceId),
      );
      expect(saved!.revision, 1);
      expect(saved.deletedAt, isNull);
      expect(await f.events(), hasLength(2));
    });
    test('current schema: rejects prepared credential after required field commits', () async {
      final f = await _Fixture.create(sessionBuilder.build());
      final prepared = f.credentialRequest(
        secret: {'token': 'synthetic-value'},
      );
      await f.patch(.update, schema: '{"token":{},"newRequired":{}}');
      await expectLater(
        f.mutate(prepared),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (e) => e.code,
            'code',
            CloudWorkspaceErrorCode.validationFailed,
          ),
        ),
      );
      await f.expectNoCredentialWrites(eventCount: 1);
      expect((await f.definition()).revision, 2);
    });
    test('current schema: direct patch cannot omit required secrets or expose them as metadata', () async {
      final f = await _Fixture.create(sessionBuilder.build());
      for (final attributes in [
        <String, String>{},
        {'token': 'synthetic-value'},
      ]) {
        await expectLater(
          f.operations([
            f.credentialRequest(metadata: attributes).resourceOperation,
          ]),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (e) => e.code,
              'code',
              CloudWorkspaceErrorCode.validationFailed,
            ),
          ),
        );
        await f.expectNoCredentialWrites(eventCount: 0);
      }
    });
    test('current schema: mutation rejects storage partition mismatches and missing metadata', () async {
      final f = await _Fixture.create(sessionBuilder.build());
      await f.patch(.update, schema: '{"token":{},"region":{"secret":false}}');
      for (final request in [
        f.credentialRequest(
          secret: {'token': 'synthetic-value', 'region': 'east'},
        ),
        f.credentialRequest(
          secret: {'token': 'synthetic-value'},
          metadata: {'token': 'leaked', 'region': 'east'},
        ),
        f.credentialRequest(secret: {'token': 'synthetic-value'}),
      ]) {
        await expectLater(
          f.mutate(request),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (e) => e.code,
              'code',
              CloudWorkspaceErrorCode.validationFailed,
            ),
          ),
        );
        await f.expectNoCredentialWrites(eventCount: 1);
      }
    });
    test('current schema: valid merged update and direct metadata patch retain required secret', () async {
      final f = await _Fixture.create(sessionBuilder.build());
      await f.patch(.update, schema: '{"token":{},"region":{"secret":false}}');
      final created = await f.mutate(
        f.credentialRequest(
          secret: {'token': 'synthetic-value'},
          metadata: {'region': 'east'},
        ),
      );
      expect(created.configured, isTrue);
      final updated = await f.mutate(
        f.credentialRequest(metadata: {'region': 'west'}, revision: 1),
      );
      expect(updated.configured, isTrue);
      final patched = await f.operations([
        f
            .credentialRequest(metadata: {'region': 'north'}, revision: 2)
            .resourceOperation,
      ]);
      expect(jsonDecode(patched.resources.single.data)['attributes'], {
        'region': 'north',
      });
      final clearing = f.credentialRequest(
        metadata: {'region': 'west'},
        revision: 3,
        clear: ['token'],
      );
      clearing.expectedSecretRevision = created.secretRevision;
      await expectLater(
        f.mutate(clearing),
        throwsA(isA<CloudWorkspaceException>()),
      );
      final saved = await WorkspaceResource.db.findFirstRow(
        f.session,
        where: (t) =>
            t.workspaceId.equals(f.workspaceId) &
            t.resourceId.equals('prepared'),
      );
      expect(saved!.revision, 3);
      expect(await f.events(), hasLength(5));
    });

    test('direct patch blocks disabled reference-only deletion', () async {
      final fixture = await _Fixture.create(sessionBuilder.build());
      await fixture.insert(.skill, 'skill', {
        'credentialDefinitionId': 'definition',
        'isEnabled': false,
      });
      await expectLater(
        fixture.patch(.delete),
        throwsA(isA<CloudWorkspaceException>()),
      );
      expect((await fixture.definition()).deletedAt, isNull);
      expect(await fixture.events(), isEmpty);
    });
    test('direct patch blocks newly required fields for disabled metadata credentials', () async {
      final fixture = await _Fixture.create(sessionBuilder.build());
      await fixture.insert(.serviceConnection, 'credential', {
        'kind': 'skillCredential',
        'credentialDefinitionId': 'definition',
        'isEnabled': false,
        'hasSecret': false,
      });
      await expectLater(
        fixture.patch(.update, schema: '{"token":{},"newField":{}}'),
        throwsA(isA<CloudWorkspaceException>()),
      );
      expect((await fixture.definition()).revision, 1);
      expect(await fixture.events(), isEmpty);
    });
    test('direct patch rejects references to deleted definitions', () async {
      final fixture = await _Fixture.create(sessionBuilder.build());
      await fixture.patch(.delete);
      await expectLater(
        fixture.operations([
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: .skill,
            resourceId: 'skill',
            data: jsonEncode({'credentialDefinitionId': 'definition'}),
            fieldMask: [],
          ),
        ]),
        throwsA(isA<CloudWorkspaceException>()),
      );
      expect(
        await WorkspaceResource.db.count(
          fixture.session,
          where: (t) =>
              t.workspaceId.equals(fixture.workspaceId) &
              t.resourceKind.equals(WorkspaceResourceKind.skill),
        ),
        0,
      );
    });
    test(
      'tool override blocks deletion without owning skill reference',
      () async {
        final fixture = await _Fixture.create(sessionBuilder.build());
        await fixture.insert(.skill, 'skill', {'isEnabled': false});
        await fixture.insert(.skillTemplateTool, 'tool', {
          'skillId': 'skill',
          'credentialDefinitionId': 'definition',
          'isEnabled': false,
        });
        await expectLater(
          fixture.patch(.delete),
          throwsA(isA<CloudWorkspaceException>()),
        );
        expect((await fixture.definition()).deletedAt, isNull);
      },
    );
    test(
      'safe optional additions and unreferenced deletion remain possible',
      () async {
        final fixture = await _Fixture.create(sessionBuilder.build());
        final other = await _Fixture.create(fixture.session);
        await other.insert(.skill, 'skill', {
          'credentialDefinitionId': 'definition',
        });
        await fixture.patch(
          .update,
          schema: '{"token":{},"region":{"optional":true}}',
        );
        expect((await fixture.definition()).revision, 2);
        await fixture.patch(.delete, revision: 2);
        expect((await fixture.definition()).deletedAt, isNotNull);
      },
    );
  });
  withServerpod('Credential definition races', (sessionBuilder, _) {
    test(
      'schema mutation rechecks after concurrent credential creation',
      () async {
        final fixture = await _Fixture.create(sessionBuilder.build());
        await fixture.patch(.update, schema: '{"token":{"optional":true}}');
        final locked = Completer<void>();
        final release = Completer<void>();
        final attempted = Completer<void>();
        final creating = WorkspaceStateUseCases(WorkspaceStateRepository())
            .patch(
              fixture.session,
              userId: fixture.userId,
              request: fixture.request([
                WorkspacePatchOperation(
                  operation: .create,
                  resourceKind: .serviceConnection,
                  resourceId: 'racing-credential',
                  data: jsonEncode({
                    'kind': 'skillCredential',
                    'credentialDefinitionId': 'definition',
                    'isEnabled': false,
                    'hasSecret': false,
                  }),
                  fieldMask: [],
                ),
              ]),
              guard: (_) async {
                locked.complete();
                await release.future;
              },
            );
        await locked.future;
        final updating = WorkspaceStateUseCases(_ObservedRepository(attempted))
            .patch(
              sessionBuilder.build(),
              userId: fixture.userId,
              request: fixture.request([
                WorkspacePatchOperation(
                  operation: .update,
                  resourceKind: .skillDefinition,
                  resourceId: 'definition',
                  expectedRevision: 2,
                  data: jsonEncode({
                    'title': 'Type',
                    'attributesJson': '{"token":{},"added":{}}',
                  }),
                  fieldMask: [],
                ),
              ]),
            );
        final rejected = expectLater(
          updating,
          throwsA(isA<CloudWorkspaceException>()),
        );
        await attempted.future;
        release.complete();
        await creating;
        await rejected;
        expect((await fixture.definition()).revision, 2);
        expect(await fixture.events(), hasLength(2));
      },
    );
    for (final deleteFirst in [false, true]) {
      test(
        'serializes reference creation and deletion, delete first: $deleteFirst',
        () async {
          final fixture = await _Fixture.create(sessionBuilder.build());
          final create = WorkspacePatchOperation(
            operation: .create,
            resourceKind: .skill,
            resourceId: 'racing-skill',
            data: jsonEncode({'credentialDefinitionId': 'definition'}),
            fieldMask: [],
          );
          final delete = WorkspacePatchOperation(
            operation: .delete,
            resourceKind: .skillDefinition,
            resourceId: 'definition',
            expectedRevision: 1,
            fieldMask: [],
          );
          final locked = Completer<void>();
          final release = Completer<void>();
          final attempted = Completer<void>();
          final first = WorkspaceStateUseCases(WorkspaceStateRepository())
              .patch(
                fixture.session,
                userId: fixture.userId,
                request: fixture.request([deleteFirst ? delete : create]),
                guard: (_) async {
                  locked.complete();
                  await release.future;
                },
              );
          await locked.future;
          final second = WorkspaceStateUseCases(_ObservedRepository(attempted))
              .patch(
                sessionBuilder.build(),
                userId: fixture.userId,
                request: fixture.request([deleteFirst ? create : delete]),
              );
          final rejected = expectLater(
            second,
            throwsA(isA<CloudWorkspaceException>()),
          );
          await attempted.future;
          release.complete();
          await first;
          await rejected;
          expect((await fixture.definition()).deletedAt != null, deleteFirst);
          expect(await fixture.events(), hasLength(1));
        },
      );
    }
  }, rollbackDatabase: RollbackDatabase.disabled);
}

class _ObservedRepository(this.attempted) extends WorkspaceStateRepository {
  final Completer<void> attempted;
  @override
  Future<CloudWorkspace?> findWorkspace(
    Session session,
    int workspaceId, {
    Transaction? transaction,
    bool lock = false,
  }) {
    if (lock && !attempted.isCompleted) attempted.complete();

    return super.findWorkspace(
      session,
      workspaceId,
      transaction: transaction,
      lock: lock,
    );
  }
}

class _Fixture {
  const _Fixture(this.session, this.workspaceId, this.userId);
  final Session session;
  final int workspaceId;
  final String userId;
  static Future<_Fixture> create(Session session) async {
    final user = const Uuid().v4().toString();
    final workspace = await workspace_repo.CloudWorkspaceRepository()
        .createWorkspace(
          session,
          name: 'Credential safety',
          ownerUserId: user,
          now: DateTime.now().toUtc(),
        );
    final fixture = _Fixture(session, workspace.id!, user);
    await fixture.insert(.skillDefinition, 'definition', {
      'title': 'Type',
      'attributesJson': '{"token":{}}',
    });

    return fixture;
  }

  Future<void> insert(
    WorkspaceResourceKind kind,
    String id,
    Map<String, Object?> data,
  ) async {
    final now = DateTime.now().toUtc();
    await WorkspaceResource.db.insertRow(
      session,
      WorkspaceResource(
        workspaceId: workspaceId,
        resourceKind: kind,
        resourceId: id,
        data: jsonEncode(data),
        revision: 1,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<PatchWorkspaceStateResponse> patch(
    WorkspacePatchOperationKind operation, {
    String? schema,
    int revision = 1,
  }) => operations([
    WorkspacePatchOperation(
      operation: operation,
      resourceKind: .skillDefinition,
      resourceId: 'definition',
      expectedRevision: revision,
      fieldMask: [],
      data: schema == null
          ? null
          : jsonEncode({'title': 'Type', 'attributesJson': schema}),
    ),
  ]);
  PatchWorkspaceStateRequest request(
    List<WorkspacePatchOperation> operations,
  ) => PatchWorkspaceStateRequest(
    workspaceId: workspaceId,
    requestId: const Uuid().v4().toString(),
    operations: operations,
  );
  Future<PatchWorkspaceStateResponse> operations(
    List<WorkspacePatchOperation> operations,
  ) => WorkspaceStateUseCases(WorkspaceStateRepository()).patch(
    session,
    userId: userId,
    request: PatchWorkspaceStateRequest(
      workspaceId: workspaceId,
      requestId: const Uuid().v4().toString(),
      operations: operations,
    ),
  );
  Future<WorkspaceResource> definition() async =>
      (await WorkspaceResource.db.findFirstRow(
        session,
        where: (t) =>
            t.workspaceId.equals(workspaceId) &
            t.resourceKind.equals(WorkspaceResourceKind.skillDefinition) &
            t.resourceId.equals('definition'),
      ))!;
  Future<List<WorkspaceEvent>> events() => WorkspaceEvent.db.find(
    session,
    where: (t) => t.workspaceId.equals(workspaceId),
  );
}

extension _CredentialWrites on _Fixture {
  MutateWorkspaceCredentialRequest credentialRequest({
    Map<String, String> secret = const {},
    Map<String, String> metadata = const {},
    int? revision,
    List<String> clear = const [],
  }) => MutateWorkspaceCredentialRequest(
    workspaceId: workspaceId,
    requestId: const Uuid().v4().toString(),
    resourceOperation: WorkspacePatchOperation(
      operation: revision == null ? .create : .update,
      resourceKind: .serviceConnection,
      resourceId: 'prepared',
      expectedRevision: revision,
      data: jsonEncode({
        'kind': 'skillCredential',
        'credentialDefinitionId': 'definition',
        'name': 'Prepared',
        'attributes': metadata,
        'isEnabled': true,
      }),
      fieldMask: [],
    ),
    secretKind: .skillCredential,
    scope: .workspace,
    clearSecret: false,
    secret: secret.isEmpty && clear.isEmpty
        ? null
        : jsonEncode({'set': secret, 'clear': clear}),
  );
  Future<MutateWorkspaceCredentialResponse> mutate(
    MutateWorkspaceCredentialRequest request,
  ) =>
      WorkspaceStateUseCases(WorkspaceStateRepository())
          .mutateCredential(session, userId: userId, request: request);
  Future<void> expectNoCredentialWrites({required int eventCount}) async {
    expect(
      await WorkspaceResource.db.count(
        session,
        where: (t) =>
            t.workspaceId.equals(workspaceId) &
            t.resourceKind.equals(WorkspaceResourceKind.serviceConnection),
      ),
      0,
    );
    expect(
      await WorkspaceSecret.db.count(
        session,
        where: (t) => t.workspaceId.equals(workspaceId),
      ),
      0,
    );
    expect(await events(), hasLength(eventCount));
    final workspace = await CloudWorkspace.db.findById(session, workspaceId);
    expect(workspace!.sequence, eventCount);
    expect(
      await WorkspaceMutationReceipt.db.count(
        session,
        where: (t) => t.workspaceId.equals(workspaceId),
      ),
      eventCount,
    );
  }
}

void _useCredentialAlias(WorkspacePatchOperation operation) {
  final data = jsonDecode(operation.data!) as Map<String, dynamic>;
  data['skillDefinitionId'] = data.remove('credentialDefinitionId');
  operation.data = jsonEncode(data);
}

extension _PersistedWriteState on _Fixture {
  Future<String> writeState() async {
    final resources = await WorkspaceResource.db.find(
      session,
      where: (t) => t.workspaceId.equals(workspaceId),
      orderBy: (t) => t.id,
    );
    final secrets = await WorkspaceSecret.db.find(
      session,
      where: (t) => t.workspaceId.equals(workspaceId),
      orderBy: (t) => t.id,
    );
    final receipts = await WorkspaceMutationReceipt.db.find(
      session,
      where: (t) => t.workspaceId.equals(workspaceId),
      orderBy: (t) => t.id,
    );
    final workspace = await CloudWorkspace.db.findById(session, workspaceId);
    return jsonEncode({
      'resources': resources.map((row) => row.toJson()).toList(),
      'secrets': secrets.map((row) => row.toJson()).toList(),
      'receipts': receipts.map((row) => row.toJson()).toList(),
      'events': (await events()).map((row) => row.toJson()).toList(),
      'workspace': workspace!.toJson(),
    });
  }
}
