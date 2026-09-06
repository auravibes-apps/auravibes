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
import 'package:auravibes_server/src/generated/protocol.dart' as _i2;

abstract class ConversationSubscribeRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ConversationSubscribeRequest._({
    required this.workspaceId,
    required this.conversationId,
    required this.afterSequence,
    this.a2uiSupportedComponents,
  });

  factory ConversationSubscribeRequest({
    required int workspaceId,
    required String conversationId,
    required int afterSequence,
    List<String>? a2uiSupportedComponents,
  }) = _ConversationSubscribeRequestImpl;

  factory ConversationSubscribeRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConversationSubscribeRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as String,
      afterSequence: jsonSerialization['afterSequence'] as int,
      a2uiSupportedComponents:
          jsonSerialization['a2uiSupportedComponents'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['a2uiSupportedComponents'],
            ),
    );
  }

  int workspaceId;

  String conversationId;

  int afterSequence;

  List<String>? a2uiSupportedComponents;

  /// Returns a shallow copy of this [ConversationSubscribeRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConversationSubscribeRequest copyWith({
    int? workspaceId,
    String? conversationId,
    int? afterSequence,
    List<String>? a2uiSupportedComponents,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationSubscribeRequest',
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'afterSequence': afterSequence,
      if (a2uiSupportedComponents != null)
        'a2uiSupportedComponents': a2uiSupportedComponents?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConversationSubscribeRequest',
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'afterSequence': afterSequence,
      if (a2uiSupportedComponents != null)
        'a2uiSupportedComponents': a2uiSupportedComponents?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConversationSubscribeRequestImpl extends ConversationSubscribeRequest {
  _ConversationSubscribeRequestImpl({
    required int workspaceId,
    required String conversationId,
    required int afterSequence,
    List<String>? a2uiSupportedComponents,
  }) : super._(
         workspaceId: workspaceId,
         conversationId: conversationId,
         afterSequence: afterSequence,
         a2uiSupportedComponents: a2uiSupportedComponents,
       );

  /// Returns a shallow copy of this [ConversationSubscribeRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConversationSubscribeRequest copyWith({
    int? workspaceId,
    String? conversationId,
    int? afterSequence,
    Object? a2uiSupportedComponents = _Undefined,
  }) {
    return ConversationSubscribeRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      afterSequence: afterSequence ?? this.afterSequence,
      a2uiSupportedComponents: a2uiSupportedComponents is List<String>?
          ? a2uiSupportedComponents
          : this.a2uiSupportedComponents?.map((e0) => e0).toList(),
    );
  }
}
