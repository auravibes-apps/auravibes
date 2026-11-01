import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

abstract final class WorkflowConnectionText {
  static String description(
    WorkspaceWorkflow workflow,
    WorkflowConnection connection,
    BuildContext context,
  ) {
    String label(String id) =>
        workflow.nodes.where((node) => node.id == id).firstOrNull?.label ?? id;
    final branch = connection.conditionBranch;
    final key = branch == null
        ? LocaleKeys.workflow_editor_connection_label
        : LocaleKeys.workflow_editor_connection_label_branch;

    return key.tr(
      context: context,
      namedArgs: {
        'from': label(connection.fromNodeId),
        'to': label(connection.toNodeId),
        if (branch != null)
          'branch':
              (branch == .trueBranch
                      ? LocaleKeys.workflow_editor_true
                      : LocaleKeys.workflow_editor_false)
                  .tr(context: context),
      },
    );
  }
}
