// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Layout helpers return widgets to isolate desktop/mobile branches.

// Required: Animation listener uses empty setState to rebuild.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

export 'responsive_sliding_drawer_provider.dart';

enum _DrawerDragDirection { opening, closing }

class ResponsiveSlidingDrawerController {
  _ResponsiveSlidingDrawerState? _state;
  bool get isDesktop => _state?.isDesktop ?? false;
  void open() => _state?._openDrawer();
  void close() => _state?._closeDrawer();
  void toggle() => _state?._toggleDrawer();
  void closeIfMobile() {
    if (!isDesktop) {
      _state?._closeDrawer();
    }
  }
}

class const ResponsiveSlidingDrawer({
  /// The widget to be displayed in the drawer panel.
  required final Widget drawer,

  /// The main content widget that will be displayed alongside the drawer.
  required final Widget body,

  /// A boolean flag indicating whether the application is currently in dark
  /// mode. This determines which scrim color and opacity settings are used.
  required final bool isDarkMode,

  /// An optional controller to programmatically open, close, or toggle the
  /// drawer state.
  required final ResponsiveSlidingDrawerController controller,
  super.key,
}) extends StatefulWidget {
  @override
  State<ResponsiveSlidingDrawer> createState() =>
      _ResponsiveSlidingDrawerState();
}

