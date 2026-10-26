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

import '../../../features/workspace_state/models/workspace_resource_kind.dart'
    as _iz7spkcy;

abstract class WorkspaceContentReport
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WorkspaceContentReport._({
    this.id,
    required this.workspaceId,
    required this.reportId,
    required this.resourceKind,
    required this.resourceId,
    this.tableId,
    required this.revision,
    this.conversationId,
    required this.reporterUserId,
    required this.status,
    required this.submittedAt,
    this.reviewerUserId,
    this.reviewedAt,
  });

  factory WorkspaceContentReport({
    int? id,
    required int workspaceId,
    required String reportId,
    required _iz7spkcy.WorkspaceResourceKind resourceKind,
    required String resourceId,
    String? tableId,
    required int revision,
    String? conversationId,
    required String reporterUserId,
    required String status,
    required DateTime submittedAt,
    String? reviewerUserId,
    DateTime? reviewedAt,
  }) = _WorkspaceContentReportImpl;

  factory WorkspaceContentReport.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceContentReport(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      reportId: jsonSerialization['reportId'] as String,
      resourceKind: _iz7spkcy.WorkspaceResourceKind.fromJson(
        (jsonSerialization['resourceKind'] as String),
      ),
      resourceId: jsonSerialization['resourceId'] as String,
      tableId: jsonSerialization['tableId'] as String?,
      revision: jsonSerialization['revision'] as int,
      conversationId: jsonSerialization['conversationId'] as String?,
      reporterUserId: jsonSerialization['reporterUserId'] as String,
      status: jsonSerialization['status'] as String,
      submittedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['submittedAt'],
      ),
      reviewerUserId: jsonSerialization['reviewerUserId'] as String?,
      reviewedAt: jsonSerialization['reviewedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['reviewedAt'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int workspaceId;

  String reportId;

  _iz7spkcy.WorkspaceResourceKind resourceKind;

  String resourceId;

  String? tableId;

  int revision;

  String? conversationId;

  String reporterUserId;

  String status;

  DateTime submittedAt;

  String? reviewerUserId;

  DateTime? reviewedAt;

  /// Returns a shallow copy of this [WorkspaceContentReport]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WorkspaceContentReport copyWith({
    int? id,
    int? workspaceId,
    String? reportId,
    _iz7spkcy.WorkspaceResourceKind? resourceKind,
    String? resourceId,
    String? tableId,
    int? revision,
    String? conversationId,
    String? reporterUserId,
    String? status,
    DateTime? submittedAt,
    String? reviewerUserId,
    DateTime? reviewedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceContentReport',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'reportId': reportId,
      'resourceKind': resourceKind.toJson(),
      'resourceId': resourceId,
      if (tableId != null) 'tableId': tableId,
      'revision': revision,
      if (conversationId != null) 'conversationId': conversationId,
      'reporterUserId': reporterUserId,
      'status': status,
      'submittedAt': submittedAt.toJson(),
      if (reviewerUserId != null) 'reviewerUserId': reviewerUserId,
      if (reviewedAt != null) 'reviewedAt': reviewedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceContentReport',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'reportId': reportId,
      'resourceKind': resourceKind.toJson(),
      'resourceId': resourceId,
      if (tableId != null) 'tableId': tableId,
      'revision': revision,
      if (conversationId != null) 'conversationId': conversationId,
      'reporterUserId': reporterUserId,
      'status': status,
      'submittedAt': submittedAt.toJson(),
      if (reviewerUserId != null) 'reviewerUserId': reviewerUserId,
      if (reviewedAt != null) 'reviewedAt': reviewedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceContentReportImpl extends WorkspaceContentReport {
  _WorkspaceContentReportImpl({
    int? id,
    required int workspaceId,
    required String reportId,
    required _iz7spkcy.WorkspaceResourceKind resourceKind,
    required String resourceId,
    String? tableId,
    required int revision,
    String? conversationId,
    required String reporterUserId,
    required String status,
    required DateTime submittedAt,
    String? reviewerUserId,
    DateTime? reviewedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         reportId: reportId,
         resourceKind: resourceKind,
         resourceId: resourceId,
         tableId: tableId,
         revision: revision,
         conversationId: conversationId,
         reporterUserId: reporterUserId,
         status: status,
         submittedAt: submittedAt,
         reviewerUserId: reviewerUserId,
         reviewedAt: reviewedAt,
       );

  /// Returns a shallow copy of this [WorkspaceContentReport]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WorkspaceContentReport copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? reportId,
    _iz7spkcy.WorkspaceResourceKind? resourceKind,
    String? resourceId,
    Object? tableId = _Undefined,
    int? revision,
    Object? conversationId = _Undefined,
    String? reporterUserId,
    String? status,
    DateTime? submittedAt,
    Object? reviewerUserId = _Undefined,
    Object? reviewedAt = _Undefined,
  }) {
    return WorkspaceContentReport(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      reportId: reportId ?? this.reportId,
      resourceKind: resourceKind ?? this.resourceKind,
      resourceId: resourceId ?? this.resourceId,
      tableId: tableId is String? ? tableId : this.tableId,
      revision: revision ?? this.revision,
      conversationId: conversationId is String?
          ? conversationId
          : this.conversationId,
      reporterUserId: reporterUserId ?? this.reporterUserId,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewerUserId: reviewerUserId is String?
          ? reviewerUserId
          : this.reviewerUserId,
      reviewedAt: reviewedAt is DateTime? ? reviewedAt : this.reviewedAt,
    );
  }
}
