import 'dart:async';

import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// A reusable modal composition with an entry point and arbitrary content.
///
/// Tapping or activating [entryPointChild] opens [contentChild] in a modal
/// route. Content can close itself with `Navigator.of(context).pop()`.
class AuraModal extends StatefulWidget {
  /// Creates a modal composition.
  const AuraModal({
    required this.entryPointChild,
    required this.contentChild,
    required this.barrierLabel,
    super.key,
    this.barrierDismissible = true,
    this.semanticLabel = 'Open modal',
  });

  /// The child that opens the modal when tapped or keyboard-activated.
  final Widget entryPointChild;

  /// The arbitrary widget displayed inside the modal surface.
  final Widget contentChild;

  /// Whether tapping the modal barrier dismisses the modal.
  final bool barrierDismissible;

  /// An accessibility label for the dismissible modal barrier.
  final String barrierLabel;

  /// An optional accessibility label for the modal route.
  final String? semanticLabel;

  @override
  State<AuraModal> createState() => _AuraModalState();
}

class _AuraModalState extends State<AuraModal> {
  int? _activePointer;
  bool _isPrimaryPointer = false;
  bool _pointerMoved = false;
  Offset? _pointerDownPosition;
  bool _isShowing = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: FocusableActionDetector(
        descendantsAreFocusable: false,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              unawaited(_show(context));

              return null;
            },
          ),
        },
        mouseCursor: SystemMouseCursors.click,
        child: Semantics(
          child: widget.entryPointChild,
          container: true,
          excludeSemantics: true,
          enabled: true,
          button: true,
          label: 'Open modal',
          onTap: () => unawaited(_show(context)),
        ),
      ),
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_activePointer != null) return;

    _activePointer = event.pointer;
    _isPrimaryPointer = event.buttons & kPrimaryButton != 0;
    _pointerDownPosition = event.position;
    _pointerMoved = false;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer || _pointerMoved) return;

    final downPosition = _pointerDownPosition;
    if (downPosition == null) return;

    if ((event.position - downPosition).distance > kTouchSlop) {
      _pointerMoved = true;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointer) return;

    final isTap = _isPrimaryPointer && !_pointerMoved;
    _resetPointer();
    if (isTap) unawaited(_show(context));
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer == _activePointer) _resetPointer();
  }

  void _resetPointer() {
    _activePointer = null;
    _isPrimaryPointer = false;
    _pointerMoved = false;
    _pointerDownPosition = null;
  }

  Future<void> _show(BuildContext context) async {
    if (_isShowing) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    final themes = InheritedTheme.capture(from: context, to: navigator.context);
    _isShowing = true;
    try {
      await showGeneralDialog<void>(
        context: context,
        pageBuilder: (context, animation, secondaryAnimation) => themes.wrap(
          _AuraModalSurface(
            content: widget.contentChild,
            semanticLabel: widget.semanticLabel,
          ),
        ),
        barrierDismissible: widget.barrierDismissible,
        barrierLabel: widget.barrierLabel,
        barrierColor: context.auraColors.scrim,
      );
    } finally {
      _isShowing = false;
    }
  }
}

class _AuraModalSurface extends StatelessWidget {
  static const _maxWidth = 400.0;

  const _AuraModalSurface({required this.content, required this.semanticLabel});

  final Widget content;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final auraTheme = context.auraTheme;
    final spacing = auraTheme.fromSpacing(.md);
    final maxHeight = MediaQuery.sizeOf(context).height - spacing * 2;

    return Semantics(
      child: SafeArea(
        child: Center(
          child: Container(
            padding: EdgeInsets.all(spacing),
            decoration: BoxDecoration(
              color: context.auraColors.surface,
              borderRadius: BorderRadius.all(
                Radius.circular(auraTheme.fromBorderRadius(.lg)),
              ),
              boxShadow: const [DesignShadows.lg],
            ),
            constraints: BoxConstraints(
              maxWidth: _maxWidth,
              maxHeight: maxHeight,
            ),
            margin: EdgeInsets.all(spacing),
            child: content,
          ),
        ),
      ),
      container: true,
      explicitChildNodes: true,
      namesRoute: semanticLabel != null,
      label: semanticLabel,
    );
  }
}
