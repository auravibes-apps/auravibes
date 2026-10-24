import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceColumnTypeLabel({
  required final WorkspaceColumnType type,
  super.key,
}) extends StatelessWidget {
  String get _labelKey => switch (type) {
    .text => LocaleKeys.workspace_items_type_text,
    .number => LocaleKeys.workspace_items_type_number,
    .checkbox => LocaleKeys.workspace_items_type_checkbox,
    .singleSelect => LocaleKeys.workspace_items_type_single_select,
    .multiSelect => LocaleKeys.workspace_items_type_multi_select,
    .url => LocaleKeys.workspace_items_type_url,
    .email => LocaleKeys.workspace_items_type_email,
    .phone => LocaleKeys.workspace_items_type_phone,
    .reference => LocaleKeys.workspace_items_type_reference,
    _ => _exactLabelKey,
  };
  String get _exactLabelKey => switch (type) {
    .dateOnly => LocaleKeys.workspace_items_type_date_only,
    .timestamp => LocaleKeys.workspace_items_type_timestamp,
    .money => LocaleKeys.workspace_items_type_money,
    _ => LocaleKeys.workspace_items_type_text,
  };

  @override
  Widget build(BuildContext context) => TextLocale(_labelKey);
}
