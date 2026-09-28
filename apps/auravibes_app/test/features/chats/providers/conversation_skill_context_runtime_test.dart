import 'dart:async';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_skill_context_runtime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('preparation, resume, fork, and stale completion stay distinct', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final runtime = container.read(
      conversationSkillContextRuntimeProvider.notifier,
    );

    expect(container.read(conversationSkillContextRuntimeProvider), isEmpty);
    final first = runtime.begin('conversation');
    expect(
      container
          .read(conversationSkillContextRuntimeProvider)['conversation']
          ?.phase,
      ConversationSkillContextPhase.preparing,
    );
    runtime.ready(
      'conversation',
      first,
      selectedRevisions: {'research': 'r1'},
      canActivate: true,
    );
    expect(
      container
          .read(conversationSkillContextRuntimeProvider)['conversation']
          ?.selectedRevisions['research'],
      'r1',
    );

    final inFlight = runtime.begin('conversation');
    runtime
      ..markNeedsContext('conversation')
      ..ready(
        'conversation',
        inFlight,
        selectedRevisions: {'research': 'r1'},
        canActivate: true,
      );
    expect(
      container
          .read(conversationSkillContextRuntimeProvider)['conversation']
          ?.phase,
      ConversationSkillContextPhase.needsContext,
    );
    final retry = runtime.begin('conversation');
    runtime.error('conversation', retry);
    expect(
      container
          .read(conversationSkillContextRuntimeProvider)['conversation']
          ?.phase,
      ConversationSkillContextPhase.error,
    );

    final resumed = ProviderContainer();
    addTearDown(resumed.dispose);
    expect(resumed.read(conversationSkillContextRuntimeProvider), isEmpty);
    expect(
      container.read(conversationSkillContextRuntimeProvider)['fork'],
      isNull,
    );
  });

  test('compaction invalidates context during an active operation', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final skillContext = container.read(
      conversationSkillContextRuntimeProvider.notifier,
    );
    final compaction = container.read(compactionExecutionRuntimeProvider);
    final prepared = skillContext.begin('conversation');
    skillContext.ready(
      'conversation',
      prepared,
      selectedRevisions: {'research': 'r1'},
      canActivate: true,
    );
    final operation = Completer<CompactionExecutionState>();
    final running = CompactionExecutionState(
      conversationId: 'conversation',
      trigger: .manual,
      startedAt: .new(2026),
      status: .running,
    );

    final result = compaction.run(
      runningState: running,
      operation: () => operation.future,
    );
    expect(
      container
          .read(conversationSkillContextRuntimeProvider)['conversation']
          ?.phase,
      ConversationSkillContextPhase.needsContext,
    );
    final success = running.copyWith(status: .success);
    operation.complete(success);
    expect(await result, success);
    expect(
      container
          .read(conversationSkillContextRuntimeProvider)['conversation']
          ?.phase,
      ConversationSkillContextPhase.needsContext,
    );
  });
}
