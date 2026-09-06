import 'package:auravibes_app/features/chats/models/chat_a2ui_message_state.dart';

class ChatA2uiSurfaceState {
  new({
    required this.ownerMessageId,
    required this.wireSurfaceId,
    required this.scopedSurfaceId,
  });

  final String ownerMessageId;
  final String wireSurfaceId;
  final String scopedSurfaceId;
  final Map<String, Map<String, dynamic>> components = {};
  final List<ChatA2uiProtocolMessage> acceptedMessages = [];
  final Set<ChatA2uiSurfaceIssue> issues = {};
  final Set<ChatA2uiSurfaceIssue> submissionIssues = {};
  final Set<String> touchedPaths = {};
  String? catalogId;
  String? interactionMode;
  Map<String, Object?>? initialDataModel;
  bool hasRoot = false;
  bool deleted = false;
}
