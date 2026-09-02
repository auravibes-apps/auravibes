import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/src/framework.dart' show Override;

class const TestProviderScope({
  required final List<Override> overrides,
  required final Widget child,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ProviderScope(overrides: overrides, child: child);
  }
}
