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

abstract class WorkspaceViewMove
    implements _is.SerializableModel, _is.ProtocolSerialization {
  WorkspaceViewMove._({
    required this.id,
    required this.expectedRevision,
    this.parentId,
    this.name,
  });

  factory WorkspaceViewMove({
    required String id,
    required int expectedRevision,
    String? parentId,
    String? name,
  }) = _WorkspaceViewMoveImpl;

  factory WorkspaceViewMove.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceViewMove(
      id: jsonSerialization['id'] as String,
      expectedRevision: jsonSerialization['expectedRevision'] as int,
      parentId: jsonSerialization['parentId'] as String?,
      name: jsonSerialization['name'] as String?,
    );
  }

  String id;

  int expectedRevision;

  String? parentId;

  String? name;

  /// Returns a shallow copy of this [WorkspaceViewMove]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WorkspaceViewMove copyWith({
    String? id,
    int? expectedRevision,
    String? parentId,
    String? name,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceViewMove',
      'id': id,
      'expectedRevision': expectedRevision,
      if (parentId != null) 'parentId': parentId,
      if (name != null) 'name': name,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceViewMove',
      'id': id,
      'expectedRevision': expectedRevision,
      if (parentId != null) 'parentId': parentId,
      if (name != null) 'name': name,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceViewMoveImpl extends WorkspaceViewMove {
  _WorkspaceViewMoveImpl({
    required String id,
    required int expectedRevision,
    String? parentId,
    String? name,
  }) : super._(
         id: id,
         expectedRevision: expectedRevision,
         parentId: parentId,
         name: name,
       );

  /// Returns a shallow copy of this [WorkspaceViewMove]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WorkspaceViewMove copyWith({
    String? id,
    int? expectedRevision,
    Object? parentId = _Undefined,
    Object? name = _Undefined,
  }) {
    return WorkspaceViewMove(
      id: id ?? this.id,
      expectedRevision: expectedRevision ?? this.expectedRevision,
      parentId: parentId is String? ? parentId : this.parentId,
      name: name is String? ? name : this.name,
    );
  }
}
