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

typedef _MobileDragCallbacks = ({
  GestureDragStartCallback? onDragStart,
  GestureDragUpdateCallback? onDragUpdate,
  GestureDragEndCallback? onDragEnd,
});

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
  static const _drawerFullyOpenThreshold = 0.001;
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
  Widget build(BuildContext context) => isDesktop
      ? _DesktopDrawerLayout(state: this)
      : _MobileDrawerLayout(state: this);

  void _rebuild(VoidCallback callback) => setState(callback);
}

extension _ResponsiveSlidingDrawerAppearance on _ResponsiveSlidingDrawerState {
  double get _gradientStartOpacity => widget.isDarkMode
      ? _ResponsiveSlidingDrawerState._scrimGradientStartOpacityDarkMode
      : _ResponsiveSlidingDrawerState._scrimGradientStartOpacityLightMode;

  double get _scrimOpacity => widget.isDarkMode
      ? _ResponsiveSlidingDrawerState._scrimColorOpacityDarkMode
      : _ResponsiveSlidingDrawerState._scrimColorOpacityLightMode;

  Color get _scrimColor => widget.isDarkMode
      ? _ResponsiveSlidingDrawerState._scrimColorDarkMode
      : _ResponsiveSlidingDrawerState._scrimColorLightMode;

  double get _currentDrawerWidth {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return isDesktop
        ? (_desktopDrawerWidth ??
              (_ResponsiveSlidingDrawerState._desktopOpenRatio * screenWidth))
        : _ResponsiveSlidingDrawerState._openRatio * screenWidth;
  }

  bool get _drawerFullyOpen =>
      _requiredController.value >=
      1.0 - _ResponsiveSlidingDrawerState._drawerFullyOpenThreshold;

  bool get _isDividerHighlighted =>
      _isHoveringDivider || _isResizing || _resizeOvershoot != 0.0;
}

extension _ResponsiveSlidingDrawerAnimation on _ResponsiveSlidingDrawerState {
  void _closeDrawer() {
    const settledThreshold = 0.001;
    if (settledThreshold >= _requiredController.value) {
      _isOpen = false;

      return;
    }
    _requiredController
        .animateTo(
          0,
          duration: _ResponsiveSlidingDrawerState._animationDuration,
        )
        .then((_) {
          _isOpen = false;
        });
  }

  void _openDrawer() {
    const settledThreshold = 0.001;
    if (_requiredController.value >= 1.0 - settledThreshold) {
      _isOpen = true;

      return;
    }
    _requiredController
        .animateTo(
          1,
          duration: _ResponsiveSlidingDrawerState._animationDuration,
        )
        .then((_) {
          _isOpen = true;
        });
  }

  void _toggleDrawer() {
    if (_isOpen) {
      _closeDrawer();
    } else {
      _openDrawer();
    }
  }

  void _handleControllerTick() => _rebuild(() {
    final _ = Object();
  });
}

extension _ResponsiveSlidingDrawerResize on _ResponsiveSlidingDrawerState {
  void _handleDividerPanUpdate(DragUpdateDetails details) {
    if (_requiredController.value < 0.99) return;
    final delta = details.delta.dx;

    _applyDesktopResizeDelta(delta);
    _clampDesktopDrawerWidth();
    _rebuild(() {
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
        _ResponsiveSlidingDrawerState._desktopMinDrawerWidth,
        _ResponsiveSlidingDrawerState._desktopMaxDrawerWidth,
      );

      return;
    }

    _applyOvershootRecovery(delta);
  }

  bool _isResizeBeyondMax(double delta) =>
      _requiredDesktopDrawerWidth >=
          _ResponsiveSlidingDrawerState._desktopMaxDrawerWidth &&
      delta > 0;

  bool _isResizeBeyondMin(double delta) =>
      _requiredDesktopDrawerWidth <=
          _ResponsiveSlidingDrawerState._desktopMinDrawerWidth &&
      delta < 0;

  void _applyOvershootRecovery(double delta) {
    if (!_isReversingOvershoot(delta)) {
      _resizeOvershoot += delta;

      return;
    }

    if (_isDeltaWithinOvershoot(delta)) {
      _resizeOvershoot += delta;

      return;
    }

    _applyRemainingResize(delta);
  }

  bool _isReversingOvershoot(double delta) =>
      (_resizeOvershoot > 0 && delta < 0) ||
      (_resizeOvershoot < 0 && delta > 0);

  bool _isDeltaWithinOvershoot(double delta) =>
      delta.abs() < _resizeOvershoot.abs();
}

