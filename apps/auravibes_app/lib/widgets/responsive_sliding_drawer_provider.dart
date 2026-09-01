import 'package:auravibes_app/widgets/responsive_sliding_drawer_controller.dart';
import 'package:flutter/widgets.dart';

/// Provides a responsive drawer controller to descendants.
class ResponsiveSlidingDrawerProvider extends InheritedWidget {
  /// Creates a responsive drawer provider.
  const new({required this.controller, required super.child, super.key});

  /// Drawer controller.
  final ResponsiveSlidingDrawerController controller;

  /// Finds the required drawer controller.
  static ResponsiveSlidingDrawerController of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<ResponsiveSlidingDrawerProvider>();
    assert(
      provider != null,
      'No ResponsiveSlidingDrawerProvider found in context',
    );
    if (provider == null) {
      throw FlutterError('No ResponsiveSlidingDrawerProvider found in context');
    }

    return provider.controller;
  }

  /// Finds an optional drawer controller.
  static ResponsiveSlidingDrawerController? maybeOf(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<ResponsiveSlidingDrawerProvider>();

    return provider?.controller;
  }

  @override
  bool updateShouldNotify(ResponsiveSlidingDrawerProvider oldWidget) {
    return controller != oldWidget.controller;
  }
}
