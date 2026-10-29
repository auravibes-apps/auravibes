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

abstract class DuplicateWorkspaceItemRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  DuplicateWorkspaceItemRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.sourceId,
    required this.expectedRevision,
    required this.targetId,
    required this.name,
    this.parentId,
    bool? copyRecords,
  }) : copyRecords = copyRecords ?? false;

  factory DuplicateWorkspaceItemRequest({
    required int workspaceId,
    required String requestId,
    required String sourceId,
    required int expectedRevision,
    required String targetId,
    required String name,
    String? parentId,
    bool? copyRecords,
  }) = _DuplicateWorkspaceItemRequestImpl;

  factory DuplicateWorkspaceItemRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DuplicateWorkspaceItemRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      sourceId: jsonSerialization['sourceId'] as String,
      expectedRevision: jsonSerialization['expectedRevision'] as int,
      targetId: jsonSerialization['targetId'] as String,
      name: jsonSerialization['name'] as String,
      parentId: jsonSerialization['parentId'] as String?,
      copyRecords: jsonSerialization['copyRecords'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['copyRecords']),
    );
  }

  int workspaceId;

  String requestId;

  String sourceId;

  int expectedRevision;

  String targetId;

  String name;

  String? parentId;

  bool copyRecords;

  /// Returns a shallow copy of this [DuplicateWorkspaceItemRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DuplicateWorkspaceItemRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? sourceId,
    int? expectedRevision,
    String? targetId,
    String? name,
    String? parentId,
    bool? copyRecords,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DuplicateWorkspaceItemRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'sourceId': sourceId,
      'expectedRevision': expectedRevision,
      'targetId': targetId,
      'name': name,
      if (parentId != null) 'parentId': parentId,
      'copyRecords': copyRecords,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DuplicateWorkspaceItemRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'sourceId': sourceId,
      'expectedRevision': expectedRevision,
      'targetId': targetId,
      'name': name,
      if (parentId != null) 'parentId': parentId,
      'copyRecords': copyRecords,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DuplicateWorkspaceItemRequestImpl extends DuplicateWorkspaceItemRequest {
  _DuplicateWorkspaceItemRequestImpl({
    required int workspaceId,
    required String requestId,
    required String sourceId,
    required int expectedRevision,
    required String targetId,
    required String name,
    String? parentId,
    bool? copyRecords,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         sourceId: sourceId,
         expectedRevision: expectedRevision,
         targetId: targetId,
         name: name,
         parentId: parentId,
         copyRecords: copyRecords,
       );

  /// Returns a shallow copy of this [DuplicateWorkspaceItemRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DuplicateWorkspaceItemRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? sourceId,
    int? expectedRevision,
    String? targetId,
    String? name,
    Object? parentId = _Undefined,
    bool? copyRecords,
  }) {
    return DuplicateWorkspaceItemRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      sourceId: sourceId ?? this.sourceId,
      expectedRevision: expectedRevision ?? this.expectedRevision,
      targetId: targetId ?? this.targetId,
      name: name ?? this.name,
      parentId: parentId is String? ? parentId : this.parentId,
      copyRecords: copyRecords ?? this.copyRecords,
    );
  }
}
