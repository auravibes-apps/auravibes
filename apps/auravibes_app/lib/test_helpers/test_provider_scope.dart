import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class TestProviderScope extends StatelessWidget {
  const TestProviderScope({
    required this.overrides,
    required this.child,
    super.key,
  });

  final List<Object> overrides;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides.cast(),
      child: child,
    );
  }
}
