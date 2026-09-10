import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// App bar following the Aura design system.
class AuraAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates an Aura app bar.
  const new({super.key, this.title, this.actions, this.bottom, this.leading});

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
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Widget?>('title', title));
  }

  @override
  Widget build(BuildContext context) => _AuraAppBarContent(appBar: this).child;
}

class _AuraAppBarContent {
  _AuraAppBarContent({required AuraAppBar appBar})
    : child = AppBar(
        leading: appBar.leading,
        title: appBar.title == null
            ? null
            : DefaultTextStyle.merge(
                softWrap: false,
                overflow: .ellipsis,
                maxLines: 1,
                child: AuraText(child: appBar.title!, style: .heading5),
              ),
        actions: appBar.actions,
        bottom: appBar.bottom,
        elevation: 0,
        backgroundColor: DesignColors.transparent,
        centerTitle: true,
      );

  final Widget child;
}
