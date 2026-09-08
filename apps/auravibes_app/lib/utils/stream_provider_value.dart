import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

Stream<T> streamProviderValue<T>(
  Ref ref,
  ProviderListenable<AsyncValue<T>> provider,
) {
  final controller = StreamController<T>();
  void emit(AsyncValue<T> next) {
    switch (next) {
      case AsyncData(:final value):
        controller.add(value);
      case AsyncError(:final error, :final stackTrace):
        controller.addError(error, stackTrace);
      case AsyncLoading():
    }
  }

  final subscription = ref.listen(
    provider,
    (_, next) => emit(next),
    fireImmediately: true,
  );
  ref
    ..onDispose(subscription.close)
    ..onDispose(() => unawaited(controller.close()));

  return controller.stream;
}
