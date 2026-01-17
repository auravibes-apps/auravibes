import 'package:flutter/material.dart';

// enum _DrawerAction { open, close }

enum _DrawerDragDirection { opening, closing }

class ResponsiveSlidingDrawerController {
  _ResponsiveSlidingDrawerState? _state;
  void open() => _state?._openDrawer();
  void close() => _state?._closeDrawer();
  void toggle() => _state?._toggleDrawer();
}

class ResponsiveSlidingDrawerProvider extends InheritedWidget {
  const ResponsiveSlidingDrawerProvider({
    required this.controller,
    required super.child,
    super.key,
  });

  final ResponsiveSlidingDrawerController controller;

  static ResponsiveSlidingDrawerController of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<ResponsiveSlidingDrawerProvider>();
    assert(
      provider != null,
      'No ResponsiveSlidingDrawerProvider found in context',
    );
    return provider!.controller;
  }

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

class ResponsiveSlidingDrawer extends StatefulWidget {
  const ResponsiveSlidingDrawer({
    required this.drawer,
    required this.body,
    required this.isDarkMode,
    this.animationDuration = const Duration(milliseconds: 250),
    this.openRatio = 0.80,
    this.desktopOpenRatio = 0.3,
    this.desktopMinDrawerWidth = 150.0,
    this.desktopMaxDrawerWidth = 400.0,
    this.swipeVelocityThreshold = 500.0,
    this.dragPercentageThreshold = 0.3,
    this.onAnimationComplete,
    this.onFinishedOpening,
    this.onFinishedClosing,
    this.onStartedOpening,
    this.onStartedClosing,
    this.dividerWidth = 5.0,
    this.centerDivider = true,
    this.controller,
    this.desktopDragAreaWidth = 10.0,
    this.scrimColorLightMode = Colors.black,
    this.scrimColorDarkMode = Colors.white,
    this.scrimColorOpacityLightMode = 0.36,
    this.scrimColorOpacityDarkMode = 0.38,
    this.scrimGradientStartOpacityLightMode = 0.14,
    this.scrimGradientStartOpacityDarkMode = 0.2,
    this.scrimGradientWidth = 16.0,
    super.key,
  });

  /// The widget to be displayed in the drawer panel.
  final Widget drawer;

  /// The main content widget that will be displayed alongside the drawer.
  final Widget body;

  /// The duration for the opening and closing animations of the drawer.
  final Duration animationDuration;

  /// The ratio of the screen width that the drawer should occupy when open
  /// on mobile devices. Defaults to 0.80 (80% of screen width).
  final double openRatio;

  /// The ratio of the screen width that the drawer should occupy when open
  /// on desktop devices. Defaults to 0.3 (30% of screen width).
  final double desktopOpenRatio;

  /// The minimum width the drawer can be resized to on desktop devices.
  final double desktopMinDrawerWidth;

  /// The maximum width the drawer can be resized to on desktop devices.
  final double desktopMaxDrawerWidth;

  /// The minimum swipe velocity required to trigger opening or closing
  /// the drawer.
  final double swipeVelocityThreshold;

  /// The percentage of the drawer width that needs to be dragged to trigger
  /// opening or closing after the drag ends.
  final double dragPercentageThreshold;

  /// A callback function that is invoked when the drawer finishes its opening
  /// or closing animation. Provides a boolean value indicating whether the
  /// drawer is now open (true) or closed (false).
  final void Function({required bool isOpen})? onAnimationComplete;

  /// Callback invoked when the drawer has fully finished opening.
  final VoidCallback? onFinishedOpening;

  /// Callback invoked when the drawer has fully finished closing.
  final VoidCallback? onFinishedClosing;

  /// Callback invoked when the drawer starts its opening animation or drag.
  final VoidCallback? onStartedOpening;

  /// Callback invoked when the drawer starts its closing animation or drag.
  final VoidCallback? onStartedClosing;

  /// The width of the draggable divider used for resizing on desktop.
  final double dividerWidth;

  /// Whether the desktop resize divider should be centered over the edge or
  /// placed entirely outside the drawer. If true, the divider is centered (half
  /// inside, half outside the drawer bounds). If false, the divider is placed
  /// entirely to the right of the drawer.
  final bool centerDivider;

  /// An optional controller to programmatically open, close, or toggle the
  /// drawer state.
  final ResponsiveSlidingDrawerController? controller;

  /// The width of the invisible area on the edge of the screen (or drawer edge
  /// when open) that triggers the drag gesture on desktop.
  final double desktopDragAreaWidth;

