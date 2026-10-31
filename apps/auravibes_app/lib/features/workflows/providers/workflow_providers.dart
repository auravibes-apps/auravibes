import 'package:auravibes_app/data/repositories/workflows_repository.dart';
import 'package:auravibes_app/features/workflows/adapters/cloud_workflow_repository.dart';
import 'package:auravibes_app/features/workflows/adapters/workflow_repository.dart';
import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/usecases/save_workflow_usecase.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workflow_providers.g.dart';

final _logger = Logger('workflow_providers');

@riverpod
WorkflowRepository workflowRepository(Ref ref, String workspaceId) {
  final session = ref
      .watch(workspaceSessionForRouteProvider(workspaceId))
      .requireValue;
  if (session.cloud == null) {
    return WorkflowsRepository(ref.watch(appDatabaseProvider));
  }
  final gateway = ref.watch(cloudWorkspaceStateGatewayProvider(session).future);

  return CloudWorkflowRepository(
    workspaceId: workspaceId,
    store: .deferred(gateway),
  );
}

@riverpod
Stream<List<WorkspaceWorkflow>> workflows(Ref ref, String workspaceId) => ref
    .watch(workflowRepositoryProvider(workspaceId))
    .watchWorkflows(workspaceId);

@riverpod
Future<WorkspaceWorkflow?> workflow(
  Ref ref,
  String workspaceId,
  String workflowId,
) async {
  try {
    final workflow = await ref
        .watch(workflowRepositoryProvider(workspaceId))
        .getWorkflow(workflowId);

    return workflow?.workspaceId == workspaceId ? workflow : null;
  } on Object catch (error, stackTrace) {
    _logger.severe(
      'Workflow load failed: workspace=$workspaceId workflow=$workflowId',
      error,
      stackTrace,
    );
    rethrow;
  }
}

@riverpod
SaveWorkflowUsecase saveWorkflowUsecase(Ref ref, String workspaceId) =>
    SaveWorkflowUsecase(ref.watch(workflowRepositoryProvider(workspaceId)));
