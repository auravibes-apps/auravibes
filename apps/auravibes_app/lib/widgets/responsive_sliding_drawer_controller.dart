// ignore_for_file: no-magic-number
// Required: Existing thresholds and limits use numeric values.
// ignore_for_file: avoid-returning-widgets
// Required: Existing helper builders return widgets.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: no-empty-block
// Required: Animation listener uses empty setState to rebuild.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
// ignore_for_file: prefer-moving-to-variable
// Required: Existing code repeats lookups where extraction adds noise.
// ignore_for_file: prefer-single-widget-per-file
// Required: Feature widgets keep closely related private widgets together.

import 'package:flutter/material.dart';

enum _DrawerDragDirection { opening, closing }

class ResponsiveSlidingDrawerController {
  _ResponsiveSlidingDrawerState? _state;
  void open() => _state?._openDrawer();
  void close() => _state?._closeDrawer();
  void toggle() => _state?._toggleDrawer();
  bool get isDesktop => _state?.isDesktop ?? false;
  void closeIfMobile() {
    if (!isDesktop) {
      _state?._closeDrawer();
    }
  }
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
    if (provider == null) {
      throw FlutterError('No ResponsiveSlidingDrawerProvider found in context');
    }

    return provider.controller;
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
    required this.controller,
    this.animationDuration = const Duration(milliseconds: 250),
    this.openRatio = 0.8,
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
  final ResponsiveSlidingDrawerController controller;

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
  AnimationController? _controller;
  double? _desktopDrawerWidth;
  double _resizeOvershoot = 0;
  bool _isHoveringDivider = false;
  bool _isResizing = false;

  bool _isOpen = false;

  bool? _dragStartedWhenOpen;
  _DrawerDragDirection? _dragDirection;

  bool _hasStartedDragCallback = false;

  bool get isDesktop => MediaQuery.sizeOf(context).width >= 600;

  AnimationController get _requiredController {
    final controller = _controller;
    if (controller == null) {
      throw StateError('_controller is not initialized');
    }

    return controller;
  }

  double get _requiredDesktopDrawerWidth {
    final width = _desktopDrawerWidth;
    if (width == null) {
      throw StateError('Desktop drawer width is not initialized');
    }

    return width;
  }

  @override
  void initState() {
    super.initState();
    _isOpen = false; // Initially closed.
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _controller?.addListener(_handleControllerTick);
    widget.controller._state = this;
  }

  void _handleControllerTick() => setState(() {});