  /// The color of the scrim overlay that appears over the body when the drawer
  /// is open in light mode. This color will be adjusted with a dynamic opacity
  /// value to create an overlay over the main content.
  final Color scrimColorLightMode;

  /// The color of the scrim overlay that appears over the body when the drawer
  /// is open in dark mode. This color will be adjusted with a dynamic opacity
  /// value to create an overlay over the main content.
  final Color scrimColorDarkMode;

  /// The maximum opacity of the scrim overlay in light mode when the drawer is
  /// fully open.
  final double scrimColorOpacityLightMode;

  /// The maximum opacity of the scrim overlay in dark mode when the drawer is
  /// fully open.
  final double scrimColorOpacityDarkMode;

  /// The starting opacity of the gradient applied to the edge of the scrim
  /// overlay in light mode. This creates a subtle shadow effect.
  final double scrimGradientStartOpacityLightMode;

  /// The starting opacity of the gradient applied to the edge of the scrim
  /// overlay in dark mode. This creates a subtle shadow effect.
  final double scrimGradientStartOpacityDarkMode;

  /// The width of the gradient applied to the edge of the scrim overlay.
  final double scrimGradientWidth;

  /// A boolean flag indicating whether the application is currently in dark
  /// mode. This determines which scrim color and opacity settings are used.
  final bool isDarkMode;

  @override
  State<ResponsiveSlidingDrawer> createState() =>
      _ResponsiveSlidingDrawerState();
}

