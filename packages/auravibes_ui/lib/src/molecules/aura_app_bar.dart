import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// App bar following the Aura design system.
class AuraAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates an Aura app bar.
  const AuraAppBar({
    super.key,
    this.title,
    this.actions,
    this.bottom,
    this.leading,
  });

  /// Title.
  final Widget? title;

  /// Actions.
  final List<Widget>? actions;

  /// Bottom of bar.
  final PreferredSizeWidget? bottom;

  /// Optional custom leading widget.
  final Widget? leading;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final title = this.title;

    return AppBar(
      leading: leading,
      title: title == null
          ? null
          : DefaultTextStyle.merge(
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              child: AuraText(child: title, style: AuraTextStyle.heading5),
            ),
      actions: actions,
      bottom: bottom,
      elevation: 0,
      backgroundColor: DesignColors.transparent,
      centerTitle: true,
    );
  }
}
