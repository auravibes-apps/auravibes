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
import 'package:auravibes_server/src/generated/protocol.dart' as _if5qez1k;
import 'package:serverpod/serverpod.dart' as _is;

abstract class WorkspaceRecordSummaryRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  WorkspaceRecordSummaryRequest._({
    required this.workspaceId,
    required this.tableId,
    required this.queryJson,
    required this.columnIds,
  });

  factory WorkspaceRecordSummaryRequest({
    required int workspaceId,
    required String tableId,
    required String queryJson,
    required List<String> columnIds,
  }) = _WorkspaceRecordSummaryRequestImpl;

  factory WorkspaceRecordSummaryRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceRecordSummaryRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      tableId: jsonSerialization['tableId'] as String,
      queryJson: jsonSerialization['queryJson'] as String,
      columnIds: _if5qez1k.Protocol().deserialize<List<String>>(
        jsonSerialization['columnIds'],
      ),
    );
  }

  int workspaceId;

  String tableId;

  String queryJson;

  List<String> columnIds;

  /// Returns a shallow copy of this [WorkspaceRecordSummaryRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WorkspaceRecordSummaryRequest copyWith({
    int? workspaceId,
    String? tableId,
    String? queryJson,
    List<String>? columnIds,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceRecordSummaryRequest',
      'workspaceId': workspaceId,
      'tableId': tableId,
      'queryJson': queryJson,
      'columnIds': columnIds.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceRecordSummaryRequest',
      'workspaceId': workspaceId,
      'tableId': tableId,
      'queryJson': queryJson,
      'columnIds': columnIds.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _WorkspaceRecordSummaryRequestImpl extends WorkspaceRecordSummaryRequest {
  _WorkspaceRecordSummaryRequestImpl({
    required int workspaceId,
    required String tableId,
    required String queryJson,
    required List<String> columnIds,
  }) : super._(
         workspaceId: workspaceId,
         tableId: tableId,
         queryJson: queryJson,
         columnIds: columnIds,
       );

  /// Returns a shallow copy of this [WorkspaceRecordSummaryRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WorkspaceRecordSummaryRequest copyWith({
    int? workspaceId,
    String? tableId,
    String? queryJson,
    List<String>? columnIds,
  }) {
    return WorkspaceRecordSummaryRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      tableId: tableId ?? this.tableId,
      queryJson: queryJson ?? this.queryJson,
      columnIds: columnIds ?? this.columnIds.map((e0) => e0).toList(),
    );
  }
}
