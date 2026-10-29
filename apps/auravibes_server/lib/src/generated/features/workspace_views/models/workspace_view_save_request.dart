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

abstract class WorkspaceViewSaveRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  WorkspaceViewSaveRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.viewId,
    required this.expectedRevision,
    required this.definition,
  });

  factory WorkspaceViewSaveRequest({
    required int workspaceId,
    required String requestId,
    required String viewId,
    required int expectedRevision,
    required String definition,
  }) = _WorkspaceViewSaveRequestImpl;

  factory WorkspaceViewSaveRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceViewSaveRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      viewId: jsonSerialization['viewId'] as String,
      expectedRevision: jsonSerialization['expectedRevision'] as int,
      definition: jsonSerialization['definition'] as String,
    );
  }

  int workspaceId;

  String requestId;

  String viewId;

  int expectedRevision;

  String definition;

  /// Returns a shallow copy of this [WorkspaceViewSaveRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WorkspaceViewSaveRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? viewId,
    int? expectedRevision,
    String? definition,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceViewSaveRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'viewId': viewId,
      'expectedRevision': expectedRevision,
      'definition': definition,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceViewSaveRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'viewId': viewId,
      'expectedRevision': expectedRevision,
      'definition': definition,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _WorkspaceViewSaveRequestImpl extends WorkspaceViewSaveRequest {
  _WorkspaceViewSaveRequestImpl({
    required int workspaceId,
    required String requestId,
    required String viewId,
    required int expectedRevision,
    required String definition,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         viewId: viewId,
         expectedRevision: expectedRevision,
         definition: definition,
       );

  /// Returns a shallow copy of this [WorkspaceViewSaveRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WorkspaceViewSaveRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? viewId,
    int? expectedRevision,
    String? definition,
  }) {
    return WorkspaceViewSaveRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      viewId: viewId ?? this.viewId,
      expectedRevision: expectedRevision ?? this.expectedRevision,
      definition: definition ?? this.definition,
    );
  }
}
