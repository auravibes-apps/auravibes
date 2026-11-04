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

abstract class RenameConversationLabelRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  RenameConversationLabelRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.labelId,
    required this.name,
  });

  factory RenameConversationLabelRequest({
    required int workspaceId,
    required String requestId,
    required String labelId,
    required String name,
  }) = _RenameConversationLabelRequestImpl;

  factory RenameConversationLabelRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RenameConversationLabelRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      labelId: jsonSerialization['labelId'] as String,
      name: jsonSerialization['name'] as String,
    );
  }

  int workspaceId;

  String requestId;

  String labelId;

  String name;

  /// Returns a shallow copy of this [RenameConversationLabelRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  RenameConversationLabelRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? labelId,
    String? name,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RenameConversationLabelRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'labelId': labelId,
      'name': name,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RenameConversationLabelRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'labelId': labelId,
      'name': name,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _RenameConversationLabelRequestImpl
    extends RenameConversationLabelRequest {
  _RenameConversationLabelRequestImpl({
    required int workspaceId,
    required String requestId,
    required String labelId,
    required String name,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         labelId: labelId,
         name: name,
       );

  /// Returns a shallow copy of this [RenameConversationLabelRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  RenameConversationLabelRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? labelId,
    String? name,
  }) {
    return RenameConversationLabelRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      labelId: labelId ?? this.labelId,
      name: name ?? this.name,
    );
  }
}
