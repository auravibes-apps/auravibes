import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';

class ToolsEmptyState extends StatelessWidget {
  const ToolsEmptyState({
    super.key,
    this.padding = const EdgeInsets.all(24),
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: const Center(
        child: AuraColumn(
          children: [
            Opacity(
              opacity: 0.5,
              child: AuraIcon(
                Icons.build_circle_outlined,
                size: AuraIconSize.extraLarge,
              ),
            ),
            AuraText(
              child: TextLocale(LocaleKeys.tools_screen_no_tools_added),
              style: AuraTextStyle.heading6,
              textAlign: TextAlign.center,
            ),
            AuraText(
              child: TextLocale(LocaleKeys.tools_screen_add_tools_hint),
              style: AuraTextStyle.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
          spacing: .md,
          mainAxisSize: MainAxisSize.min,
        ),
      ),
    );
  }
}
