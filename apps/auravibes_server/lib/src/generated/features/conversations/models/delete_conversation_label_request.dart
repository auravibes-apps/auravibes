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

abstract class DeleteConversationLabelRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  DeleteConversationLabelRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.labelId,
  });

  factory DeleteConversationLabelRequest({
    required int workspaceId,
    required String requestId,
    required String labelId,
  }) = _DeleteConversationLabelRequestImpl;

  factory DeleteConversationLabelRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DeleteConversationLabelRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      labelId: jsonSerialization['labelId'] as String,
    );
  }

  int workspaceId;

  String requestId;

  String labelId;

  /// Returns a shallow copy of this [DeleteConversationLabelRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DeleteConversationLabelRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? labelId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeleteConversationLabelRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'labelId': labelId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DeleteConversationLabelRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'labelId': labelId,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _DeleteConversationLabelRequestImpl
    extends DeleteConversationLabelRequest {
  _DeleteConversationLabelRequestImpl({
    required int workspaceId,
    required String requestId,
    required String labelId,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         labelId: labelId,
       );

  /// Returns a shallow copy of this [DeleteConversationLabelRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DeleteConversationLabelRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? labelId,
  }) {
    return DeleteConversationLabelRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      labelId: labelId ?? this.labelId,
    );
  }
}
