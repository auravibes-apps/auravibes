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

abstract class WorkspaceViewListRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  WorkspaceViewListRequest._({
    required this.workspaceId,
    this.parentId,
    required this.allFolders,
  });

  factory WorkspaceViewListRequest({
    required int workspaceId,
    String? parentId,
    required bool allFolders,
  }) = _WorkspaceViewListRequestImpl;

  factory WorkspaceViewListRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceViewListRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      parentId: jsonSerialization['parentId'] as String?,
      allFolders: _is.BoolJsonExtension.fromJson(
        jsonSerialization['allFolders'],
      ),
    );
  }

  int workspaceId;

  String? parentId;

  bool allFolders;

  /// Returns a shallow copy of this [WorkspaceViewListRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WorkspaceViewListRequest copyWith({
    int? workspaceId,
    String? parentId,
    bool? allFolders,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceViewListRequest',
      'workspaceId': workspaceId,
      if (parentId != null) 'parentId': parentId,
      'allFolders': allFolders,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceViewListRequest',
      'workspaceId': workspaceId,
      if (parentId != null) 'parentId': parentId,
      'allFolders': allFolders,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceViewListRequestImpl extends WorkspaceViewListRequest {
  _WorkspaceViewListRequestImpl({
    required int workspaceId,
    String? parentId,
    required bool allFolders,
  }) : super._(
         workspaceId: workspaceId,
         parentId: parentId,
         allFolders: allFolders,
       );

  /// Returns a shallow copy of this [WorkspaceViewListRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WorkspaceViewListRequest copyWith({
    int? workspaceId,
    Object? parentId = _Undefined,
    bool? allFolders,
  }) {
    return WorkspaceViewListRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      parentId: parentId is String? ? parentId : this.parentId,
      allFolders: allFolders ?? this.allFolders,
    );
  }
}
