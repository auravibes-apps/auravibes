import 'package:auravibes_app/features/workflows/adapters/workflow_repository.dart';
import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/providers/workflow_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test(
    'logs workflow load failures before surfacing them to the editor',
    () async {
      final records = <LogRecord>[];
      final subscription = Logger.root.onRecord.listen(records.add);
      addTearDown(subscription.cancel);
      final previousLevel = Logger.root.level;
      Logger.root.level = .ALL;
      addTearDown(() => Logger.root.level = previousLevel);
      final container = ProviderContainer(
        overrides: [
          workflowRepositoryProvider('workspace')
              .overrideWithValue(_FailingWorkflowRepository()),
        ],
        retry: (_, _) => null,
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(workflowProvider('workspace', 'workflow').future),
        throwsA(isA<StateError>()),
      );

      final errors = records
          .where(
            (record) =>
                record.loggerName == 'workflow_providers' &&
                record.message.contains('Workflow load failed'),
          )
          .toList();
      expect(errors, hasLength(1));
      expect(errors.single.level, Level.SEVERE);
      expect(errors.single.error, isA<StateError>());
      expect(errors.single.stackTrace, isNotNull);
    },
  );
}

class _FailingWorkflowRepository implements WorkflowRepository {
  @override
  Stream<List<WorkspaceWorkflow>> watchWorkflows(String workspaceId) =>
      const Stream.empty();

  @override
  Stream<List<WorkspaceWorkflow>> watchDirectory(
    String workspaceId,
    String? parentId,
  ) => const Stream.empty();

  @override
  Future<List<WorkspaceWorkflow>> getWorkflows(String workspaceId) async => [];

  @override
  Future<WorkspaceWorkflow?> getWorkflow(String id) =>
      Future.error(StateError('Workflow unavailable'));

  @override
  Future<WorkspaceWorkflow> saveWorkflow(WorkspaceWorkflow workflow) =>
      Future.error(StateError('Workflow unavailable'));
}
