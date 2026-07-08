import 'package:meta/meta.dart';

@immutable
class AgentIterationContext {
  const AgentIterationContext({
    required this.origin,
    this.ackMessageIds = const [],
  });

  final AgentIterationOrigin origin;
  final List<String> ackMessageIds;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AgentIterationContext &&
            other.origin == origin &&
            _listEquals(other.ackMessageIds, ackMessageIds);
  }

  @override
  int get hashCode => Object.hash(origin, Object.hashAll(ackMessageIds));
}

enum AgentIterationOrigin {
  userMessage,
  toolResume,
  manualContinue,
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;

  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }

  return true;
}
