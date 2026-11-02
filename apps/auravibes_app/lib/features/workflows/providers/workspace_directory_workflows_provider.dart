import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/providers/workflow_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_directory_workflows_provider.g.dart';

@riverpod
Stream<List<WorkspaceWorkflow>> workspaceDirectoryWorkflows(
  Ref ref,
  String workspaceId,
  String? parentId,
) => ref
    .watch(workflowRepositoryProvider(workspaceId))
    .watchDirectory(workspaceId, parentId);
