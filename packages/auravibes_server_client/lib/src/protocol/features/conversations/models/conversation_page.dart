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

import '../../../features/conversations/models/conversation_summary.dart'
    as _i2;

import 'package:auravibes_server_client/src/protocol/protocol.dart' as _i3;

abstract class ConversationPage implements _i1.SerializableModel {
  ConversationPage._({
    required this.conversations,
    this.nextCursor,
  });

  factory ConversationPage({
    required List<_i2.ConversationSummary> conversations,
    String? nextCursor,
  }) = _ConversationPageImpl;

  factory ConversationPage.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConversationPage(
      conversations: _i3.Protocol().deserialize<List<_i2.ConversationSummary>>(
        jsonSerialization['conversations'],
      ),
      nextCursor: jsonSerialization['nextCursor'] as String?,
    );
  }

  List<_i2.ConversationSummary> conversations;

  String? nextCursor;

  /// Returns a shallow copy of this [ConversationPage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConversationPage copyWith({
    List<_i2.ConversationSummary>? conversations,
    String? nextCursor,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationPage',
      'conversations': conversations.toJson(valueToJson: (v) => v.toJson()),
      if (nextCursor != null) 'nextCursor': nextCursor,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConversationPageImpl extends ConversationPage {
  _ConversationPageImpl({
    required List<_i2.ConversationSummary> conversations,
    String? nextCursor,
  }) : super._(
         conversations: conversations,
         nextCursor: nextCursor,
       );

  /// Returns a shallow copy of this [ConversationPage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConversationPage copyWith({
    List<_i2.ConversationSummary>? conversations,
    Object? nextCursor = _Undefined,
  }) {
    return ConversationPage(
      conversations:
          conversations ??
          this.conversations.map((e0) => e0.copyWith()).toList(),
      nextCursor: nextCursor is String? ? nextCursor : this.nextCursor,
    );
  }
}
