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
import 'package:serverpod/serverpod.dart' as _is;

abstract class ForkConversationRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ForkConversationRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.forkConversationId,
    required this.sourceConversationId,
    this.throughMessageId,
  });

  factory ForkConversationRequest({
    required int workspaceId,
    required String requestId,
    required String forkConversationId,
    required String sourceConversationId,
    String? throughMessageId,
  }) = _ForkConversationRequestImpl;

  factory ForkConversationRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ForkConversationRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      forkConversationId: jsonSerialization['forkConversationId'] as String,
      sourceConversationId: jsonSerialization['sourceConversationId'] as String,
      throughMessageId: jsonSerialization['throughMessageId'] as String?,
    );
  }

  int workspaceId;

  String requestId;

  String forkConversationId;

  String sourceConversationId;

  String? throughMessageId;

  /// Returns a shallow copy of this [ForkConversationRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ForkConversationRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? forkConversationId,
    String? sourceConversationId,
    String? throughMessageId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ForkConversationRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'forkConversationId': forkConversationId,
      'sourceConversationId': sourceConversationId,
      if (throughMessageId != null) 'throughMessageId': throughMessageId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ForkConversationRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'forkConversationId': forkConversationId,
      'sourceConversationId': sourceConversationId,
      if (throughMessageId != null) 'throughMessageId': throughMessageId,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ForkConversationRequestImpl extends ForkConversationRequest {
  _ForkConversationRequestImpl({
    required int workspaceId,
    required String requestId,
    required String forkConversationId,
    required String sourceConversationId,
    String? throughMessageId,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         forkConversationId: forkConversationId,
         sourceConversationId: sourceConversationId,
         throughMessageId: throughMessageId,
       );

  /// Returns a shallow copy of this [ForkConversationRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ForkConversationRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? forkConversationId,
    String? sourceConversationId,
    Object? throughMessageId = _Undefined,
  }) {
    return ForkConversationRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      forkConversationId: forkConversationId ?? this.forkConversationId,
      sourceConversationId: sourceConversationId ?? this.sourceConversationId,
      throughMessageId: throughMessageId is String?
          ? throughMessageId
          : this.throughMessageId,
    );
  }
}