extension _ResponsiveSlidingDrawerResizeBounds
    on _ResponsiveSlidingDrawerState {
  void _applyRemainingResize(double delta) {
    final remaining = delta.abs() - _resizeOvershoot.abs();
    _resizeOvershoot = 0.0;
    final direction = delta > 0 ? remaining : -remaining;
    _desktopDrawerWidth = (_requiredDesktopDrawerWidth + direction).clamp(
      _ResponsiveSlidingDrawerState._desktopMinDrawerWidth,
      _ResponsiveSlidingDrawerState._desktopMaxDrawerWidth,
    );
  }

  void _clampDesktopDrawerWidth() {
    _desktopDrawerWidth = _requiredDesktopDrawerWidth.clamp(
      _ResponsiveSlidingDrawerState._desktopMinDrawerWidth,
      _ResponsiveSlidingDrawerState._desktopMaxDrawerWidth,
    );
  }

  void _setResizing(bool value) {
    _rebuild(() {
      _isResizing = value;
      _resizeOvershoot = 0.0;
    });
  }

  void _setDividerHover(bool value) =>
      _rebuild(() => _isHoveringDivider = value);
}

extension _ResponsiveSlidingDrawerDrag on _ResponsiveSlidingDrawerState {
  void _handleDragEnd(DragEndDetails details) {
    if (_isResizing || _dragDirection == null) return;
    final velocity = details.velocity.pixelsPerSecond.dx;
    _settleDrag(velocity);
    _resetDrag();
  }

  void _settleDrag(double velocity) {
    if (velocity.abs() >=
        _ResponsiveSlidingDrawerState._swipeVelocityThreshold) {
      _settleByVelocity(velocity);

      return;
    }

    _settleByProgress();
  }

  void _settleByVelocity(double velocity) {
    if (velocity > 0) {
      _openDrawer();
    } else {
      _closeDrawer();
    }
  }

  void _settleByProgress() {
    if (_requiredController.value >=
        _ResponsiveSlidingDrawerState._dragPercentageThreshold) {
      _openDrawer();
    } else {
      _closeDrawer();
    }
  }

  void _resetDrag() {
    _dragStartedWhenOpen = null;
    _dragDirection = null;
  }
}

extension _ResponsiveSlidingDrawerGesture on _ResponsiveSlidingDrawerState {
  bool _isMobilePlatform(BuildContext context) {
    final platform = Theme.of(context).platform;

    return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }

  _MobileDragCallbacks _mobileDragCallbacks(BuildContext context) {
    if (!_isMobilePlatform(context)) {
      return (onDragStart: null, onDragUpdate: null, onDragEnd: null);
    }

    return (
      onDragStart: _handleDragStart,
      onDragUpdate: _handleDragUpdate,
      onDragEnd: _handleDragEnd,
    );
  }

  void _closeIfFullyOpen(bool drawerFullyOpen) {
    if (drawerFullyOpen) _closeDrawer();
  }

  void _closeIfFullyOpenCurrent() => _closeIfFullyOpen(_drawerFullyOpen);

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isResizing) return;
    final primaryDelta = details.primaryDelta;
    if (primaryDelta == null) return;

    if (!_updateDragDirection(primaryDelta)) return;
    final effectiveWidth = _currentDrawerWidth;
    final delta = primaryDelta / effectiveWidth;
    _requiredController.value += delta;
  }

  bool _updateDragDirection(double primaryDelta) {
    if (_dragDirection != null) return true;

    final direction = _dragDirectionFor(primaryDelta);
    if (direction == null) return false;
    _dragDirection = direction;

    return true;
  }

  _DrawerDragDirection? _dragDirectionFor(double primaryDelta) {
    if (_dragStartedWhenOpen == false && primaryDelta > 0) {
      return .opening;
    }

    if ((_dragStartedWhenOpen ?? false) && primaryDelta < 0) {
      return .closing;
    }

    return null;
  }

  void _handleDragStart(DragStartDetails _) {
    _dragStartedWhenOpen = _isOpen;
    _dragDirection = null;
  }
}

class const _DesktopDrawerLayout({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      _DesktopDrawerBody(state: state),
      _DesktopDrawerPanel(state: state),
      _DesktopDrawerDragArea(state: state),
      if (state._drawerFullyOpen) _DesktopDrawerDivider(state: state),
    ],
  );
}

class const _DesktopDrawerBody({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state._requiredController,
    builder: (context, _) => _DesktopBodyPosition(state: state),
  );
}

class const _DesktopBodyPosition({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final animation = state._requiredController;
    final drawerWidth = state._currentDrawerWidth;

    return Positioned(
      left: drawerWidth * animation.value,
      top: 0,
      right: 0,
      bottom: 0,
      child: state.widget.body,
    );
  }
}

