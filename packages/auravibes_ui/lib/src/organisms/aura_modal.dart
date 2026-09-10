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
      return _AuraModalDisabledEntry(widget: widget);
    }

    return _AuraModalInteractiveEntry.fromState(widget: widget, state: this);
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

    _isShowing = true;
    try {
      await _showAuraModal(context, widget);
    } finally {
      _isShowing = false;
    }
  }
}

Future<void> _showAuraModal(BuildContext context, AuraModal widget) {
  final navigator = Navigator.of(context, rootNavigator: true);

  return _AuraModalDialogData(
    context: context,
    widget: widget,
    themes: InheritedTheme.capture(from: context, to: navigator.context),
    policy: AuraInteractionScope.of(context),
  ).future;
}

class _AuraModalDialogData({
  required final BuildContext context,
  required final AuraModal widget,
  required final CapturedThemes themes,
  required final AuraInteractionPolicy policy,
}) {
  final Future<void> future = showGeneralDialog<void>(
    context: context,
    pageBuilder: (context, animation, secondaryAnimation) =>
        themes.wrap(_AuraModalSurface.fromWidget(widget, policy)),
    barrierDismissible: widget.barrierDismissible,
    barrierLabel: widget.barrierLabel,
    barrierColor: context.auraColors.scrim,
  );
}

class const _AuraModalDisabledEntry({required final AuraModal widget})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: IgnorePointer(child: widget.entryPointChild),
    container: true,
    enabled: false,
    button: true,
    label: widget.semanticLabel ?? 'Open modal',
  );
}

class _AuraModalInteractiveEntry extends StatelessWidget {
  const _AuraModalInteractiveEntry({
    required this.widget,
    required this.onShow,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
    required this.onPointerCancel,
  });

  _AuraModalInteractiveEntry.fromState({
    required AuraModal widget,
    required _AuraModalState state,
  }) : this(
         widget: widget,
         onShow: () => unawaited(state._show(state.context)),
         onPointerDown: state._onPointerDown,
         onPointerMove: state._onPointerMove,
         onPointerUp: state._onPointerUp,
         onPointerCancel: state._onPointerCancel,
       );

  final AuraModal widget;
  final VoidCallback onShow;
  final PointerDownEventListener onPointerDown;
  final PointerMoveEventListener onPointerMove;
  final PointerUpEventListener onPointerUp;
  final PointerCancelEventListener onPointerCancel;

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: onPointerDown,
    onPointerMove: onPointerMove,
    onPointerUp: onPointerUp,
    onPointerCancel: onPointerCancel,
    child: _AuraModalInteractiveFocus(widget: widget, onShow: onShow),
  );
}

