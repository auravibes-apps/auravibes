import 'package:auravibes_server_client/auravibes_server_client.dart';

class CloudLiveTurnState {
  const CloudLiveTurnState({
    required this.turnId,
    required this.revision,
    required this.sequence,
    required this.state,
    this.text,
    this.messageId,
    this.errorCode,
  });

  factory CloudLiveTurnState.fromEvent(LiveTurnEvent event) =>
      CloudLiveTurnState(
        turnId: event.turnId,
        revision: 0,
        sequence: event.sequence,
        state: CloudLiveTurnLifecycle.fromEvent(event.kind),
        text: event.text,
        messageId: event.messageId,
        errorCode: event.errorCode,
      );

  final String turnId;
  final int revision;
  final int sequence;
  final CloudLiveTurnLifecycle state;
  final String? text;
  final String? messageId;
  final String? errorCode;

  bool get isTerminal => switch (state) {
    .completed || .failed || .cancelled => true,
    _ => false,
  };

  bool get isBusy => !isTerminal;

  CloudLiveTurnState copyWithEvent(LiveTurnEvent event) => CloudLiveTurnState(
    turnId: turnId,
    revision: revision,
    sequence: event.sequence,
    state: CloudLiveTurnLifecycle.fromEvent(event.kind),
    text: event.text,
    messageId: event.messageId,
    errorCode: event.errorCode,
  );
}

enum CloudLiveTurnLifecycle {
  queued,
  thinking,
  streaming,
  awaitingApproval,
  completed,
  failed,
  cancelled;

  factory CloudLiveTurnLifecycle.fromEvent(LiveTurnEventKind kind) =>
      switch (kind) {
        .queued => .queued,
        .running => .thinking,
        .text => .streaming,
        .awaitingApproval => .awaitingApproval,
        .completed => .completed,
        .failed => .failed,
        .cancelled => .cancelled,
      };

  factory CloudLiveTurnLifecycle.fromStatus(String status) => switch (status) {
    'queued' => .queued,
    'running' => .thinking,
    'awaitingApproval' => .awaitingApproval,
    'completed' => .completed,
    'failed' => .failed,
    'cancelled' => .cancelled,
    _ => .failed,
  };
}
