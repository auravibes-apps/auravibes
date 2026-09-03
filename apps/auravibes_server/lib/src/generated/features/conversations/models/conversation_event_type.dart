/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;

enum ConversationEventType implements _i1.SerializableModel {
  messageQueued,
  messageEdited,
  messageReordered,
  messageRemoved,
  executionStarted,
  executionStateChanged,
  executionStopped,
  executionCompleted,
  executionFailed,
  executionRetried,
  settingsChanged,
  toolCallCreated,
  toolApprovalRequested,
  toolDecisionRecorded,
  toolResolved;

  static ConversationEventType fromJson(String name) {
    switch (name) {
      case 'messageQueued':
        return ConversationEventType.messageQueued;
      case 'messageEdited':
        return ConversationEventType.messageEdited;
      case 'messageReordered':
        return ConversationEventType.messageReordered;
      case 'messageRemoved':
        return ConversationEventType.messageRemoved;
      case 'executionStarted':
        return ConversationEventType.executionStarted;
      case 'executionStateChanged':
        return ConversationEventType.executionStateChanged;
      case 'executionStopped':
        return ConversationEventType.executionStopped;
      case 'executionCompleted':
        return ConversationEventType.executionCompleted;
      case 'executionFailed':
        return ConversationEventType.executionFailed;
      case 'executionRetried':
        return ConversationEventType.executionRetried;
      case 'settingsChanged':
        return ConversationEventType.settingsChanged;
      case 'toolCallCreated':
        return ConversationEventType.toolCallCreated;
      case 'toolApprovalRequested':
        return ConversationEventType.toolApprovalRequested;
      case 'toolDecisionRecorded':
        return ConversationEventType.toolDecisionRecorded;
      case 'toolResolved':
        return ConversationEventType.toolResolved;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "ConversationEventType"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
