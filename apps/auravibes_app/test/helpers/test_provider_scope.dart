// ignore_for_file: avoid-top-level-members-in-tests
// Required: Test files keep shared fixtures and helpers top-level.

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/src/framework.dart' show Override;

class TestProviderScope extends StatelessWidget {
  const TestProviderScope({
    required this.overrides,
    required this.child,
    super.key,
  });

  final List<Override> overrides;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: child,
    );
  }
}
