import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

typedef _ConversationLayoutData = ({
  bool hasWideLayout,
  bool showSideBySide,
  bool hideMainContent,
  double panelWidth,
  double maxPanelWidth,
  double availableWidth,
});
typedef _ConversationLayoutSizingRequest = ({
  double availableWidth,
  double widthPercent,
  double? draggedPanelWidth,
  bool sidePanelVisible,
});
typedef _ConversationPanelGeometry = ({
  bool hasWideLayout,
  bool showSideBySide,
  double maxPanelWidth,
  double panelWidth,
});
typedef _ConversationPanelMode = ({
  bool hasWideLayout,
  bool showSideBySide,
  double minPanelWidth,
});
typedef _ResizePaneCallbacks = ({
  ValueChanged<bool> onHoverChanged,
  ValueChanged<double> onDragStart,
  void Function(DragUpdateDetails, {required bool isRightToLeft}) onDragUpdate,
  void Function(double, {required double maxPanelWidth}) onDragEnd,
});
typedef _ResizeHandleActions = ({
  ValueChanged<bool> onHoverChanged,
  GestureDragStartCallback onDragStart,
  GestureDragUpdateCallback onDragUpdate,
  GestureDragEndCallback onDragEnd,
  VoidCallback onDragCancel,
});

const _dividerHitWidth = 8.0;
const _dividerWidth = 1.0;
const _closeDragFraction = 0.5;

/// Shows conversation content beside a side panel when space allows.
class const ResponsiveConversationLayout({
  required final Widget mainContent,
  required final ResponsiveConversationSidePanel sidePanel,
  super.key,
}) extends StatefulWidget {
  static const minimumSidePanelWidth = 320.0;
  static const minimumMainContentWidth = 480.0;

  @override
  State<ResponsiveConversationLayout> createState() =>
      _ResponsiveConversationLayoutState();
}

class const ResponsiveConversationSidePanel({
  required final bool visible,
  required final bool mounted,
  required final double widthPercent,
  required final ValueChanged<double> onWidthChanged,
  required final VoidCallback onClose,
  required final Widget Function() builder,
});

class _ResponsiveConversationLayoutState
    extends State<ResponsiveConversationLayout> {
  double? _dragPanelWidth;
  double? _dragStartWidth;
  bool _isResizing = false;
  bool _isHoveringDivider = false;

  @override
  void didUpdateWidget(covariant ResponsiveConversationLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sidePanel.widthPercent != widget.sidePanel.widthPercent &&
        !_isResizing) {
      _dragPanelWidth = null;
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => _buildConversationLayout(
      _conversationLayoutData((
        availableWidth: constraints.maxWidth,
        widthPercent: widget.sidePanel.widthPercent,
        draggedPanelWidth: _dragPanelWidth,
        sidePanelVisible: widget.sidePanel.visible,
      )),
    ),
  );

  Widget _buildConversationLayout(_ConversationLayoutData data) {
    return _ConversationLayoutStack(
      layout: widget,
      data: data,
      isHighlighted: _isResizing || _isHoveringDivider,
      callbacks: (
        onHoverChanged: _setDividerHover,
        onDragStart: _startResize,
        onDragUpdate: _updateResize,
        onDragEnd: _finishResize,
      ),
    );
  }

  void _startResize(double panelWidth) => setState(() {
    _isResizing = true;
    _dragStartWidth = panelWidth;
    _dragPanelWidth = panelWidth;
  });

  void _updateResize(DragUpdateDetails details, {required bool isRightToLeft}) {
    final currentWidth = _dragPanelWidth;
    if (!_isResizing || currentWidth == null) return;
    final delta = isRightToLeft ? details.delta.dx : -details.delta.dx;

    setState(() {
      _dragPanelWidth = currentWidth + delta;
    });
  }

  void _setDividerHover(bool isHovering) =>
      setState(() => _isHoveringDivider = isHovering);

  void _finishResize(double availableWidth, {required double maxPanelWidth}) {
    final startWidth = _dragStartWidth;
    final currentWidth = _dragPanelWidth;
    if (startWidth == null || currentWidth == null) return;
    _saveResize(
      _resizeCompletion(
        startWidth: startWidth,
        currentWidth: currentWidth,
        availableWidth: availableWidth,
        maxPanelWidth: maxPanelWidth,
      ),
    );
  }

  ({bool shouldClose, double widthPercent, double panelWidth})
  _resizeCompletion({
    required double startWidth,
    required double currentWidth,
    required double availableWidth,
    required double maxPanelWidth,
  }) {
    final shouldClose =
        startWidth - currentWidth > startWidth * _closeDragFraction;
    final panelWidth = currentWidth.clamp(
      ResponsiveConversationLayout.minimumSidePanelWidth,
      maxPanelWidth,
    );

    return (
      shouldClose: shouldClose,
      widthPercent: panelWidth / availableWidth,
      panelWidth: panelWidth,
    );
  }

  void _saveResize(
    ({bool shouldClose, double widthPercent, double panelWidth}) completion,
  ) {
    setState(() {
      _isResizing = false;
      _dragStartWidth = null;
      _dragPanelWidth = completion.shouldClose ? null : completion.panelWidth;
    });
    if (completion.shouldClose) {
      widget.sidePanel.onClose();

      return;
    }

    widget.sidePanel.onWidthChanged(completion.widthPercent);
  }
}

