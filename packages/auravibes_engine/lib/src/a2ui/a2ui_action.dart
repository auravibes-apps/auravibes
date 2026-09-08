import 'dart:convert';

/// Canonical human action transported as ordinary chat input metadata.
class A2uiChatAction {
  const new({
    required this.protocolVersion,
    required this.conversationId,
    required this.turnId,
    required this.surfaceId,
    required this.componentId,
    required this.actionName,
    required this.context,
    required this.messageText,
    this.assistantMessageId,
    this.answers = const {},
    this.touchedPaths = const [],
    this.unansweredPaths = const [],
    this.submittedAtUtc,
    this.wireSurfaceId,
  });

  final String protocolVersion;
  final String conversationId;
  final String turnId;
  final String? assistantMessageId;
  final String surfaceId;
  final String? wireSurfaceId;
  final String componentId;
  final String actionName;
  final Map<String, Object?> context;
  final String messageText;
  final Map<String, Object?> answers;
  final List<String> touchedPaths;
  final List<String> unansweredPaths;
  final String? submittedAtUtc;

  Map<String, Object?> toJson() => {
    'protocolVersion': protocolVersion,
    'conversationId': conversationId,
    'turnId': turnId,
    if (assistantMessageId != null) 'assistantMessageId': assistantMessageId,
    'surfaceId': surfaceId,
    if (wireSurfaceId != null) 'wireSurfaceId': wireSurfaceId,
    'componentId': componentId,
    'actionName': actionName,
    'context': context,
    'messageText': messageText,
    'answers': answers,
    'touchedPaths': touchedPaths,
    'unansweredPaths': unansweredPaths,
    if (submittedAtUtc != null) 'submittedAtUtc': submittedAtUtc,
  };

  String get metadataJson => jsonEncode(toJson());
}