class _ResponsiveSlidingDrawerState extends State<ResponsiveSlidingDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double? _desktopDrawerWidth;
  double _resizeOvershoot = 0;
  bool _isHoveringDivider = false;
  bool _isResizing = false;

  bool _isOpen = false;

  bool? _dragStartedWhenOpen;
  _DrawerDragDirection? _dragDirection;

  bool _hasStartedDragCallback = false;

  bool get isDesktop => MediaQuery.of(context).size.width >= 600;

  @override
  void initState() {
    super.initState();
    _isOpen = false; // initially closed
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _controller.addListener(() => setState(() {}));
    widget.controller?._state = this;
  }

  @override
  void didUpdateWidget(covariant ResponsiveSlidingDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isDesktop) {
      final screenWidth = MediaQuery.of(context).size.width;
      _desktopDrawerWidth ??= widget.desktopOpenRatio * screenWidth;
      _desktopDrawerWidth = _desktopDrawerWidth!.clamp(
        widget.desktopMinDrawerWidth,
        widget.desktopMaxDrawerWidth,
      );
    }
  }

  void _toggleDrawer() {
    if (_isOpen) {
      _closeDrawer();
    } else {
      _openDrawer();
    }
  }

  void _handleDragStart(DragStartDetails details) {
    _dragStartedWhenOpen = _isOpen;
    _dragDirection = null;
    _hasStartedDragCallback = false;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isResizing) return;

    if (_dragDirection == null) {
      if (_dragStartedWhenOpen == false && details.primaryDelta! > 0) {
        _dragDirection = _DrawerDragDirection.opening;
        if (!_hasStartedDragCallback) {
          widget.onStartedOpening?.call();
          _hasStartedDragCallback = true;
        }
      } else if ((_dragStartedWhenOpen ?? false) && details.primaryDelta! < 0) {
        _dragDirection = _DrawerDragDirection.closing;
        if (!_hasStartedDragCallback) {
          widget.onStartedClosing?.call();
          _hasStartedDragCallback = true;
        }
      } else {
        return;
      }
    }
    final effectiveWidth = _currentDrawerWidth;
    final delta = details.primaryDelta! / effectiveWidth;
    _controller.value += delta;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isResizing || _dragDirection == null) return;
    final velocity = details.velocity.pixelsPerSecond.dx;
    if (velocity.abs() >= widget.swipeVelocityThreshold) {
      if (velocity > 0) {
        _openDrawer();
      } else {
        _closeDrawer();
      }
    } else {
      if (_controller.value >= widget.dragPercentageThreshold) {
        _openDrawer();
      } else {
        _closeDrawer();
      }
    }
    _dragStartedWhenOpen = null;
    _dragDirection = null;
    _hasStartedDragCallback = false;
  }

  void _openDrawer() {
    if (_dragDirection == null) {
      widget.onStartedOpening?.call();
    }
    if (_controller.value >= 1.0 - 0.001) {
      _isOpen = true;
      widget.onAnimationComplete?.call(isOpen: true);
      widget.onFinishedOpening?.call();
      return;
    }
    _controller.animateTo(1, duration: widget.animationDuration).then((_) {
      _isOpen = true;
      widget.onAnimationComplete?.call(isOpen: true);
      widget.onFinishedOpening?.call();
    });
  }

  void _closeDrawer() {
    // Only call onStartedClosing if not already triggered by a drag.
    if (_dragDirection == null) {
      widget.onStartedClosing?.call();
    }
    if (_controller.value <= 0.0 + 0.001) {
      _isOpen = false;
      widget.onAnimationComplete?.call(isOpen: false);
      widget.onFinishedClosing?.call();
      return;
    }
    _controller.animateTo(0, duration: widget.animationDuration).then((_) {
      _isOpen = false;
      widget.onAnimationComplete?.call(isOpen: false);
      widget.onFinishedClosing?.call();
    });
  }

  double get _currentDrawerWidth {
    final screenWidth = MediaQuery.of(context).size.width;
    return isDesktop
        ? (_desktopDrawerWidth ?? (widget.desktopOpenRatio * screenWidth))
        : widget.openRatio * screenWidth;
  }

  void _handleDividerPanUpdate(DragUpdateDetails details) {
    if (_controller.value < 0.99) return;
    final delta = details.delta.dx;
    final newWidth = _desktopDrawerWidth! + delta;
    if (_desktopDrawerWidth! >= widget.desktopMaxDrawerWidth && delta > 0) {
      _resizeOvershoot += delta;
    } else if (_desktopDrawerWidth! <= widget.desktopMinDrawerWidth &&
        delta < 0) {
      _resizeOvershoot += delta;
    } else {
      if (_resizeOvershoot != 0.0) {
        if ((_resizeOvershoot > 0 && delta < 0) ||
            (_resizeOvershoot < 0 && delta > 0)) {
          if (delta.abs() >= _resizeOvershoot.abs()) {
            final remaining = delta.abs() - _resizeOvershoot.abs();
            _resizeOvershoot = 0.0;
            _desktopDrawerWidth =
                (_desktopDrawerWidth! + (delta > 0 ? remaining : -remaining))
                    .clamp(
                      widget.desktopMinDrawerWidth,
                      widget.desktopMaxDrawerWidth,
                    );
          } else {
            _resizeOvershoot += delta;
          }
        } else {
          _resizeOvershoot += delta;
        }
      } else {
        _desktopDrawerWidth = newWidth.clamp(
          widget.desktopMinDrawerWidth,
          widget.desktopMaxDrawerWidth,
        );
      }
    }
    _desktopDrawerWidth = _desktopDrawerWidth!.clamp(
      widget.desktopMinDrawerWidth,
      widget.desktopMaxDrawerWidth,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final drawerWidth = _currentDrawerWidth;
    final drawerFullyOpen = _controller.value >= 1.0 - 0.001;
    final isDarkMode = widget.isDarkMode;

    final currentScrimColor = isDarkMode
        ? widget.scrimColorDarkMode
        : widget.scrimColorLightMode;
    final currentScrimOpacity = isDarkMode
        ? widget.scrimColorOpacityDarkMode
        : widget.scrimColorOpacityLightMode;
    final currentGradientStartOpacity = isDarkMode
        ? widget.scrimGradientStartOpacityDarkMode
        : widget.scrimGradientStartOpacityLightMode;

    final isMobile =
        TargetPlatform.android == Theme.of(context).platform ||
        TargetPlatform.iOS == Theme.of(context).platform;
    if (isDesktop) {
      return Stack(
        children: [
          // Main body that slides (no drag gestures here on desktop).
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final leftOffset = drawerWidth * _controller.value;
              return Positioned(
                left: leftOffset,
                top: 0,
                right: 0,
                bottom: 0,
                child: widget.body,
              );
            },
          ),
          // The drawer.
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final dx = -drawerWidth * (1 - _controller.value);
              return Transform.translate(
                offset: Offset(dx, 0),
                child: GestureDetector(
                  onHorizontalDragStart: _handleDragStart,
                  onHorizontalDragUpdate: _handleDragUpdate,
                  onHorizontalDragEnd: _handleDragEnd,
                  child: SizedBox(
                    width: drawerWidth,
                    height: MediaQuery.of(context).size.height,
                    child: widget.drawer,
                  ),
                ),
              );
            },
          ),
          // Desktop drag area (the only draggable region on desktop).
          Positioned(
            left: _controller.value < 0.5 ? 0 : drawerWidth,
            top: 0,
            bottom: 0,
            width: widget.desktopDragAreaWidth,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: _handleDragStart,
              onHorizontalDragUpdate: _handleDragUpdate,
              onHorizontalDragEnd: _handleDragEnd,
            ),
          ),
          if (drawerFullyOpen)
            Positioned(
              left: widget.centerDivider
                  ? drawerWidth - widget.dividerWidth / 2
                  : drawerWidth,
              top: 0,
              bottom: 0,
              width: widget.dividerWidth,
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHoveringDivider = true),
                onExit: (_) => setState(() => _isHoveringDivider = false),
                cursor: SystemMouseCursors.resizeColumn,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: (_isHoveringDivider || _resizeOvershoot != 0.0)
                      ? 1.0
                      : 0.0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (_) {
                      setState(() {
                        _isResizing = true;
                        _resizeOvershoot = 0.0;
                      });
                    },
                    onPanUpdate: _handleDividerPanUpdate,
                    onPanEnd: (_) {
                      setState(() {
                        _isResizing = false;
                        _resizeOvershoot = 0.0;
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      child: Container(
                        width: 4,
                        height: double.infinity,
                        color: const Color.fromARGB(255, 103, 103, 103),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    } else {
      // Mobile layout: The whole main area is draggable on Android and IOS but
      // not on other platforms.
      return Stack(
        children: [
          // Body + tap/drag area
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final dx = drawerWidth * _controller.value;
              return Transform.translate(
                offset: Offset(dx, 0),
                child: GestureDetector(
                  // Tapping the main area when the drawer is open should close
                  // it.
                  onTap: () {
                    if (drawerFullyOpen) _toggleDrawer();
                  },
                  onHorizontalDragStart: isMobile ? _handleDragStart : null,
                  onHorizontalDragUpdate: isMobile ? _handleDragUpdate : null,
                  onHorizontalDragEnd: isMobile ? _handleDragEnd : null,
                  child: widget.body,
                ),
              );
            },
          ),
          // Scrim + gradient overlay
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final dx = drawerWidth * _controller.value;
              return Transform.translate(
                offset: Offset(dx, 0),
                child: IgnorePointer(
                  ignoring: _controller.value == 0,
                  child: GestureDetector(
                    onTap: () {
                      if (drawerFullyOpen) _toggleDrawer();
                    },
                    onHorizontalDragStart: isMobile ? _handleDragStart : null,
                    onHorizontalDragUpdate: isMobile ? _handleDragUpdate : null,
                    onHorizontalDragEnd: isMobile ? _handleDragEnd : null,
                    child: Stack(
                      children: [
                        Container(
                          color: currentScrimColor.withValues(
                            alpha: currentScrimOpacity * _controller.value,
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: widget.scrimGradientWidth,
                          child: IgnorePointer(
                            child: isDarkMode
                                ? Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withValues(
                                            alpha:
                                                currentGradientStartOpacity *
                                                _controller.value,
                                          ),
                                          Colors.black.withValues(
                                            alpha:
                                                (currentGradientStartOpacity *
                                                    _controller.value) *
                                                0.5,
                                          ),
                                          Colors.black.withValues(
                                            alpha:
                                                (currentGradientStartOpacity *
                                                    _controller.value) *
                                                0.2,
                                          ),
                                          Colors.black.withValues(alpha: 0),
                                        ],
                                        stops: const [0.0, 0.2, 0.6, 1.0],
                                      ),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          currentScrimColor.withValues(
                                            alpha:
                                                currentGradientStartOpacity *
                                                _controller.value,
                                          ),
                                          currentScrimColor.withValues(
                                            alpha:
                                                (currentGradientStartOpacity *
                                                    _controller.value) *
                                                0.5,
                                          ),
                                          currentScrimColor.withValues(
                                            alpha:
                                                (currentGradientStartOpacity *
                                                    _controller.value) *
                                                0.2,
                                          ),
                                          currentScrimColor.withValues(
                                            alpha: 0,
                                          ),
                                        ],
                                        stops: const [0.0, 0.2, 0.6, 1.0],
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Drawer itself
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final dx = -drawerWidth * (1 - _controller.value);
              return Transform.translate(
                offset: Offset(dx, 0),
                child: GestureDetector(
                  onHorizontalDragStart: isMobile ? _handleDragStart : null,
                  onHorizontalDragUpdate: isMobile ? _handleDragUpdate : null,
                  onHorizontalDragEnd: isMobile ? _handleDragEnd : null,
                  child: SizedBox(
                    width: drawerWidth,
                    height: MediaQuery.of(context).size.height,
                    child: widget.drawer,
                  ),
                ),
              );
            },
          ),
        ],
      );
    }
  }

  @override
  void dispose() {
    widget.controller?._state = null;
    _controller.dispose();
    super.dispose();
  }
}