class _AuraModalInteractiveFocus extends StatelessWidget {
  _AuraModalInteractiveFocus({
    required AuraModal widget,
    required VoidCallback onShow,
  }) : _child = FocusableActionDetector(
         descendantsAreFocusable: false,
         actions: <Type, Action<Intent>>{
           ActivateIntent: CallbackAction<ActivateIntent>(
             onInvoke: (_) {
               onShow();

               return null;
             },
           ),
         },
         mouseCursor: SystemMouseCursors.click,
         child: _AuraModalEntrySemantics(widget: widget, onShow: onShow),
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _AuraModalEntrySemantics({
  required final AuraModal widget,
  required final VoidCallback onShow,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: widget.entryPointChild,
    container: true,
    excludeSemantics: true,
    enabled: true,
    button: true,
    label: 'Open modal',
    onTap: onShow,
  );
}

class const _AuraModalSurface({
  required final Widget content,
  required final String? semanticLabel,
  required final AuraInteractionPolicy policy,
  required final Widget? title,
  required final String? closeLabel,
  required final AuraModalSize size,
}) extends StatelessWidget {
  new fromWidget(AuraModal widget, AuraInteractionPolicy policy)
    : this(
        content: widget.contentChild,
        semanticLabel: widget.semanticLabel,
        policy: policy,
        title: widget.title,
        closeLabel: widget.closeLabel,
        size: widget.size,
      );

  @override
  Widget build(BuildContext context) =>
      _AuraModalSurfaceSemantics(surface: this);
}

class const _AuraModalSurfaceSemantics({
  required final _AuraModalSurface surface,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: _AuraModalSurfaceFrame(surface: surface),
    container: true,
    explicitChildNodes: true,
    namesRoute: surface.semanticLabel != null,
    label: surface.semanticLabel,
  );
}

class const _AuraModalSurfaceFrame({required final _AuraModalSurface surface})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _AuraModalSurfaceFrameContent.fromContext(context, surface);
}

class _AuraModalSurfaceFrameContent extends StatelessWidget {
  _AuraModalSurfaceFrameContent.fromContext(
    BuildContext context,
    _AuraModalSurface surface,
  ) : _child = _AuraModalSurfaceFrameLayout.fromContext(context, surface);

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _AuraModalSurfaceFrameLayout extends StatelessWidget {
  _AuraModalSurfaceFrameLayout.fromContext(
    BuildContext context,
    _AuraModalSurface surface,
  ) : this(
        surface: surface,
        spacing: context.auraTheme.fromSpacing(.md),
        maxHeight:
            MediaQuery.sizeOf(context).height -
            context.auraTheme.fromSpacing(.md) * 2,
        decoration: _modalSurfaceDecoration(context),
      );

  _AuraModalSurfaceFrameLayout({
    required _AuraModalSurface surface,
    required double spacing,
    required double maxHeight,
    required Decoration decoration,
  }) : _child = SafeArea(
         child: Center(
           child: _AuraModalSurfaceBox(
             surface: surface,
             spacing: spacing,
             maxHeight: maxHeight,
             decoration: decoration,
           ),
         ),
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _AuraModalSurfaceBox extends StatelessWidget {
  _AuraModalSurfaceBox({
    required _AuraModalSurface surface,
    required double spacing,
    required double maxHeight,
    required Decoration decoration,
  }) : _child = Container(
         padding: EdgeInsets.all(spacing),
         decoration: decoration,
         constraints: .new(
           maxWidth: surface.size.maxWidth,
           maxHeight: maxHeight,
         ),
         margin: EdgeInsets.all(spacing),
         child: AuraInteractionScope(
           policy: surface.policy,
           child: _AuraModalSurfaceContent(surface: surface, spacing: spacing),
         ),
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

BoxDecoration _modalSurfaceDecoration(BuildContext context) => BoxDecoration(
  color: context.auraColors.surface,
  borderRadius: BorderRadius.all(
    .circular(context.auraTheme.fromBorderRadius(.lg)),
  ),
  boxShadow: const [DesignShadows.lg],
);

class _AuraModalSurfaceContent extends StatelessWidget {
  _AuraModalSurfaceContent({
    required _AuraModalSurface surface,
    required double spacing,
  }) : _child = Column(
         mainAxisSize: .min,
         crossAxisAlignment: .stretch,
         children: [
           if (surface.title != null || surface.closeLabel != null)
             _AuraModalHeader(surface: surface),
           if (surface.title != null || surface.closeLabel != null)
             SizedBox(height: spacing),
           Flexible(child: SingleChildScrollView(child: surface.content)),
         ],
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _AuraModalHeader extends StatelessWidget {
  _AuraModalHeader({required _AuraModalSurface surface})
    : _child = Row(
        crossAxisAlignment: .start,
        children: [
          if (surface.title case final value?) Expanded(child: value),
          if (surface.closeLabel case final label?)
            _AuraModalCloseButton(label: label),
        ],
      );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _AuraModalCloseButton({required final String label})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => Navigator.of(context).pop(),
    child: Text(label),
    variant: .text,
    semanticLabel: label,
  );
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
    .small => 320,
    .medium => 400,
    .large => 720,
  };
}
