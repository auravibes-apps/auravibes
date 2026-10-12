import 'dart:async';

import 'package:async/async.dart';
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/background_work_repository.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/background_work_coordinator.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

QueryExecutor _createTestConnection() => DatabaseConnection.delayed(
  Future(() {
    return DatabaseConnection(
      LazyDatabase(() async => NativeDatabase.memory()),
    );
  }),
);

typedef _BackgroundWorkFixture = ({
  AppDatabase database,
  String workspaceId,
  String conversationId,
  AgentCancellationRuntime runtime,
  BackgroundWorkRepository repository,
});

Future<_BackgroundWorkFixture> _createFixture() async {
  final database = AppDatabase(connection: _createTestConnection());
  final workspace = await database.workspaceDao.insertWorkspace(
    .insert(name: 'Background work coordinator', type: .local),
  );
  final conversation = await database.conversationDao.insertConversation(
    .insert(workspaceId: workspace.id, title: 'Coordinator test'),
  );
  final runtime = AgentCancellationRuntime()..start(conversation.id);

  return (
    database: database,
    workspaceId: workspace.id,
    conversationId: conversation.id,
    runtime: runtime,
    repository: BackgroundWorkRepository(database),
  );
}

AgentToolCancellationHandle _registerToolCancellationHandleForTest(
  AgentCancellationRuntime runtime, {
  required String conversationId,
  required String toolCallId,
  required bool isSupported,
  required Future<void> Function() cancel,
  required Future<Object?> operationResult,
  bool Function()? isCancellationConfirmed,
}) {
  final registration = (
    conversationId: conversationId,
    toolCallId: toolCallId,
    isSupported: isSupported,
    cancel: cancel,
    operationResult: operationResult,
    isCancellationConfirmed: isCancellationConfirmed,
  );

  return runtime.registerToolCancellationHandle(registration);
}

