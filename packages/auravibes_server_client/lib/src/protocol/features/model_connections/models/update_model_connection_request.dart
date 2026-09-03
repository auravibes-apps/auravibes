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

abstract class UpdateModelConnectionRequest implements _i1.SerializableModel {
  UpdateModelConnectionRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.connectionId,
    required this.expectedRevision,
    required this.name,
    this.url,
  });

  factory UpdateModelConnectionRequest({
    required int workspaceId,
    required String requestId,
    required String connectionId,
    required int expectedRevision,
    required String name,
    String? url,
  }) = _UpdateModelConnectionRequestImpl;

  factory UpdateModelConnectionRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return UpdateModelConnectionRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      connectionId: jsonSerialization['connectionId'] as String,
      expectedRevision: jsonSerialization['expectedRevision'] as int,
      name: jsonSerialization['name'] as String,
      url: jsonSerialization['url'] as String?,
    );
  }

  int workspaceId;

  String requestId;

  String connectionId;

  int expectedRevision;

  String name;

  String? url;

  /// Returns a shallow copy of this [UpdateModelConnectionRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UpdateModelConnectionRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? connectionId,
    int? expectedRevision,
    String? name,
    String? url,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UpdateModelConnectionRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'connectionId': connectionId,
      'expectedRevision': expectedRevision,
      'name': name,
      if (url != null) 'url': url,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UpdateModelConnectionRequestImpl extends UpdateModelConnectionRequest {
  _UpdateModelConnectionRequestImpl({
    required int workspaceId,
    required String requestId,
    required String connectionId,
    required int expectedRevision,
    required String name,
    String? url,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         connectionId: connectionId,
         expectedRevision: expectedRevision,
         name: name,
         url: url,
       );

  /// Returns a shallow copy of this [UpdateModelConnectionRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UpdateModelConnectionRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? connectionId,
    int? expectedRevision,
    String? name,
    Object? url = _Undefined,
  }) {
    return UpdateModelConnectionRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      connectionId: connectionId ?? this.connectionId,
      expectedRevision: expectedRevision ?? this.expectedRevision,
      name: name ?? this.name,
      url: url is String? ? url : this.url,
    );
  }
}