class _ResponsiveSlidingDrawerState extends State<ResponsiveSlidingDrawer>
    with SingleTickerProviderStateMixin {
  static const _scrimGradientStartOpacityDarkMode = 0.2;
  static const _openRatio = 0.8;
  static const _desktopOpenRatio = 0.3;
  static const _desktopMinDrawerWidth = 150.0;
  static const _desktopMaxDrawerWidth = 400.0;
  static const _swipeVelocityThreshold = 500.0;
  static const _dragPercentageThreshold = 0.3;
  static const _dividerWidth = 5.0;
  static const _dividerVisibleWidth = 4.0;
  static const _dividerIdleOpacity = 0.45;
  static const _desktopDragAreaWidth = 10.0;
  static const _desktopDragAreaMidpoint = 0.5;
  static const _gradientMiddleOpacity = 0.5;
  static const _gradientTrailingOpacity = 0.2;
  static const Color _scrimColorLightMode = DesignColors.neutral900;
  static const Color _scrimColorDarkMode = DesignColors.neutral50;
  static const _scrimColorOpacityLightMode = 0.36;
  static const _scrimColorOpacityDarkMode = 0.38;
  static const _scrimGradientStartOpacityLightMode = 0.14;
  static const _animationDuration = Duration(milliseconds: 250);
  static const _scrimGradientWidth = 16.0;

  AnimationController? _controller;
  double? _desktopDrawerWidth;
  double _resizeOvershoot = 0;
  bool _isHoveringDivider = false;
  bool _isResizing = false;

  bool _isOpen = false;

  bool? _dragStartedWhenOpen;
  _DrawerDragDirection? _dragDirection;

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

  double get _gradientStartOpacity {
    return widget.isDarkMode
        ? _scrimGradientStartOpacityDarkMode
        : _scrimGradientStartOpacityLightMode;
  }

  double get _scrimOpacity {
    return widget.isDarkMode
        ? _scrimColorOpacityDarkMode
        : _scrimColorOpacityLightMode;
  }

  Color get _scrimColor {
    return widget.isDarkMode ? _scrimColorDarkMode : _scrimColorLightMode;
  }

  double get _currentDrawerWidth {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return isDesktop
        ? (_desktopDrawerWidth ?? (_desktopOpenRatio * screenWidth))
        : _openRatio * screenWidth;
  }

  @override
  void initState() {
    super.initState();
    _isOpen = false; // Initially closed.
    _controller = .new(duration: _animationDuration, vsync: this);
    _controller?.addListener(_handleControllerTick);
    widget.controller._state = this;
  }

  @override
  void dispose() {
    widget.controller._state = null;
    _controller?.removeListener(_handleControllerTick);
    _controller?.dispose();
    super.dispose();
  }

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
      _desktopDrawerWidth ??= _desktopOpenRatio * screenWidth;
      _desktopDrawerWidth = _requiredDesktopDrawerWidth.clamp(
        _desktopMinDrawerWidth,
        _desktopMaxDrawerWidth,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final drawerWidth = _currentDrawerWidth;
    final drawerFullyOpen = _requiredController.value >= 1.0 - 0.001;
    if (isDesktop) {
      return _DesktopDrawerLayout(
        animation: _requiredController,
        drawer: widget.drawer,
        body: widget.body,
        drawerWidth: drawerWidth,
        drawerFullyOpen: drawerFullyOpen,
        isHoveringDivider: _isHoveringDivider,
        isResizing: _isResizing,
        resizeOvershoot: _resizeOvershoot,
        onDragStart: _handleDragStart,
        onDragUpdate: _handleDragUpdate,
        onDragEnd: _handleDragEnd,
        onDividerHover: (value) => setState(() => _isHoveringDivider = value),
        onStartResizing: () => _setResizing(true),
        onStopResizing: () => _setResizing(false),
        onDividerPanUpdate: _handleDividerPanUpdate,
      );
    }

    final enableGestures = _isMobilePlatform(context);

    return _MobileDrawerLayout(
      animation: _requiredController,
      drawer: widget.drawer,
      body: widget.body,
      drawerWidth: drawerWidth,
      drawerFullyOpen: drawerFullyOpen,
      isDarkMode: widget.isDarkMode,
      scrimColor: _scrimColor,
      scrimOpacity: _scrimOpacity,
      gradientStartOpacity: _gradientStartOpacity,
      onClose: () => _closeIfFullyOpen(drawerFullyOpen),
      onDragStart: enableGestures ? _handleDragStart : null,
      onDragUpdate: enableGestures ? _handleDragUpdate : null,
      onDragEnd: enableGestures ? _handleDragEnd : null,
    );
  }

  void _closeDrawer() {
    const settledThreshold = 0.001;
    if (settledThreshold >= _requiredController.value) {
      _isOpen = false;

      return;
    }
    _requiredController.animateTo(0, duration: _animationDuration).then((_) {
      _isOpen = false;
    });
  }

  void _openDrawer() {
    const settledThreshold = 0.001;
    if (_requiredController.value >= 1.0 - settledThreshold) {
      _isOpen = true;

      return;
    }
    _requiredController.animateTo(1, duration: _animationDuration).then((_) {
      _isOpen = true;
    });
  }

  void _handleDividerPanUpdate(DragUpdateDetails details) {
    if (_requiredController.value < 0.99) return;
    final delta = details.delta.dx;

    _applyDesktopResizeDelta(delta);
    _clampDesktopDrawerWidth();
    setState(() {
      final _ = Object();
    });
  }

  void _applyDesktopResizeDelta(double delta) {
    if (_isResizeBeyondMax(delta) || _isResizeBeyondMin(delta)) {
      _resizeOvershoot += delta;

      return;
    }

    if (_resizeOvershoot == 0.0) {
      _desktopDrawerWidth = (_requiredDesktopDrawerWidth + delta).clamp(
        _desktopMinDrawerWidth,
        _desktopMaxDrawerWidth,
      );

      return;
    }

    _applyOvershootRecovery(delta);
  }

  bool _isResizeBeyondMax(double delta) {
    return _requiredDesktopDrawerWidth >= _desktopMaxDrawerWidth && delta > 0;
  }

  bool _isResizeBeyondMin(double delta) {
    return _requiredDesktopDrawerWidth <= _desktopMinDrawerWidth && delta < 0;
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
            .clamp(_desktopMinDrawerWidth, _desktopMaxDrawerWidth);
  }

  void _clampDesktopDrawerWidth() {
    _desktopDrawerWidth = _requiredDesktopDrawerWidth.clamp(
      _desktopMinDrawerWidth,
      _desktopMaxDrawerWidth,
    );
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isResizing || _dragDirection == null) return;
    final velocity = details.velocity.pixelsPerSecond.dx;
    if (velocity.abs() >= _swipeVelocityThreshold) {
      if (velocity > 0) {
        _openDrawer();
      } else {
        _closeDrawer();
      }
    } else {
      if (_requiredController.value >= _dragPercentageThreshold) {
        _openDrawer();
      } else {
        _closeDrawer();
      }
    }
    _dragStartedWhenOpen = null;
    _dragDirection = null;
  }

  void _setResizing(bool value) {
    setState(() {
      _isResizing = value;
      _resizeOvershoot = 0.0;
    });
  }

  bool _isMobilePlatform(BuildContext context) {
    final platform = Theme.of(context).platform;

    return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }

  void _closeIfFullyOpen(bool drawerFullyOpen) {
    if (drawerFullyOpen) _closeDrawer();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isResizing) return;
    final primaryDelta = details.primaryDelta;
    if (primaryDelta == null) return;

    if (_dragDirection == null) {
      if (_dragStartedWhenOpen == false && primaryDelta > 0) {
        _dragDirection = .opening;
      } else if ((_dragStartedWhenOpen ?? false) && primaryDelta < 0) {
        _dragDirection = .closing;
      } else {
        return;
      }
    }
    final effectiveWidth = _currentDrawerWidth;
    final delta = primaryDelta / effectiveWidth;
    _requiredController.value += delta;
  }

  void _toggleDrawer() {
    if (_isOpen) {
      _closeDrawer();
    } else {
      _openDrawer();
    }
  }

  void _handleControllerTick() => setState(() {
    final _ = Object();
  });

  void _handleDragStart(DragStartDetails _) {
    _dragStartedWhenOpen = _isOpen;
    _dragDirection = null;
  }
}