  @override
  void didUpdateWidget(covariant ResponsiveSlidingDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._state = null;
      widget.controller._state = this;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isDesktop) {
      final screenWidth = MediaQuery.sizeOf(context).width;
      _desktopDrawerWidth ??= widget.desktopOpenRatio * screenWidth;
      _desktopDrawerWidth = _requiredDesktopDrawerWidth.clamp(
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

  void _handleDragStart(DragStartDetails _) {
    _dragStartedWhenOpen = _isOpen;
    _dragDirection = null;
    _hasStartedDragCallback = false;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isResizing) return;
    final primaryDelta = details.primaryDelta;
    if (primaryDelta == null) return;

    if (_dragDirection == null) {
      if (_dragStartedWhenOpen == false && primaryDelta > 0) {
        _dragDirection = _DrawerDragDirection.opening;
        if (!_hasStartedDragCallback) {
          widget.onStartedOpening?.call();
          _hasStartedDragCallback = true;
        }
      } else if ((_dragStartedWhenOpen ?? false) && primaryDelta < 0) {
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
    final delta = primaryDelta / effectiveWidth;
    _requiredController.value += delta;
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
      if (_requiredController.value >= widget.dragPercentageThreshold) {
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
    if (_requiredController.value >= 1.0 - 0.001) {
      _isOpen = true;
      widget.onAnimationComplete?.call(isOpen: true);
      widget.onFinishedOpening?.call();

      return;
    }
    _requiredController.animateTo(1, duration: widget.animationDuration).then((
      _,
    ) {
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
    if (_requiredController.value <= 0.0 + 0.001) {
      _isOpen = false;
      widget.onAnimationComplete?.call(isOpen: false);
      widget.onFinishedClosing?.call();

      return;
    }
    _requiredController.animateTo(0, duration: widget.animationDuration).then((
      _,
    ) {
      _isOpen = false;
      widget.onAnimationComplete?.call(isOpen: false);
      widget.onFinishedClosing?.call();
    });
  }

  double get _currentDrawerWidth {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return isDesktop
        ? (_desktopDrawerWidth ?? (widget.desktopOpenRatio * screenWidth))
        : widget.openRatio * screenWidth;
  }

  void _handleDividerPanUpdate(DragUpdateDetails details) {
    if (_requiredController.value < 0.99) return;
    final delta = details.delta.dx;

    _applyDesktopResizeDelta(delta);
    _clampDesktopDrawerWidth();
    setState(() {});
  }

  void _applyDesktopResizeDelta(double delta) {
    if (_isResizeBeyondMax(delta) || _isResizeBeyondMin(delta)) {
      _resizeOvershoot += delta;

      return;
    }

    if (_resizeOvershoot == 0.0) {
      _desktopDrawerWidth = (_requiredDesktopDrawerWidth + delta).clamp(
        widget.desktopMinDrawerWidth,
        widget.desktopMaxDrawerWidth,
      );

      return;
    }

    _applyOvershootRecovery(delta);
  }

  bool _isResizeBeyondMax(double delta) {
    return _requiredDesktopDrawerWidth >= widget.desktopMaxDrawerWidth &&
        delta > 0;
  }

  bool _isResizeBeyondMin(double delta) {
    return _requiredDesktopDrawerWidth <= widget.desktopMinDrawerWidth &&
        delta < 0;
  }

  void _applyOvershootRecovery(double delta) {
    final reversingOvershoot =
        (_resizeOvershoot > 0 && delta < 0) ||
        (_resizeOvershoot < 0 && delta > 0);
    if (!reversingOvershoot) {
      _resizeOvershoot += delta;

      return;
    }

    if (delta.abs() < _resizeOvershoot.abs()) {
      _resizeOvershoot += delta;

      return;
    }

    final remaining = delta.abs() - _resizeOvershoot.abs();
    _resizeOvershoot = 0.0;
    _desktopDrawerWidth =
        (_requiredDesktopDrawerWidth + (delta > 0 ? remaining : -remaining))
            .clamp(
              widget.desktopMinDrawerWidth,
              widget.desktopMaxDrawerWidth,
            );
  }

  void _clampDesktopDrawerWidth() {
    _desktopDrawerWidth = _requiredDesktopDrawerWidth.clamp(
      widget.desktopMinDrawerWidth,
      widget.desktopMaxDrawerWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final drawerWidth = _currentDrawerWidth;
    final drawerFullyOpen = _requiredController.value >= 1.0 - 0.001;
    if (isDesktop) {
      return _buildDesktopLayout(drawerWidth, drawerFullyOpen);
    }

    return _buildMobileLayout(context, drawerWidth, drawerFullyOpen);
  }

  Widget _buildDesktopLayout(double drawerWidth, bool drawerFullyOpen) {
    return Stack(
      children: [
        _buildDesktopBody(drawerWidth),
        _buildDrawer(drawerWidth, enableGestures: true),
        _buildDesktopDragArea(drawerWidth),
        if (drawerFullyOpen) _buildResizeDivider(drawerWidth),
      ],
    );
  }

  Widget _buildDesktopBody(double drawerWidth) {
    return AnimatedBuilder(
      animation: _requiredController,
      builder: (context, child) {
        final leftOffset = drawerWidth * _requiredController.value;

        return Positioned(
          left: leftOffset,
          top: 0,
          right: 0,
          bottom: 0,
          child: widget.body,
        );
      },
    );
  }

  Widget _buildDrawer(double drawerWidth, {required bool enableGestures}) {
    return AnimatedBuilder(
      animation: _requiredController,
      builder: (context, child) {
        final dx = -drawerWidth * (1 - _requiredController.value);

        return Transform.translate(
          offset: Offset(dx, 0),
          child: GestureDetector(
            child: SizedBox(
              width: drawerWidth,
              height: MediaQuery.sizeOf(context).height,
              child: widget.drawer,
            ),
            onHorizontalDragStart: enableGestures ? _handleDragStart : null,
            onHorizontalDragUpdate: enableGestures ? _handleDragUpdate : null,
            onHorizontalDragEnd: enableGestures ? _handleDragEnd : null,
          ),
        );
      },
    );
  }

  Widget _buildDesktopDragArea(double drawerWidth) {
    return Positioned(
      left: _requiredController.value < 0.5 ? 0 : drawerWidth,
      top: 0,
      bottom: 0,
      width: widget.desktopDragAreaWidth,
      child: GestureDetector(
        onHorizontalDragStart: _handleDragStart,
        onHorizontalDragUpdate: _handleDragUpdate,
        onHorizontalDragEnd: _handleDragEnd,
        behavior: HitTestBehavior.opaque,
      ),
    );
  }

  Widget _buildResizeDivider(double drawerWidth) {
    return Positioned(
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
          child: GestureDetector(
            child: Center(
              child: Container(
                color: const Color.fromARGB(255, 103, 103, 103),
                width: 4,
                height: double.infinity,
              ),
            ),
            onPanStart: (_) => _setResizing(true),
            onPanUpdate: _handleDividerPanUpdate,
            onPanEnd: (_) => _setResizing(false),
            onPanCancel: () => _setResizing(false),
            behavior: HitTestBehavior.opaque,
          ),
          opacity: (_isHoveringDivider || _resizeOvershoot != 0.0) ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
        ),
      ),
    );
  }

  void _setResizing(bool value) {
    setState(() {
      _isResizing = value;
      _resizeOvershoot = 0.0;
    });
  }

  Widget _buildMobileLayout(
    BuildContext context,
    double drawerWidth,
    bool drawerFullyOpen,
  ) {
    final enableGestures = _isMobilePlatform(context);

    return Stack(
      children: [
        _buildMobileBody(drawerWidth, drawerFullyOpen, enableGestures),
        _buildScrimOverlay(drawerWidth, drawerFullyOpen, enableGestures),
        _buildDrawer(drawerWidth, enableGestures: enableGestures),
      ],
    );
  }

  bool _isMobilePlatform(BuildContext context) {
    final platform = Theme.of(context).platform;

    return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }

  Widget _buildMobileBody(
    double drawerWidth,
    bool drawerFullyOpen,
    bool enableGestures,
  ) {
    return AnimatedBuilder(
      animation: _requiredController,
      builder: (context, child) {
        final dx = drawerWidth * _requiredController.value;

        return Transform.translate(
          offset: Offset(dx, 0),
          child: GestureDetector(
            child: widget.body,
            onTap: () => _closeIfFullyOpen(drawerFullyOpen),
            onHorizontalDragStart: enableGestures ? _handleDragStart : null,
            onHorizontalDragUpdate: enableGestures ? _handleDragUpdate : null,
            onHorizontalDragEnd: enableGestures ? _handleDragEnd : null,
          ),
        );
      },
    );
  }

  Widget _buildScrimOverlay(
    double drawerWidth,
    bool drawerFullyOpen,
    bool enableGestures,
  ) {
    return AnimatedBuilder(
      animation: _requiredController,
      builder: (context, child) {
        final dx = drawerWidth * _requiredController.value;

        return Transform.translate(
          offset: Offset(dx, 0),
          child: IgnorePointer(
            ignoring: _requiredController.value == 0,
            child: GestureDetector(
              child: Stack(
                children: [
                  _buildScrimColor(),
                  _buildScrimGradient(),
                ],
              ),
              onTap: () => _closeIfFullyOpen(drawerFullyOpen),
              onHorizontalDragStart: enableGestures ? _handleDragStart : null,
              onHorizontalDragUpdate: enableGestures ? _handleDragUpdate : null,
              onHorizontalDragEnd: enableGestures ? _handleDragEnd : null,
            ),
          ),
        );
      },
    );
  }

  void _closeIfFullyOpen(bool drawerFullyOpen) {
    if (drawerFullyOpen) _closeDrawer();
  }

  Widget _buildScrimColor() {
    return Container(
      color: _scrimColor.withValues(
        alpha: _scrimOpacity * _requiredController.value,
      ),
    );
  }

  Widget _buildScrimGradient() {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      width: widget.scrimGradientWidth,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _scrimGradientColors,
              stops: const [0.0, 0.2, 0.6, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Color get _scrimColor {
    return widget.isDarkMode
        ? widget.scrimColorDarkMode
        : widget.scrimColorLightMode;
  }

  double get _scrimOpacity {
    return widget.isDarkMode
        ? widget.scrimColorOpacityDarkMode
        : widget.scrimColorOpacityLightMode;
  }

  double get _gradientStartOpacity {
    return widget.isDarkMode
        ? widget.scrimGradientStartOpacityDarkMode
        : widget.scrimGradientStartOpacityLightMode;
  }

  List<Color> get _scrimGradientColors {
    final color = widget.isDarkMode ? Colors.black : _scrimColor;
    final opacity = _gradientStartOpacity * _requiredController.value;

    return [
      color.withValues(alpha: opacity),
      color.withValues(alpha: opacity * 0.5),
      color.withValues(alpha: opacity * 0.2),
      color.withValues(alpha: 0),
    ];
  }

  @override
  void dispose() {
    widget.controller._state = null;
    _controller?.removeListener(_handleControllerTick);
    _controller?.dispose();
    super.dispose();
  }
}
