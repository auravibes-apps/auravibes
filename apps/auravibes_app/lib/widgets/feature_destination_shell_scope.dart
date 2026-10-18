import 'package:flutter/widgets.dart';

class const FeatureDestinationShellScope({
  required final bool isCompact,
  required final GlobalKey<NavigatorState> navigatorKey,
  required final GlobalKey<NavigatorState> parentNavigatorKey,
  required super.child,
  super.key,
}) extends InheritedWidget {
  static FeatureDestinationShellScope? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FeatureDestinationShellScope>();

  @override
  bool updateShouldNotify(FeatureDestinationShellScope oldWidget) =>
      isCompact != oldWidget.isCompact ||
      navigatorKey != oldWidget.navigatorKey ||
      parentNavigatorKey != oldWidget.parentNavigatorKey;
}

abstract final class FeatureDestinationShellLayout {
  static const masterDetailBreakpoint = 720.0;
  static const masterPaneWidth = 220.0;
}

class const FeatureDestinationStackPush({
  final String? returnLocation,
  final GlobalKey<NavigatorState>? sourceNavigatorKey,
  final GlobalKey<NavigatorState>? parentNavigatorKey,
});