class const _DesktopDrawerLayout({
  required final Animation<double> animation,
  required final Widget drawer,
  required final Widget body,
  required final double drawerWidth,
  required final bool drawerFullyOpen,
  required final bool isHoveringDivider,
  required final bool isResizing,
  required final double resizeOvershoot,
  required final GestureDragStartCallback onDragStart,
  required final GestureDragUpdateCallback onDragUpdate,
  required final GestureDragEndCallback onDragEnd,
  required final ValueChanged<bool> onDividerHover,
  required final VoidCallback onStartResizing,
  required final VoidCallback onStopResizing,
  required final GestureDragUpdateCallback onDividerPanUpdate,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final leftOffset = drawerWidth * animation.value;

            return Positioned(
              left: leftOffset,
              top: 0,
              right: 0,
              bottom: 0,
              child: body,
            );
          },
        ),
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final dx = -drawerWidth * (1 - animation.value);

            return Transform.translate(
              offset: .new(dx, 0),
              child: GestureDetector(
                child: SizedBox(
                  width: drawerWidth,
                  height: MediaQuery.sizeOf(context).height,
                  child: FocusScope(
                    child: drawer,
                    canRequestFocus: drawerFullyOpen,
                    descendantsAreFocusable: drawerFullyOpen,
                    descendantsAreTraversable: drawerFullyOpen,
                  ),
                ),
                onHorizontalDragStart: onDragStart,
                onHorizontalDragUpdate: onDragUpdate,
                onHorizontalDragEnd: onDragEnd,
              ),
            );
          },
        ),
        Positioned(
          left:
              animation.value <
                  _ResponsiveSlidingDrawerState._desktopDragAreaMidpoint
              ? 0
              : drawerWidth,
          top: 0,
          bottom: 0,
          width: _ResponsiveSlidingDrawerState._desktopDragAreaWidth,
          child: GestureDetector(
            onHorizontalDragStart: onDragStart,
            onHorizontalDragUpdate: onDragUpdate,
            onHorizontalDragEnd: onDragEnd,
            behavior: .opaque,
          ),
        ),
        if (drawerFullyOpen)
          Positioned(
            left: drawerWidth - _ResponsiveSlidingDrawerState._dividerWidth / 2,
            top: 0,
            bottom: 0,
            width: _ResponsiveSlidingDrawerState._dividerWidth,
            child: MouseRegion(
              onEnter: (_) => onDividerHover(true),
              onExit: (_) => onDividerHover(false),
              cursor: SystemMouseCursors.resizeColumn,
              child: AuraTooltip(
                message: LocaleKeys.navigation_drawer_resize_handle_tooltip.tr(
                  context: context,
                ),
                child: Semantics(
                  child: AnimatedOpacity(
                    child: GestureDetector(
                      child: SizedBox(
                        width: _ResponsiveSlidingDrawerState._dividerWidth,
                        child: Center(
                          child: Container(
                            color: isHoveringDivider || isResizing
                                ? context.auraColors.primary
                                : context.auraColors.outlineVariant,
                            width: _ResponsiveSlidingDrawerState
                                ._dividerVisibleWidth,
                            height: .infinity,
                          ),
                        ),
                      ),
                      onPanStart: (_) => onStartResizing(),
                      onPanUpdate: onDividerPanUpdate,
                      onPanEnd: (_) => onStopResizing(),
                      onPanCancel: onStopResizing,
                      behavior: .opaque,
                    ),
                    opacity:
                        isHoveringDivider ||
                            isResizing ||
                            resizeOvershoot != 0.0
                        ? 1.0
                        : _ResponsiveSlidingDrawerState._dividerIdleOpacity,
                    duration: const Duration(milliseconds: 200),
                  ),
                  label: LocaleKeys.navigation_drawer_resize_handle_tooltip.tr(
                    context: context,
                  ),
                  hint: LocaleKeys.navigation_drawer_resize_handle_hint.tr(
                    context: context,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class const _MobileDrawerLayout({
  required final Animation<double> animation,
  required final Widget drawer,
  required final Widget body,
  required final double drawerWidth,
  required final bool drawerFullyOpen,
  required final bool isDarkMode,
  required final Color scrimColor,
  required final double scrimOpacity,
  required final double gradientStartOpacity,
  required final VoidCallback onClose,
  required final GestureDragStartCallback? onDragStart,
  required final GestureDragUpdateCallback? onDragUpdate,
  required final GestureDragEndCallback? onDragEnd,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final dx = drawerWidth * animation.value;

            return Transform.translate(
              offset: .new(dx, 0),
              child: GestureDetector(
                child: body,
                onTap: onClose,
                onHorizontalDragStart: onDragStart,
                onHorizontalDragUpdate: onDragUpdate,
                onHorizontalDragEnd: onDragEnd,
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final dx = drawerWidth * animation.value;
            final gradientOpacity = gradientStartOpacity * animation.value;
            final gradientColor = isDarkMode ? Colors.black : scrimColor;

            return Transform.translate(
              offset: .new(dx, 0),
              child: IgnorePointer(
                ignoring: animation.value == 0,
                child: GestureDetector(
                  child: Stack(
                    children: [
                      Container(
                        color: scrimColor.withValues(
                          alpha: scrimOpacity * animation.value,
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width:
                            _ResponsiveSlidingDrawerState._scrimGradientWidth,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  gradientColor.withValues(
                                    alpha: gradientOpacity,
                                  ),
                                  gradientColor.withValues(
                                    alpha:
                                        gradientOpacity *
                                        _ResponsiveSlidingDrawerState
                                            ._gradientMiddleOpacity,
                                  ),
                                  gradientColor.withValues(
                                    alpha:
                                        gradientOpacity *
                                        _ResponsiveSlidingDrawerState
                                            ._gradientTrailingOpacity,
                                  ),
                                  gradientColor.withValues(alpha: 0),
                                ],
                                stops: const [0.0, 0.2, 0.6, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: onClose,
                  onHorizontalDragStart: onDragStart,
                  onHorizontalDragUpdate: onDragUpdate,
                  onHorizontalDragEnd: onDragEnd,
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final dx = -drawerWidth * (1 - animation.value);

            return Transform.translate(
              offset: .new(dx, 0),
              child: GestureDetector(
                child: SizedBox(
                  width: drawerWidth,
                  height: MediaQuery.sizeOf(context).height,
                  child: FocusScope(
                    child: drawer,
                    canRequestFocus: drawerFullyOpen,
                    descendantsAreFocusable: drawerFullyOpen,
                    descendantsAreTraversable: drawerFullyOpen,
                  ),
                ),
                onHorizontalDragStart: onDragStart,
                onHorizontalDragUpdate: onDragUpdate,
                onHorizontalDragEnd: onDragEnd,
              ),
            );
          },
        ),
      ],
    );
  }
}
