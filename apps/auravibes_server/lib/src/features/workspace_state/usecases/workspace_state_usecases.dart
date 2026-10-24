import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../mcp_servers/mcp_server_headers.dart';
import '../../mcp_servers/mcp_server_policy.dart';
import '../../workspaces/domain/workspace_roles.dart';
import '../domain/workspace_resource_validation.dart';
import '../repositories/workspace_state_repository.dart';
import '../workspace_directory_move_batch.dart';
import '../workspace_record_mutation_batch.dart';
import '../workspace_secret_cipher.dart';
import '../workspace_table_access.dart';
import '../workspace_table_mutation_validation.dart';
import '../workspace_table_page_reader.dart';

typedef _OperationCommitMetadata = ({
  String userId,
  String endpoint,
  String requestId,
  String hash,
});

class WorkspaceStateUseCases(final WorkspaceStateRepository _repository) {
  static const _maxPageSize = 100;
  static const _maxOperations = 50;
  static const _endpointPatch = 'workspaceState.patch';
  static const _endpointDuplicateAgent = 'workspaceState.duplicateAgent';
  static const _endpointSecret = 'workspaceSecret.put';
  static const _endpointCredentialMutation = 'workspaceState.mutateCredential';
  Future<ReadWorkspaceStateResponse> read(
    Session session, {
    required String userId,
    required ReadWorkspaceStateRequest request,
  }) async {
    final member = await _authorize(session, request.workspaceId, userId);
    final workspace = await _repository.findWorkspace(
      session,
      request.workspaceId,
    );
    if (workspace == null) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.membershipRequired,
      );
    }
    if (request.pages.length > 20 ||
        request.eventLimit < 0 ||
        request.eventLimit > _maxPageSize ||
        request.pages.any(
          (page) => page.limit < 1 || page.limit > _maxPageSize,
        )) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.validationFailed,
      );
    }

    final pageReader = WorkspaceTablePageReader(_repository, session, member);
    final pages = [
      for (final selector in request.pages) await pageReader.page(selector),
    ];

    final firstEvent = await _repository.firstEvent(
      session,
      request.workspaceId,
    );
    final earliest = firstEvent?.sequence;
    final after = request.afterSequence;
    final requiresSnapshot =
        after != null && earliest != null && after < earliest - 1;
    final events = after == null || requiresSnapshot
        ? <WorkspaceEvent>[]
        : await _repository.readEvents(
            session,
            workspaceId: request.workspaceId,
            afterSequence: after,
            limit: request.eventLimit,
          );
    return ReadWorkspaceStateResponse(
      pages: pages,
      currentSequence: workspace.sequence,
      events: [
        for (final event in events)
          await const WorkspaceTableAccess().visibleEvent(
            session,
            member,
            event,
          ),
      ],
      earliestRetainedSequence: earliest,
      requiresSnapshot: requiresSnapshot,
    );
  }

  Future<PatchWorkspaceStateResponse> patch(
    Session session, {
    required String userId,
    required PatchWorkspaceStateRequest request,
    Future<void> Function(Transaction transaction)? guard,
    bool previewOnly = false,
  }) async {
    final moves = WorkspaceDirectoryMoveBatch(request)..validate();
    try {
      for (final operation in request.operations) {
        final data = operation.data;
        if (data != null) WorkspaceResourceValidation.validateDataSize(data);
      }
    } on FormatException {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.validationFailed,
      );
    }
    if (request.operations.any(
      (operation) =>
          operation.operation == .delete &&
          {
            WorkspaceResourceKind.folder,
            WorkspaceResourceKind.table,
            WorkspaceResourceKind.tableRecord,
          }.contains(operation.resourceKind),
    )) {
      throw CloudWorkspaceException(code: .validationFailed);
    }
    final requestJson = jsonEncode(moves.canonicalRequest());
    final requestHash = (await Sha256().hash(utf8.encode(requestJson))).bytes;
    final hash = base64UrlEncode(requestHash);

    try {
      return await session.db.transaction((transaction) async {
        await _authorize(
          session,
          request.workspaceId,
          userId,
          transaction: transaction,
        );
        final workspace = await _requireLockedWorkspace(
          session,
          request.workspaceId,
          transaction,
        );
        final member = await _authorize(
          session,
          request.workspaceId,
          userId,
          transaction: transaction,
        );
        _requirePatchRole(member.role, request.operations);
        for (final operation in request.operations) {
          await WorkspaceTableAccess(transaction: transaction).requireWrite(
            session,
            member,
            operation,
          );
        }
        await moves.authorize(session, member, transaction);
        final receipt = await _findReceipt(
          session,
          request.workspaceId,
          userId,
          _endpointPatch,
          request.requestId,
          transaction,
        );
        if (!previewOnly && receipt != null) {
          if (receipt.requestHash != hash) _idempotencyConflict();

          return await _visiblePatch(
            session,
            member,
            transaction,
            PatchWorkspaceStateResponse.fromJson(
              jsonDecode(receipt.responseJson) as Map<String, dynamic>,
            ),
          );
        }

        await guard?.call(transaction);
        await moves.apply(session, member, transaction);
        final response = await _commitOperations(
          session,
          workspace: workspace,
          workspaceId: request.workspaceId,
          metadata: (
            userId: userId,
            endpoint: _endpointPatch,
            requestId: request.requestId,
            hash: hash,
          ),
          operations: request.operations,
          transaction: transaction,
        );
        if (previewOnly) throw _WorkspacePreviewComplete(response);

        return response;
      });
    } on _WorkspacePreviewComplete catch (preview) {
      return preview.response;
    }
  }

  Future<PatchWorkspaceStateResponse> duplicateAgent(
    Session session, {
    required String userId,
    required DuplicateWorkspaceAgentRequest request,
  }) async {
    if (request.requestId.isEmpty || request.sourceAgentId.isEmpty) {
      _validationFailed();
    }
    final requestJson = jsonEncode(request.toJson());
    final requestHash = (await Sha256().hash(utf8.encode(requestJson))).bytes;
    final hash = base64UrlEncode(requestHash);

    return session.db.transaction((transaction) async {
      final member = await _authorize(
        session,
        request.workspaceId,
        userId,
        transaction: transaction,
      );
      if (member.role == WorkspaceRoles.member) {
        throw CloudWorkspaceException(
          code: CloudWorkspaceErrorCode.permissionDenied,
        );
      }
      final workspace = await _requireLockedWorkspace(
        session,
        request.workspaceId,
        transaction,
      );
      final receipt = await _findReceipt(
        session,
        request.workspaceId,
        userId,
        _endpointDuplicateAgent,
        request.requestId,
        transaction,
      );
      if (receipt != null) {
        if (receipt.requestHash != hash) _idempotencyConflict();
        return PatchWorkspaceStateResponse.fromJson(
          jsonDecode(receipt.responseJson) as Map<String, dynamic>,
        );
      }

      final operations = await _duplicateAgentOperations(
        session,
        request,
        transaction,
      );
      return _commitOperations(
        session,
        workspace: workspace,
        workspaceId: request.workspaceId,
        metadata: (
          userId: userId,
          endpoint: _endpointDuplicateAgent,
          requestId: request.requestId,
          hash: hash,
        ),
        operations: operations,
        transaction: transaction,
      );
    });
  }

  Future<PatchWorkspaceStateResponse> _commitOperations(
    Session session, {
    required CloudWorkspace workspace,
    required int workspaceId,
    required _OperationCommitMetadata metadata,
    required Iterable<WorkspacePatchOperation> operations,
    required Transaction transaction,
  }) async {
    return await _commitPrepared((
      session: session,
      workspace: workspace,
      workspaceId: workspaceId,
      metadata: metadata,
      transaction: transaction,
      now: DateTime.now().toUtc(),
    ), operations);
  }

  Future<PatchWorkspaceStateResponse> _commitPrepared(
    _OperationCommitContext context,
    Iterable<WorkspacePatchOperation> operations,
  ) async {
    final changed = await _applyBatch(context, operations);
    final response = await _emitBatch(context, changed);
    await _saveBatchReceipt(context, response);

    return await _projectBatch(context, response);
  }

  WorkspaceRecordMutationBatch _recordBatch(_OperationCommitContext context) =>
      WorkspaceRecordMutationBatch(
        _repository,
        context.session,
        context.workspaceId,
        context.transaction,
        context.metadata.userId,
      );

  Future<List<WorkspaceResource>> _applyBatch(
    _OperationCommitContext context,
    Iterable<WorkspacePatchOperation> operations,
  ) async {
    final records = _recordBatch(context);
    final changed = <WorkspaceResource>[];
    for (final operation in operations) {
      await records.remember(operation);
      changed.add(await _applyBatchOperation(context, operation));
    }
    await records.validate(changed);

    return changed;
  }

  Future<WorkspaceResource> _applyBatchOperation(
    _OperationCommitContext context,
    WorkspacePatchOperation operation,
  ) => _applyOperation(
    context.session,
    operation,
    context.workspaceId,
    context.now,
    context.transaction,
    userId: context.metadata.userId,
    deferRecordState: true,
  );

  Future<PatchWorkspaceStateResponse> _emitBatch(
    _OperationCommitContext context,
    List<WorkspaceResource> changed,
  ) async {
    final sequence = await _recordBatchEvents(context, changed);
    await _updateBatchWorkspace(context, sequence);

    return PatchWorkspaceStateResponse(resources: changed, sequence: sequence);
  }

  Future<int> _recordBatchEvents(
    _OperationCommitContext context,
    List<WorkspaceResource> changed,
  ) async {
    var sequence = context.workspace.sequence;
    for (final resource in changed) {
      sequence++;
      await _recordBatchEvent(context, resource, sequence);
    }

    return sequence;
  }

  Future<void> _recordBatchEvent(
    _OperationCommitContext context,
    WorkspaceResource resource,
    int sequence,
  ) async {
    final event = WorkspaceResourceValidation.eventFor(resource);
    await _recordEvent(
      context.session,
      workspaceId: context.workspaceId,
      sequence: sequence,
      userId: context.metadata.userId,
      kind: event.kind,
      resourceKind: event.resourceKind,
      resourceId: event.resourceId,
      transaction: context.transaction,
    );
  }

  Future<void> _updateBatchWorkspace(
    _OperationCommitContext context,
    int sequence,
  ) async {
    final _ = await CloudWorkspace.db.updateRow(
      context.session,
      context.workspace.copyWith(sequence: sequence, updatedAt: context.now),
      transaction: context.transaction,
    );
  }

  Future<void> _saveBatchReceipt(
    _OperationCommitContext context,
    PatchWorkspaceStateResponse response,
  ) async {
    final metadata = context.metadata;
    await _saveReceipt(
      context.session,
      workspaceId: context.workspaceId,
      userId: metadata.userId,
      endpoint: metadata.endpoint,
      requestId: metadata.requestId,
      hash: metadata.hash,
      responseJson: jsonEncode(response.toJson()),
      now: context.now,
      transaction: context.transaction,
    );
  }

  Future<PatchWorkspaceStateResponse> _projectBatch(
    _OperationCommitContext context,
    PatchWorkspaceStateResponse response,
  ) async {
    final member = await _repository.findMember(
      context.session,
      workspaceId: context.workspaceId,
      userId: context.metadata.userId,
      transaction: context.transaction,
    );
    if (member == null) throw CloudWorkspaceException(code: .permissionDenied);

    return await _visiblePatch(
      context.session,
      member,
      context.transaction,
      response,
    );
  }

  Future<PatchWorkspaceStateResponse> _visiblePatch(
    Session session,
    WorkspaceMember member,
    Transaction transaction,
    PatchWorkspaceStateResponse response,
  ) async {
    final resources = <WorkspaceResource>[];
    for (final row in response.resources) {
      final visible = await WorkspaceTableAccess(transaction: transaction)
          .visible(session, member, row);
      if (visible != null) resources.add(visible);
    }
    return response.copyWith(resources: resources);
  }

  Future<PutWorkspaceSecretResponse> putSecret(
    Session session, {
    required String userId,
    required PutWorkspaceSecretRequest request,
  }) async {
    if (request.requestId.isEmpty || request.resourceId.isEmpty) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.validationFailed,
      );
    }
    if (request.secretKind == WorkspaceSecretKind.mcp) _validationFailed();
    final hash = base64UrlEncode(
      (await Sha256().hash(utf8.encode(jsonEncode(request.toJson())))).bytes,
    );
    return session.db.transaction((transaction) async {
      final member = await _authorize(
        session,
        request.workspaceId,
        userId,
        transaction: transaction,
      );
      if (member.role == WorkspaceRoles.member) {
        throw CloudWorkspaceException(
          code: CloudWorkspaceErrorCode.permissionDenied,
        );
      }
      final workspace = await _requireLockedWorkspace(
        session,
        request.workspaceId,
        transaction,
      );
      final receipt = await _findReceipt(
        session,
        request.workspaceId,
        userId,
        _endpointSecret,
        request.requestId,
        transaction,
      );
      if (receipt != null) {
        if (receipt.requestHash != hash) _idempotencyConflict();
        return PutWorkspaceSecretResponse.fromJson(
          jsonDecode(receipt.responseJson) as Map<String, dynamic>,
        );
      }

      if (request.scope == WorkspaceSecretScope.user &&
          request.secretKind == WorkspaceSecretKind.provider) {
        final connection = await _repository.findResource(
          session,
          workspaceId: request.workspaceId,
          kind: WorkspaceResourceKind.serviceConnection,
          resourceId: request.resourceId,
          transaction: transaction,
        );
        if (connection != null && connection.deletedAt == null) {
          _validationFailed();
        }
      }
      final owner = WorkspaceResourceValidation.secretOwnerKey(
        request.scope,
        userId,
      );
      final existing = await _repository.findSecret(
        session,
        workspaceId: request.workspaceId,
        kind: request.secretKind,
        scope: request.scope,
        ownerUserId: owner,
        resourceId: request.resourceId,
        transaction: transaction,
      );
      if (request.expectedRevision != existing?.revision) _staleRevision();
      final now = DateTime.now().toUtc();
      final secret = request.secret;
      final revision = (existing?.revision ?? 0) + 1;
      final box = secret == null
          ? null
          : await const WorkspaceSecretCipher().encrypt(
              session,
              secret,
              workspaceId: request.workspaceId,
              resourceId: request.resourceId,
            );
      final row = WorkspaceSecret(
        id: existing?.id,
        workspaceId: request.workspaceId,
        secretKind: request.secretKind,
        scope: request.scope,
        ownerUserId: owner,
        resourceId: request.resourceId,
        ciphertext: box?.ciphertext ?? ByteData(0),
        nonce: box?.nonce ?? ByteData(0),
        authenticationTag: box?.authenticationTag ?? ByteData(0),
        algorithm: 'AES-256-GCM',
        keyVersion: 1,
        displaySuffix: secret == null ? null : _suffix(secret),
        revision: revision,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        deletedAt: secret == null ? now : null,
      );
      final saved = existing == null
          ? await WorkspaceSecret.db.insertRow(
              session,
              row,
              transaction: transaction,
            )
          : await WorkspaceSecret.db.updateRow(
              session,
              row,
              transaction: transaction,
            );
      final sequence = workspace.sequence + 1;
      await CloudWorkspace.db.updateRow(
        session,
        workspace.copyWith(sequence: sequence, updatedAt: now),
        transaction: transaction,
      );
      await _recordEvent(
        session,
        workspaceId: request.workspaceId,
        sequence: sequence,
        userId: userId,
        kind: secret == null ? 'deleted' : 'updated',
        resourceKind: 'secretConfiguredState',
        transaction: transaction,
      );
      final response = PutWorkspaceSecretResponse(
        configured: secret != null,
        displaySuffix: saved.displaySuffix,
        revision: revision,
        sequence: sequence,
      );
      await _saveReceipt(
        session,
        workspaceId: request.workspaceId,
        userId: userId,
        endpoint: _endpointSecret,
        requestId: request.requestId,
        hash: hash,
        responseJson: jsonEncode(response.toJson()),
        now: now,
        transaction: transaction,
      );
      return response;
    });
  }

  Future<MutateWorkspaceCredentialResponse> mutateCredential(
    Session session, {
    required String userId,
    required MutateWorkspaceCredentialRequest request,
  }) async {
    final operation = request.resourceOperation;
    if (request.requestId.isEmpty || operation.resourceId.isEmpty) {
      _validationFailed();
    }
    final isServiceConnection =
        operation.resourceKind == WorkspaceResourceKind.serviceConnection &&
        request.secretKind == WorkspaceSecretKind.provider &&
        request.scope == WorkspaceSecretScope.workspace;
    final deletesServiceConnection =
        isServiceConnection &&
        operation.operation == WorkspacePatchOperationKind.delete;
    final isMcpCredential =
        operation.resourceKind == WorkspaceResourceKind.mcpServer &&
        request.secretKind == WorkspaceSecretKind.mcp &&
        request.scope == WorkspaceSecretScope.workspace;
    if (!isServiceConnection && !isMcpCredential) {
      _validationFailed();
    }
    if (isMcpCredential &&
        operation.operation != WorkspacePatchOperationKind.update) {
      _validationFailed();
    }
    try {
      if (operation.data != null) {
        WorkspaceResourceValidation.validateDataSize(operation.data!);
      }
    } on FormatException {
      _validationFailed();
    }
    final hash = base64UrlEncode(
      (await Sha256().hash(utf8.encode(jsonEncode(request.toJson())))).bytes,
    );
    return session.db.transaction((transaction) async {
      final member = await _authorize(
        session,
        request.workspaceId,
        userId,
        transaction: transaction,
      );
      _requirePatchRole(member.role, [operation]);
      if (member.role == WorkspaceRoles.member) {
        throw CloudWorkspaceException(
          code: CloudWorkspaceErrorCode.permissionDenied,
        );
      }
      final workspace = await _requireLockedWorkspace(
        session,
        request.workspaceId,
        transaction,
      );
      final receipt = await _findReceipt(
        session,
        request.workspaceId,
        userId,
        _endpointCredentialMutation,
        request.requestId,
        transaction,
      );
      if (receipt != null) {
        if (receipt.requestHash != hash) _idempotencyConflict();
        return MutateWorkspaceCredentialResponse.fromJson(
          jsonDecode(receipt.responseJson) as Map<String, dynamic>,
        );
      }

      final now = DateTime.now().toUtc();
      final owner = WorkspaceResourceValidation.secretOwnerKey(
        request.scope,
        userId,
      );
      final existing = await _repository.findSecret(
        session,
        workspaceId: request.workspaceId,
        kind: request.secretKind,
        scope: request.scope,
        ownerUserId: owner,
        resourceId: operation.resourceId,
        transaction: transaction,
      );
      final writesSecret = deletesServiceConnection
          ? existing != null && existing.deletedAt == null
          : request.secret != null ||
                (request.clearSecret && existing?.deletedAt == null);
      var expectedSecretRevision = request.expectedSecretRevision;
      if (writesSecret && expectedSecretRevision != existing?.revision) {
        if (!await _isLegacyMcpSecretUpdate(
          session,
          operation: operation,
          workspaceId: request.workspaceId,
          expectedSecretRevision: expectedSecretRevision,
          existing: existing,
          transaction: transaction,
        )) {
          _staleRevision();
        }
        expectedSecretRevision = existing?.revision;
      }
      final secret = writesSecret
          ? request.clearSecret || deletesServiceConnection
                ? null
                : request.secret
          : existing != null && existing.deletedAt == null
          ? await const WorkspaceSecretCipher().decrypt(session, existing)
          : null;
      if (isMcpCredential) {
        _validateMcpSecret(operation.data!, secret);
      }
      final secretRevision = writesSecret
          ? (existing?.revision ?? 0) + 1
          : existing?.revision;
      final displaySuffix = writesSecret
          ? secret == null
                ? null
                : _suffix(secret)
          : existing?.displaySuffix;
      final sanitized = _credentialOperation(
        operation,
        configured: secret != null,
        displaySuffix: displaySuffix,
        secretRevision: secretRevision,
      );
      final previousResource = isMcpCredential
          ? await _repository.findResource(
              session,
              workspaceId: request.workspaceId,
              kind: WorkspaceResourceKind.mcpServer,
              resourceId: operation.resourceId,
              transaction: transaction,
            )
          : null;
      final resetMcpPermissions =
          previousResource != null &&
          _mcpIdentityChanged(
            previousResource.data,
            sanitized.data!,
            secretChanged: writesSecret,
          );
      final resource = await _applyOperation(
        session,
        sanitized,
        request.workspaceId,
        now,
        transaction,
        userId: userId,
        credentialSecret: (value: secret),
      );
      final resetResources = resetMcpPermissions
          ? await _resetMcpPermissions(
              session,
              workspaceId: request.workspaceId,
              mcpServerId: operation.resourceId,
              now: now,
              transaction: transaction,
            )
          : const <WorkspaceResource>[];
      if (!writesSecret) {
        final resourceEvent = WorkspaceResourceValidation.eventFor(resource);
        var sequence = workspace.sequence + 1;
        await _recordEvent(
          session,
          workspaceId: request.workspaceId,
          sequence: sequence,
          userId: userId,
          kind: resourceEvent.kind,
          resourceKind: resourceEvent.resourceKind,
          resourceId: resourceEvent.resourceId,
          transaction: transaction,
        );
        for (final resetResource in resetResources) {
          sequence++;
          await _recordEvent(
            session,
            workspaceId: request.workspaceId,
            sequence: sequence,
            userId: userId,
            kind: 'updated',
            resourceKind: resetResource.resourceKind.name,
            resourceId: resetResource.resourceId,
            transaction: transaction,
          );
        }
        await CloudWorkspace.db.updateRow(
          session,
          workspace.copyWith(sequence: sequence, updatedAt: now),
          transaction: transaction,
        );
        final response = MutateWorkspaceCredentialResponse(
          resource: resource,
          configured: secret != null,
          displaySuffix: displaySuffix,
          secretRevision: secretRevision,
          sequence: sequence,
        );
        await _saveReceipt(
          session,
          workspaceId: request.workspaceId,
          userId: userId,
          endpoint: _endpointCredentialMutation,
          requestId: request.requestId,
          hash: hash,
          responseJson: jsonEncode(response.toJson()),
          now: now,
          transaction: transaction,
        );
        return response;
      }
      final box = secret == null
          ? null
          : await const WorkspaceSecretCipher().encrypt(
              session,
              secret,
              workspaceId: request.workspaceId,
              resourceId: operation.resourceId,
            );
      final savedSecret = WorkspaceSecret(
        id: existing?.id,
        workspaceId: request.workspaceId,
        secretKind: request.secretKind,
        scope: request.scope,
        ownerUserId: owner,
        resourceId: operation.resourceId,
        ciphertext: box?.ciphertext ?? ByteData(0),
        nonce: box?.nonce ?? ByteData(0),
        authenticationTag: box?.authenticationTag ?? ByteData(0),
        algorithm: 'AES-256-GCM',
        keyVersion: 1,
        displaySuffix: secret == null ? null : _suffix(secret),
        revision: secretRevision!,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        deletedAt: secret == null ? now : null,
      );
      final storedSecret = existing == null
          ? await WorkspaceSecret.db.insertRow(
              session,
              savedSecret,
              transaction: transaction,
            )
          : await WorkspaceSecret.db.updateRow(
              session,
              savedSecret,
              transaction: transaction,
            );
      final resourceEvent = WorkspaceResourceValidation.eventFor(resource);
      var sequence = workspace.sequence + 1;
      await _recordEvent(
        session,
        workspaceId: request.workspaceId,
        sequence: sequence,
        userId: userId,
        kind: resourceEvent.kind,
        resourceKind: resourceEvent.resourceKind,
        resourceId: resourceEvent.resourceId,
        transaction: transaction,
      );
      sequence++;
      await _recordEvent(
        session,
        workspaceId: request.workspaceId,
        sequence: sequence,
        userId: userId,
        kind: secret == null ? 'deleted' : 'updated',
        resourceKind: 'secretConfiguredState',
        transaction: transaction,
      );
      for (final resetResource in resetResources) {
        sequence++;
        await _recordEvent(
          session,
          workspaceId: request.workspaceId,
          sequence: sequence,
          userId: userId,
          kind: 'updated',
          resourceKind: resetResource.resourceKind.name,
          resourceId: resetResource.resourceId,
          transaction: transaction,
        );
      }
      final finalSequence = sequence;
      await CloudWorkspace.db.updateRow(
        session,
        workspace.copyWith(sequence: finalSequence, updatedAt: now),
        transaction: transaction,
      );
      final response = MutateWorkspaceCredentialResponse(
        resource: resource,
        configured: secret != null,
        displaySuffix: storedSecret.displaySuffix,
        secretRevision: secretRevision,
        sequence: finalSequence,
      );
      await _saveReceipt(
        session,
        workspaceId: request.workspaceId,
        userId: userId,
        endpoint: _endpointCredentialMutation,
        requestId: request.requestId,
        hash: hash,
        responseJson: jsonEncode(response.toJson()),
        now: now,
        transaction: transaction,
      );
      return response;
    });
  }

  WorkspacePatchOperation _credentialOperation(
    WorkspacePatchOperation operation, {
    required bool configured,
    required String? displaySuffix,
    required int? secretRevision,
  }) {
    final data = operation.data;
    if (operation.operation == WorkspacePatchOperationKind.delete) {
      return operation;
    }
    if (data == null) _validationFailed();
    final decoded = jsonDecode(data);
    if (decoded is! Map<String, dynamic> || _containsSecretData(decoded)) {
      _validationFailed();
    }
    if (operation.resourceKind == WorkspaceResourceKind.mcpServer) {
      _validateMcpCredentialData(decoded, configured: configured);
    }
    decoded
      ..remove('hasSecret')
      ..remove('keySuffix')
      ..remove('secretRevision')
      ..['hasSecret'] = configured;
    if (displaySuffix != null) decoded['keySuffix'] = displaySuffix;
    if (secretRevision != null) decoded['secretRevision'] = secretRevision;
    return WorkspacePatchOperation(
      operation: operation.operation,
      resourceKind: operation.resourceKind,
      resourceId: operation.resourceId,
      data: jsonEncode(decoded),
      fieldMask: operation.fieldMask,
      expectedRevision: operation.expectedRevision,
    );
  }

  void _validateMcpCredentialData(
    Map<String, dynamic> data, {
    required bool configured,
  }) {
    if (data['name'] is! String ||
        (data['name'] as String).trim().isEmpty ||
        data['url'] is! String) {
      _validationFailed();
    }
    try {
      McpServerPolicy.validateUri(data['url']! as String);
    } on FormatException {
      _validationFailed();
    }
    final transport = data['transport'];
    if (transport is! Map ||
        !const {'streamableHttp', 'sse'}.contains(transport['type']) ||
        (transport['useHttp2'] != null && transport['useHttp2'] is! bool)) {
      _validationFailed();
    }
    if (data['isEnabled'] != null && data['isEnabled'] is! bool) {
      _validationFailed();
    }
    if (data['authStatus'] != null &&
        !const {
          'active',
          'reauthRequired',
          'needsReauth',
          'failed',
        }.contains(data['authStatus'])) {
      _validationFailed();
    }
    final authType = data['authType'];
    if (!const {'none', 'bearerToken', 'httpHeaders', 'oauth'}.contains(
          authType,
        ) ||
        configured != (authType != 'none')) {
      _validationFailed();
    }
  }

  void _validateMcpSecret(String dataJson, String? secret) {
    final data = jsonDecode(dataJson) as Map<String, dynamic>;
    switch (data['authType']) {
      case 'none':
        if (secret != null) _validationFailed();
      case 'bearerToken':
        if (secret == null ||
            secret.isEmpty ||
            secret.contains(RegExp(r'[\r\n]'))) {
          _validationFailed();
        }
      case 'httpHeaders':
        try {
          if (parseMcpHttpHeaders(secret).isEmpty) _validationFailed();
        } on FormatException {
          _validationFailed();
        }
      case 'oauth':
        if (secret == null || secret.isEmpty) _validationFailed();
      default:
        _validationFailed();
    }
  }

  Future<bool> _isLegacyMcpSecretUpdate(
    Session session, {
    required WorkspacePatchOperation operation,
    required int workspaceId,
    required int? expectedSecretRevision,
    required WorkspaceSecret? existing,
    required Transaction transaction,
  }) async {
    if (operation.resourceKind != WorkspaceResourceKind.mcpServer ||
        expectedSecretRevision != null ||
        existing?.deletedAt != null ||
        existing == null) {
      return false;
    }
    final resource = await _repository.findResource(
      session,
      workspaceId: workspaceId,
      kind: WorkspaceResourceKind.mcpServer,
      resourceId: operation.resourceId,
      transaction: transaction,
    );
    if (resource == null || resource.revision != operation.expectedRevision) {
      return false;
    }
    final data = jsonDecode(resource.data);

    return data is Map<String, dynamic> && data['secretRevision'] == null;
  }

  bool _mcpIdentityChanged(
    String previousJson,
    String nextJson, {
    required bool secretChanged,
  }) {
    final previous = jsonDecode(previousJson) as Map<String, dynamic>;
    final next = jsonDecode(nextJson) as Map<String, dynamic>;

    return previous['url'] != next['url'] ||
        jsonEncode(previous['transport']) != jsonEncode(next['transport']) ||
        previous['authType'] != next['authType'] ||
        secretChanged;
  }

  Future<List<WorkspaceResource>> _resetMcpPermissions(
    Session session, {
    required int workspaceId,
    required String mcpServerId,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final resources = await WorkspaceResource.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.resourceKind.inSet({
            WorkspaceResourceKind.tool,
            WorkspaceResourceKind.toolGroup,
            WorkspaceResourceKind.toolPermission,
          }) &
          table.deletedAt.equals(null),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    final groups = resources.where((resource) {
      if (resource.resourceKind != WorkspaceResourceKind.toolGroup) {
        return false;
      }
      final data = jsonDecode(resource.data);

      return data is Map<String, dynamic> && data['mcpServerId'] == mcpServerId;
    });
    final groupIds = groups.map((group) => group.resourceId).toSet();
    final tools = resources.where((resource) {
      if (resource.resourceKind != WorkspaceResourceKind.tool) return false;
      final data = jsonDecode(resource.data);
      if (data is! Map<String, dynamic>) return false;

      return data['mcpServerId'] == mcpServerId ||
          groupIds.contains(data['toolGroupId']);
    });
    final toolIds = tools.map((tool) => tool.resourceId).toSet();
    final changed = <WorkspaceResource>[];
    for (final resource in resources) {
      final data = jsonDecode(resource.data);
      if (data is! Map<String, dynamic> ||
          data['permissionMode'] == 'alwaysAsk') {
        continue;
      }
      final isAffected = switch (resource.resourceKind) {
        WorkspaceResourceKind.toolGroup => groupIds.contains(
          resource.resourceId,
        ),
        WorkspaceResourceKind.tool => toolIds.contains(resource.resourceId),
        WorkspaceResourceKind.toolPermission =>
          groupIds.contains(data['toolGroupId']) ||
              toolIds.contains(data['toolId']),
        _ => false,
      };
      if (!isAffected) continue;
      data['permissionMode'] = 'alwaysAsk';
      final updated = await WorkspaceResource.db.updateRow(
        session,
        resource.copyWith(
          data: jsonEncode(data),
          revision: resource.revision + 1,
          updatedAt: now,
        ),
        transaction: transaction,
      );
      changed.add(updated);
    }

    return changed;
  }

  bool _containsSecretData(Object? value) {
    if (value is List) return value.any(_containsSecretData);
    if (value is! Map) return false;
    const secretKeys = {'secret', 'token', 'apiKey', 'password', 'credential'};
    return value.entries.any(
      (entry) =>
          (entry.key is String && secretKeys.contains(entry.key)) ||
          _containsSecretData(entry.value),
    );
  }

  Future<WorkspaceMember> _authorize(
    Session session,
    int workspaceId,
    String userId, {
    Transaction? transaction,
  }) async {
    final member = await _repository.findMember(
      session,
      workspaceId: workspaceId,
      userId: userId,
      transaction: transaction,
    );
    if (member == null ||
        await _repository.findWorkspace(
              session,
              workspaceId,
              transaction: transaction,
            ) ==
            null) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.membershipRequired,
      );
    }
    return member;
  }

  void _requirePatchRole(
    String role,
    List<WorkspacePatchOperation> operations,
  ) {
    const memberKinds = {
      WorkspaceResourceKind.tableRecord,
      WorkspaceResourceKind.conversation,
      WorkspaceResourceKind.conversationToolSelection,
      WorkspaceResourceKind.conversationSkillSelection,
    };
    if (role == WorkspaceRoles.member &&
        operations.any(
          (operation) => !memberKinds.contains(operation.resourceKind),
        )) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.permissionDenied,
      );
    }
  }

  Future<List<WorkspacePatchOperation>> _duplicateAgentOperations(
    Session session,
    DuplicateWorkspaceAgentRequest request,
    Transaction transaction,
  ) async {
    final source = await _repository.findResource(
      session,
      workspaceId: request.workspaceId,
      kind: WorkspaceResourceKind.agent,
      resourceId: request.sourceAgentId,
      transaction: transaction,
    );
    if (source == null || source.deletedAt != null) {
      throw CloudWorkspaceException(code: CloudWorkspaceErrorCode.conflict);
    }
    final agents = await _repository.findActiveResources(
      session,
      workspaceId: request.workspaceId,
      kind: WorkspaceResourceKind.agent,
      limit: _maxOperations + 1,
      transaction: transaction,
    );
    final associations = await _repository.findActiveResources(
      session,
      workspaceId: request.workspaceId,
      kind: WorkspaceResourceKind.agentAssociation,
      limit: _maxOperations + 1,
      transaction: transaction,
    );
    if (agents.length > _maxOperations ||
        associations.length > _maxOperations) {
      _validationFailed();
    }
    final sourceData = _decodeResource(source);
    final duplicateId = const Uuid().v7();
    final duplicateData = Map<String, Object?>.from(sourceData)
      ..['id'] = duplicateId
      ..['name'] = _copyAgentName(sourceData['name'] as String, agents);

    final operations = [
      _createResourceOperation(
        kind: WorkspaceResourceKind.agent,
        id: duplicateId,
        data: duplicateData,
      ),
      ..._duplicateAgentAssociations(
        associations,
        sourceAgentId: request.sourceAgentId,
        duplicateAgentId: duplicateId,
      ),
    ];
    if (operations.length > _maxOperations) _validationFailed();
    return operations;
  }

  Map<String, Object?> _decodeResource(WorkspaceResource resource) {
    try {
      return WorkspaceResourceValidation.decode(
        kind: resource.resourceKind,
        resourceId: resource.resourceId,
        workspaceId: resource.workspaceId,
        data: resource.data,
      );
    } on FormatException {
      _validationFailed();
    }
  }

  String _copyAgentName(
    String originalName,
    Iterable<WorkspaceResource> agents,
  ) {
    final names = agents.map((agent) => _decodeResource(agent)['name']).toSet();
    for (var suffix = 1; ; suffix++) {
      final name = suffix == 1
          ? '$originalName Copy'
          : '$originalName Copy $suffix';
      if (!names.contains(name)) return name;
    }
  }

  Iterable<WorkspacePatchOperation> _duplicateAgentAssociations(
    Iterable<WorkspaceResource> associations, {
    required String sourceAgentId,
    required String duplicateAgentId,
  }) sync* {
    for (final association in associations) {
      final Object? raw;
      try {
        raw = jsonDecode(association.data);
      } on FormatException {
        _validationFailed();
      }
      if (raw is! Map<String, dynamic> || raw['agentId'] != sourceAgentId) {
        continue;
      }
      final data = Map<String, Object?>.from(_decodeResource(association));
      try {
        WorkspaceResourceValidation.references(
          WorkspaceResourceKind.agentAssociation,
          data,
        );
      } on FormatException {
        _validationFailed();
      }
      data['agentId'] = duplicateAgentId;
      final id = const Uuid().v7();
      if (data.containsKey('id')) data['id'] = id;
      yield _createResourceOperation(
        kind: WorkspaceResourceKind.agentAssociation,
        id: id,
        data: data,
      );
    }
  }

  WorkspacePatchOperation _createResourceOperation({
    required WorkspaceResourceKind kind,
    required String id,
    required Map<String, Object?> data,
  }) => WorkspacePatchOperation(
    operation: WorkspacePatchOperationKind.create,
    resourceKind: kind,
    resourceId: id,
    data: jsonEncode(data),
    fieldMask: const [],
  );

  Future<void> _validateFolderParent(
    Session session,
    int workspaceId,
    String folderId,
    String? parentId,
    Transaction transaction,
  ) async {
    final visited = {folderId};
    var current = parentId;
    while (current != null) {
      if (!visited.add(current)) throw const FormatException();
      final parent = await _repository.findResource(
        session,
        workspaceId: workspaceId,
        kind: WorkspaceResourceKind.folder,
        resourceId: current,
        transaction: transaction,
      );
      if (parent == null || parent.deletedAt != null) {
        throw const FormatException();
      }
      final data = jsonDecode(parent.data) as Map<String, dynamic>;
      current = data['parentId'] as String?;
    }
  }

  Future<WorkspaceResource> _applyOperation(
    Session session,
    WorkspacePatchOperation operation,
    int workspaceId,
    DateTime now,
    Transaction transaction, {
    required String userId,
    ({String? value})? credentialSecret,
    bool deferRecordState = false,
  }) async {
    if (operation.resourceId.isEmpty) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.validationFailed,
      );
    }
    try {
      WorkspaceResourceValidation.validateFieldMask(operation.fieldMask);
    } on FormatException {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.validationFailed,
      );
    }
    final existing = await _repository.findResource(
      session,
      workspaceId: workspaceId,
      kind: operation.resourceKind,
      resourceId: operation.resourceId,
      transaction: transaction,
    );
    var validatedData = operation.data;
    if (operation.operation != WorkspacePatchOperationKind.delete) {
      final data = operation.data;
      if (data == null) {
        throw CloudWorkspaceException(
          code: CloudWorkspaceErrorCode.validationFailed,
        );
      }
      try {
        final decoded = WorkspaceResourceValidation.decode(
          kind: operation.resourceKind,
          resourceId: operation.resourceId,
          workspaceId: workspaceId,
          data: data,
        );
        await WorkspaceResourceValidation.validateReferences(
          operation.resourceKind,
          decoded,
          (reference) => _repository.resourceExists(
            session,
            workspaceId: workspaceId,
            kind: reference.kind,
            resourceId: reference.id,
            transaction: transaction,
          ),
        );
        await WorkspaceTableMutationValidation(
          _repository,
          session,
          workspaceId,
          transaction,
          userId,
          deferRecordState: deferRecordState,
        ).validate(operation, decoded, existing);
        if (operation.resourceKind == WorkspaceResourceKind.tableRecord) {
          validatedData = jsonEncode(decoded);
        }
        if (operation.resourceKind == WorkspaceResourceKind.folder) {
          await _validateFolderParent(
            session,
            workspaceId,
            operation.resourceId,
            decoded['parentId'] as String?,
            transaction,
          );
        }
      } on FormatException {
        throw CloudWorkspaceException(
          code: CloudWorkspaceErrorCode.validationFailed,
        );
      }
    }
    if (operation.operation == WorkspacePatchOperationKind.create) {
      if (existing != null ||
          operation.data == null ||
          operation.expectedRevision != null) {
        throw CloudWorkspaceException(code: CloudWorkspaceErrorCode.conflict);
      }
      return WorkspaceResource.db.insertRow(
        session,
        WorkspaceResource(
          workspaceId: workspaceId,
          resourceKind: operation.resourceKind,
          resourceId: operation.resourceId,
          data: validatedData!,
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
        transaction: transaction,
      );
    }
    if (existing == null || existing.deletedAt != null) {
      throw CloudWorkspaceException(code: CloudWorkspaceErrorCode.conflict);
    }
    if (operation.expectedRevision != existing.revision) _staleRevision();
    final updated = existing.copyWith(
      data: operation.operation == WorkspacePatchOperationKind.delete
          ? existing.data
          : validatedData ?? existing.data,
      revision: existing.revision + 1,
      updatedAt: now,
      deletedAt: operation.operation == WorkspacePatchOperationKind.delete
          ? now
          : null,
    );
    if (operation.operation == WorkspacePatchOperationKind.delete &&
        operation.resourceKind == WorkspaceResourceKind.skill) {
      final resources = await SkillResource.db.find(
        session,
        where: (table) =>
            table.workspaceId.equals(workspaceId) &
            table.skillId.equals(operation.resourceId) &
            table.deletedAt.equals(null),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      for (final resource in resources) {
        await SkillResource.db.updateRow(
          session,
          resource.copyWith(
            deletedAt: now,
            revision: resource.revision + 1,
            updatedAt: now,
          ),
          transaction: transaction,
        );
      }
    }
    return WorkspaceResource.db.updateRow(
      session,
      updated,
      transaction: transaction,
    );
  }

  Future<CloudWorkspace> _requireLockedWorkspace(
    Session session,
    int workspaceId,
    Transaction transaction,
  ) async =>
      await _repository.findWorkspace(
        session,
        workspaceId,
        transaction: transaction,
        lock: true,
      ) ??
      (throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.membershipRequired,
      ));

  Future<WorkspaceMutationReceipt?> _findReceipt(
    Session session,
    int workspaceId,
    String userId,
    String endpoint,
    String requestId,
    Transaction transaction,
  ) => WorkspaceMutationReceipt.db.findFirstRow(
    session,
    where: (t) =>
        t.workspaceId.equals(workspaceId) &
        t.actorUserId.equals(userId) &
        t.scopeKey.equals(
          WorkspaceResourceValidation.receiptScopeKey(workspaceId),
        ) &
        t.endpoint.equals(endpoint) &
        t.requestId.equals(requestId),
    transaction: transaction,
  );

  Future<void> _saveReceipt(
    Session session, {
    required int workspaceId,
    required String userId,
    required String endpoint,
    required String requestId,
    required String hash,
    required String responseJson,
    required DateTime now,
    required Transaction transaction,
  }) async {
    await WorkspaceMutationReceipt.db.insertRow(
      session,
      WorkspaceMutationReceipt(
        workspaceId: workspaceId,
        actorUserId: userId,
        scopeKey: WorkspaceResourceValidation.receiptScopeKey(workspaceId),
        endpoint: endpoint,
        requestId: requestId,
        requestHash: hash,
        responseJson: responseJson,
        createdAt: now,
      ),
      transaction: transaction,
    );
  }

  Future<void> _recordEvent(
    Session session, {
    required int workspaceId,
    required int sequence,
    required String userId,
    required String kind,
    required String resourceKind,
    String? resourceId,
    required Transaction transaction,
  }) async {
    await WorkspaceEvent.db.insertRow(
      session,
      WorkspaceEvent(
        eventId: const Uuid().v7(),
        workspaceId: workspaceId,
        sequence: sequence,
        actorUserId: userId,
        kind: kind,
        resourceKind: resourceKind,
        resourceId: resourceId,
        createdAt: DateTime.now().toUtc(),
      ),
      transaction: transaction,
    );
  }

  String _suffix(String secret) =>
      secret.length <= 4 ? '••••' : secret.substring(secret.length - 4);

  Never _validationFailed() => throw CloudWorkspaceException(
    code: CloudWorkspaceErrorCode.validationFailed,
  );

  Never _staleRevision() => throw CloudWorkspaceException(
    code: CloudWorkspaceErrorCode.staleRevision,
  );

  Never _idempotencyConflict() => throw CloudWorkspaceException(
    code: CloudWorkspaceErrorCode.idempotencyConflict,
  );
}

class const _WorkspacePreviewComplete(
  final PatchWorkspaceStateResponse response,
) implements Exception;

typedef _OperationCommitContext = ({
  Session session,
  CloudWorkspace workspace,
  int workspaceId,
  _OperationCommitMetadata metadata,
  Transaction transaction,
  DateTime now,
});
