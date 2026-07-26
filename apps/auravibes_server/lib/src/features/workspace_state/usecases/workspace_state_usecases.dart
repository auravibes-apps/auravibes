import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../workspaces/domain/workspace_roles.dart';
import '../domain/workspace_resource_validation.dart';
import '../repositories/workspace_state_repository.dart';
import '../workspace_secret_cipher.dart';

class WorkspaceStateUseCases {
  WorkspaceStateUseCases(this._repository);

  static const _maxPageSize = 100;
  static const _maxOperations = 50;
  static const _endpointPatch = 'workspaceState.patch';
  static const _endpointSecret = 'workspaceSecret.put';
  static const _endpointCredentialMutation = 'workspaceState.mutateCredential';
  final WorkspaceStateRepository _repository;

  Future<ReadWorkspaceStateResponse> read(
    Session session, {
    required String userId,
    required ReadWorkspaceStateRequest request,
  }) async {
    await _authorize(session, request.workspaceId, userId);
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

    final pages = <WorkspaceResourcePage>[];
    for (final selector in request.pages) {
      final rows = await _repository.readPage(
        session,
        workspaceId: request.workspaceId,
        kind: selector.resourceKind,
        limit: selector.limit + 1,
        afterResourceId: selector.afterResourceId,
      );
      final hasMore = rows.length > selector.limit;
      if (hasMore) rows.removeLast();
      pages.add(
        WorkspaceResourcePage(
          resourceKind: selector.resourceKind,
          resources: rows,
          nextResourceId: hasMore ? rows.last.resourceId : null,
        ),
      );
    }

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
      events: events,
      earliestRetainedSequence: earliest,
      requiresSnapshot: requiresSnapshot,
    );
  }

  Future<PatchWorkspaceStateResponse> patch(
    Session session, {
    required String userId,
    required PatchWorkspaceStateRequest request,
    Future<void> Function(Transaction transaction)? guard,
  }) async {
    if (request.requestId.isEmpty ||
        request.operations.isEmpty ||
        request.operations.length > _maxOperations) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.validationFailed,
      );
    }
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
      _requirePatchRole(member.role, request.operations);
      final receipt = await _findReceipt(
        session,
        request.workspaceId,
        userId,
        _endpointPatch,
        request.requestId,
        transaction,
      );
      if (receipt != null) {
        if (receipt.requestHash != hash) _idempotencyConflict();
        return PatchWorkspaceStateResponse.fromJson(
          jsonDecode(receipt.responseJson) as Map<String, dynamic>,
        );
      }

      final workspace = await _requireLockedWorkspace(
        session,
        request.workspaceId,
        transaction,
      );
      await guard?.call(transaction);
      final now = DateTime.now().toUtc();
      final changed = <WorkspaceResource>[];
      for (final operation in request.operations) {
        changed.add(
          await _applyOperation(
            session,
            operation,
            request.workspaceId,
            now,
            transaction,
          ),
        );
      }
      var sequence = workspace.sequence;
      for (final resource in changed) {
        sequence++;
        final event = WorkspaceResourceValidation.eventFor(resource);
        await _recordEvent(
          session,
          workspaceId: request.workspaceId,
          sequence: sequence,
          userId: userId,
          kind: event.kind,
          resourceKind: event.resourceKind,
          resourceId: event.resourceId,
          transaction: transaction,
        );
      }
      await CloudWorkspace.db.updateRow(
        session,
        workspace.copyWith(sequence: sequence, updatedAt: now),
        transaction: transaction,
      );
      final response = PatchWorkspaceStateResponse(
        resources: changed,
        sequence: sequence,
      );
      await _saveReceipt(
        session,
        workspaceId: request.workspaceId,
        userId: userId,
        endpoint: _endpointPatch,
        requestId: request.requestId,
        hash: hash,
        responseJson: jsonEncode(response.toJson()),
        now: now,
        transaction: transaction,
      );
      return response;
    });
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
      final secret = await _mergedSecret(
        session,
        request: request,
        existing: existing,
      );
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
    if (operation.resourceKind != WorkspaceResourceKind.serviceConnection ||
        request.secretKind != WorkspaceSecretKind.skillCredential) {
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
      final writesSecret =
          request.secret != null ||
          (request.clearSecret && existing?.deletedAt == null);
      if (writesSecret &&
          request.expectedSecretRevision != existing?.revision) {
        _staleRevision();
      }
      final isSkillCredential =
          operation.operation != WorkspacePatchOperationKind.delete &&
          _credentialKind(operation) == 'skillCredential';
      final secret = writesSecret
          ? isSkillCredential
                ? await _mergedSecret(
                    session,
                    request: PutWorkspaceSecretRequest(
                      workspaceId: request.workspaceId,
                      requestId: request.requestId,
                      secretKind: request.secretKind,
                      scope: request.scope,
                      resourceId: operation.resourceId,
                      secret: request.clearSecret ? null : request.secret,
                      expectedRevision: request.expectedSecretRevision,
                    ),
                    existing: existing,
                  )
                : request.clearSecret
                ? null
                : request.secret
          : existing?.deletedAt == null
          ? await const WorkspaceSecretCipher().decrypt(session, existing!)
          : null;
      final secretRevision = writesSecret
          ? (existing?.revision ?? 0) + 1
          : existing?.revision;
      final sanitized = _credentialOperation(
        operation,
        configured: secret != null,
        displaySuffix: secret == null ? null : _suffix(secret),
        secretRevision: secretRevision,
      );
      final resource = await _applyOperation(
        session,
        sanitized,
        request.workspaceId,
        now,
        transaction,
      );
      if (!writesSecret) {
        final resourceEvent = WorkspaceResourceValidation.eventFor(resource);
        final sequence = workspace.sequence + 1;
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
        await CloudWorkspace.db.updateRow(
          session,
          workspace.copyWith(sequence: sequence, updatedAt: now),
          transaction: transaction,
        );
        final response = MutateWorkspaceCredentialResponse(
          resource: resource,
          configured: secret != null,
          displaySuffix: secret == null ? null : _suffix(secret),
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
      final sequence = workspace.sequence + 1;
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
      await _recordEvent(
        session,
        workspaceId: request.workspaceId,
        sequence: sequence + 1,
        userId: userId,
        kind: secret == null ? 'deleted' : 'updated',
        resourceKind: 'secretConfiguredState',
        transaction: transaction,
      );
      final finalSequence = sequence + 1;
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

  String _credentialKind(WorkspacePatchOperation operation) {
    final data = operation.data;
    if (data == null) _validationFailed();
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic> && decoded['kind'] is String) {
        return decoded['kind'] as String;
      }
    } on FormatException {
      _validationFailed();
    }
    _validationFailed();
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

  Future<WorkspaceResource> _applyOperation(
    Session session,
    WorkspacePatchOperation operation,
    int workspaceId,
    DateTime now,
    Transaction transaction,
  ) async {
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
          data: operation.data!,
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
          : operation.data ?? existing.data,
      revision: existing.revision + 1,
      updatedAt: now,
      deletedAt: operation.operation == WorkspacePatchOperationKind.delete
          ? now
          : null,
    );
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

  Future<String?> _mergedSecret(
    Session session, {
    required PutWorkspaceSecretRequest request,
    required WorkspaceSecret? existing,
  }) async {
    final value = request.secret;
    if (value == null ||
        request.secretKind != WorkspaceSecretKind.skillCredential) {
      return value;
    }
    final decoded = _credentialPatch(value);
    final merged = existing == null || existing.deletedAt != null
        ? <String, String>{}
        : Map<String, String>.from(
            jsonDecode(
                  await const WorkspaceSecretCipher().decrypt(
                    session,
                    existing,
                  ),
                )
                as Map,
          );
    merged.addAll(decoded.set);
    for (final key in decoded.clear) {
      merged.remove(key);
    }
    return merged.isEmpty ? null : jsonEncode(merged);
  }

  ({Map<String, String> set, List<String> clear}) _credentialPatch(
    String value,
  ) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map ||
          decoded['set'] is! Map ||
          decoded['clear'] is! List) {
        _validationFailed();
      }
      final set = <String, String>{};
      for (final entry in (decoded['set'] as Map).entries) {
        if (entry.key is! String || entry.value is! String) _validationFailed();
        set[entry.key as String] = entry.value as String;
      }
      final clear = <String>[];
      for (final key in decoded['clear'] as List) {
        if (key is! String) _validationFailed();
        clear.add(key);
      }
      return (set: set, clear: clear);
    } on FormatException {
      _validationFailed();
    }
  }

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
