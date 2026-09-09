import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:auravibes_engine/auravibes_engine.dart';

typedef ChatA2uiSurfaceIssue = A2uiIssueCode;

class ChatA2uiMessageState {
  new(this.messageId);

  final String messageId;
  final List<String> payloads = [];
  final List<String> diagnosticPayloads = [];
  final List<ChatA2uiProtocolMessage> pendingMessages = [];
  final Set<String> messageKeys = {};
  final Map<String, String> scopedSurfaceIds = {};
  final List<String> surfaceOrder = [];
  final Set<ChatA2uiSurfaceIssue> issues = {};
  final Set<ChatA2uiSurfaceIssue> messageIssues = {};
  bool closed = false;
  bool blocking = false;
}

class ChatA2uiProtocolMessage {
  const new({required this.envelope, required this.message});

  final A2uiEnvelope envelope;
  final core.A2uiMessage message;
  String get payloadJson => envelope.payloadJson;
  String get interactionMode => envelope.interactionMode;
  A2uiOperation get operation => envelope.operation;
}

class ChatA2uiParseResult {
  // ignore: unnecessary-nullable, valid and invalid results share one value type.
  const new valid(this.message) : issue = null, wireSurfaceId = null;

  // ignore: unnecessary-nullable, valid and invalid results share one value type.
  const new invalid(this.issue, {this.wireSurfaceId}) : message = null;

  final ChatA2uiProtocolMessage? message;
  final ChatA2uiSurfaceIssue? issue;
  final String? wireSurfaceId;
}
