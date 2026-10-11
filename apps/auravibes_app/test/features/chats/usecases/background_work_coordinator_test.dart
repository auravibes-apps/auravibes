import 'dart:async';

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
}) {
  final registration = (
    conversationId: conversationId,
    toolCallId: toolCallId,
    isSupported: isSupported,
    cancel: cancel,
  );

  return runtime.registerToolCancellationHandle(
    registration,
    operationResult: operationResult,
  );
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