class const _DesktopDrawerPanel({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state._requiredController,
    builder: (context, _) => _DesktopPanelPosition(state: state),
  );
}

class const _DesktopPanelPosition({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final animation = state._requiredController;
    final drawerWidth = state._currentDrawerWidth;

    return Transform.translate(
      offset: .new(-drawerWidth * (1 - animation.value), 0),
      child: _DrawerPanelGesture(state: state),
    );
  }
}

class const _DrawerPanelGesture({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    child: _DrawerFocusBox(state: state),
    onHorizontalDragStart: state._handleDragStart,
    onHorizontalDragUpdate: state._handleDragUpdate,
    onHorizontalDragEnd: state._handleDragEnd,
  );
}

class const _DrawerFocusBox({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final drawerFullyOpen = state._drawerFullyOpen;

    return SizedBox(
      width: state._currentDrawerWidth,
      height: MediaQuery.sizeOf(context).height,
      child: FocusScope(
        child: state.widget.drawer,
        canRequestFocus: drawerFullyOpen,
        descendantsAreFocusable: drawerFullyOpen,
        descendantsAreTraversable: drawerFullyOpen,
      ),
    );
  }
}

class const _DesktopDrawerDragArea({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state._requiredController,
    builder: (context, _) => _DesktopDragAreaPosition(state: state),
  );
}

class const _DesktopDragAreaPosition({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  double get _left =>
      state._requiredController.value <
          _ResponsiveSlidingDrawerState._desktopDragAreaMidpoint
      ? 0
      : state._currentDrawerWidth;

  @override
  Widget build(BuildContext context) => Positioned(
    left: _left,
    top: 0,
    bottom: 0,
    width: _ResponsiveSlidingDrawerState._desktopDragAreaWidth,
    child: _DesktopDragAreaGesture(state: state),
  );
}

class const _DesktopDragAreaGesture({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onHorizontalDragStart: state._handleDragStart,
    onHorizontalDragUpdate: state._handleDragUpdate,
    onHorizontalDragEnd: state._handleDragEnd,
    behavior: .opaque,
  );
}

class const _DesktopDrawerDivider({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Positioned(
    left:
        state._currentDrawerWidth -
        _ResponsiveSlidingDrawerState._dividerWidth / 2,
    top: 0,
    bottom: 0,
    width: _ResponsiveSlidingDrawerState._dividerWidth,
    child: _DesktopDividerInteraction(state: state),
  );
}

class const _DesktopDividerInteraction({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => state._setDividerHover(true),
    onExit: (_) => state._setDividerHover(false),
    cursor: SystemMouseCursors.resizeColumn,
    child: _DesktopDividerTooltip(state: state),
  );
}

class const _DesktopDividerTooltip({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tooltip = LocaleKeys.navigation_drawer_resize_handle_tooltip.tr(
      context: context,
    );

    return AuraTooltip(
      message: tooltip,
      child: _DesktopDividerSemantics(state: state, tooltip: tooltip),
    );
  }
}

class const _DesktopDividerSemantics({
  required final _ResponsiveSlidingDrawerState state,
  required final String tooltip,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hint = LocaleKeys.navigation_drawer_resize_handle_hint.tr(
      context: context,
    );

    return Semantics(
      child: _DesktopDividerVisual(state: state),
      label: tooltip,
      hint: hint,
    );
  }
}

class const _DesktopDividerVisual({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _DesktopDividerOpacity(state: state);
}

class const _DesktopDividerOpacity({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    child: _DesktopDividerGesture(state: state),
    opacity: state._isDividerHighlighted
        ? 1.0
        : _ResponsiveSlidingDrawerState._dividerIdleOpacity,
    duration: const Duration(milliseconds: 200),
  );
}

class const _DesktopDividerGesture({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: _DesktopDividerIndicator(color: _color(context)),
      onPanStart: (_) => state._setResizing(true),
      onPanUpdate: state._handleDividerPanUpdate,
      onPanEnd: (_) => state._setResizing(false),
      onPanCancel: () => state._setResizing(false),
      behavior: .opaque,
    );
  }

  Color _color(BuildContext context) =>
      state._isHoveringDivider || state._isResizing
      ? context.auraColors.primary
      : context.auraColors.outlineVariant;
}

class const _DesktopDividerIndicator({required final Color color})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: _ResponsiveSlidingDrawerState._dividerWidth,
    child: Center(
      child: Container(
        color: color,
        width: _ResponsiveSlidingDrawerState._dividerVisibleWidth,
        height: .infinity,
      ),
    ),
  );
}

