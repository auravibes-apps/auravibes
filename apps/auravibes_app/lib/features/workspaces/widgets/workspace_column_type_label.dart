import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceColumnTypeLabel({
  required final WorkspaceColumnType type,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (type) {
    .text => const TextLocale(LocaleKeys.workspace_items_type_text),
    .number => const TextLocale(LocaleKeys.workspace_items_type_number),
    .checkbox => const TextLocale(LocaleKeys.workspace_items_type_checkbox),
    .singleSelect => const TextLocale(
      LocaleKeys.workspace_items_type_single_select,
    ),
    .multiSelect => const TextLocale(
      LocaleKeys.workspace_items_type_multi_select,
    ),
    .url => const TextLocale(LocaleKeys.workspace_items_type_url),
    .email => const TextLocale(LocaleKeys.workspace_items_type_email),
    .phone => const TextLocale(LocaleKeys.workspace_items_type_phone),
    .dateOnly => const TextLocale(LocaleKeys.workspace_items_type_date_only),
    .timestamp => const TextLocale(LocaleKeys.workspace_items_type_timestamp),
    .money => const TextLocale(LocaleKeys.workspace_items_type_money),
  };
}
