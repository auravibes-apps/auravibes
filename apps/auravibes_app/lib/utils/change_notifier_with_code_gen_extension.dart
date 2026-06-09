// Required: Existing test and UI helpers keep compact return flow.
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
