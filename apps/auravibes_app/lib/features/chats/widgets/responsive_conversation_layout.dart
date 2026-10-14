import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

/// Shows conversation content beside a side panel when space allows.
class const ResponsiveConversationLayout({
  required final Widget mainContent,
  required final bool sidePanelVisible,
  required final bool sidePanelMounted,
  required final double sidePanelWidthPercent,
  required final ValueChanged<double> onSidePanelWidthChanged,
  required final VoidCallback onSidePanelClose,
  required final Widget Function() sidePanelBuilder,
  super.key,
}) extends StatefulWidget {
  static const minimumSidePanelWidth = 320.0;
  static const minimumMainContentWidth = 480.0;

  @override
  State<ResponsiveConversationLayout> createState() =>
      _ResponsiveConversationLayoutState();
}

class _ResponsiveConversationLayoutState
    extends State<ResponsiveConversationLayout> {
  static const _dividerHitWidth = 8.0;
  static const _dividerWidth = 1.0;
  static const _closeDragFraction = 0.5;

  double? _dragPanelWidth;
  double? _dragStartWidth;
  bool _isResizing = false;
  bool _isHoveringDivider = false;

  @override
  void didUpdateWidget(covariant ResponsiveConversationLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sidePanelWidthPercent != widget.sidePanelWidthPercent &&
        !_isResizing) {
      _dragPanelWidth = null;
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final hasWideLayout = constraints.maxWidth >= DesignBreakpoints.lg;
      final showSideBySide = widget.sidePanelVisible && hasWideLayout;
      final minPanelWidth = showSideBySide
          ? ResponsiveConversationLayout.minimumSidePanelWidth
          : 0.0;
      final maxPanelWidth = showSideBySide
          ? (constraints.maxWidth -
                    ResponsiveConversationLayout.minimumMainContentWidth -
                    _dividerWidth)
                .clamp(minPanelWidth, constraints.maxWidth)
          : constraints.maxWidth;
      final panelWidth =
          (_dragPanelWidth ??
                  constraints.maxWidth * widget.sidePanelWidthPercent)
              .clamp(minPanelWidth, maxPanelWidth);
      final hideMainContent = widget.sidePanelVisible && !showSideBySide;

      return Stack(
        fit: .expand,
        children: [
          PositionedDirectional(
            start: 0,
            top: 0,
            end: showSideBySide ? panelWidth + _dividerWidth : 0,
            bottom: 0,
            child: ExcludeFocus(
              excluding: hideMainContent,
              child: ExcludeSemantics(
                excluding: hideMainContent,
                child: Offstage(
                  offstage: hideMainContent,
                  child: widget.mainContent,
                ),
              ),
            ),
          ),
          if (widget.sidePanelMounted)
            PositionedDirectional(
              top: 0,
              end: 0,
              bottom: 0,
              width: hasWideLayout ? panelWidth : constraints.maxWidth,
              child: ExcludeFocus(
                excluding: !widget.sidePanelVisible,
                child: ExcludeSemantics(
                  excluding: !widget.sidePanelVisible,
                  child: Offstage(
                    offstage: !widget.sidePanelVisible,
                    child: widget.sidePanelBuilder(),
                  ),
                ),
              ),
            ),
          if (showSideBySide)
            PositionedDirectional(
              top: 0,
              end: (panelWidth - _dividerHitWidth / 2).clamp(
                0.0,
                constraints.maxWidth,
              ),
              bottom: 0,
              width: _dividerHitWidth,
              child: _SidePanelResizeHandle(
                isHighlighted: _isResizing || _isHoveringDivider,
                onHoverChanged: _setDividerHover,
                onDragStart: () => _startResize(panelWidth),
                onDragUpdate: (details) => _updateResize(
                  details,
                  isRightToLeft: Directionality.of(context) == .rtl,
                ),
                onDragEnd: () => _finishResize(
                  constraints.maxWidth,
                  maxPanelWidth: maxPanelWidth,
                ),
              ),
            ),
        ],
      );
    },
  );

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

  void _finishResize(double availableWidth, {required double maxPanelWidth}) {
    final startWidth = _dragStartWidth;
    final currentWidth = _dragPanelWidth;
    if (startWidth == null || currentWidth == null) return;
    final shouldClose =
        startWidth - currentWidth > startWidth * _closeDragFraction;
    final savedWidth = currentWidth.clamp(
      ResponsiveConversationLayout.minimumSidePanelWidth,
      maxPanelWidth,
    );
    setState(() {
      _isResizing = false;
      _dragStartWidth = null;
      _dragPanelWidth = shouldClose ? null : savedWidth;
    });

    if (shouldClose) {
      widget.onSidePanelClose();

      return;
    }

    widget.onSidePanelWidthChanged(savedWidth / availableWidth);
  }

  void _setDividerHover(bool isHovering) =>
      setState(() => _isHoveringDivider = isHovering);
}

class const _SidePanelResizeHandle({
  required final bool isHighlighted,
  required final ValueChanged<bool> onHoverChanged,
  required final VoidCallback onDragStart,
  required final GestureDragUpdateCallback onDragUpdate,
  required final VoidCallback onDragEnd,
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

    return MouseRegion(
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      cursor: SystemMouseCursors.resizeColumn,
      child: AuraTooltip(
        message: tooltip,
        child: Semantics(
          child: GestureDetector(
            key: const ValueKey('chat_side_panel_resize_handle'),
            child: Center(
              child: SizedBox(
                width: 1,
                height: .infinity,
                child: ColoredBox(color: color),
              ),
            ),
            onHorizontalDragStart: (_) => onDragStart(),
            onHorizontalDragUpdate: onDragUpdate,
            onHorizontalDragEnd: (_) => onDragEnd(),
            onHorizontalDragCancel: onDragEnd,
            behavior: .opaque,
          ),
          label: tooltip,
          hint: hint,
        ),
      ),
    );
  }
}
