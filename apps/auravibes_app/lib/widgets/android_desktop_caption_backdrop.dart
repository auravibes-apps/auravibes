import 'package:auravibes_app/widgets/responsive_shell_layout.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:material_ui/material_ui.dart';

/// Adds a contrasting backdrop behind Android desktop caption controls.
class const AndroidDesktopCaptionBackdrop({
  required final Widget child,
  super.key,
}) extends StatelessWidget {
  /// The 40dp cutoff may misclassify tall bars; use exact insets later.
  static bool shouldShow({
    required TargetPlatform platform,
    required double width,
    required double topInset,
  }) =>
      platform == TargetPlatform.android &&
      ResponsiveShellLayout.isDesktop(width) &&
      topInset >= 40;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    if (!shouldShow(
      platform: defaultTargetPlatform,
      width: MediaQuery.sizeOf(context).width,
      topInset: topInset,
    )) {
      return child;
    }

    return _AndroidCaptionBackdropSurface(
      topInset: topInset,
      captionColor: _captionColor(context),
      child: child,
    );
  }

  static Color _captionColor(BuildContext context) {
    final theme = Theme.of(context);

    return theme.brightness == Brightness.light
        ? theme.colorScheme.onSurface
        : theme.colorScheme.surface;
  }
}

class const _AndroidCaptionBackdropSurface({
  required final double topInset,
  required final Color captionColor,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(
        left: 0,
        top: 0,
        right: 0,
        height: topInset,
        child: IgnorePointer(child: ColoredBox(color: captionColor)),
      ),
      SafeArea(left: false, right: false, bottom: false, child: child),
    ],
  );
}
