import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/messages_table_type.dart';
import 'package:auravibes_app/data/repositories/background_work_repository.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/background_work_coordinator.dart';
import 'package:auravibes_app/features/chats/usecases/background_work_detach_request.dart';
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

void main() {
  late AppDatabase database;
  late String workspaceId;
  late String conversationId;
  late AgentCancellationRuntime runtime;
  late BackgroundWorkRepository repository;

  setUp(() async {
    database = AppDatabase(connection: _createTestConnection());
    final workspace = await database.workspaceDao.insertWorkspace(
      .insert(name: 'Background work coordinator', type: WorkspaceType.local),
    );
    workspaceId = workspace.id;
    final conversation = await database.conversationDao.insertConversation(
      .insert(workspaceId: workspaceId, title: 'Coordinator test'),
    );
    conversationId = conversation.id;
    runtime = AgentCancellationRuntime()..start(conversationId);
    repository = BackgroundWorkRepository(database);
  });

  tearDown(() => database.close());

  BackgroundWorkCoordinator _coordinator() => BackgroundWorkCoordinator(
    repository,
    runtime,
    (id) async => id == conversationId ? workspaceId : null,
  );

  test(
    'detach persists work and foreground cleanup leaves it running',
    () async {
      final originatingMessage = await database.messageDao.insertMessage(
        MessagesCompanion.insert(
          conversationId: conversationId,
          content: 'Originating user message',
          messageType: MessagesTableType.text,
          isUser: true,
          status: MessageTableStatus.sent,
        ),
      );
      final operation = Completer<Object?>();
      var cancelCalls = 0;
      final handle = runtime.registerToolCancellationHandle((
        conversationId: conversationId,
        toolCallId: 'tool-call-1',
        isSupported: true,
        cancel: () async => cancelCalls++,
      ), operationResult: operation.future);
      final coordinator = _coordinator();

      final work = await coordinator.runInBackground(
        BackgroundWorkDetachRequest(
          conversationId: conversationId,
          toolCallId: 'tool-call-1',
          toolKind: 'skill.native',
          originatingMessageId: originatingMessage.id,
        ),
      );
      expect(work?.state.status, AgentBackgroundWorkStatus.running);
      expect(work?.identity.originatingMessageId, originatingMessage.id);
      expect(await handle.detached, work?.identity.id);

      final scope = runtime.current(conversationId)!;
      runtime.clear(conversationId, scope);
      await runtime.waitForCompletion(conversationId);
      expect(cancelCalls, 0);

      final terminal = repository
          .watchConversation(conversationId)
          .firstWhere(
            (items) =>
                items.single.state.status != AgentBackgroundWorkStatus.running,
          );
      operation.complete({'answer': 'ready'});
      final saved = await terminal;
      expect(saved.single.state.status, AgentBackgroundWorkStatus.completed);
      expect(saved.single.state.resultContent, '{"answer":"ready"}');
    },
  );

  test(
    'stop is reported confirmed only after operation cancellation',
    () async {
      final operation = Completer<Object?>();
      final cancellation = Completer<void>();
      final handle = runtime.registerToolCancellationHandle((
        conversationId: conversationId,
        toolCallId: 'tool-call-2',
        isSupported: true,
        cancel: () => cancellation.future,
      ), operationResult: operation.future);
      final coordinator = _coordinator();
      final work = await coordinator.runInBackground(
        BackgroundWorkDetachRequest(
          conversationId: conversationId,
          toolCallId: 'tool-call-2',
          toolKind: 'skill.native',
        ),
      );
      final requested = repository
          .watchConversation(conversationId)
          .firstWhere(
            (items) =>
                items.single.state.status ==
                AgentBackgroundWorkStatus.stopRequested,
          );
      final stop = coordinator.requestStop(
        conversationId: conversationId,
        workId: work!.identity.id,
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
    final operation = Completer<Object?>();
    final workspaceLookup = Completer<void>();
    final workspaceResolved = Completer<String?>();
    final handle = runtime.registerToolCancellationHandle((
      conversationId: conversationId,
      toolCallId: 'tool-call-3',
      isSupported: true,
      cancel: () async {},
    ), operationResult: operation.future);
    final coordinator = BackgroundWorkCoordinator(repository, runtime, (_) {
      workspaceLookup.complete();

      return workspaceResolved.future;
    });

    final detaching = coordinator.runInBackground(
      BackgroundWorkDetachRequest(
        conversationId: conversationId,
        toolCallId: 'tool-call-3',
        toolKind: 'skill.native',
      ),
    );
    await workspaceLookup.future;
    operation.complete('already complete');
    await operation.future;
    await Future<void>.delayed(Duration.zero);
    workspaceResolved.complete(workspaceId);
    final work = await detaching;

    expect(work, isNull);
    expect(handle.status, AgentToolCancellationStatus.completed);
    expect(await repository.watchConversation(conversationId).first, isEmpty);
  });
}