void main() {
  BackgroundWorkCoordinator _coordinator(_BackgroundWorkFixture fixture) =>
      BackgroundWorkCoordinator(
        fixture.repository,
        fixture.runtime,
        (id) async => id == fixture.conversationId ? fixture.workspaceId : null,
      );

  test(
    'detach persists work and foreground cleanup leaves it running',
    () async {
      final fixture = await _createFixture();
      addTearDown(fixture.database.close);
      final database = fixture.database;
      final conversationId = fixture.conversationId;
      final runtime = fixture.runtime;
      final repository = fixture.repository;
      final originatingMessage = await database.messageDao.insertMessage(
        .insert(
          conversationId: conversationId,
          content: 'Originating user message',
          messageType: .text,
          isUser: true,
          status: .sent,
        ),
      );
      final operation = Completer<Object?>();
      var cancelCalls = 0;
      final handle = _registerToolCancellationHandleForTest(
        runtime,
        conversationId: conversationId,
        toolCallId: 'tool-call-1',
        isSupported: true,
        cancel: () async => cancelCalls++,
        operationResult: operation.future,
      );
      final coordinator = _coordinator(fixture);

      final work = await coordinator.runInBackground(
        .new(
          conversationId: conversationId,
          toolCallId: 'tool-call-1',
          toolKind: 'skill.native',
          originatingMessageId: originatingMessage.id,
        ),
      );
      expect(work?.state.status, AgentBackgroundWorkStatus.running);
      expect(work?.identity.originatingMessageId, originatingMessage.id);
      expect(await handle.detached, work?.identity.id);

      final scope =
          runtime.current(conversationId) ??
          fail('Expected the active conversation scope to be registered.');
      runtime.clear(conversationId, scope);
      await runtime.waitForCompletion(conversationId);
      expect(cancelCalls, 0);

      final terminal = repository
          .watchConversation(conversationId)
          .firstWhere((items) => items.single.state.status != .running);
      operation.complete({'answer': 'ready'});
      final saved = await terminal;
      expect(saved.single.state.status, AgentBackgroundWorkStatus.completed);
      expect(saved.single.state.resultContent, '{"answer":"ready"}');
    },
  );

  test(
    'stop is reported confirmed only after operation cancellation',
    () async {
      final fixture = await _createFixture();
      addTearDown(fixture.database.close);
      final conversationId = fixture.conversationId;
      final runtime = fixture.runtime;
      final repository = fixture.repository;
      final operation = Completer<Object?>();
      final cancellation = Completer<void>();
      final handle = _registerToolCancellationHandleForTest(
        runtime,
        conversationId: conversationId,
        toolCallId: 'tool-call-2',
        isSupported: true,
        cancel: () => cancellation.future,
        operationResult: operation.future,
      );
      final coordinator = _coordinator(fixture);
      final work =
          await coordinator.runInBackground(
            .new(
              conversationId: conversationId,
              toolCallId: 'tool-call-2',
              toolKind: 'skill.native',
            ),
          ) ??
          fail('Expected background work to be created.');
      final requested = repository
          .watchConversation(conversationId)
          .firstWhere(
            (items) =>
                items.single.state.status ==
                AgentBackgroundWorkStatus.stopRequested,
          );
      final stop = coordinator.requestStop(
        conversationId: conversationId,
        workId: work.identity.id,
      );

      expect(
        (await requested).single.state.status,
        AgentBackgroundWorkStatus.stopRequested,
      );
      cancellation.complete();
      expect(await stop, isTrue);
      expect(handle.cancellationWasConfirmed, isTrue);

      final terminal = repository
          .watchConversation(conversationId)
          .firstWhere(
            (items) =>
                items.single.state.status ==
                AgentBackgroundWorkStatus.cancelled,
          );
      operation.completeError(StateError('cancelled'));
      expect(
        (await terminal).single.state.status,
        AgentBackgroundWorkStatus.cancelled,
      );
    },
  );

  test(
    'CancelableOperation cancellation persists a stopped work record',
    () async {
      final fixture = await _createFixture();
      addTearDown(fixture.database.close);
      final conversationId = fixture.conversationId;
      final runtime = fixture.runtime;
      final repository = fixture.repository;
      final operation = CancelableOperation<Object?>.fromFuture(
        Completer<Object?>().future,
      );
      final handle = _registerToolCancellationHandleForTest(
        runtime,
        conversationId: conversationId,
        toolCallId: 'tool-call-cancelable',
        isSupported: true,
        cancel: operation.cancel,
        operationResult: operation.valueOrCancellation(),
        isCancellationConfirmed: () => operation.isCanceled,
      );
      final coordinator = _coordinator(fixture);
      final work = await coordinator.runInBackground(
        .new(
          conversationId: conversationId,
          toolCallId: 'tool-call-cancelable',
          toolKind: 'skill.native',
        ),
      );

      expect(
        await coordinator.requestStop(
          conversationId: conversationId,
          workId: (work ?? fail('Expected detached work.')).identity.id,
        ),
        isTrue,
      );
      final stopped = await repository
          .watchConversation(conversationId)
          .firstWhere(
            (items) =>
                items.single.state.status ==
                AgentBackgroundWorkStatus.cancelled,
          );

      expect(handle.cancellationWasConfirmed, isTrue);
      expect(stopped.single.state.resultContent, isNull);
      expect(stopped.single.state.resultByteLength, 0);
    },
  );

  test(
    'conversation deletion cancels detached work and blocks new detaches',
    () async {
      final fixture = await _createFixture();
      addTearDown(fixture.database.close);
      final database = fixture.database;
      final workspaceId = fixture.workspaceId;
      final conversationId = fixture.conversationId;
      final runtime = fixture.runtime;
      final repository = fixture.repository;
      final operation = Completer<Object?>();
      var cancelCalls = 0;
      final _ = runtime.registerToolCancellationHandle((
        conversationId: conversationId,
        toolCallId: 'tool-call-delete-conversation',
        isSupported: true,
        cancel: () async => cancelCalls++,
        operationResult: operation.future,
        isCancellationConfirmed: null,
      ));
      final coordinator = _coordinator(fixture);
      final work = await coordinator.runInBackground(
        .new(
          conversationId: conversationId,
          toolCallId: 'tool-call-delete-conversation',
          toolKind: 'skill.native',
        ),
      );

      await coordinator.prepareConversationDeletion(conversationId);

      expect(cancelCalls, 1);
      expect(
        (await repository.watchConversation(conversationId).first)
            .single
            .state
            .status,
        AgentBackgroundWorkStatus.stopRequested,
      );
      final blockedOperation = Completer<Object?>();
      final blockedHandle = runtime.registerToolCancellationHandle((
        conversationId: conversationId,
        toolCallId: 'tool-call-after-conversation-delete-started',
        isSupported: true,
        cancel: Future<void>.value,
        operationResult: blockedOperation.future,
        isCancellationConfirmed: null,
      ));
      expect(
        await coordinator.runInBackground(
          .new(
            conversationId: conversationId,
            toolCallId: 'tool-call-after-conversation-delete-started',
            toolKind: 'skill.native',
          ),
        ),
        isNull,
      );
      expect(blockedHandle.status, AgentToolCancellationStatus.running);
      blockedOperation.complete('still foreground');

      expect(
        await database.conversationDao.deleteConversation(conversationId),
        isTrue,
      );
      operation.complete({'answer': 'late result'});
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(await repository.watchConversation(conversationId).first, isEmpty);
      expect(work, isNotNull);
    },
  );

  test(
    'conversation deletion does not wait forever for cancellation',
    () async {
      final fixture = await _createFixture();
      addTearDown(fixture.database.close);
      final database = fixture.database;
      final workspaceId = fixture.workspaceId;
      final conversationId = fixture.conversationId;
      final repository = fixture.repository;
      final cancellationRuntime = AgentCancellationRuntime(
        cleanupTimeout: const Duration(milliseconds: 10),
      )..start(conversationId);
      final cancellation = Completer<void>();
      final operation = Completer<Object?>();
      final handle = cancellationRuntime.registerToolCancellationHandle((
        conversationId: conversationId,
        toolCallId: 'tool-call-slow-cancellation',
        isSupported: true,
        cancel: () => cancellation.future,
        operationResult: operation.future,
        isCancellationConfirmed: null,
      ));
      final coordinator = BackgroundWorkCoordinator(
        repository,
        cancellationRuntime,
        (id) async => id == conversationId ? workspaceId : null,
      );
      final work = await coordinator.runInBackground(
        .new(
          conversationId: conversationId,
          toolCallId: 'tool-call-slow-cancellation',
          toolKind: 'skill.native',
        ),
      );

      await coordinator
          .prepareConversationDeletion(conversationId)
          .timeout(const Duration(seconds: 1));

      expect(
        (await repository.watchConversation(conversationId).first)
            .single
            .state
            .status,
        AgentBackgroundWorkStatus.stopRequested,
      );
      final cancellationCompletion = handle.cancellationCompletion;
      if (cancellationCompletion == null) {
        fail('Cancellation request was not started.');
      }
      cancellation.complete();
      expect(await cancellationCompletion, isTrue);
      operation.complete('late result');
      final stopped = await repository
          .watchConversation(conversationId)
          .firstWhere(
            (items) =>
                items.single.state.status ==
                AgentBackgroundWorkStatus.cancelled,
          );

      expect(work, isNotNull);
      expect(stopped.single.state.resultContent, isNull);
    },
  );

  test(
    'conversation deletion drops a late result when cancellation never settles',
    () async {
      final fixture = await _createFixture();
      addTearDown(fixture.database.close);
      final database = fixture.database;
      final workspaceId = fixture.workspaceId;
      final conversationId = fixture.conversationId;
      final repository = fixture.repository;
      final cancellationRuntime = AgentCancellationRuntime(
        cleanupTimeout: const Duration(milliseconds: 10),
      )..start(conversationId);
      final cancellation = Completer<void>();
      final operation = Completer<Object?>();
      final handle = cancellationRuntime.registerToolCancellationHandle((
        conversationId: conversationId,
        toolCallId: 'tool-call-unsettled-cancellation',
        isSupported: true,
        cancel: () => cancellation.future,
        operationResult: operation.future,
        isCancellationConfirmed: null,
      ));
      final coordinator = BackgroundWorkCoordinator(
        repository,
        cancellationRuntime,
        (id) async => id == conversationId ? workspaceId : null,
      );
      final work = await coordinator.runInBackground(
        .new(
          conversationId: conversationId,
          toolCallId: 'tool-call-unsettled-cancellation',
          toolKind: 'skill.native',
        ),
      );
      if (work == null) fail('Expected detached work.');

      await coordinator
          .prepareConversationDeletion(conversationId)
          .timeout(const Duration(seconds: 1));
      operation.complete({'secret': 'late result'});
      final stopped = await repository
          .watchConversation(conversationId)
          .firstWhere(
            (items) =>
                items.single.state.status !=
                AgentBackgroundWorkStatus.stopRequested,
          )
          .timeout(const Duration(seconds: 1));

      expect(stopped.single.state.status, AgentBackgroundWorkStatus.failed);
      expect(stopped.single.state.errorCode, 'outcome_unknown');
      expect(stopped.single.state.resultContent, isNull);
      expect(stopped.single.state.resultByteLength, 0);
      expect(
        cancellationRuntime.toolCancellationHandle(
          conversationId: conversationId,
          toolCallId: 'tool-call-unsettled-cancellation',
        ),
        isNull,
      );
      expect(handle.isOperationCompleted(), isTrue);
      expect(
        await database.conversationDao.deleteConversation(conversationId),
        isTrue,
      );
      expect(await repository.watchConversation(conversationId).first, isEmpty);
    },
  );

  test(
    'workspace deletion cancels detached work and fences new detaches',
    () async {
      final fixture = await _createFixture();
      addTearDown(fixture.database.close);
      final database = fixture.database;
      final workspaceId = fixture.workspaceId;
      final conversationId = fixture.conversationId;
      final runtime = fixture.runtime;
      final repository = fixture.repository;
      final operation = Completer<Object?>();
      var cancelCalls = 0;
      final _ = runtime.registerToolCancellationHandle((
        conversationId: conversationId,
        toolCallId: 'tool-call-delete-workspace',
        isSupported: true,
        cancel: () async => cancelCalls++,
        operationResult: operation.future,
        isCancellationConfirmed: null,
      ));
      final coordinator = _coordinator(fixture);
      final work = await coordinator.runInBackground(
        .new(
          conversationId: conversationId,
          toolCallId: 'tool-call-delete-workspace',
          toolKind: 'skill.native',
        ),
      );

      await coordinator.prepareWorkspaceDeletion(workspaceId);

      expect(cancelCalls, 1);
      expect(
        (await repository.watchConversation(conversationId).first)
            .single
            .state
            .status,
        AgentBackgroundWorkStatus.stopRequested,
      );
      final blockedOperation = Completer<Object?>();
      final blockedHandle = runtime.registerToolCancellationHandle((
        conversationId: conversationId,
        toolCallId: 'tool-call-after-workspace-delete-started',
        isSupported: true,
        cancel: Future<void>.value,
        operationResult: blockedOperation.future,
        isCancellationConfirmed: null,
      ));
      expect(
        await coordinator.runInBackground(
          .new(
            conversationId: conversationId,
            toolCallId: 'tool-call-after-workspace-delete-started',
            toolKind: 'skill.native',
          ),
        ),
        isNull,
      );
      expect(blockedHandle.status, AgentToolCancellationStatus.running);
      blockedOperation.complete('still foreground');

      expect(await database.workspaceDao.deleteWorkspace(workspaceId), isTrue);
      operation.complete({'answer': 'late result'});
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(await repository.watchConversation(conversationId).first, isEmpty);
      expect(work, isNotNull);
    },
  );

  test('completion wins while detachment is resolving its workspace', () async {
    final fixture = await _createFixture();
    addTearDown(fixture.database.close);
    final workspaceId = fixture.workspaceId;
    final conversationId = fixture.conversationId;
    final runtime = fixture.runtime;
    final repository = fixture.repository;
    final operation = Completer<Object?>();
    final workspaceLookup = Completer<void>();
    final workspaceResolved = Completer<String?>();
    final handle = _registerToolCancellationHandleForTest(
      runtime,
      conversationId: conversationId,
      toolCallId: 'tool-call-3',
      isSupported: true,
      cancel: Future<void>.value,
      operationResult: operation.future,
    );
    final coordinator = BackgroundWorkCoordinator(repository, runtime, (_) {
      workspaceLookup.complete();

      return workspaceResolved.future;
    });

    final detaching = coordinator.runInBackground(
      .new(
        conversationId: conversationId,
        toolCallId: 'tool-call-3',
        toolKind: 'skill.native',
      ),
    );
    await workspaceLookup.future;
    operation.complete('already complete');
    expect(await operation.future, 'already complete');
    await Future<void>.delayed(.zero);
    workspaceResolved.complete(workspaceId);
    final work = await detaching;

    expect(work, isNull);
    expect(handle.status, AgentToolCancellationStatus.completed);
    expect(await repository.watchConversation(conversationId).first, isEmpty);
  });
}