class const _ConversationMainPane({
  required final ResponsiveConversationLayout layout,
  required final _ConversationLayoutData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hideMainContent = data.hideMainContent;

    return PositionedDirectional(
      start: 0,
      top: 0,
      end: data.showSideBySide ? data.panelWidth + _dividerWidth : 0,
      bottom: 0,
      child: _ConversationPaneVisibility(
        visible: !hideMainContent,
        child: layout.mainContent,
      ),
    );
  }
}

class const _ConversationSidePane({
  required final ResponsiveConversationLayout layout,
  required final _ConversationLayoutData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sidePanel = layout.sidePanel;
    final child = sidePanel.builder();

    return PositionedDirectional(
      top: 0,
      end: 0,
      bottom: 0,
      width: data.hasWideLayout ? data.panelWidth : data.availableWidth,
      child: _ConversationPaneVisibility(
        visible: sidePanel.visible,
        child: child,
      ),
    );
  }
}

class const _ConversationPaneVisibility({
  required final bool visible,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ExcludeFocus(
    excluding: !visible,
    child: TickerMode(
      enabled: visible,
      child: ExcludeSemantics(
        excluding: !visible,
        child: Offstage(offstage: !visible, child: child),
      ),
    ),
  );
}

class const _ConversationLayoutStack({
  required final ResponsiveConversationLayout layout,
  required final _ConversationLayoutData data,
  required final bool isHighlighted,
  required final _ResizePaneCallbacks callbacks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
    fit: .expand,
    children: [
      _ConversationMainPane(layout: layout, data: data),
      if (layout.sidePanel.mounted)
        _ConversationSidePane(layout: layout, data: data),
      if (data.showSideBySide)
        _ConversationResizePane(
          data: data,
          isHighlighted: isHighlighted,
          callbacks: callbacks,
        ),
    ],
  );
}

class const _ConversationResizePane({
  required final _ConversationLayoutData data,
  required final bool isHighlighted,
  required final _ResizePaneCallbacks callbacks,
}) extends StatefulWidget {
  @override
  State<_ConversationResizePane> createState() =>
      _ConversationResizePaneState();
}

class _ConversationResizePaneState extends State<_ConversationResizePane> {
  _ResizeHandleActions get _actions => (
    onHoverChanged: widget.callbacks.onHoverChanged,
    onDragStart: _onDragStart,
    onDragUpdate: _onDragUpdate,
    onDragEnd: _onDragEnd,
    onDragCancel: _onDragCancel,
  );

  @override
  Widget build(BuildContext context) {
    return _SidePanelResizePosition(
      data: widget.data,
      child: _SidePanelResizeHandle(
        isHighlighted: widget.isHighlighted,
        actions: _actions,
      ),
    );
  }

  void _onDragStart(DragStartDetails _) =>
      widget.callbacks.onDragStart(widget.data.panelWidth);

  void _onDragUpdate(DragUpdateDetails details) => widget.callbacks
      .onDragUpdate(details, isRightToLeft: Directionality.of(context) == .rtl);

  void _onDragEnd(DragEndDetails _) => _finishDrag();

  void _onDragCancel() => _finishDrag();

  void _finishDrag() => widget.callbacks.onDragEnd(
    widget.data.availableWidth,
    maxPanelWidth: widget.data.maxPanelWidth,
  );
}

class const _SidePanelResizePosition({
  required final _ConversationLayoutData data,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => PositionedDirectional(
    top: 0,
    end: (data.panelWidth - _dividerHitWidth / 2).clamp(
      0.0,
      data.availableWidth,
    ),
    bottom: 0,
    width: _dividerHitWidth,
    child: child,
  );
}

class const _SidePanelResizeHandle({
  required final bool isHighlighted,
  required final _ResizeHandleActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tooltip = LocaleKeys.browser_resize_handle_tooltip.tr(
      context: context,
    );
    final hint = LocaleKeys.browser_resize_handle_hint.tr(context: context);
    final color = isHighlighted
        ? context.auraColors.primary
        : context.auraColors.outlineVariant;

    return _SidePanelResizeTooltip(
      tooltip: tooltip,
      hint: hint,
      color: color,
      actions: actions,
    );
  }
}

class const _SidePanelResizeTooltip({
  required final String tooltip,
  required final String hint,
  required final Color color,
  required final _ResizeHandleActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraTooltip(
    message: tooltip,
    child: Semantics(
      child: _SidePanelResizeGesture(color: color, actions: actions),
      label: tooltip,
      hint: hint,
    ),
  );
}

class const _SidePanelResizeGesture({
  required final Color color,
  required final _ResizeHandleActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => actions.onHoverChanged(true),
    onExit: (_) => actions.onHoverChanged(false),
    cursor: SystemMouseCursors.resizeColumn,
    child: _SidePanelResizeDragGesture(color: color, actions: actions),
  );
}

class const _SidePanelResizeDragGesture({
  required final Color color,
  required final _ResizeHandleActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const ValueKey('chat_side_panel_resize_handle'),
    child: _SidePanelResizeIndicator(color: color),
    onHorizontalDragStart: actions.onDragStart,
    onHorizontalDragUpdate: actions.onDragUpdate,
    onHorizontalDragEnd: actions.onDragEnd,
    onHorizontalDragCancel: actions.onDragCancel,
    behavior: .opaque,
  );
}

class const _SidePanelResizeIndicator({required final Color color})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 1,
      height: .infinity,
      child: ColoredBox(color: color),
    ),
  );
}

