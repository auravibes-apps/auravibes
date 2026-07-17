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

abstract class CreateCloudWorkspaceRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  CreateCloudWorkspaceRequest._({
    required this.name,
    required this.requestId,
  });

  factory CreateCloudWorkspaceRequest({
    required String name,
    required String requestId,
  }) = _CreateCloudWorkspaceRequestImpl;

  factory CreateCloudWorkspaceRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CreateCloudWorkspaceRequest(
      name: jsonSerialization['name'] as String,
      requestId: jsonSerialization['requestId'] as String,
    );
  }

  String name;

  String requestId;

  /// Returns a shallow copy of this [CreateCloudWorkspaceRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CreateCloudWorkspaceRequest copyWith({
    String? name,
    String? requestId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CreateCloudWorkspaceRequest',
      'name': name,
      'requestId': requestId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CreateCloudWorkspaceRequest',
      'name': name,
      'requestId': requestId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _CreateCloudWorkspaceRequestImpl extends CreateCloudWorkspaceRequest {
  _CreateCloudWorkspaceRequestImpl({
    required String name,
    required String requestId,
  }) : super._(
         name: name,
         requestId: requestId,
       );

  /// Returns a shallow copy of this [CreateCloudWorkspaceRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CreateCloudWorkspaceRequest copyWith({
    String? name,
    String? requestId,
  }) {
    return CreateCloudWorkspaceRequest(
      name: name ?? this.name,
      requestId: requestId ?? this.requestId,
    );
  }
}
