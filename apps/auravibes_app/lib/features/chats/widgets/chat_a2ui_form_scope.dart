import 'package:auravibes_app/features/chats/notifiers/chat_a2ui_runtime.dart';
import 'package:flutter/widgets.dart';

/// Supplies app-owned form state tracking to catalog input builders.
class ChatA2uiFormScope extends InheritedWidget {
  /// Creates a scope for one rendered surface.
  const new({
    required this.runtime,
    required this.surfaceId,
    required super.child,
    super.key,
  });

  /// Runtime that owns the surface.
  final ChatA2uiRuntime runtime;

  /// Turn-scoped surface identity.
  final String surfaceId;

  /// Records a user-edited JSON Pointer path.
  static void markTouched(BuildContext context, String path) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ChatA2uiFormScope>();
    scope?.runtime.markFormPathTouched(scope.surfaceId, path);
  }

  /// Returns the current app-owned validation code for a bound form path.
  static String? errorFor(BuildContext context, String path) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ChatA2uiFormScope>();

    return scope?.runtime
        .formValidationFor(scope.surfaceId)
        ?.errorsByPath[path];
  }

  @override
  bool updateShouldNotify(ChatA2uiFormScope oldWidget) =>
      runtime != oldWidget.runtime || surfaceId != oldWidget.surfaceId;
}
