import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';

/// Permission mode selector widget.
class ToolPermissionSelector extends StatelessWidget {
  const ToolPermissionSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final ToolPermissionMode value;
  final void Function(ToolPermissionMode?) onChanged;

  @override
  Widget build(BuildContext context) {
    return AuraButtonGroup<ToolPermissionMode>.single(
      items: const [
        AuraButtonGroupItem(
          value: ToolPermissionMode.alwaysAsk,
          child: TextLocale(LocaleKeys.tools_screen_permission_always_ask),
        ),
        AuraButtonGroupItem(
          value: ToolPermissionMode.alwaysAllow,
          child: TextLocale(LocaleKeys.tools_screen_permission_always_allow),
        ),
      ],
      selectedValue: value,
      onChanged: onChanged,
      size: AuraButtonGroupSize.sm,
    );
  }
}
