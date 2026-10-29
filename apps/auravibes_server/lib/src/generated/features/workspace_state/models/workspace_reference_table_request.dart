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

abstract class WorkspaceReferenceTableRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  WorkspaceReferenceTableRequest._({
    required this.workspaceId,
    required this.tableId,
    String? search,
    this.afterId,
  }) : search = search ?? '';

  factory WorkspaceReferenceTableRequest({
    required int workspaceId,
    required String tableId,
    String? search,
    String? afterId,
  }) = _WorkspaceReferenceTableRequestImpl;

  factory WorkspaceReferenceTableRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceReferenceTableRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      tableId: jsonSerialization['tableId'] as String,
      search: jsonSerialization['search'] as String?,
      afterId: jsonSerialization['afterId'] as String?,
    );
  }

  int workspaceId;

  String tableId;

  String search;

  String? afterId;

  /// Returns a shallow copy of this [WorkspaceReferenceTableRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WorkspaceReferenceTableRequest copyWith({
    int? workspaceId,
    String? tableId,
    String? search,
    String? afterId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceReferenceTableRequest',
      'workspaceId': workspaceId,
      'tableId': tableId,
      'search': search,
      if (afterId != null) 'afterId': afterId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceReferenceTableRequest',
      'workspaceId': workspaceId,
      'tableId': tableId,
      'search': search,
      if (afterId != null) 'afterId': afterId,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceReferenceTableRequestImpl
    extends WorkspaceReferenceTableRequest {
  _WorkspaceReferenceTableRequestImpl({
    required int workspaceId,
    required String tableId,
    String? search,
    String? afterId,
  }) : super._(
         workspaceId: workspaceId,
         tableId: tableId,
         search: search,
         afterId: afterId,
       );

  /// Returns a shallow copy of this [WorkspaceReferenceTableRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WorkspaceReferenceTableRequest copyWith({
    int? workspaceId,
    String? tableId,
    String? search,
    Object? afterId = _Undefined,
  }) {
    return WorkspaceReferenceTableRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      tableId: tableId ?? this.tableId,
      search: search ?? this.search,
      afterId: afterId is String? ? afterId : this.afterId,
    );
  }
}
