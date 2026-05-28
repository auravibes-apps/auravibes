// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
import 'package:equatable/equatable.dart';

class AgentIterationContext extends Equatable {
  const AgentIterationContext({
    required this.origin,
    this.ackMessageIds = const [],
  });

  final AgentIterationOrigin origin;
  final List<String> ackMessageIds;

  @override
  List<Object?> get props => [origin, ackMessageIds];
}

enum AgentIterationOrigin {
  userMessage,
  toolResume,
  manualContinue,
}
