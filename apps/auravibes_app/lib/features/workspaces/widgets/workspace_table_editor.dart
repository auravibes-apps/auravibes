import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_actions.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceTableEditor({
  required final WorkspaceTable table,
  required final VoidCallback onBack,
  required final WorkspaceTableAction action,
  required final Future<void> Function() onSave,
  required final WorkspaceTableEditorKind kind,
  required final List<Widget> children,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _EditorBack(
        kind: kind,
        name: table.name,
        disabled: action.pending,
        onBack: onBack,
      ),
      ...children,
      if (kind.canSave(table))
        _SaveTableButton(action: action, onSave: onSave, kind: kind),
      if (action.error case final error?) WorkspaceItemFailure(error: error),
    ],
  );
}

class const _SaveTableButton({
  required final WorkspaceTableAction action,
  required final Future<void> Function() onSave,
  required final WorkspaceTableEditorKind kind,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => unawaited(action.run(onSave)),
    child: TextLocale(kind.label),
    isLoading: action.pending,
    disabled: action.pending,
    identifier: kind.identifier,
  );
}

class const _EditorBack({
  required final WorkspaceTableEditorKind kind,
  required final String name,
  required final bool disabled,
  required final VoidCallback onBack,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Tooltip(
    message: LocaleKeys.common_back.tr(),
    child: ListTile(
      key: ValueKey('workspace_${kind.name}_back'),
      leading: const Icon(Icons.arrow_back),
      title: Text(name),
      onTap: disabled ? null : onBack,
    ),
  );
}

enum WorkspaceTableEditorKind {
  record,
  column;

  String get label => this == record
      ? LocaleKeys.workspace_items_save_record
      : LocaleKeys.workspace_items_save_typed_column;
  String get identifier =>
      this == record ? 'workspace_record_save' : 'workspace_column_save';
  bool canSave(WorkspaceTable table) =>
      this == record ? table.canEditRecords : table.canManage;
}
