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

import '../../../features/conversations/models/conversation_message_view.dart'
    as _iwfcarya;
import '../../../features/conversations/models/conversation_tool_call_view.dart'
    as _irozunu0;
import '../../../features/conversations/models/conversation_turn_view.dart'
    as _igb82ssp;

abstract class TurnSnapshot
    implements _is.SerializableModel, _is.ProtocolSerialization {
  TurnSnapshot._({
    required this.turn,
    required this.messages,
    required this.toolCalls,
    required this.terminal,
  });

  factory TurnSnapshot({
    required _igb82ssp.ConversationTurnView turn,
    required List<_iwfcarya.ConversationMessageView> messages,
    required List<_irozunu0.ConversationToolCallView> toolCalls,
    required bool terminal,
  }) = _TurnSnapshotImpl;

  factory TurnSnapshot.fromJson(Map<String, dynamic> jsonSerialization) {
    return TurnSnapshot(
      turn: _if5qez1k.Protocol().deserialize<_igb82ssp.ConversationTurnView>(
        jsonSerialization['turn'],
      ),
      messages: _if5qez1k.Protocol()
          .deserialize<List<_iwfcarya.ConversationMessageView>>(
            jsonSerialization['messages'],
          ),
      toolCalls: _if5qez1k.Protocol()
          .deserialize<List<_irozunu0.ConversationToolCallView>>(
            jsonSerialization['toolCalls'],
          ),
      terminal: _is.BoolJsonExtension.fromJson(jsonSerialization['terminal']),
    );
  }

  _igb82ssp.ConversationTurnView turn;

  List<_iwfcarya.ConversationMessageView> messages;

  List<_irozunu0.ConversationToolCallView> toolCalls;

  bool terminal;

  /// Returns a shallow copy of this [TurnSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  TurnSnapshot copyWith({
    _igb82ssp.ConversationTurnView? turn,
    List<_iwfcarya.ConversationMessageView>? messages,
    List<_irozunu0.ConversationToolCallView>? toolCalls,
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
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TurnSnapshot',
      'turn': turn.toJsonForProtocol(),
      'messages': messages.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'toolCalls': toolCalls.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'terminal': terminal,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _TurnSnapshotImpl extends TurnSnapshot {
  _TurnSnapshotImpl({
    required _igb82ssp.ConversationTurnView turn,
    required List<_iwfcarya.ConversationMessageView> messages,
    required List<_irozunu0.ConversationToolCallView> toolCalls,
    required bool terminal,
  }) : super._(
         turn: turn,
         messages: messages,
         toolCalls: toolCalls,
         terminal: terminal,
       );

  /// Returns a shallow copy of this [TurnSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  TurnSnapshot copyWith({
    _igb82ssp.ConversationTurnView? turn,
    List<_iwfcarya.ConversationMessageView>? messages,
    List<_irozunu0.ConversationToolCallView>? toolCalls,
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
