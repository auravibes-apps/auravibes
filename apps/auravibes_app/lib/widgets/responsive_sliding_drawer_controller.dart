// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.

// Required: Animation listener uses empty setState to rebuild.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
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
    super.key,
  });

  /// The widget to be displayed in the drawer panel.
  final Widget drawer;

  /// The main content widget that will be displayed alongside the drawer.
  final Widget body;

  /// An optional controller to programmatically open, close, or toggle the
  /// drawer state.
  final ResponsiveSlidingDrawerController controller;

  /// A boolean flag indicating whether the application is currently in dark
  /// mode. This determines which scrim color and opacity settings are used.
  final bool isDarkMode;

  @override
  State<ResponsiveSlidingDrawer> createState() =>
      _ResponsiveSlidingDrawerState();
}

class _ResponsiveSlidingDrawerState extends State<ResponsiveSlidingDrawer>
    with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 250);
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
  static const Color _scrimColorLightMode = DesignColors.neutral900;
  static const Color _scrimColorDarkMode = DesignColors.neutral50;
  static const _scrimColorOpacityLightMode = 0.36;
  static const _scrimColorOpacityDarkMode = 0.38;
  static const _scrimGradientStartOpacityLightMode = 0.14;
  static const _scrimGradientStartOpacityDarkMode = 0.2;
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

  @override
  void initState() {
    super.initState();
    _isOpen = false; // Initially closed.
    _controller = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );
    _controller?.addListener(_handleControllerTick);
    widget.controller._state = this;
  }

  void _handleControllerTick() => setState(() {
    final _ = Object();
  });

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
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isResizing) return;
    final primaryDelta = details.primaryDelta;
    if (primaryDelta == null) return;

    if (_dragDirection == null) {
      if (_dragStartedWhenOpen == false && primaryDelta > 0) {
        _dragDirection = _DrawerDragDirection.opening;
      } else if ((_dragStartedWhenOpen ?? false) && primaryDelta < 0) {
        _dragDirection = _DrawerDragDirection.closing;
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

  void _openDrawer() {
    if (_requiredController.value >= 1.0 - 0.001) {
      _isOpen = true;

      return;
    }
    _requiredController.animateTo(1, duration: _animationDuration).then((
      _,
    ) {
      _isOpen = true;
    });
  }

  void _closeDrawer() {
    if (_requiredController.value <= 0.0 + 0.001) {
      _isOpen = false;

      return;
    }
    _requiredController.animateTo(0, duration: _animationDuration).then((
      _,
    ) {
      _isOpen = false;
    });
  }

  double get _currentDrawerWidth {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return isDesktop
        ? (_desktopDrawerWidth ?? (_desktopOpenRatio * screenWidth))
        : _openRatio * screenWidth;
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
            .clamp(
              _desktopMinDrawerWidth,
              _desktopMaxDrawerWidth,
            );
  }

  void _clampDesktopDrawerWidth() {
    _desktopDrawerWidth = _requiredDesktopDrawerWidth.clamp(
      _desktopMinDrawerWidth,
      _desktopMaxDrawerWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final drawerWidth = _currentDrawerWidth;
    final drawerFullyOpen = _requiredController.value >= 1.0 - 0.001;
    if (isDesktop) {
      return _buildDesktopLayout(drawerWidth, drawerFullyOpen);
    }

    final enableGestures = _isMobilePlatform(context);

    return _buildMobileLayout(
      drawerWidth,
      drawerFullyOpen,
      enableGestures,
    );
  }

  Widget _buildDesktopLayout(
    double drawerWidth,
    bool drawerFullyOpen,
  ) {
    return Stack(
      children: [
        _buildDesktopBody(drawerWidth),
        _buildDesktopDrawer(drawerWidth),
        _buildDesktopDragArea(drawerWidth),
        if (drawerFullyOpen) _buildDesktopDivider(drawerWidth),
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

  Widget _buildDesktopDrawer(double drawerWidth) {
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
            onHorizontalDragStart: _handleDragStart,
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
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
      width: _desktopDragAreaWidth,
      child: GestureDetector(
        onHorizontalDragStart: _handleDragStart,
        onHorizontalDragUpdate: _handleDragUpdate,
        onHorizontalDragEnd: _handleDragEnd,
        behavior: HitTestBehavior.opaque,
      ),
    );
  }

  Widget _buildDesktopDivider(double drawerWidth) {
    final isDividerActive = _isHoveringDivider || _isResizing;
    final dividerColor = isDividerActive
        ? context.auraColors.primary
        : context.auraColors.outlineVariant;
    final resizeHandleTooltip = LocaleKeys
        .navigation_drawer_resize_handle_tooltip
        .tr(context: context);
    final resizeHandleHint = LocaleKeys.navigation_drawer_resize_handle_hint.tr(
      context: context,
    );

    return Positioned(
      left: drawerWidth - _dividerWidth / 2,
      top: 0,
      bottom: 0,
      width: _dividerWidth,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHoveringDivider = true),
        onExit: (_) => setState(() => _isHoveringDivider = false),
        cursor: SystemMouseCursors.resizeColumn,
        child: AuraTooltip(
          message: resizeHandleTooltip,
          child: Semantics(
            child: AnimatedOpacity(
              child: GestureDetector(
                child: SizedBox(
                  width: _dividerWidth,
                  child: Center(
                    child: Container(
                      color: dividerColor,
                      width: _dividerVisibleWidth,
                      height: double.infinity,
                    ),
                  ),
                ),
                onPanStart: (_) => _setResizing(true),
                onPanUpdate: _handleDividerPanUpdate,
                onPanEnd: (_) => _setResizing(false),
                onPanCancel: () => _setResizing(false),
                behavior: HitTestBehavior.opaque,
              ),
              opacity: (isDividerActive || _resizeOvershoot != 0.0)
                  ? 1.0
                  : _dividerIdleOpacity,
              duration: const Duration(milliseconds: 200),
            ),
            label: resizeHandleTooltip,
            hint: resizeHandleHint,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    double drawerWidth,
    bool drawerFullyOpen,
    bool enableGestures,
  ) {
    return Stack(
      children: [
        _buildMobileBody(drawerWidth, drawerFullyOpen, enableGestures),
        _buildMobileScrim(drawerWidth, drawerFullyOpen, enableGestures),
        _buildMobileDrawer(drawerWidth, enableGestures),
      ],
    );
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

  Widget _buildMobileScrim(
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
              child: _buildScrimContent(),
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

  Widget _buildScrimContent() {
    return Stack(
      children: [
        Container(
          color: _scrimColor.withValues(
            alpha: _scrimOpacity * _requiredController.value,
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: _scrimGradientWidth,
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
        ),
      ],
    );
  }

  Widget _buildMobileDrawer(double drawerWidth, bool enableGestures) {
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

  Color get _scrimColor {
    return widget.isDarkMode ? _scrimColorDarkMode : _scrimColorLightMode;
  }

  double get _scrimOpacity {
    return widget.isDarkMode
        ? _scrimColorOpacityDarkMode
        : _scrimColorOpacityLightMode;
  }

  double get _gradientStartOpacity {
    return widget.isDarkMode
        ? _scrimGradientStartOpacityDarkMode
        : _scrimGradientStartOpacityLightMode;
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
