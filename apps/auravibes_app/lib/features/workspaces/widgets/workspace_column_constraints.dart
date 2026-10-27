import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_record_field.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';

typedef WorkspaceColumnConstraintDraft = ({
  ValueNotifier<bool> required,
  ValueNotifier<bool> unique,
  ValueNotifier<Object?> defaultValue,
});

class const WorkspaceColumnConstraints({
  required final WorkspaceColumnConstraintDraft draft,
  required final WorkspaceColumn column,
  required final bool disabled,
  final Widget? defaultEditor,
  super.key,
}) extends StatelessWidget {
  static WorkspaceColumnConstraintDraft use(WorkspaceColumn? column) => (
    required: useState(column?.isRequired ?? false),
    unique: useState(column?.isUnique ?? false),
    defaultValue: useState<Object?>(column?.defaultValue),
  );

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _ConstraintUnique(draft: draft, disabled: disabled),
      const TextLocale(LocaleKeys.workspace_items_default_value),
      _ConstraintDefault(view: this),
    ],
  );
}

class const _ConstraintUnique({
  required final WorkspaceColumnConstraintDraft draft,
  required final bool disabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCheckboxListTile(
    value: draft.unique.value,
    onChanged: (value) => draft.unique.value = value,
    title: const TextLocale(LocaleKeys.workspace_items_unique),
    disabled: disabled,
  );
}

class const _ConstraintDefault({required final WorkspaceColumnConstraints view})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (view.defaultEditor case final editor?) return editor;
    if (view.column.type == .reference) {
      return const TextLocale(
        LocaleKeys.workspace_items_reference_choose_target,
      );
    }

    return _ScalarDefault(view: view);
  }
}

class const _ScalarDefault({required final WorkspaceColumnConstraints view})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final draft = view.draft;

    return WorkspaceRecordField(
      column: view.column,
      value: draft.defaultValue.value,
      present: draft.defaultValue.value != null,
      disabled: view.disabled,
      identifier: 'workspace_column_default',
      onChanged: (value) => draft.defaultValue.value = value,
      onUnset: _unset,
    );
  }

  void _unset() => view.draft.defaultValue.value = null;
}
