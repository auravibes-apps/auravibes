import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';

class const ToolsEmptyState({
  super.key,
  final EdgeInsetsGeometry padding = const EdgeInsets.all(24),
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(padding: padding, child: const _ToolsEmptyContent());
  }
}

class const _ToolsEmptyContent() extends StatelessWidget {
  static const _content = Center(
    child: AuraColumn(
      children: [
        Opacity(
          opacity: 0.5,
          child: AuraIcon(Icons.build_circle_outlined, size: .extraLarge),
        ),
        AuraText(
          child: TextLocale(LocaleKeys.tools_screen_no_tools_added),
          style: .heading6,
          textAlign: .center,
        ),
        AuraText(
          child: TextLocale(LocaleKeys.tools_screen_add_tools_hint),
          style: .bodySmall,
          textAlign: .center,
        ),
      ],
      spacing: .md,
      mainAxisSize: .min,
    ),
  );

  @override
  Widget build(BuildContext context) => _content;
}