class const _MobileDrawerLayout({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      _MobileDrawerBody(state: state),
      _MobileDrawerScrim(state: state),
      _MobileDrawerPanel(state: state),
    ],
  );
}

class const _MobileDrawerBody({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state._requiredController,
    builder: (context, _) => _MobileBodyPosition(state: state),
  );
}

class const _MobileBodyPosition({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final animation = state._requiredController;
    final drawerWidth = state._currentDrawerWidth;

    return Transform.translate(
      offset: .new(drawerWidth * animation.value, 0),
      child: _MobileBodyGesture(state: state),
    );
  }
}

class const _MobileBodyGesture({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final callbacks = state._mobileDragCallbacks(context);

    return GestureDetector(
      child: state.widget.body,
      onTap: state._closeIfFullyOpenCurrent,
      onHorizontalDragStart: callbacks.onDragStart,
      onHorizontalDragUpdate: callbacks.onDragUpdate,
      onHorizontalDragEnd: callbacks.onDragEnd,
    );
  }
}

class const _MobileDrawerScrim({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state._requiredController,
    builder: (context, _) => _MobileScrimPosition(state: state),
  );
}

class const _MobileScrimPosition({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final animation = state._requiredController;
    final drawerWidth = state._currentDrawerWidth;

    return Transform.translate(
      offset: .new(drawerWidth * animation.value, 0),
      child: _MobileScrimGesture(state: state),
    );
  }
}

class const _MobileScrimGesture({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: state._requiredController.value == 0,
    child: _MobileScrimInteraction(state: state),
  );
}

class const _MobileScrimInteraction({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final callbacks = state._mobileDragCallbacks(context);

    return GestureDetector(
      child: _MobileScrimSurface(state: state),
      onTap: state._closeIfFullyOpenCurrent,
      onHorizontalDragStart: callbacks.onDragStart,
      onHorizontalDragUpdate: callbacks.onDragUpdate,
      onHorizontalDragEnd: callbacks.onDragEnd,
    );
  }
}

class _MobileScrimSurface extends Stack {
  new({required this.state})
    : super(
        children: [
          _MobileScrimColor(state: state),
          _MobileScrimGradient(state: state),
        ],
      );

  final _ResponsiveSlidingDrawerState state;
}

class const _MobileScrimColor({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final value = state._requiredController.value;

    return Container(
      color: state._scrimColor.withValues(alpha: state._scrimOpacity * value),
    );
  }
}

class const _MobileScrimGradient({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Positioned(
    left: 0,
    top: 0,
    bottom: 0,
    width: _ResponsiveSlidingDrawerState._scrimGradientWidth,
    child: _MobileScrimGradientLayer(state: state),
  );
}

class const _MobileScrimGradientLayer({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final value = state._requiredController.value;
    final color = state.widget.isDarkMode ? Colors.black : state._scrimColor;
    final opacity = state._gradientStartOpacity * value;

    return IgnorePointer(
      child: _MobileScrimGradientFill(color: color, opacity: opacity),
    );
  }
}

class const _MobileScrimGradientFill({
  required final Color color,
  required final double opacity,
}) extends StatelessWidget {
  LinearGradient get _gradient => LinearGradient(
    colors: _gradientColors,
    stops: const [0.0, 0.2, 0.6, 1.0],
  );

  List<Color> get _gradientColors => [
    _withOpacity(opacity),
    _withOpacity(
      opacity * _ResponsiveSlidingDrawerState._gradientMiddleOpacity,
    ),
    _withOpacity(
      opacity * _ResponsiveSlidingDrawerState._gradientTrailingOpacity,
    ),
    _withOpacity(0),
  ];

  @override
  Widget build(BuildContext context) =>
      Container(decoration: BoxDecoration(gradient: _gradient));

  Color _withOpacity(double alpha) => color.withValues(alpha: alpha);
}

class const _MobileDrawerPanel({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state._requiredController,
    builder: (context, _) => _MobilePanelPosition(state: state),
  );
}

class const _MobilePanelPosition({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final animation = state._requiredController;
    final drawerWidth = state._currentDrawerWidth;

    return Transform.translate(
      offset: .new(-drawerWidth * (1 - animation.value), 0),
      child: _MobilePanelGesture(state: state),
    );
  }
}

class const _MobilePanelGesture({
  required final _ResponsiveSlidingDrawerState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final callbacks = state._mobileDragCallbacks(context);

    return GestureDetector(
      child: _DrawerFocusBox(state: state),
      onHorizontalDragStart: callbacks.onDragStart,
      onHorizontalDragUpdate: callbacks.onDragUpdate,
      onHorizontalDragEnd: callbacks.onDragEnd,
    );
  }
}
