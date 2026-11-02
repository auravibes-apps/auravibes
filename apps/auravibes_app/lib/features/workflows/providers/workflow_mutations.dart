import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:riverpod/experimental/mutation.dart';

abstract final class WorkflowMutations {
  static final save = Mutation<WorkspaceWorkflow>();
}
