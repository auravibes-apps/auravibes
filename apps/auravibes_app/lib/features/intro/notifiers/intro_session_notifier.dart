import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'intro_session_notifier.g.dart';

/// Keeps an active setup task on Intro after its first workspace is saved.
@riverpod
class IntroSessionNotifier extends _$IntroSessionNotifier {
  @override
  bool build() => false;

  void begin() => state = true;

  void finish() => state = false;
}
