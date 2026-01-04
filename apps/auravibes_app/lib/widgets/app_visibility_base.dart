import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart';

/// A base widget that controls the visibility of [child] using Riverpod state.
///
/// The [visible] parameter is a [ProviderListenable] of [bool] that is watched
/// with [WidgetRef.watch]. Whenever the provider's value changes, this widget
/// rebuilds and shows or hides [child] accordingly using Flutter's
/// [Visibility] widget.
///
/// Typical usage is to pass a `Provider<bool>` (or similar) that represents
/// whether the content should be visible:
///
/// ```dart
/// AppVisibilityBase(
///   visible: someBoolProvider,
///   child: YourChildWidget(),
/// )
/// ```
class AppVisibilityBase extends ConsumerWidget {
  const AppVisibilityBase({
    required this.visible,
    required this.child,
    super.key,
  });

  final ProviderListenable<bool> visible;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Visibility(
      visible: ref.watch(visible),
      child: child,
    );
  }
}
