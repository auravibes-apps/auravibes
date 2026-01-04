import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart';

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
