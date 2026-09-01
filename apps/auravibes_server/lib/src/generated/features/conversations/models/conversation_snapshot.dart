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

import '../../../features/conversations/models/conversation_projection_view.dart'
    as _i2;
import '../../../features/conversations/models/conversation_message_view.dart'
    as _i3;
import '../../../features/conversations/models/conversation_execution_view.dart'
    as _i4;
import '../../../features/conversations/models/conversation_tool_call_view.dart'
    as _i5;

import 'package:auravibes_server/src/generated/protocol.dart' as _i6;

abstract class ConversationSnapshot
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ConversationSnapshot._({
    required this.conversation,
    required this.messages,
    required this.pendingMessages,
    this.activeExecution,
    required this.toolCalls,
    required this.sequence,
  });

  factory ConversationSnapshot({
    required _i2.ConversationProjectionView conversation,
    required List<_i3.ConversationMessageView> messages,
    required List<_i3.ConversationMessageView> pendingMessages,
    _i4.ConversationExecutionView? activeExecution,
    required List<_i5.ConversationToolCallView> toolCalls,
    required int sequence,
  }) = _ConversationSnapshotImpl;

  factory ConversationSnapshot.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConversationSnapshot(
      conversation: _i6.Protocol().deserialize<_i2.ConversationProjectionView>(
        jsonSerialization['conversation'],
      ),
      messages: _i6.Protocol().deserialize<List<_i3.ConversationMessageView>>(
        jsonSerialization['messages'],
      ),
      pendingMessages: _i6.Protocol()
          .deserialize<List<_i3.ConversationMessageView>>(
            jsonSerialization['pendingMessages'],
          ),
      activeExecution: jsonSerialization['activeExecution'] == null
          ? null
          : _i6.Protocol().deserialize<_i4.ConversationExecutionView>(
              jsonSerialization['activeExecution'],
            ),
      toolCalls: _i6.Protocol().deserialize<List<_i5.ConversationToolCallView>>(
        jsonSerialization['toolCalls'],
      ),
      sequence: jsonSerialization['sequence'] as int,
    );
  }

  _i2.ConversationProjectionView conversation;

  List<_i3.ConversationMessageView> messages;

  List<_i3.ConversationMessageView> pendingMessages;

  _i4.ConversationExecutionView? activeExecution;

  List<_i5.ConversationToolCallView> toolCalls;

  int sequence;

  /// Returns a shallow copy of this [ConversationSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConversationSnapshot copyWith({
    _i2.ConversationProjectionView? conversation,
    List<_i3.ConversationMessageView>? messages,
    List<_i3.ConversationMessageView>? pendingMessages,
    _i4.ConversationExecutionView? activeExecution,
    List<_i5.ConversationToolCallView>? toolCalls,
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
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConversationSnapshotImpl extends ConversationSnapshot {
  _ConversationSnapshotImpl({
    required _i2.ConversationProjectionView conversation,
    required List<_i3.ConversationMessageView> messages,
    required List<_i3.ConversationMessageView> pendingMessages,
    _i4.ConversationExecutionView? activeExecution,
    required List<_i5.ConversationToolCallView> toolCalls,
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
  @_i1.useResult
  @override
  ConversationSnapshot copyWith({
    _i2.ConversationProjectionView? conversation,
    List<_i3.ConversationMessageView>? messages,
    List<_i3.ConversationMessageView>? pendingMessages,
    Object? activeExecution = _Undefined,
    List<_i5.ConversationToolCallView>? toolCalls,
    int? sequence,
  }) {
    return ConversationSnapshot(
      conversation: conversation ?? this.conversation.copyWith(),
      messages: messages ?? this.messages.map((e0) => e0.copyWith()).toList(),
      pendingMessages:
          pendingMessages ??
          this.pendingMessages.map((e0) => e0.copyWith()).toList(),
      activeExecution: activeExecution is _i4.ConversationExecutionView?
          ? activeExecution
          : this.activeExecution?.copyWith(),
      toolCalls:
          toolCalls ?? this.toolCalls.map((e0) => e0.copyWith()).toList(),
      sequence: sequence ?? this.sequence,
    );
  }
}
