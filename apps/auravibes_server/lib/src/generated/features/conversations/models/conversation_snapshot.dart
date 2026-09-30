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
import 'package:auravibes_server/src/generated/protocol.dart' as _if5qez1k;
import 'package:serverpod/serverpod.dart' as _is;

import '../../../features/conversations/models/conversation_execution_view.dart'
    as _iid4e7gg;
import '../../../features/conversations/models/conversation_message_view.dart'
    as _iwfcarya;
import '../../../features/conversations/models/conversation_projection_view.dart'
    as _iu8ytkcm;
import '../../../features/conversations/models/conversation_tool_call_view.dart'
    as _irozunu0;

abstract class ConversationSnapshot
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ConversationSnapshot._({
    required this.conversation,
    required this.messages,
    required this.pendingMessages,
    this.activeExecution,
    required this.toolCalls,
    required this.sequence,
  });

  factory ConversationSnapshot({
    required _iu8ytkcm.ConversationProjectionView conversation,
    required List<_iwfcarya.ConversationMessageView> messages,
    required List<_iwfcarya.ConversationMessageView> pendingMessages,
    _iid4e7gg.ConversationExecutionView? activeExecution,
    required List<_irozunu0.ConversationToolCallView> toolCalls,
    required int sequence,
  }) = _ConversationSnapshotImpl;

  factory ConversationSnapshot.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConversationSnapshot(
      conversation: _if5qez1k.Protocol()
          .deserialize<_iu8ytkcm.ConversationProjectionView>(
            jsonSerialization['conversation'],
          ),
      messages: _if5qez1k.Protocol()
          .deserialize<List<_iwfcarya.ConversationMessageView>>(
            jsonSerialization['messages'],
          ),
      pendingMessages: _if5qez1k.Protocol()
          .deserialize<List<_iwfcarya.ConversationMessageView>>(
            jsonSerialization['pendingMessages'],
          ),
      activeExecution: jsonSerialization['activeExecution'] == null
          ? null
          : _if5qez1k.Protocol()
                .deserialize<_iid4e7gg.ConversationExecutionView>(
                  jsonSerialization['activeExecution'],
                ),
      toolCalls: _if5qez1k.Protocol()
          .deserialize<List<_irozunu0.ConversationToolCallView>>(
            jsonSerialization['toolCalls'],
          ),
      sequence: jsonSerialization['sequence'] as int,
    );
  }

  _iu8ytkcm.ConversationProjectionView conversation;

  List<_iwfcarya.ConversationMessageView> messages;

  List<_iwfcarya.ConversationMessageView> pendingMessages;

  _iid4e7gg.ConversationExecutionView? activeExecution;

  List<_irozunu0.ConversationToolCallView> toolCalls;

  int sequence;

  /// Returns a shallow copy of this [ConversationSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ConversationSnapshot copyWith({
    _iu8ytkcm.ConversationProjectionView? conversation,
    List<_iwfcarya.ConversationMessageView>? messages,
    List<_iwfcarya.ConversationMessageView>? pendingMessages,
    _iid4e7gg.ConversationExecutionView? activeExecution,
    List<_irozunu0.ConversationToolCallView>? toolCalls,
    int? sequence,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationSnapshot',
      'conversation': conversation.toJson(),
      'messages': messages.toJson(valueToJson: (v) => v.toJson()),
      'pendingMessages': pendingMessages.toJson(valueToJson: (v) => v.toJson()),
      if (activeExecution != null) 'activeExecution': activeExecution?.toJson(),
      'toolCalls': toolCalls.toJson(valueToJson: (v) => v.toJson()),
      'sequence': sequence,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConversationSnapshot',
      'conversation': conversation.toJsonForProtocol(),
      'messages': messages.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'pendingMessages': pendingMessages.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      if (activeExecution != null)
        'activeExecution': activeExecution?.toJsonForProtocol(),
      'toolCalls': toolCalls.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'sequence': sequence,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConversationSnapshotImpl extends ConversationSnapshot {
  _ConversationSnapshotImpl({
    required _iu8ytkcm.ConversationProjectionView conversation,
    required List<_iwfcarya.ConversationMessageView> messages,
    required List<_iwfcarya.ConversationMessageView> pendingMessages,
    _iid4e7gg.ConversationExecutionView? activeExecution,
    required List<_irozunu0.ConversationToolCallView> toolCalls,
    required int sequence,
  }) : super._(
         conversation: conversation,
         messages: messages,
         pendingMessages: pendingMessages,
         activeExecution: activeExecution,
         toolCalls: toolCalls,
         sequence: sequence,
       );

  /// Returns a shallow copy of this [ConversationSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ConversationSnapshot copyWith({
    _iu8ytkcm.ConversationProjectionView? conversation,
    List<_iwfcarya.ConversationMessageView>? messages,
    List<_iwfcarya.ConversationMessageView>? pendingMessages,
    Object? activeExecution = _Undefined,
    List<_irozunu0.ConversationToolCallView>? toolCalls,
    int? sequence,
  }) {
    return ConversationSnapshot(
      conversation: conversation ?? this.conversation.copyWith(),
      messages: messages ?? this.messages.map((e0) => e0.copyWith()).toList(),
      pendingMessages:
          pendingMessages ??
          this.pendingMessages.map((e0) => e0.copyWith()).toList(),
      activeExecution: activeExecution is _iid4e7gg.ConversationExecutionView?
          ? activeExecution
          : this.activeExecution?.copyWith(),
      toolCalls:
          toolCalls ?? this.toolCalls.map((e0) => e0.copyWith()).toList(),
      sequence: sequence ?? this.sequence,
    );
  }
}
