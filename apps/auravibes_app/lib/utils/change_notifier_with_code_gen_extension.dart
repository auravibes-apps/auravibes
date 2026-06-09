// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
import 'package:flutter/widgets.dart';
import 'package:riverpod/riverpod.dart';

extension ChangeNotifierWithCodeGenExtension on Ref {
  T listenAndDisposeChangeNotifier<T extends ChangeNotifier>(T notifier) {
    notifier.addListener(notifyListeners);
    final _ = onDispose(() => notifier.removeListener(notifyListeners));
    final _ = onDispose(notifier.dispose);

    return notifier;
  }
}
