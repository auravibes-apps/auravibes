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
import 'package:serverpod_client/serverpod_client.dart' as _isc;

abstract class WorkspaceReferenceRecordRequest
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WorkspaceReferenceRecordRequest._({
    required this.workspaceId,
    required this.tableId,
    required this.recordId,
    this.afterId,
  });

  factory WorkspaceReferenceRecordRequest({
    required int workspaceId,
    required String tableId,
    required String recordId,
    String? afterId,
  }) = _WorkspaceReferenceRecordRequestImpl;

  factory WorkspaceReferenceRecordRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceReferenceRecordRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      tableId: jsonSerialization['tableId'] as String,
      recordId: jsonSerialization['recordId'] as String,
      afterId: jsonSerialization['afterId'] as String?,
    );
  }

  int workspaceId;

  String tableId;

  String recordId;

  String? afterId;

  /// Returns a shallow copy of this [WorkspaceReferenceRecordRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WorkspaceReferenceRecordRequest copyWith({
    int? workspaceId,
    String? tableId,
    String? recordId,
    String? afterId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceReferenceRecordRequest',
      'workspaceId': workspaceId,
      'tableId': tableId,
      'recordId': recordId,
      if (afterId != null) 'afterId': afterId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceReferenceRecordRequest',
      'workspaceId': workspaceId,
      'tableId': tableId,
      'recordId': recordId,
      if (afterId != null) 'afterId': afterId,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceReferenceRecordRequestImpl
    extends WorkspaceReferenceRecordRequest {
  _WorkspaceReferenceRecordRequestImpl({
    required int workspaceId,
    required String tableId,
    required String recordId,
    String? afterId,
  }) : super._(
         workspaceId: workspaceId,
         tableId: tableId,
         recordId: recordId,
         afterId: afterId,
       );

  /// Returns a shallow copy of this [WorkspaceReferenceRecordRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WorkspaceReferenceRecordRequest copyWith({
    int? workspaceId,
    String? tableId,
    String? recordId,
    Object? afterId = _Undefined,
  }) {
    return WorkspaceReferenceRecordRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      tableId: tableId ?? this.tableId,
      recordId: recordId ?? this.recordId,
      afterId: afterId is String? ? afterId : this.afterId,
    );
  }
}
