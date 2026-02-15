import 'package:auravibes_app/domain/entities/messages.dart';

enum StreamingProjectionStatus {
  created,
  streaming,
  done,
  error,
  awaitingToolConfirmation,
  executingTools,
  waitingForMcpConnections,
}

class StreamingMessageProjection {
  const StreamingMessageProjection({
    required this.content,
    required this.status,
    this.metadata,
  });

  final String content;
  final StreamingProjectionStatus status;
  final MessageMetadataEntity? metadata;
}
