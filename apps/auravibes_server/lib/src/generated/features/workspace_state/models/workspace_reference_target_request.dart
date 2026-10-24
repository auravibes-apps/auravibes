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

abstract class WorkspaceReferenceTargetRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  WorkspaceReferenceTargetRequest._({
    required this.workspaceId,
    required this.sourceTableId,
    required this.columnId,
    String? search,
    this.afterId,
    this.parentId,
  }) : search = search ?? '';

  factory WorkspaceReferenceTargetRequest({
    required int workspaceId,
    required String sourceTableId,
    required String columnId,
    String? search,
    String? afterId,
    String? parentId,
  }) = _WorkspaceReferenceTargetRequestImpl;

  factory WorkspaceReferenceTargetRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceReferenceTargetRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      sourceTableId: jsonSerialization['sourceTableId'] as String,
      columnId: jsonSerialization['columnId'] as String,
      search: jsonSerialization['search'] as String?,
      afterId: jsonSerialization['afterId'] as String?,
      parentId: jsonSerialization['parentId'] as String?,
    );
  }

  int workspaceId;

  String sourceTableId;

  String columnId;

  String search;

  String? afterId;

  String? parentId;

  /// Returns a shallow copy of this [WorkspaceReferenceTargetRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WorkspaceReferenceTargetRequest copyWith({
    int? workspaceId,
    String? sourceTableId,
    String? columnId,
    String? search,
    String? afterId,
    String? parentId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceReferenceTargetRequest',
      'workspaceId': workspaceId,
      'sourceTableId': sourceTableId,
      'columnId': columnId,
      'search': search,
      if (afterId != null) 'afterId': afterId,
      if (parentId != null) 'parentId': parentId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceReferenceTargetRequest',
      'workspaceId': workspaceId,
      'sourceTableId': sourceTableId,
      'columnId': columnId,
      'search': search,
      if (afterId != null) 'afterId': afterId,
      if (parentId != null) 'parentId': parentId,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceReferenceTargetRequestImpl
    extends WorkspaceReferenceTargetRequest {
  _WorkspaceReferenceTargetRequestImpl({
    required int workspaceId,
    required String sourceTableId,
    required String columnId,
    String? search,
    String? afterId,
    String? parentId,
  }) : super._(
         workspaceId: workspaceId,
         sourceTableId: sourceTableId,
         columnId: columnId,
         search: search,
         afterId: afterId,
         parentId: parentId,
       );

  /// Returns a shallow copy of this [WorkspaceReferenceTargetRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WorkspaceReferenceTargetRequest copyWith({
    int? workspaceId,
    String? sourceTableId,
    String? columnId,
    String? search,
    Object? afterId = _Undefined,
    Object? parentId = _Undefined,
  }) {
    return WorkspaceReferenceTargetRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      sourceTableId: sourceTableId ?? this.sourceTableId,
      columnId: columnId ?? this.columnId,
      search: search ?? this.search,
      afterId: afterId is String? ? afterId : this.afterId,
      parentId: parentId is String? ? parentId : this.parentId,
    );
  }
}
