import 'package:auravibes_app/features/workflows/adapters/workflow_repository.dart';
import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_graph_validation.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:uuid/v7.dart';

class SaveWorkflowUsecase {
  const new(this._repository);

  final WorkflowRepository _repository;

  Future<WorkflowDefinition> call(WorkflowDefinition draft) async {
    final workflow = WorkflowSaveDraft.prepare(draft);
    await _validateAndPersist(workflow);

    return workflow;
  }

  Future<void> _validateAndPersist(WorkflowDefinition workflow) async {
    final issues = await WorkflowSaveValidation.issues(_repository, workflow);
    if (issues.isNotEmpty) throw WorkflowValidationException(issues);
    await _repository.saveWorkflow(workflow);
  }
}

abstract final class WorkflowSaveDraft {
  static WorkflowDefinition prepare(WorkflowDefinition draft) {
    final now = DateTime.now().toUtc();
    final isNew = draft.id.isEmpty;

    return draft.copyWith(
      id: isNew ? const UuidV7().generate() : draft.id,
      name: draft.name.trim(),
      description: draft.description.trim(),
      createdAt: isNew ? now : draft.createdAt,
      updatedAt: now,
    );
  }
}

abstract final class WorkflowSaveValidation {
  static Future<List<WorkflowGraphIssue>> issues(
    WorkflowRepository repository,
    WorkflowDefinition workflow,
  ) async {
    final result = <WorkflowGraphIssue>[
      ...WorkflowGraphValidation.validateWorkflowDefinition(workflow),
    ];
    final existing = await repository.getWorkflows(workflow.workspaceId);
    if (WorkflowGraphValidation.workflowHasDependencyCycle(
      workflow,
      existing,
    )) {
      result.add(.workflowDependencyCycle);
    }

    return result;
  }
}

class WorkflowValidationException implements Exception {
  const new(this.issues);

  final List<WorkflowGraphIssue> issues;

  String get localizationKey => LocaleKeys.workflow_editor_validation_error;

  bool get hasIssues => issues.isNotEmpty;

  String get description => issues.join(', ');

  String messageKeyOr(String fallback) =>
      hasIssues ? localizationKey : fallback;

  @override
  String toString() => 'WorkflowValidationException: $description';
}
