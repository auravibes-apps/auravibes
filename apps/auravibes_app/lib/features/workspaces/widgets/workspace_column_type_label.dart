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
    .attachment => LocaleKeys.workspace_assets_attachments,
    _ => LocaleKeys.workspace_items_type_text,
  };

  static IconData iconFor(WorkspaceColumnType type) => switch (type) {
    .text => Icons.text_fields,
    .number => Icons.numbers,
    .checkbox => Icons.check_box_outlined,
    .singleSelect => Icons.radio_button_checked,
    .multiSelect => Icons.sell_outlined,
    .url => Icons.link,
    .email => Icons.mail_outline,
    .phone => Icons.phone_outlined,
    _ => _otherIcon(type),
  };

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: .min,
    children: [
      Icon(iconFor(type), size: 18),
      const SizedBox(width: 8),
      Flexible(
        child: TextLocale(
          _labelKey,
          softWrap: false,
          overflow: .ellipsis,
          maxLines: 1,
        ),
      ),
    ],
  );

  static IconData _otherIcon(WorkspaceColumnType type) => switch (type) {
    .dateOnly => Icons.calendar_today_outlined,
    .timestamp => Icons.schedule_outlined,
    .money => Icons.payments_outlined,
    .reference => Icons.link_outlined,
    .attachment => Icons.attach_file,
    _ => Icons.text_fields,
  };
}
