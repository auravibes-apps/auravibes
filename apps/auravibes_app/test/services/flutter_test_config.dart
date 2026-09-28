import 'dart:async';

// Keep service tests unbound. ponytail: Move widget tests to a separate folder.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await testMain();
}
