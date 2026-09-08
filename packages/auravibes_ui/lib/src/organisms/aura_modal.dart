import 'dart:async';

import 'package:auravibes_ui/src/atoms/aura_interaction_scope.dart';
import 'package:auravibes_ui/src/molecules/aura_button.dart';
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
  const new({
    required this.entryPointChild,
    required this.contentChild,
    required this.barrierLabel,
    super.key,
    this.barrierDismissible = true,
    this.semanticLabel = 'Open modal',
    this.title,
    this.closeLabel,
    this.size = AuraModalSize.medium,
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

  /// Optional title shown above the modal content.
  final Widget? title;

  /// Caller-provided localized label for the app-owned close control.
  final String? closeLabel;

  /// Maximum horizontal size of the modal surface.
  final AuraModalSize size;

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
    final policy = AuraInteractionScope.of(context);
    if (!policy.allowsNavigation) {
      return Semantics(
        child: IgnorePointer(child: widget.entryPointChild),
        container: true,
        enabled: false,
        button: true,
        label: widget.semanticLabel ?? 'Open modal',
      );
    }

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
    if (_isShowing || !AuraInteractionScope.of(context).allowsNavigation) {
      return;
    }

    final navigator = Navigator.of(context, rootNavigator: true);
    final themes = InheritedTheme.capture(from: context, to: navigator.context);
    final policy = AuraInteractionScope.of(context);
    _isShowing = true;
    try {
      await showGeneralDialog<void>(
        context: context,
        pageBuilder: (context, animation, secondaryAnimation) => themes.wrap(
          _AuraModalSurface(
            content: widget.contentChild,
            semanticLabel: widget.semanticLabel,
            policy: policy,
            title: widget.title,
            closeLabel: widget.closeLabel,
            size: widget.size,
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

class const _AuraModalSurface({
  required final Widget content,
  required final String? semanticLabel,
  required final AuraInteractionPolicy policy,
  required final Widget? title,
  required final String? closeLabel,
  required final AuraModalSize size,
}) extends StatelessWidget {
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
              maxWidth: size.maxWidth,
              maxHeight: maxHeight,
            ),
            margin: EdgeInsets.all(spacing),
            child: AuraInteractionScope(
              policy: policy,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title != null || closeLabel != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title case final value?) Expanded(child: value),
                        if (closeLabel case final label?)
                          AuraButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(label),
                            variant: AuraButtonVariant.text,
                            semanticLabel: label,
                          ),
                      ],
                    ),
                  if (title != null || closeLabel != null)
                    SizedBox(height: spacing),
                  Flexible(child: SingleChildScrollView(child: content)),
                ],
              ),
            ),
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

/// Tokenized modal widths for compact and desktop layouts.
enum AuraModalSize {
  /// Compact dialogs such as confirmations.
  small,

  /// Standard dialog width.
  medium,

  /// Wide detail dialog.
  large;

  /// Maximum dialog width in logical pixels.
  double get maxWidth => switch (this) {
    AuraModalSize.small => 320,
    AuraModalSize.medium => 400,
    AuraModalSize.large => 720,
  };
}
