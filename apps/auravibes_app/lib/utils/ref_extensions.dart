import 'package:flutter/widgets.dart';
import 'package:riverpod/riverpod.dart';

extension ChangeNotifierWithCodeGenExtension on Ref {
  T listenAndDisposeChangeNotifier<T extends ChangeNotifier>(T notifier) {
    notifier.addListener(notifyListeners);
    onDispose(() => notifier.removeListener(notifyListeners));
    onDispose(notifier.dispose);
    return notifier;
  }
}
