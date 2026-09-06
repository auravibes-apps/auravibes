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

abstract class GetConversationRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  GetConversationRequest._({
    required this.workspaceId,
    required this.conversationId,
    this.a2uiSupportedComponents,
  });

  factory GetConversationRequest({
    required int workspaceId,
    required String conversationId,
    List<String>? a2uiSupportedComponents,
  }) = _GetConversationRequestImpl;

  factory GetConversationRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return GetConversationRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as String,
      a2uiSupportedComponents:
          jsonSerialization['a2uiSupportedComponents'] == null
          ? null
          : _if5qez1k.Protocol().deserialize<List<String>>(
              jsonSerialization['a2uiSupportedComponents'],
            ),
    );
  }

  int workspaceId;

  String conversationId;

  List<String>? a2uiSupportedComponents;

  /// Returns a shallow copy of this [GetConversationRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  GetConversationRequest copyWith({
    int? workspaceId,
    String? conversationId,
    List<String>? a2uiSupportedComponents,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GetConversationRequest',
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      if (a2uiSupportedComponents != null)
        'a2uiSupportedComponents': a2uiSupportedComponents?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GetConversationRequest',
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      if (a2uiSupportedComponents != null)
        'a2uiSupportedComponents': a2uiSupportedComponents?.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GetConversationRequestImpl extends GetConversationRequest {
  _GetConversationRequestImpl({
    required int workspaceId,
    required String conversationId,
    List<String>? a2uiSupportedComponents,
  }) : super._(
         workspaceId: workspaceId,
         conversationId: conversationId,
         a2uiSupportedComponents: a2uiSupportedComponents,
       );

  /// Returns a shallow copy of this [GetConversationRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  GetConversationRequest copyWith({
    int? workspaceId,
    String? conversationId,
    Object? a2uiSupportedComponents = _Undefined,
  }) {
    return GetConversationRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      a2uiSupportedComponents: a2uiSupportedComponents is List<String>?
          ? a2uiSupportedComponents
          : this.a2uiSupportedComponents?.map((e0) => e0).toList(),
    );
  }
}
