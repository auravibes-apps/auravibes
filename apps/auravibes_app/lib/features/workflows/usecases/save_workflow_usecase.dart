import 'package:auravibes_app/features/workflows/adapters/workflow_repository.dart';
import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_graph_validation.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:uuid/v7.dart';

class SaveWorkflowUsecase {
  const new(this._repository);

  final WorkflowRepository _repository;

  Future<WorkflowDefinition> call(WorkflowDefinition draft) async {
    final now = DateTime.now().toUtc();
    final workflow = draft.copyWith(
      id: draft.id.isEmpty ? const UuidV7().generate() : draft.id,
      name: draft.name.trim(),
      description: draft.description.trim(),
      createdAt: draft.id.isEmpty ? now : draft.createdAt,
      updatedAt: now,
    );
    final issues = [...validateWorkflowDefinition(workflow)];
    final existing = await _repository.getWorkflows(workflow.workspaceId);
    if (workflowHasDependencyCycle(workflow, existing)) {
      issues.add(.workflowDependencyCycle);
    }
    if (issues.isNotEmpty) throw WorkflowValidationException(issues);
    await _repository.saveWorkflow(workflow);

    return workflow;
  }
}

class WorkflowValidationException implements Exception {
  const new(this.issues);

  final List<WorkflowGraphIssue> issues;

  String get localizationKey => LocaleKeys.workflow_editor_validation_error;
}
