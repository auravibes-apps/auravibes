import 'package:meta/meta.dart';

@immutable
class AgentIterationContext {
  const AgentIterationContext({
    required this.origin,
    this.ackMessageId,
  });

  final AgentIterationOrigin origin;
  final String? ackMessageId;

  @override
  bool operator ==(Object other) {
    return other is AgentIterationContext &&
        other.origin == origin &&
        other.ackMessageId == ackMessageId;
  }

  @override
  int get hashCode => Object.hash(origin, ackMessageId);
}

enum AgentIterationOrigin {
  userMessage,
  toolResume,
  manualContinue,
}