_ConversationLayoutData _conversationLayoutData(
  _ConversationLayoutSizingRequest request,
) {
  final geometry = _conversationPanelGeometry(request);

  return (
    availableWidth: request.availableWidth,
    hasWideLayout: geometry.hasWideLayout,
    showSideBySide: geometry.showSideBySide,
    hideMainContent: request.sidePanelVisible && !geometry.showSideBySide,
    panelWidth: geometry.panelWidth,
    maxPanelWidth: geometry.maxPanelWidth,
  );
}

_ConversationPanelGeometry _conversationPanelGeometry(
  _ConversationLayoutSizingRequest request,
) {
  final mode = _conversationPanelMode(request);
  final availableWidth = request.availableWidth;
  final maxPanelWidth = _maxConversationPanelWidth(
    availableWidth,
    mode.minPanelWidth,
    mode.showSideBySide,
  );

  return (
    hasWideLayout: mode.hasWideLayout,
    showSideBySide: mode.showSideBySide,
    maxPanelWidth: maxPanelWidth,
    panelWidth: _conversationPanelWidth(
      request,
      mode.minPanelWidth,
      maxPanelWidth,
    ),
  );
}

_ConversationPanelMode _conversationPanelMode(
  _ConversationLayoutSizingRequest request,
) {
  final availableWidth = request.availableWidth;
  final hasWideLayout = availableWidth >= DesignBreakpoints.lg;
  final showSideBySide = request.sidePanelVisible && hasWideLayout;

  return (
    hasWideLayout: hasWideLayout,
    showSideBySide: showSideBySide,
    minPanelWidth: showSideBySide
        ? ResponsiveConversationLayout.minimumSidePanelWidth
        : 0.0,
  );
}

double _maxConversationPanelWidth(
  double availableWidth,
  double minPanelWidth,
  bool showSideBySide,
) => showSideBySide
    ? (availableWidth -
              ResponsiveConversationLayout.minimumMainContentWidth -
              _dividerWidth)
          .clamp(minPanelWidth, availableWidth)
    : availableWidth;

double _conversationPanelWidth(
  _ConversationLayoutSizingRequest request,
  double minPanelWidth,
  double maxPanelWidth,
) =>
    (request.draggedPanelWidth ?? request.availableWidth * request.widthPercent)
        .clamp(minPanelWidth, maxPanelWidth);
