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
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import '../../../features/conversations/models/conversation_turn_view.dart'
    as _i2;
import '../../../features/conversations/models/conversation_message_view.dart'
    as _i3;
import '../../../features/conversations/models/conversation_tool_call_view.dart'
    as _i4;
import 'package:auravibes_server_client/src/protocol/protocol.dart' as _i5;

abstract class TurnSnapshot implements _i1.SerializableModel {
  TurnSnapshot._({
    required this.turn,
    required this.messages,
    required this.toolCalls,
    required this.terminal,
  });

  factory TurnSnapshot({
    required _i2.ConversationTurnView turn,
    required List<_i3.ConversationMessageView> messages,
    required List<_i4.ConversationToolCallView> toolCalls,
    required bool terminal,
  }) = _TurnSnapshotImpl;

  factory TurnSnapshot.fromJson(Map<String, dynamic> jsonSerialization) {
    return TurnSnapshot(
      turn: _i5.Protocol().deserialize<_i2.ConversationTurnView>(
        jsonSerialization['turn'],
      ),
      messages: _i5.Protocol().deserialize<List<_i3.ConversationMessageView>>(
        jsonSerialization['messages'],
      ),
      toolCalls: _i5.Protocol().deserialize<List<_i4.ConversationToolCallView>>(
        jsonSerialization['toolCalls'],
      ),
      terminal: _i1.BoolJsonExtension.fromJson(jsonSerialization['terminal']),
    );
  }

  _i2.ConversationTurnView turn;

  List<_i3.ConversationMessageView> messages;

  List<_i4.ConversationToolCallView> toolCalls;

  bool terminal;

  /// Returns a shallow copy of this [TurnSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TurnSnapshot copyWith({
    _i2.ConversationTurnView? turn,
    List<_i3.ConversationMessageView>? messages,
    List<_i4.ConversationToolCallView>? toolCalls,
    bool? terminal,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TurnSnapshot',
      'turn': turn.toJson(),
      'messages': messages.toJson(valueToJson: (v) => v.toJson()),
      'toolCalls': toolCalls.toJson(valueToJson: (v) => v.toJson()),
      'terminal': terminal,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _TurnSnapshotImpl extends TurnSnapshot {
  _TurnSnapshotImpl({
    required _i2.ConversationTurnView turn,
    required List<_i3.ConversationMessageView> messages,
    required List<_i4.ConversationToolCallView> toolCalls,
    required bool terminal,
  }) : super._(
         turn: turn,
         messages: messages,
         toolCalls: toolCalls,
         terminal: terminal,
       );

  /// Returns a shallow copy of this [TurnSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TurnSnapshot copyWith({
    _i2.ConversationTurnView? turn,
    List<_i3.ConversationMessageView>? messages,
    List<_i4.ConversationToolCallView>? toolCalls,
    bool? terminal,
  }) {
    return TurnSnapshot(
      turn: turn ?? this.turn.copyWith(),
      messages: messages ?? this.messages.map((e0) => e0.copyWith()).toList(),
      toolCalls:
          toolCalls ?? this.toolCalls.map((e0) => e0.copyWith()).toList(),
      terminal: terminal ?? this.terminal,
    );
  }
}
