import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:auravibes_server/src/features/objects/object_cleanup_service.dart';
import 'package:auravibes_server/src/features/objects/object_scanner.dart';
import 'package:auravibes_server/src/features/objects/object_store.dart';
import 'package:auravibes_server/src/features/objects/object_use_cases.dart';
import 'package:auravibes_server/src/features/objects/testing/in_memory_object_store.dart';
import 'package:auravibes_server/src/features/workers/worker_coordinator_repository.dart';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'package:auravibes_server/src/features/workspaces/workspace_erasure_cleanup.dart';
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/auth_services_test_helper.dart';
import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Cloud workspace erasure', (builder, endpoints) {
    setUp(() => _clearCoordinator(builder.build()));
    tearDownAll(() => _clearCoordinator(builder.build()));

    test(
      'lists unresolved erasures beyond recent completed statuses',
      () async {
        final userId = const Uuid().v4().toString();
        final authenticated = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final session = authenticated.build();
        await AuthUser.db.insertRow(
          session,
          AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          session,
          EmailAccount(
            authUserId: UuidValue.fromString(userId),
            email: '$userId@example.invalid',
            passwordHash: 'unused',
          ),
        );
        final now = DateTime.now().toUtc();
        final pendingRequestId = 'old-pending-$userId';
        final attentionRequestId = 'old-attention-$userId';
        final requests = [
          WorkspaceErasureRequest(
            workspaceId: 1,
            workspaceName: 'Older pending workspace',
            ownerUserId: userId,
            requestId: pendingRequestId,
            requestHash: 'synthetic-pending-hash',
            state: 'pending',
            requestedAt: now.subtract(const Duration(days: 1)),
          ),
          WorkspaceErasureRequest(
            workspaceId: 2,
            workspaceName: 'Older attention workspace',
            ownerUserId: userId,
            requestId: attentionRequestId,
            requestHash: 'synthetic-attention-hash',
            state: 'needsAttention',
            requestedAt: now.subtract(const Duration(days: 2)),
            failureReason: 'synthetic retry needed',
          ),
          for (final index in List.generate(101, (index) => index))
            WorkspaceErasureRequest(
              workspaceId: 1000 + index,
              workspaceName: 'Completed workspace $index',
              ownerUserId: userId,
              requestId: 'completed-$index-$userId',
              requestHash: 'synthetic-completed-hash-$index',
              state: 'complete',
              requestedAt: now.add(Duration(seconds: index + 1)),
              completedAt: now.add(Duration(seconds: index + 2)),
            ),
        ];
        await WorkspaceErasureRequest.db.insert(session, requests);

        final statuses = await endpoints.cloudWorkspace.listWorkspaceErasures(
          authenticated,
        );
        final requestIds = statuses.map((status) => status.requestId).toSet();

        expect(
          requestIds,
          containsAll({pendingRequestId, attentionRequestId}),
        );
        expect(requestIds, contains('completed-100-$userId'));
        expect(statuses.length, greaterThanOrEqualTo(102));
      },
    );

    test(
      'does not treat a legacy upload expiry as erasure proof',
      () async {
        final userId = const Uuid().v4().toString();
        final authenticated = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final session = authenticated.build();
        await AuthUser.db.insertRow(
          session,
          AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          session,
          EmailAccount(
            authUserId: UuidValue.fromString(userId),
            email: '$userId@example.invalid',
            passwordHash: 'unused',
          ),
        );
        final now = DateTime.now().toUtc();
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              session,
              name: 'Upload expiry erasure',
              ownerUserId: userId,
              now: now,
            );
        final object = await WorkspaceObject.db.insertRow(
          session,
          WorkspaceObject(
            workspaceId: workspace.id!,
            objectKey: 'private/upload-expiry',
            purpose: 'workspace_asset',
            displayName: 'upload.txt',
            mimeType: 'text/plain',
            sizeBytes: 4,
            checksumSha256: 'a' * 64,
            status: 'deleted',
            revision: 2,
            createdAt: now,
            updatedAt: now,
            deletedAt: now,
          ),
        );
        await ObjectDeletion.db.insertRow(
          session,
          ObjectDeletion(
            workspaceId: workspace.id!,
            objectId: object.id!,
            objectKey: object.objectKey,
            requestId: 'old-delete-$userId',
            expectedRevision: 1,
            requestedAt: now,
            completedAt: now,
            attempts: 0,
            availableAt: now,
          ),
        );
        final uploadExpiry = now.add(const Duration(minutes: 10));
        await ObjectUpload.db.insertRow(
          session,
          ObjectUpload(
            workspaceId: workspace.id!,
            objectId: object.id!,
            actorUserId: userId,
            requestId: 'signed-upload-$userId',
            requestHash: 'synthetic-upload-hash',
            expiresAt: uploadExpiry,
            createdAt: now,
          ),
        );

        final status = await endpoints.cloudWorkspace.eraseWorkspace(
          authenticated,
          EraseCloudWorkspaceRequest(
            workspaceId: workspace.id!,
            confirmationName: workspace.name,
            requestId: 'erase-upload-$userId',
            expectedWorkspaceRevision: workspace.revision,
          ),
        );
        final deletion = await ObjectDeletion.db.findFirstRow(
          session,
          where: (row) => row.objectId.equals(object.id!),
        );

        expect(status.state, 'pending');
        expect(deletion, isNotNull);
        expect(deletion!.availableAt.isBefore(now), isFalse);
        expect(deletion.availableAt.isBefore(uploadExpiry), isTrue);
        expect(deletion.completedAt, isNull);
        expect(
          await CloudWorkspace.db.findById(session, workspace.id!),
          isNotNull,
        );
      },
    );

    test('idempotent begin cannot re-sign a deleted object', () async {
      final userId = const Uuid().v4().toString();
      final authenticated = builder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );
      final session = authenticated.build();
      await AuthUser.db.insertRow(
        session,
        AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
      );
      await EmailAccount.db.insertRow(
        session,
        EmailAccount(
          authUserId: UuidValue.fromString(userId),
          email: '$userId@example.invalid',
          passwordHash: 'unused',
        ),
      );
      final now = DateTime.now().toUtc();
      final workspace = await workspace_repo.CloudWorkspaceRepository()
          .createWorkspace(
            session,
            name: 'Deleted upload retry',
            ownerUserId: userId,
            now: now,
          );
      const requestId = 'deleted-upload-retry';
      const displayName = 'deleted.txt';
      final checksum = List<String>.filled(64, 'd').join();
      final request = BeginUploadRequest(
        workspaceId: workspace.id!,
        requestId: requestId,
        purpose: 'workspace_asset',
        displayName: displayName,
        mimeType: 'text/plain',
        sizeBytes: 4,
        checksumSha256: checksum,
      );
      final object = await WorkspaceObject.db.insertRow(
        session,
        WorkspaceObject(
          workspaceId: workspace.id!,
          objectKey: 'private/deleted-upload',
          purpose: 'workspace_asset',
          displayName: displayName,
          mimeType: 'text/plain',
          sizeBytes: 4,
          checksumSha256: checksum,
          status: 'deleted',
          revision: 2,
          createdAt: now,
          updatedAt: now,
          deletedAt: now,
        ),
      );
      final requestHash = base64Url.encode(
        utf8.encode(
          [
            request.purpose,
            request.displayName,
            request.mimeType,
            request.sizeBytes,
            request.checksumSha256.toLowerCase(),
          ].join('\n'),
        ),
      );
      await ObjectUpload.db.insertRow(
        session,
        ObjectUpload(
          workspaceId: workspace.id!,
          objectId: object.id!,
          actorUserId: userId,
          requestId: requestId,
          requestHash: requestHash,
          expiresAt: now.add(const Duration(minutes: 10)),
          signingReservationCount: 0,
          createdAt: now,
        ),
      );
      final store = _CountingUploadStore();
      final objects = ObjectUseCases(
        store: store,
        scanner: const UnconfiguredObjectScanner(),
      );

      await expectLater(
        objects.beginUpload(session, userId: userId, request: request),
        throwsA(
          isA<ObjectException>().having(
            (error) => error.code,
            'code',
            ObjectErrorCode.objectNotFound,
          ),
        ),
      );
      expect(store.signCalls, 0);
    });

    test(
      'opaque and legacy object keys remain isolated across workspaces',
      () async {
        final userId = const Uuid().v4().toString();
        final authenticated = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final session = authenticated.build();
        await AuthUser.db.insertRow(
          session,
          AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          session,
          EmailAccount(
            authUserId: UuidValue.fromString(userId),
            email: '$userId@example.invalid',
            passwordHash: 'unused',
          ),
        );
        final now = DateTime.now().toUtc();
        final repository = workspace_repo.CloudWorkspaceRepository();
        final source = await repository.createWorkspace(
          session,
          name: 'Source',
          ownerUserId: userId,
          now: now,
        );
        final other = await repository.createWorkspace(
          session,
          name: 'Other',
          ownerUserId: userId,
          now: now,
        );
        final randomPart = userId.replaceAll('-', '');
        for (final key in [
          '$randomPart${'a' * 16}',
          '${source.id}/$randomPart${'b' * 16}',
        ]) {
          final object = await _insertRegisteredUpload(
            session,
            workspaceId: source.id!,
            userId: userId,
            objectKey: key,
            requestId: 'cross-workspace-$key-$userId',
            now: now,
          );
          await WorkspaceResource.db.insertRow(
            session,
            WorkspaceResource(
              workspaceId: source.id!,
              resourceKind: WorkspaceResourceKind.file,
              resourceId: 'file-${object.id}',
              data: jsonEncode({
                'name': 'Synthetic',
                'assetId': '${object.id}',
              }),
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
          );
          final own = GetDownloadRequest(
            workspaceId: source.id!,
            objectId: object.id!,
          );
          final foreign = GetDownloadRequest(
            workspaceId: other.id!,
            objectId: object.id!,
          );
          expect(
            (await endpoints.object.describe(authenticated, own)).objectId,
            object.id,
          );
          for (final action in [
            () => endpoints.object.describe(authenticated, foreign),
            () => endpoints.object.getDownload(authenticated, foreign),
          ]) {
            await expectLater(
              action(),
              throwsA(
                isA<ObjectException>().having(
                  (error) => error.code,
                  'code',
                  ObjectErrorCode.objectNotFound,
                ),
              ),
            );
          }
          final unchanged = await WorkspaceObject.db.findById(
            session,
            object.id!,
          );
          expect(unchanged?.status, 'active');
          expect(unchanged?.objectKey, key);
        }
      },
    );

    test('persists a gateway registration before signing an upload', () async {
      final userId = const Uuid().v4().toString();
      final authenticated = builder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          userId,
          const {},
        ),
      );
      final session = authenticated.build();
      await AuthUser.db.insertRow(
        session,
        AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
      );
      await EmailAccount.db.insertRow(
        session,
        EmailAccount(
          authUserId: UuidValue.fromString(userId),
          email: '$userId@example.invalid',
          passwordHash: 'unused',
        ),
      );
      final workspace = await workspace_repo.CloudWorkspaceRepository()
          .createWorkspace(
            session,
            name: 'Registered upload',
            ownerUserId: userId,
            now: DateTime.now().toUtc(),
          );
      const requestId = 'registered-upload';
      final store = _RegistrationAwareObjectStore(session);
      final objects = ObjectUseCases(
        store: store,
        scanner: const UnconfiguredObjectScanner(),
      );
      final request = BeginUploadRequest(
        workspaceId: workspace.id!,
        requestId: '$requestId-$userId',
        purpose: 'workspace_asset',
        displayName: 'registered.txt',
        mimeType: 'text/plain',
        sizeBytes: 4,
        checksumSha256: 'e' * 64,
      );

      final firstSigning = objects.beginUpload(
        session,
        userId: userId,
        request: request,
      );
      await store.registrationStarted.future.timeout(
        const Duration(seconds: 5),
      );
      await expectLater(
        objects.beginUpload(session, userId: userId, request: request),
        throwsA(
          isA<ObjectException>().having(
            (error) => error.code,
            'code',
            ObjectErrorCode.uploadProvenanceUnavailable,
          ),
        ),
      );
      expect(store.operations, ['register']);
      expect(store.registrationStatesAtSigning, isEmpty);
      store.releaseRegistration.complete();
      await firstSigning;
      await objects.beginUpload(session, userId: userId, request: request);
      final upload = await ObjectUpload.db.findFirstRow(
        session,
        where: (row) => row.requestId.equals('$requestId-$userId'),
      );

      final uploadedObject = await WorkspaceObject.db.findFirstRow(
        session,
        where: (row) => row.id.equals(upload!.objectId),
      );
      expect(uploadedObject?.objectKey, matches(RegExp(r'^[a-f0-9]{48}$')));
      expect(uploadedObject?.objectKey, isNot(contains('${workspace.id}/')));
      expect(store.registeredKey, uploadedObject?.objectKey);
      expect(store.operations, ['register', 'sign', 'sign']);
      expect(store.registrationAtRegistration, isNotNull);
      expect(store.registrationStateAtRegistration, 'registering');
      expect(
        store.registrationAtRegistration,
        matches(RegExp(r'^[a-f0-9]{64}$')),
      );
      expect(store.registrationAtRegistration, store.registeredId);
      expect(store.signingRegistrationId, store.registrationAtRegistration);
      expect(upload?.gatewayRegistrationId, store.registrationAtRegistration);
      expect(upload?.gatewayRegistrationState, 'registered');
      expect(store.registrationStatesAtSigning, ['registered', 'registered']);
    });

    test(
      'erasure winning during registration prevents the first PUT signature',
      () async {
        final userId = const Uuid().v4().toString();
        final authenticated = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final session = authenticated.build();
        await AuthUser.db.insertRow(
          session,
          AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          session,
          EmailAccount(
            authUserId: UuidValue.fromString(userId),
            email: '$userId@example.invalid',
            passwordHash: 'unused',
          ),
        );
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              session,
              name: 'Erased during gateway registration',
              ownerUserId: userId,
              now: DateTime.now().toUtc(),
            );
        final store = _RegistrationAwareObjectStore(session);
        final objects = ObjectUseCases(
          store: store,
          scanner: const UnconfiguredObjectScanner(),
        );
        final request = BeginUploadRequest(
          workspaceId: workspace.id!,
          requestId: 'erase-during-registration-$userId',
          purpose: 'workspace_asset',
          displayName: 'pending.txt',
          mimeType: 'text/plain',
          sizeBytes: 4,
          checksumSha256: 'f' * 64,
        );
        final signing = objects.beginUpload(
          session,
          userId: userId,
          request: request,
        );
        final outcome = signing.then<Object>(
          (result) => result,
          onError: (Object error, StackTrace _) => error,
        );
        await store.registrationStarted.future.timeout(
          const Duration(seconds: 5),
        );
        final upload = await ObjectUpload.db.findFirstRow(
          session,
          where: (row) => row.requestId.equals(request.requestId),
        );
        expect(upload?.gatewayRegistrationState, 'registering');

        final erasure = await endpoints.cloudWorkspace.eraseWorkspace(
          authenticated,
          EraseCloudWorkspaceRequest(
            workspaceId: workspace.id!,
            confirmationName: workspace.name,
            requestId: 'erase-during-registration-$userId',
            expectedWorkspaceRevision: workspace.revision,
          ),
        );
        expect(erasure.state, 'pending');
        store.releaseRegistration.complete();

        final result = await outcome;
        expect(
          result,
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.membershipRequired,
          ),
        );
        expect(store.operations, ['register']);
        expect(store.registrationStatesAtSigning, isEmpty);
        final completedUpload = await ObjectUpload.db.findFirstRow(
          session,
          where: (row) => row.requestId.equals(request.requestId),
        );
        expect(completedUpload?.gatewayRegistrationState, 'registering');
        expect(completedUpload?.signingReservationCount, 0);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    test(
      'signing completion cannot return a URL after object deletion wins',
      () async {
        final userId = const Uuid().v4().toString();
        final authenticated = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final session = authenticated.build();
        await AuthUser.db.insertRow(
          session,
          AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          session,
          EmailAccount(
            authUserId: UuidValue.fromString(userId),
            email: '$userId@example.invalid',
            passwordHash: 'unused',
          ),
        );
        final now = DateTime.now().toUtc();
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              session,
              name: 'Deleted during signing',
              ownerUserId: userId,
              now: now,
            );
        final store = _BlockingUploadStore();
        final objects = ObjectUseCases(
          store: store,
          scanner: const UnconfiguredObjectScanner(),
        );
        final request = BeginUploadRequest(
          workspaceId: workspace.id!,
          requestId: 'delete-during-sign-$userId',
          purpose: 'workspace_asset',
          displayName: 'pending.txt',
          mimeType: 'text/plain',
          sizeBytes: 4,
          checksumSha256: 'f' * 64,
        );
        final signing = objects.beginUpload(
          session,
          userId: userId,
          request: request,
        );
        final outcome = signing.then<Object>(
          (result) => result,
          onError: (Object error, StackTrace _) => error,
        );
        await store.started[0].future.timeout(const Duration(seconds: 5));
        final upload = (await ObjectUpload.db.findFirstRow(
          session,
          where: (row) => row.requestId.equals(request.requestId),
        ))!;
        final deleted = objects.delete(
          session,
          userId: userId,
          request: DeleteObjectRequest(
            workspaceId: workspace.id!,
            objectId: upload.objectId,
            requestId: 'delete-pending-$userId',
            expectedRevision: 1,
          ),
        );
        await deleted;

        store.release.complete();
        final result = await outcome;
        expect(
          result,
          isA<ObjectException>().having(
            (error) => error.code,
            'code',
            ObjectErrorCode.objectNotFound,
          ),
        );
        final resolvedUpload = await ObjectUpload.db.findFirstRow(
          session,
          where: (row) => row.requestId.equals(request.requestId),
        );
        expect(resolvedUpload?.signingReservationCount, 0);
        expect(store.deleteAttempts, 0);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    test(
      'retains late upload cleanup until gateway confirms quiescence',
      () async {
        final userId = const Uuid().v4().toString();
        final authenticated = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final session = authenticated.build();
        await AuthUser.db.insertRow(
          session,
          AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          session,
          EmailAccount(
            authUserId: UuidValue.fromString(userId),
            email: '$userId@example.invalid',
            passwordHash: 'unused',
          ),
        );
        final now = DateTime.now().toUtc();
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              session,
              name: 'Late upload erasure',
              ownerUserId: userId,
              now: now,
            );
        final object = await WorkspaceObject.db.insertRow(
          session,
          WorkspaceObject(
            workspaceId: workspace.id!,
            objectKey: 'private/late-upload',
            purpose: 'workspace_asset',
            displayName: 'late.txt',
            mimeType: 'text/plain',
            sizeBytes: 4,
            checksumSha256: 'b' * 64,
            status: 'pending',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final upload = await ObjectUpload.db.insertRow(
          session,
          ObjectUpload(
            workspaceId: workspace.id!,
            objectId: object.id!,
            actorUserId: userId,
            requestId: 'late-upload-$userId',
            requestHash: 'synthetic-late-upload-hash',
            expiresAt: now.add(const Duration(minutes: 10)),
            gatewayRegistrationId: _registrationId(object.id!),
            signingReservationCount: 0,
            createdAt: now,
          ),
        );
        final store = _RetryingObjectStore()
          ..failDeletes = false
          ..uploadQuiescenceConfirmed = false;
        store.objects[object.objectKey] = ObjectMetadata(
          sizeBytes: 4,
          mimeType: 'text/plain',
          checksumSha256: 'b' * 64,
        );

        final request = EraseCloudWorkspaceRequest(
          workspaceId: workspace.id!,
          confirmationName: workspace.name,
          requestId: 'erase-late-upload-$userId',
          expectedWorkspaceRevision: workspace.revision,
        );
        final initialStatus = await endpoints.cloudWorkspace.eraseWorkspace(
          authenticated,
          request,
        );
        expect(initialStatus.state, 'pending');
        final deletion = await ObjectDeletion.db.findFirstRow(
          session,
          where: (row) => row.objectId.equals(object.id!),
        );
        expect(deletion, isNotNull);

        final expiredAt = DateTime.now().toUtc().subtract(
          const Duration(seconds: 1),
        );
        await ObjectUpload.db.updateRow(
          session,
          upload.copyWith(expiresAt: expiredAt),
        );
        await ObjectDeletion.db.updateRow(
          session,
          deletion!.copyWith(availableAt: DateTime.now().toUtc()),
        );

        // Model an older cleanup deleting before an in-flight PUT finishes.
        store.objects.remove(object.objectKey);
        store.objects[object.objectKey] = ObjectMetadata(
          sizeBytes: 4,
          mimeType: 'text/plain',
          checksumSha256: 'b' * 64,
        );
        final lease = await const WorkerCoordinatorRepository()
            .acquireCoordinator(
              session,
              ownerId: 'late-upload-erasure-test-$userId',
            );
        expect(lease, isNotNull);
        final cleanup = ObjectCleanupService(store: store);

        await cleanup.runOnce(session, coordinator: lease!);

        final blockedStatus =
            (await endpoints.cloudWorkspace.listWorkspaceErasures(
              authenticated,
            )).single;
        expect(blockedStatus.state, 'needsAttention');
        expect(blockedStatus.failureReason, 'uploadQuiescenceUnverified');
        expect(store.deleteAttempts, 0);
        expect(store.objects, contains(object.objectKey));
        expect(
          await CloudWorkspace.db.findById(session, workspace.id!),
          isNotNull,
        );

        final retried = await endpoints.cloudWorkspace.retryWorkspaceErasure(
          authenticated,
          RetryCloudWorkspaceErasureRequest(requestId: request.requestId),
        );
        expect(retried.state, 'pending');
        store.uploadQuiescenceConfirmed = true;
        await cleanup.runOnce(session, coordinator: lease);

        expect(store.deleteAttempts, 1);
        expect(store.objects, isNot(contains(object.objectKey)));
        expect(
          await CloudWorkspace.db.findById(session, workspace.id!),
          isNull,
        );
        final complete = (await endpoints.cloudWorkspace.listWorkspaceErasures(
          authenticated,
        )).single;
        expect(complete.state, 'complete');
        expect(complete.failureReason, isNull);
        await cleanup.runOnce(session, coordinator: lease);
        expect(store.deleteAttempts, 1);
      },
    );

    test(
      'reopens legacy completion and keeps unproven upload blocked',
      () async {
        final userId = const Uuid().v4().toString();
        final authenticated = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final session = authenticated.build();
        await AuthUser.db.insertRow(
          session,
          AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          session,
          EmailAccount(
            authUserId: UuidValue.fromString(userId),
            email: '$userId@example.invalid',
            passwordHash: 'unused',
          ),
        );
        final now = DateTime.now().toUtc();
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              session,
              name: 'Legacy completion proof',
              ownerUserId: userId,
              now: now,
            );
        final object = await WorkspaceObject.db.insertRow(
          session,
          WorkspaceObject(
            workspaceId: workspace.id!,
            objectKey: 'private/legacy-completed-upload',
            purpose: 'workspace_asset',
            displayName: 'legacy.txt',
            mimeType: 'text/plain',
            sizeBytes: 4,
            checksumSha256: 'f' * 64,
            status: 'active',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final expiresAt = now.subtract(const Duration(minutes: 1));
        await ObjectUpload.db.insertRow(
          session,
          ObjectUpload(
            workspaceId: workspace.id!,
            objectId: object.id!,
            actorUserId: userId,
            requestId: 'legacy-upload-$userId',
            requestHash: 'synthetic-legacy-upload-hash',
            expiresAt: expiresAt,
            signingReservationCount: 0,
            createdAt: now,
          ),
        );
        final request = EraseCloudWorkspaceRequest(
          workspaceId: workspace.id!,
          confirmationName: workspace.name,
          requestId: 'erase-legacy-upload-$userId',
          expectedWorkspaceRevision: workspace.revision,
        );
        expect(
          (await endpoints.cloudWorkspace.eraseWorkspace(
            authenticated,
            request,
          )).state,
          'pending',
        );
        final queued = (await ObjectDeletion.db.findFirstRow(
          session,
          where: (row) => row.objectId.equals(object.id!),
        ))!;
        expect(queued.uploadCleanupVerifiedAt, isNull);

        // An older worker can set completedAt without upload-specific proof.
        await ObjectDeletion.db.updateRow(
          session,
          queued.copyWith(completedAt: DateTime.now().toUtc()),
        );
        final store = _RetryingObjectStore()
          ..failDeletes = false
          ..uploadQuiescenceConfirmed = true;
        store.objects[object.objectKey] = ObjectMetadata(
          sizeBytes: 4,
          mimeType: 'text/plain',
          checksumSha256: 'f' * 64,
        );
        final lease = (await const WorkerCoordinatorRepository()
            .acquireCoordinator(
              session,
              ownerId: 'legacy-proof-test-$userId',
            ))!;
        final erasureCleanup = WorkspaceErasureCleanup(session);

        expect(await erasureCleanup.purgeReady(lease), 0);
        final reopened = (await ObjectDeletion.db.findFirstRow(
          session,
          where: (row) => row.objectId.equals(object.id!),
        ))!;
        expect(reopened.completedAt, isNull);
        expect(
          reopened.cleanupGeneration,
          greaterThan(queued.cleanupGeneration),
        );
        expect(reopened.uploadCleanupVerifiedAt, isNull);
        expect(store.objects, contains(object.objectKey));
        expect(
          await CloudWorkspace.db.findById(session, workspace.id!),
          isNotNull,
        );

        final cleanup = ObjectCleanupService(
          store: store,
          purgeReadyWorkspaceErasures: (_, _) async => 0,
        );
        expect(await cleanup.runOnce(session, coordinator: lease), 0);
        final blocked = (await ObjectDeletion.db.findFirstRow(
          session,
          where: (row) => row.objectId.equals(object.id!),
        ))!;
        expect(blocked.completedAt, isNull);
        expect(blocked.lastError, 'legacyUploadUnverifiable');
        expect(blocked.uploadCleanupVerifiedAt, isNull);
        expect(store.quiescenceCalls, 0);
        expect(store.deleteAttempts, 0);
        expect(store.objects, contains(object.objectKey));
        expect(await erasureCleanup.purgeReady(lease), 0);
        expect(
          await CloudWorkspace.db.findById(session, workspace.id!),
          isNotNull,
        );
      },
    );

    test(
      'stale delete completion cannot overtake erasure rescheduling',
      () async {
        final userId = const Uuid().v4().toString();
        final authenticated = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final session = authenticated.build();
        await AuthUser.db.insertRow(
          session,
          AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          session,
          EmailAccount(
            authUserId: UuidValue.fromString(userId),
            email: '$userId@example.invalid',
            passwordHash: 'unused',
          ),
        );
        final now = DateTime.now().toUtc();
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              session,
              name: 'Rescheduled upload deletion',
              ownerUserId: userId,
              now: now,
            );
        final object = await WorkspaceObject.db.insertRow(
          session,
          WorkspaceObject(
            workspaceId: workspace.id!,
            objectKey: 'private/rescheduled-upload',
            purpose: 'workspace_asset',
            displayName: 'rescheduled.txt',
            mimeType: 'text/plain',
            sizeBytes: 4,
            checksumSha256: 'e' * 64,
            status: 'active',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final expiresAt = now.subtract(const Duration(minutes: 1));
        await ObjectUpload.db.insertRow(
          session,
          ObjectUpload(
            workspaceId: workspace.id!,
            objectId: object.id!,
            actorUserId: userId,
            requestId: 'rescheduled-upload-$userId',
            requestHash: 'synthetic-rescheduled-upload-hash',
            expiresAt: expiresAt,
            gatewayRegistrationId: _registrationId(object.id!),
            signingReservationCount: 0,
            createdAt: now,
          ),
        );
        final request = EraseCloudWorkspaceRequest(
          workspaceId: workspace.id!,
          confirmationName: workspace.name,
          requestId: 'erase-rescheduled-upload-$userId',
          expectedWorkspaceRevision: workspace.revision,
        );
        await endpoints.cloudWorkspace.eraseWorkspace(authenticated, request);
        final erasureRequest = (await WorkspaceErasureRequest.db.findFirstRow(
          session,
          where: (row) => row.requestId.equals(request.requestId),
        ))!;
        await WorkspaceErasureRequest.db.updateRow(
          session,
          erasureRequest.copyWith(
            state: 'needsAttention',
            failureReason: 'objectCleanupFailed',
          ),
        );

        final store = _BlockingDeleteObjectStore()
          ..failDeletes = false
          ..uploadQuiescenceConfirmed = true;
        store.objects[object.objectKey] = ObjectMetadata(
          sizeBytes: 4,
          mimeType: 'text/plain',
          checksumSha256: 'e' * 64,
        );
        final lease = (await const WorkerCoordinatorRepository()
            .acquireCoordinator(
              session,
              ownerId: 'rescheduled-delete-test-$userId',
            ))!;
        final cleanup = ObjectCleanupService(
          store: store,
          purgeReadyWorkspaceErasures: (_, _) async => 0,
        );
        final staleCleanup = cleanup.runOnce(session, coordinator: lease);
        try {
          await store.deleteStarted.future.timeout(const Duration(seconds: 5));
          final beforeRetry = (await ObjectDeletion.db.findFirstRow(
            session,
            where: (row) => row.objectId.equals(object.id!),
          ))!;
          final retry = await endpoints.cloudWorkspace.retryWorkspaceErasure(
            authenticated,
            RetryCloudWorkspaceErasureRequest(requestId: request.requestId),
          );
          expect(retry.state, 'pending');
          final rescheduled = (await ObjectDeletion.db.findFirstRow(
            session,
            where: (row) => row.objectId.equals(object.id!),
          ))!;
          expect(
            rescheduled.cleanupGeneration,
            greaterThan(beforeRetry.cleanupGeneration),
          );

          store.releaseDelete.complete();
          expect(await staleCleanup, 0);
          final staleCompletion = (await ObjectDeletion.db.findFirstRow(
            session,
            where: (row) => row.objectId.equals(object.id!),
          ))!;
          expect(staleCompletion.completedAt, isNull);
          expect(staleCompletion.uploadCleanupVerifiedAt, isNull);
          expect(store.deleteAttempts, 1);
          expect(
            await CloudWorkspace.db.findById(session, workspace.id!),
            isNotNull,
          );
        } finally {
          if (!store.releaseDelete.isCompleted) {
            store.releaseDelete.complete();
          }
          await staleCleanup;
        }

        expect(await cleanup.runOnce(session, coordinator: lease), 1);
        final verified = (await ObjectDeletion.db.findFirstRow(
          session,
          where: (row) => row.objectId.equals(object.id!),
        ))!;
        final upload = (await ObjectUpload.db.findFirstRow(
          session,
          where: (row) => row.objectId.equals(object.id!),
        ))!;
        expect(verified.uploadCleanupVerifiedAt, isNotNull);
        expect(
          verified.uploadCleanupVerifiedGeneration,
          verified.cleanupGeneration,
        );
        expect(verified.uploadCleanupVerifiedExpiresAt, upload.expiresAt);
        expect(store.deleteAttempts, 2);
        expect(
          await WorkspaceErasureCleanup(session).purgeReady(lease),
          1,
        );
        expect(
          await CloudWorkspace.db.findById(session, workspace.id!),
          isNull,
        );
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'workspace erasure fences an in-flight ordinary object deletion',
      () async {
        final userId = const Uuid().v4().toString();
        final authenticated = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final session = authenticated.build();
        await AuthUser.db.insertRow(
          session,
          AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          session,
          EmailAccount(
            authUserId: UuidValue.fromString(userId),
            email: '$userId@example.invalid',
            passwordHash: 'unused',
          ),
        );
        final now = DateTime.now().toUtc();
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              session,
              name: 'Erasure reschedules ordinary delete',
              ownerUserId: userId,
              now: now,
            );
        final object = await WorkspaceObject.db.insertRow(
          session,
          WorkspaceObject(
            workspaceId: workspace.id!,
            objectKey: 'private/ordinary-delete-race',
            purpose: 'workspace_asset',
            displayName: 'ordinary-delete.txt',
            mimeType: 'text/plain',
            sizeBytes: 4,
            checksumSha256: 'a' * 64,
            status: 'active',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await ObjectUpload.db.insertRow(
          session,
          ObjectUpload(
            workspaceId: workspace.id!,
            objectId: object.id!,
            actorUserId: userId,
            requestId: 'ordinary-upload-$userId',
            requestHash: 'synthetic-ordinary-upload-hash',
            expiresAt: now.subtract(const Duration(minutes: 1)),
            gatewayRegistrationId: _registrationId(object.id!),
            signingReservationCount: 0,
            createdAt: now,
          ),
        );
        final store = _BlockingDeleteObjectStore()
          ..failDeletes = false
          ..uploadQuiescenceConfirmed = true;
        store.objects[object.objectKey] = ObjectMetadata(
          sizeBytes: 4,
          mimeType: 'text/plain',
          checksumSha256: 'a' * 64,
        );
        final objects = ObjectUseCases(
          store: store,
          scanner: const UnconfiguredObjectScanner(),
        );
        await objects.delete(
          session,
          userId: userId,
          request: DeleteObjectRequest(
            workspaceId: workspace.id!,
            objectId: object.id!,
            requestId: 'ordinary-delete-$userId',
            expectedRevision: 1,
          ),
        );
        final ordinaryDeletion = (await ObjectDeletion.db.findFirstRow(
          session,
          where: (row) => row.objectId.equals(object.id!),
        ))!;
        await ObjectDeletion.db.updateRow(
          session,
          ordinaryDeletion.copyWith(
            availableAt: DateTime.now().toUtc().subtract(
              const Duration(minutes: 1),
            ),
          ),
        );
        final lease = (await const WorkerCoordinatorRepository()
            .acquireCoordinator(
              session,
              ownerId: 'ordinary-delete-erasure-race-$userId',
            ))!;
        final cleanup = ObjectCleanupService(
          store: store,
          purgeReadyWorkspaceErasures: (_, _) async => 0,
        );
        final staleCleanup = cleanup.runOnce(session, coordinator: lease);
        try {
          await store.deleteStarted.future.timeout(const Duration(seconds: 5));
          final inFlight = (await ObjectDeletion.db.findFirstRow(
            session,
            where: (row) => row.objectId.equals(object.id!),
          ))!;
          final workspaceAfterDelete = (await CloudWorkspace.db.findById(
            session,
            workspace.id!,
          ))!;
          final eraseRequest = EraseCloudWorkspaceRequest(
            workspaceId: workspace.id!,
            confirmationName: workspace.name,
            requestId: 'erase-in-flight-ordinary-delete-$userId',
            expectedWorkspaceRevision: workspaceAfterDelete.revision,
          );
          expect(
            (await endpoints.cloudWorkspace.eraseWorkspace(
              authenticated,
              eraseRequest,
            )).state,
            'pending',
          );
          final rescheduled = (await ObjectDeletion.db.findFirstRow(
            session,
            where: (row) => row.objectId.equals(object.id!),
          ))!;
          expect(
            rescheduled.cleanupGeneration,
            greaterThan(inFlight.cleanupGeneration),
          );

          store.releaseDelete.complete();
          expect(await staleCleanup, 0);
          final rejectedCompletion = (await ObjectDeletion.db.findFirstRow(
            session,
            where: (row) => row.objectId.equals(object.id!),
          ))!;
          expect(rejectedCompletion.completedAt, isNull);
          expect(rejectedCompletion.uploadCleanupVerifiedAt, isNull);
          expect(store.deleteAttempts, 1);
          expect(
            await CloudWorkspace.db.findById(session, workspace.id!),
            isNotNull,
          );
        } finally {
          if (!store.releaseDelete.isCompleted) {
            store.releaseDelete.complete();
          }
          await staleCleanup;
        }

        expect(await cleanup.runOnce(session, coordinator: lease), 1);
        final verified = (await ObjectDeletion.db.findFirstRow(
          session,
          where: (row) => row.objectId.equals(object.id!),
        ))!;
        final upload = (await ObjectUpload.db.findFirstRow(
          session,
          where: (row) => row.objectId.equals(object.id!),
        ))!;
        expect(verified.uploadCleanupVerifiedAt, isNotNull);
        expect(
          verified.uploadCleanupVerifiedGeneration,
          verified.cleanupGeneration,
        );
        expect(verified.uploadCleanupVerifiedExpiresAt, upload.expiresAt);
        expect(store.deleteAttempts, 2);
        expect(
          await WorkspaceErasureCleanup(session).purgeReady(lease),
          1,
        );
        expect(
          await CloudWorkspace.db.findById(session, workspace.id!),
          isNull,
        );
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'keeps idempotent signing reservations until signer resolves',
      () async {
        final userId = const Uuid().v4().toString();
        final authenticated = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final session = authenticated.build();
        await AuthUser.db.insertRow(
          session,
          AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          session,
          EmailAccount(
            authUserId: UuidValue.fromString(userId),
            email: '$userId@example.invalid',
            passwordHash: 'unused',
          ),
        );
        final now = DateTime.now().toUtc();
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              session,
              name: 'Signing reservation erasure',
              ownerUserId: userId,
              now: now,
            );
        final store = _BlockingUploadStore();
        final objects = ObjectUseCases(
          store: store,
          scanner: const UnconfiguredObjectScanner(),
        );
        final request = BeginUploadRequest(
          workspaceId: workspace.id!,
          requestId: 'idempotent-upload-$userId',
          purpose: 'workspace_asset',
          displayName: 'reserved.txt',
          mimeType: 'text/plain',
          sizeBytes: 4,
          checksumSha256: 'c' * 64,
        );
        final first = objects.beginUpload(
          session,
          userId: userId,
          request: request,
        );
        final firstOutcome = first.then<Object>(
          (result) => result,
          onError: (Object error, StackTrace _) => error,
        );
        await store.started[0].future.timeout(const Duration(seconds: 5));
        final second = objects.beginUpload(
          session,
          userId: userId,
          request: request,
        );
        final secondOutcome = second.then<Object>(
          (result) => result,
          onError: (Object error, StackTrace _) => error,
        );
        await store.started[1].future.timeout(const Duration(seconds: 5));
        final upload = (await ObjectUpload.db.findFirstRow(
          session,
          where: (row) => row.requestId.equals(request.requestId),
        ))!;
        expect(upload.signingReservationCount, 2);

        final erasure = EraseCloudWorkspaceRequest(
          workspaceId: workspace.id!,
          confirmationName: workspace.name,
          requestId: 'erase-signing-$userId',
          expectedWorkspaceRevision: workspace.revision,
        );
        final status = await endpoints.cloudWorkspace.eraseWorkspace(
          authenticated,
          erasure,
        );
        expect(status.state, 'pending');
        final queued = await ObjectDeletion.db.findFirstRow(
          session,
          where: (row) => row.objectId.equals(upload.objectId),
        );
        expect(queued, isNotNull);
        // Quiescence, not URL expiry, determines when a registered key can be
        // deleted. The cleanup job is available immediately.
        expect(queued!.availableAt.isBefore(upload.expiresAt), isTrue);

        final expiredAt = DateTime.now().toUtc().subtract(
          const Duration(seconds: 1),
        );
        await ObjectUpload.db.updateRow(
          session,
          upload.copyWith(expiresAt: expiredAt),
        );
        await ObjectDeletion.db.updateRow(
          session,
          queued.copyWith(availableAt: DateTime.now().toUtc()),
        );
        final lease = await const WorkerCoordinatorRepository()
            .acquireCoordinator(
              session,
              ownerId: 'signing-reservation-test-$userId',
            );
        expect(lease, isNotNull);
        final cleanup = ObjectCleanupService(store: store);
        await cleanup.runOnce(session, coordinator: lease!);

        final blocked = (await endpoints.cloudWorkspace.listWorkspaceErasures(
          authenticated,
        )).single;
        expect(blocked.state, 'needsAttention');
        expect(blocked.failureReason, 'uploadQuiescenceUnverified');
        final retryableDeletion = (await ObjectDeletion.db.findFirstRow(
          session,
          where: (row) => row.objectId.equals(upload.objectId),
        ))!;
        final retryableUpload = (await ObjectUpload.db.findFirstRow(
          session,
          where: (row) => row.objectId.equals(upload.objectId),
        ))!;
        expect(retryableDeletion.attempts, 0);
        expect(
          retryableUpload.gatewayRegistrationId,
          upload.gatewayRegistrationId,
        );
        expect(store.deleteAttempts, 0);
        expect(
          await CloudWorkspace.db.findById(session, workspace.id!),
          isNotNull,
        );

        store.release.complete();
        final outcomes = await Future.wait([firstOutcome, secondOutcome]);
        for (final outcome in outcomes) {
          expect(
            outcome,
            isA<CloudWorkspaceException>().having(
              (error) => error.code,
              'code',
              CloudWorkspaceErrorCode.membershipRequired,
            ),
          );
        }
        final resolved = await ObjectUpload.db.findFirstRow(
          session,
          where: (row) => row.requestId.equals(request.requestId),
        );
        expect(resolved?.signingReservationCount, 0);
        expect(resolved!.expiresAt.isAfter(expiredAt), isTrue);
        expect(store.deleteAttempts, 0);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'keeps legacy signer rows blocked despite gateway attestation',
      () async {
        final userId = const Uuid().v4().toString();
        final authenticated = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final session = authenticated.build();
        await AuthUser.db.insertRow(
          session,
          AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          session,
          EmailAccount(
            authUserId: UuidValue.fromString(userId),
            email: '$userId@example.invalid',
            passwordHash: 'unused',
          ),
        );
        final now = DateTime.now().toUtc();
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              session,
              name: 'Unresolved signing erasure',
              ownerUserId: userId,
              now: now,
            );
        for (final (index, reservations) in [null, 1].indexed) {
          final object = await WorkspaceObject.db.insertRow(
            session,
            WorkspaceObject(
              workspaceId: workspace.id!,
              objectKey: 'private/unresolved-$index',
              purpose: 'workspace_asset',
              displayName: 'unresolved-$index.txt',
              mimeType: 'text/plain',
              sizeBytes: 4,
              checksumSha256: 'e' * 64,
              status: 'active',
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
          );
          await ObjectUpload.db.insertRow(
            session,
            ObjectUpload(
              workspaceId: workspace.id!,
              objectId: object.id!,
              actorUserId: userId,
              requestId: 'unresolved-$index-$userId',
              requestHash: 'synthetic-unresolved-hash-$index',
              expiresAt: now.subtract(const Duration(minutes: 1)),
              signingReservationCount: reservations,
              createdAt: now,
            ),
          );
        }
        final request = EraseCloudWorkspaceRequest(
          workspaceId: workspace.id!,
          confirmationName: workspace.name,
          requestId: 'erase-unresolved-$userId',
          expectedWorkspaceRevision: workspace.revision,
        );
        final initial = await endpoints.cloudWorkspace.eraseWorkspace(
          authenticated,
          request,
        );
        expect(initial.state, 'pending');
        final lease = await const WorkerCoordinatorRepository()
            .acquireCoordinator(
              session,
              ownerId: 'unresolved-signing-test-$userId',
            );
        expect(lease, isNotNull);
        final store = _RetryingObjectStore()
          ..failDeletes = false
          ..uploadQuiescenceConfirmed = true;
        final cleanup = ObjectCleanupService(store: store);

        await cleanup.runOnce(session, coordinator: lease!);

        final pending = (await endpoints.cloudWorkspace.listWorkspaceErasures(
          authenticated,
        )).single;
        expect(pending.state, 'needsAttention');
        expect(pending.failureReason, 'legacyUploadUnverifiable');
        for (var index = 0; index < 2; index++) {
          final key = 'private/unresolved-$index';
          expect(store.quiescenceKeys, isNot(contains(key)));
          expect(store.deleteKeys, isNot(contains(key)));
        }
        expect(
          await ObjectDeletion.db.find(
            session,
            where: (row) =>
                row.workspaceId.equals(workspace.id!) &
                row.lastError.equals('legacyUploadUnverifiable'),
          ),
          hasLength(2),
        );
        expect(
          await CloudWorkspace.db.findById(session, workspace.id!),
          isNotNull,
        );

        await endpoints.cloudWorkspace.retryWorkspaceErasure(
          authenticated,
          RetryCloudWorkspaceErasureRequest(requestId: request.requestId),
        );
        await cleanup.runOnce(session, coordinator: lease);

        final stillBlocked =
            (await endpoints.cloudWorkspace.listWorkspaceErasures(
              authenticated,
            )).single;
        expect(stillBlocked.state, 'needsAttention');
        expect(stillBlocked.failureReason, 'legacyUploadUnverifiable');
        expect(store.quiescenceCalls, 0);
        expect(store.deleteAttempts, 0);
        expect(
          await CloudWorkspace.db.findById(session, workspace.id!),
          isNotNull,
        );
      },
    );

    test(
      'provider replica blocker persists across retry and outranks pending cleanup',
      () async {
        final userId = const Uuid().v4().toString();
        final authenticated = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final session = authenticated.build();
        await AuthUser.db.insertRow(
          session,
          AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          session,
          EmailAccount(
            authUserId: UuidValue.fromString(userId),
            email: '$userId@example.invalid',
            passwordHash: 'unused',
          ),
        );
        final now = DateTime.now().toUtc();
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              session,
              name: 'Provider deletion blocker',
              ownerUserId: userId,
              now: now,
            );
        final blockedObject = await _insertRegisteredUpload(
          session,
          workspaceId: workspace.id!,
          userId: userId,
          objectKey: 'private/provider-blocked-$userId',
          requestId: 'provider-blocked-$userId',
          now: now,
        );
        final pendingObject = await _insertRegisteredUpload(
          session,
          workspaceId: workspace.id!,
          userId: userId,
          objectKey: 'private/quiescence-pending-$userId',
          requestId: 'quiescence-pending-$userId',
          now: now,
        );
        final request = EraseCloudWorkspaceRequest(
          workspaceId: workspace.id!,
          confirmationName: workspace.name,
          requestId: 'erase-provider-blocker-$userId',
          expectedWorkspaceRevision: workspace.revision,
        );
        final initial = await endpoints.cloudWorkspace.eraseWorkspace(
          authenticated,
          request,
        );
        expect(initial.state, 'pending');
        final pendingDeletion = await ObjectDeletion.db.findFirstRow(
          session,
          where: (row) => row.objectId.equals(pendingObject.id!),
        );
        await ObjectDeletion.db.updateRow(
          session,
          pendingDeletion!.copyWith(
            lastError: 'uploadQuiescenceUnverified',
            availableAt: now.add(const Duration(days: 1)),
          ),
        );
        final lease = await const WorkerCoordinatorRepository()
            .acquireCoordinator(
              session,
              ownerId: 'provider-blocker-test-$userId',
            );
        expect(lease, isNotNull);
        final store = _ProviderBlockedObjectStore(
          blockedKeys: {blockedObject.objectKey},
        );

        await ObjectCleanupService(store: store).runOnce(
          session,
          coordinator: lease!,
        );

        final blockedRows = await ObjectDeletion.db.find(
          session,
          where: (row) => row.workspaceId.equals(workspace.id!),
        );
        final providerDeletion = blockedRows.singleWhere(
          (row) => row.objectId == blockedObject.id,
        );
        final retryableDeletion = blockedRows.singleWhere(
          (row) => row.objectId == pendingObject.id,
        );
        expect(providerDeletion.lastError, 'providerDeletionUnverified');
        expect(providerDeletion.attempts, 0);
        expect(retryableDeletion.lastError, 'uploadQuiescenceUnverified');
        expect(store.deleteAttempts, 1);

        final status = (await endpoints.cloudWorkspace.listWorkspaceErasures(
          authenticated,
        )).single;
        expect(status.state, 'needsAttention');
        expect(status.failureReason, 'providerDeletionUnverified');
        final retry = await endpoints.cloudWorkspace.retryWorkspaceErasure(
          authenticated,
          RetryCloudWorkspaceErasureRequest(requestId: request.requestId),
        );
        expect(retry.state, 'needsAttention');
        expect(retry.failureReason, 'providerDeletionUnverified');
        await ObjectCleanupService(store: store).runOnce(
          session,
          coordinator: lease,
        );
        expect(store.deleteAttempts, 1);
        final afterRetry = await ObjectDeletion.db.findById(
          session,
          retryableDeletion.id!,
        );
        expect(afterRetry?.lastError, 'uploadQuiescenceUnverified');
        expect(afterRetry?.availableAt, now.add(const Duration(days: 1)));
        expect(
          await CloudWorkspace.db.findById(session, workspace.id!),
          isNotNull,
        );
      },
    );

    test(
      'keeps a tombstone until retries erase assets and workspace data',
      () async {
        final userId = const Uuid().v4().toString();
        final authenticated = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final session = authenticated.build();
        await AuthUser.db.insertRow(
          session,
          AuthUser(id: UuidValue.fromString(userId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          session,
          EmailAccount(
            authUserId: UuidValue.fromString(userId),
            email: '$userId@example.invalid',
            passwordHash: 'unused',
          ),
        );
        final now = DateTime.now().toUtc();
        final workspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              session,
              name: 'Erase me',
              ownerUserId: userId,
              now: now,
            );
        final legacyWorkspace = await workspace_repo.CloudWorkspaceRepository()
            .createWorkspace(
              session,
              name: 'Legacy deleted workspace',
              ownerUserId: userId,
              now: now,
            );
        final oauthTransactionId = 'oauth-target-$userId';
        final retainedOauthTransactionId = 'oauth-retained-$userId';
        final samplingConnectionId = 'sampling-target-$userId';
        final retainedSamplingConnectionId = 'sampling-retained-$userId';
        await _insertOAuthTransaction(
          session,
          workspaceId: workspace.id!,
          userId: userId,
          transactionId: oauthTransactionId,
          now: now,
        );
        await _insertOAuthTransaction(
          session,
          workspaceId: legacyWorkspace.id!,
          userId: userId,
          transactionId: retainedOauthTransactionId,
          now: now,
        );
        await _insertToolSamplingPolicy(
          session,
          workspaceId: workspace.id!,
          connectionId: samplingConnectionId,
        );
        await _insertToolSamplingPolicy(
          session,
          workspaceId: legacyWorkspace.id!,
          connectionId: retainedSamplingConnectionId,
        );
        await session.db.transaction((transaction) async {
          await workspace_repo.CloudWorkspaceRepository().softDeleteWorkspace(
            session,
            workspace: legacyWorkspace,
            now: now,
            transaction: transaction,
          );
        });
        final object = await WorkspaceObject.db.insertRow(
          session,
          WorkspaceObject(
            workspaceId: workspace.id!,
            objectKey: 'private/erase-me',
            purpose: 'workspace_asset',
            displayName: 'private.txt',
            mimeType: 'text/plain',
            sizeBytes: 4,
            checksumSha256: 'a' * 64,
            status: 'active',
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await ObjectUpload.db.insertRow(
          session,
          ObjectUpload(
            workspaceId: workspace.id!,
            objectId: object.id!,
            actorUserId: userId,
            requestId: 'erase-object-upload-$userId',
            requestHash: 'synthetic-erase-object-upload-hash',
            expiresAt: now.subtract(const Duration(minutes: 1)),
            gatewayRegistrationId: _registrationId(object.id!),
            signingReservationCount: 0,
            createdAt: now,
          ),
        );
        await WorkspaceResource.db.insertRow(
          session,
          WorkspaceResource(
            workspaceId: workspace.id!,
            resourceKind: WorkspaceResourceKind.file,
            resourceId: 'file-1',
            data: jsonEncode({
              'assetId': '${object.id}',
              'name': 'private.txt',
            }),
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );

        final request = EraseCloudWorkspaceRequest(
          workspaceId: workspace.id!,
          confirmationName: workspace.name,
          requestId: const Uuid().v4().toString(),
          expectedWorkspaceRevision: workspace.revision,
        );
        final initialStatus = await endpoints.cloudWorkspace.eraseWorkspace(
          authenticated,
          request,
        );
        expect(initialStatus.state, 'pending');
        final legacyCandidates = await endpoints.cloudWorkspace
            .listOwnedDeletedWorkspacesForErasure(authenticated);
        expect(legacyCandidates, hasLength(1));
        expect(legacyCandidates.single.id, legacyWorkspace.id);

        final tombstone = await CloudWorkspace.db.findById(
          session,
          workspace.id!,
        );
        expect(tombstone?.deletedAt, isNotNull);
        expect(tombstone?.erasureRequestedAt, isNotNull);
        expect(
          await WorkspaceResource.db.find(
            session,
            where: (row) => row.workspaceId.equals(workspace.id!),
          ),
          hasLength(1),
        );
        expect(
          await WorkspaceSecret.db.find(
            session,
            where: (row) => row.workspaceId.equals(workspace.id!),
          ),
          isEmpty,
        );
        final deletion = await ObjectDeletion.db.findFirstRow(
          session,
          where: (row) => row.objectId.equals(object.id!),
        );
        expect(deletion?.objectKey, 'private/erase-me');

        final store = _RetryingObjectStore()
          ..objects['private/erase-me'] = ObjectMetadata(
            sizeBytes: 4,
            mimeType: 'text/plain',
            checksumSha256: 'a' * 64,
          );
        final lease = await const WorkerCoordinatorRepository()
            .acquireCoordinator(session, ownerId: 'erasure-test-$userId');
        expect(lease, isNotNull);
        final cleanup = ObjectCleanupService(store: store);

        await expectLater(
          endpoints.account.deleteCurrentUser(authenticated),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (error) => error.code,
              'code',
              CloudWorkspaceErrorCode.workspaceErasurePending,
            ),
          ),
        );

        final otherUserId = const Uuid().v4().toString();
        final otherAccount = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            otherUserId,
            const {},
          ),
        );
        final otherSession = otherAccount.build();
        await AuthUser.db.insertRow(
          otherSession,
          AuthUser(id: UuidValue.fromString(otherUserId), scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          otherSession,
          EmailAccount(
            authUserId: UuidValue.fromString(otherUserId),
            email: '$otherUserId@example.invalid',
            passwordHash: 'unused',
          ),
        );
        expect(
          await endpoints.cloudWorkspace.listWorkspaceErasures(otherAccount),
          isEmpty,
        );
        expect(
          await endpoints.cloudWorkspace.listOwnedDeletedWorkspacesForErasure(
            otherAccount,
          ),
          isEmpty,
        );
        await expectLater(
          endpoints.cloudWorkspace.retryWorkspaceErasure(
            otherAccount,
            RetryCloudWorkspaceErasureRequest(requestId: request.requestId),
          ),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (error) => error.code,
              'code',
              CloudWorkspaceErrorCode.workspaceNotFound,
            ),
          ),
        );

        for (var attempt = 0; attempt < 8; attempt++) {
          await cleanup.runOnce(session, coordinator: lease!);
          final failedDeletion = await ObjectDeletion.db.findFirstRow(
            session,
            where: (row) => row.objectId.equals(object.id!),
          );
          expect(failedDeletion?.attempts, attempt + 1);
          await ObjectDeletion.db.updateRow(
            session,
            failedDeletion!.copyWith(availableAt: DateTime.now().toUtc()),
          );
        }
        final attention = await endpoints.cloudWorkspace.listWorkspaceErasures(
          authenticated,
        );
        expect(attention.single.state, 'needsAttention');
        final replay = await endpoints.cloudWorkspace.eraseWorkspace(
          authenticated,
          request,
        );
        expect(replay.requestId, attention.single.requestId);
        expect(replay.workspaceId, attention.single.workspaceId);
        expect(replay.state, attention.single.state);
        expect(
          await CloudWorkspace.db.findById(session, workspace.id!),
          isNotNull,
        );
        expect(
          await WorkspaceResource.db.find(
            session,
            where: (row) => row.workspaceId.equals(workspace.id!),
          ),
          hasLength(1),
        );

        final retried = await endpoints.cloudWorkspace.retryWorkspaceErasure(
          authenticated,
          RetryCloudWorkspaceErasureRequest(requestId: request.requestId),
        );
        expect(retried.state, 'pending');
        store.failDeletes = false;
        await cleanup.runOnce(session, coordinator: lease!);

        expect(store.deleteAttempts, 9);
        expect(
          await CloudWorkspace.db.findById(session, workspace.id!),
          isNull,
        );
        expect(
          await WorkspaceResource.db.find(
            session,
            where: (row) => row.workspaceId.equals(workspace.id!),
          ),
          isEmpty,
        );
        expect(await WorkspaceObject.db.findById(session, object.id!), isNull);
        expect(
          await WorkspaceModelSelectionToolSamplingPolicy.db.find(
            session,
            where: (row) => row.workspaceId.equals(workspace.id!),
          ),
          isEmpty,
        );
        final retainedSamplingPolicy =
            await WorkspaceModelSelectionToolSamplingPolicy.db.find(
              session,
              where: (row) =>
                  row.workspaceId.equals(legacyWorkspace.id!) &
                  row.connectionId.equals(retainedSamplingConnectionId),
            );
        expect(retainedSamplingPolicy, hasLength(1));
        expect(retainedSamplingPolicy.single.modelId, 'model-synthetic');
        expect(
          retainedSamplingPolicy.single.toolSamplingPolicy,
          '{"mode":"synthetic"}',
        );
        expect(
          await CodexOAuthTransaction.db.find(
            session,
            where: (row) => row.transactionId.equals(oauthTransactionId),
          ),
          isEmpty,
        );
        final retainedOauthTransaction = await CodexOAuthTransaction.db.find(
          session,
          where: (row) => row.transactionId.equals(retainedOauthTransactionId),
        );
        expect(retainedOauthTransaction, hasLength(1));
        expect(
          retainedOauthTransaction.single.verifierCiphertext.lengthInBytes,
          24,
        );
        expect(retainedOauthTransaction.single.verifierNonce.lengthInBytes, 12);
        expect(
          retainedOauthTransaction
              .single
              .verifierAuthenticationTag
              .lengthInBytes,
          16,
        );
        final complete = await endpoints.cloudWorkspace.listWorkspaceErasures(
          authenticated,
        );
        expect(complete.single.state, 'complete');
        expect(complete.single.completedAt, isNotNull);
        await expectLater(
          endpoints.account.deleteCurrentUser(authenticated),
          throwsA(
            isA<CloudWorkspaceException>().having(
              (error) => error.code,
              'code',
              CloudWorkspaceErrorCode.ownershipTransferRequired,
            ),
          ),
        );
        final remainingOwned = await endpoints.cloudWorkspace
            .listOwnedDeletedWorkspacesForErasure(authenticated);
        expect(remainingOwned.single.id, legacyWorkspace.id);

        final legacyRequest = EraseCloudWorkspaceRequest(
          workspaceId: legacyWorkspace.id!,
          confirmationName: legacyWorkspace.name,
          requestId: const Uuid().v4().toString(),
          expectedWorkspaceRevision: legacyWorkspace.revision + 1,
        );
        final legacyComplete = await endpoints.cloudWorkspace.eraseWorkspace(
          authenticated,
          legacyRequest,
        );
        expect(legacyComplete.state, 'complete');
        expect(
          await CloudWorkspace.db.findById(session, legacyWorkspace.id!),
          isNull,
        );
        expect(
          await CodexOAuthTransaction.db.find(
            session,
            where: (row) =>
                row.transactionId.equals(retainedOauthTransactionId),
          ),
          isEmpty,
        );
        expect(
          await WorkspaceModelSelectionToolSamplingPolicy.db.find(
            session,
            where: (row) => row.workspaceId.equals(legacyWorkspace.id!),
          ),
          isEmpty,
        );

        initializeTestAuthServices(session.serverpod);
        await endpoints.account.deleteCurrentUser(authenticated);
        expect(
          await WorkspaceErasureRequest.db.find(
            session,
            where: (row) => row.ownerUserId.equals(userId),
          ),
          isEmpty,
        );
      },
    );
  }, rollbackDatabase: RollbackDatabase.disabled);
}

Future<void> _clearCoordinator(Session session) =>
    WorkerCoordinatorLease.db.deleteWhere(
      session,
      where: (row) => row.key.equals('global'),
    );

String _registrationId(int objectId) =>
    objectId.toRadixString(16).padLeft(64, '0');

Future<void> _insertOAuthTransaction(
  Session session, {
  required int workspaceId,
  required String userId,
  required String transactionId,
  required DateTime now,
}) async {
  final _ = await CodexOAuthTransaction.db.insertRow(
    session,
    CodexOAuthTransaction(
      transactionId: transactionId,
      workspaceId: workspaceId,
      connectionId: 'connection-$transactionId',
      userId: userId,
      stateHash: 'synthetic-state-hash',
      verifierCiphertext: _syntheticBytes(24),
      verifierNonce: _syntheticBytes(12),
      verifierAuthenticationTag: _syntheticBytes(16),
      redirectUri: 'http://localhost/callback',
      expiresAt: now.add(const Duration(minutes: 10)),
      createdAt: now,
    ),
  );
}

Future<WorkspaceObject> _insertRegisteredUpload(
  Session session, {
  required int workspaceId,
  required String userId,
  required String objectKey,
  required String requestId,
  required DateTime now,
}) async {
  final object = await WorkspaceObject.db.insertRow(
    session,
    WorkspaceObject(
      workspaceId: workspaceId,
      objectKey: objectKey,
      purpose: 'workspace_asset',
      displayName: '$requestId.txt',
      mimeType: 'text/plain',
      sizeBytes: 4,
      checksumSha256: 'a' * 64,
      status: 'active',
      revision: 1,
      createdAt: now,
      updatedAt: now,
    ),
  );
  await ObjectUpload.db.insertRow(
    session,
    ObjectUpload(
      workspaceId: workspaceId,
      objectId: object.id!,
      actorUserId: userId,
      requestId: requestId,
      requestHash: 'synthetic-$requestId',
      expiresAt: now.subtract(const Duration(minutes: 1)),
      gatewayRegistrationId: _registrationId(object.id!),
      gatewayRegistrationState: 'registered',
      signingReservationCount: 0,
      createdAt: now,
    ),
  );
  return object;
}

ByteData _syntheticBytes(int length) => ByteData(length)..setUint8(0, 1);

Future<void> _insertToolSamplingPolicy(
  Session session, {
  required int workspaceId,
  required String connectionId,
}) async {
  final _ = await WorkspaceModelSelectionToolSamplingPolicy.db.insertRow(
    session,
    WorkspaceModelSelectionToolSamplingPolicy(
      workspaceId: workspaceId,
      connectionId: connectionId,
      modelId: 'model-synthetic',
      toolSamplingPolicy: '{"mode":"synthetic"}',
    ),
  );
}

class _RetryingObjectStore extends InMemoryObjectStore {
  bool failDeletes = true;
  bool uploadQuiescenceConfirmed = true;
  int deleteAttempts = 0;
  int quiescenceCalls = 0;
  final deleteKeys = <String>[];
  final quiescenceKeys = <String>[];

  @override
  Future<void> delete(String key, {String? registrationId}) async {
    deleteAttempts++;
    deleteKeys.add(key);
    if (failDeletes) throw StateError('temporary object-store failure');
    await super.delete(key, registrationId: registrationId);
  }

  @override
  Future<bool> confirmsUploadQuiescence({
    required String key,
    required DateTime expiresAt,
    String? registrationId,
  }) async {
    quiescenceCalls++;
    quiescenceKeys.add(key);
    return uploadQuiescenceConfirmed;
  }
}

class _ProviderBlockedObjectStore extends InMemoryObjectStore {
  _ProviderBlockedObjectStore({required this.blockedKeys});

  final Set<String> blockedKeys;
  int deleteAttempts = 0;

  @override
  Future<bool> confirmsUploadQuiescence({
    required String key,
    required DateTime expiresAt,
    String? registrationId,
  }) async => true;

  @override
  Future<void> delete(String key, {String? registrationId}) async {
    deleteAttempts++;
    if (blockedKeys.contains(key)) {
      throw const ObjectStoreDeleteBlockedException(
        'replica_provenance_unavailable',
      );
    }
    await super.delete(key, registrationId: registrationId);
  }
}

class _BlockingDeleteObjectStore extends _RetryingObjectStore {
  final deleteStarted = Completer<void>();
  final releaseDelete = Completer<void>();

  @override
  Future<void> delete(String key, {String? registrationId}) async {
    if (!deleteStarted.isCompleted) {
      deleteStarted.complete();
      await releaseDelete.future;
    }
    await super.delete(key, registrationId: registrationId);
  }
}

class _BlockingUploadStore extends InMemoryObjectStore {
  final started = [Completer<void>(), Completer<void>()];
  final release = Completer<void>();
  bool uploadQuiescenceConfirmed = false;
  int signCalls = 0;
  int deleteAttempts = 0;

  @override
  Future<SignedObjectRequest> signPut({
    required String key,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
    required DateTime expiresAt,
    String? registrationId,
  }) async {
    final index = signCalls++;
    if (index < started.length) {
      started[index].complete();
      await release.future;
    }
    return SignedObjectRequest(
      url: Uri.parse('https://object.test/$key'),
      headers: const {},
      expiresAt: expiresAt,
    );
  }

  @override
  Future<bool> confirmsUploadQuiescence({
    required String key,
    required DateTime expiresAt,
    String? registrationId,
  }) async => uploadQuiescenceConfirmed;

  @override
  Future<void> delete(String key, {String? registrationId}) async {
    deleteAttempts++;
    await super.delete(key, registrationId: registrationId);
  }
}

class _CountingUploadStore extends InMemoryObjectStore {
  int signCalls = 0;

  @override
  Future<SignedObjectRequest> signPut({
    required String key,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
    required DateTime expiresAt,
    String? registrationId,
  }) async {
    signCalls++;
    return super.signPut(
      key: key,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      checksumSha256: checksumSha256,
      expiresAt: expiresAt,
      registrationId: registrationId,
    );
  }
}

class _RegistrationAwareObjectStore extends InMemoryObjectStore {
  _RegistrationAwareObjectStore(this.session);

  final Session session;
  final operations = <String>[];
  String? registrationAtRegistration;
  String? registrationStateAtRegistration;
  String? registeredId;
  String? registeredKey;
  String? signingRegistrationId;
  final registrationStatesAtSigning = <String?>[];
  final registrationStarted = Completer<void>();
  final releaseRegistration = Completer<void>();

  @override
  Future<void> registerFreshKey({
    required String key,
    required String registrationId,
  }) async {
    operations.add('register');
    registeredKey = key;
    registeredId = registrationId;
    final object = await WorkspaceObject.db.findFirstRow(
      session,
      where: (row) => row.objectKey.equals(key),
    );
    if (object == null) return;
    final upload = await ObjectUpload.db.findFirstRow(
      session,
      where: (row) => row.objectId.equals(object.id!),
    );
    registrationAtRegistration = upload?.gatewayRegistrationId;
    registrationStateAtRegistration = upload?.gatewayRegistrationState;
    registrationStarted.complete();
    await releaseRegistration.future;
  }

  @override
  Future<SignedObjectRequest> signPut({
    required String key,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
    required DateTime expiresAt,
    String? registrationId,
  }) async {
    operations.add('sign');
    signingRegistrationId = registrationId;
    final object = await WorkspaceObject.db.findFirstRow(
      session,
      where: (row) => row.objectKey.equals(key),
    );
    if (object != null) {
      final upload = await ObjectUpload.db.findFirstRow(
        session,
        where: (row) => row.objectId.equals(object.id!),
      );
      registrationStatesAtSigning.add(upload?.gatewayRegistrationState);
    }
    return super.signPut(
      key: key,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      checksumSha256: checksumSha256,
      expiresAt: expiresAt,
      registrationId: registrationId,
    );
  }
}
