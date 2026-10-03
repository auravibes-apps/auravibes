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
    return _ToolsEmptyViewport(
      child: Padding(
        padding: padding,
        child: _ToolsEmptyContent(canAddNativeTools: canAddNativeTools),
      ),
    );
  }
}

class const _ToolsEmptyViewport({required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (!constraints.hasBoundedHeight) return child;

      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: .new(minHeight: constraints.maxHeight),
          child: child,
        ),
      );
    },
  );
}

class const _ToolsEmptyContent({required final bool canAddNativeTools})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: AuraColumn(
      children: [
        const _ToolsEmptyIcon(),
        const _ToolsEmptyTitle(),
        _ToolsEmptyHint(canAddNativeTools: canAddNativeTools),
      ],
      spacing: .md,
      mainAxisSize: .min,
    ),
  );
}

class const _ToolsEmptyIcon() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Opacity(
    opacity: 0.5,
    child: AuraIcon(Icons.build_circle_outlined, size: .extraLarge),
  );
}

class const _ToolsEmptyTitle() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraText(
    child: TextLocale(LocaleKeys.tools_screen_no_tools_added),
    style: .heading6,
    textAlign: .center,
  );
}

class const _ToolsEmptyHint({required final bool canAddNativeTools})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: TextLocale(
      canAddNativeTools
          ? LocaleKeys.tools_screen_add_tools_hint
          : 'connection_setup.native_tools_restriction',
    ),
    style: .bodySmall,
    textAlign: .center,
  );
}
