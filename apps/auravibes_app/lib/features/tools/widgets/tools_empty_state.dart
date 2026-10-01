import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

class const ToolsEmptyState({
  super.key,
  final bool canAddNativeTools = true,
  final EdgeInsetsGeometry padding = const EdgeInsets.all(24),
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: _ToolsEmptyContent(canAddNativeTools: canAddNativeTools),
    );
  }
}

class const _ToolsEmptyContent({required final bool canAddNativeTools})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: AuraColumn(
      children: [
        const Opacity(
          opacity: 0.5,
          child: AuraIcon(Icons.build_circle_outlined, size: .extraLarge),
        ),
        const AuraText(
          child: TextLocale(LocaleKeys.tools_screen_no_tools_added),
          style: .heading6,
          textAlign: .center,
        ),
        AuraText(
          child: TextLocale(
            canAddNativeTools
                ? LocaleKeys.tools_screen_add_tools_hint
                : 'connection_setup.native_tools_restriction',
          ),
          style: .bodySmall,
          textAlign: .center,
        ),
      ],
      spacing: .md,
      mainAxisSize: .min,
    ),
  );
}
