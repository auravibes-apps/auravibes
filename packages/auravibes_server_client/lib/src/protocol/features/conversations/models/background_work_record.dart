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

abstract class BackgroundWorkRecord
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  BackgroundWorkRecord._({
    this.id,
    required this.workspaceId,
    required this.conversationId,
    required this.conversationToolCallId,
    this.originatingMessageId,
    required this.stableId,
    required this.toolCallId,
    required this.toolKind,
    this.runtimeServerId,
    required this.status,
    this.statusPreview,
    this.resultContent,
    int? resultByteLength,
    this.errorCode,
    required this.createdAt,
    required this.updatedAt,
  }) : resultByteLength = resultByteLength ?? 0;

  factory BackgroundWorkRecord({
    int? id,
    required int workspaceId,
    required int conversationId,
    required int conversationToolCallId,
    int? originatingMessageId,
    required String stableId,
    required String toolCallId,
    required String toolKind,
    String? runtimeServerId,
    required String status,
    String? statusPreview,
    String? resultContent,
    int? resultByteLength,
    String? errorCode,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _BackgroundWorkRecordImpl;

  factory BackgroundWorkRecord.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return BackgroundWorkRecord(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as int,
      conversationToolCallId:
          jsonSerialization['conversationToolCallId'] as int,
      originatingMessageId: jsonSerialization['originatingMessageId'] as int?,
      stableId: jsonSerialization['stableId'] as String,
      toolCallId: jsonSerialization['toolCallId'] as String,
      toolKind: jsonSerialization['toolKind'] as String,
      runtimeServerId: jsonSerialization['runtimeServerId'] as String?,
      status: jsonSerialization['status'] as String,
      statusPreview: jsonSerialization['statusPreview'] as String?,
      resultContent: jsonSerialization['resultContent'] as String?,
      resultByteLength: jsonSerialization['resultByteLength'] as int?,
      errorCode: jsonSerialization['errorCode'] as String?,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int workspaceId;

  int conversationId;

  int conversationToolCallId;

  int? originatingMessageId;

  String stableId;

  String toolCallId;

  String toolKind;

  String? runtimeServerId;

  String status;

  String? statusPreview;

  String? resultContent;

  int resultByteLength;

  String? errorCode;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [BackgroundWorkRecord]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  BackgroundWorkRecord copyWith({
    int? id,
    int? workspaceId,
    int? conversationId,
    int? conversationToolCallId,
    int? originatingMessageId,
    String? stableId,
    String? toolCallId,
    String? toolKind,
    String? runtimeServerId,
    String? status,
    String? statusPreview,
    String? resultContent,
    int? resultByteLength,
    String? errorCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BackgroundWorkRecord',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'conversationToolCallId': conversationToolCallId,
      if (originatingMessageId != null)
        'originatingMessageId': originatingMessageId,
      'stableId': stableId,
      'toolCallId': toolCallId,
      'toolKind': toolKind,
      if (runtimeServerId != null) 'runtimeServerId': runtimeServerId,
      'status': status,
      if (statusPreview != null) 'statusPreview': statusPreview,
      if (resultContent != null) 'resultContent': resultContent,
      'resultByteLength': resultByteLength,
      if (errorCode != null) 'errorCode': errorCode,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BackgroundWorkRecord',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'conversationToolCallId': conversationToolCallId,
      if (originatingMessageId != null)
        'originatingMessageId': originatingMessageId,
      'stableId': stableId,
      'toolCallId': toolCallId,
      'toolKind': toolKind,
      if (runtimeServerId != null) 'runtimeServerId': runtimeServerId,
      'status': status,
      if (statusPreview != null) 'statusPreview': statusPreview,
      if (resultContent != null) 'resultContent': resultContent,
      'resultByteLength': resultByteLength,
      if (errorCode != null) 'errorCode': errorCode,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BackgroundWorkRecordImpl extends BackgroundWorkRecord {
  _BackgroundWorkRecordImpl({
    int? id,
    required int workspaceId,
    required int conversationId,
    required int conversationToolCallId,
    int? originatingMessageId,
    required String stableId,
    required String toolCallId,
    required String toolKind,
    String? runtimeServerId,
    required String status,
    String? statusPreview,
    String? resultContent,
    int? resultByteLength,
    String? errorCode,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         conversationId: conversationId,
         conversationToolCallId: conversationToolCallId,
         originatingMessageId: originatingMessageId,
         stableId: stableId,
         toolCallId: toolCallId,
         toolKind: toolKind,
         runtimeServerId: runtimeServerId,
         status: status,
         statusPreview: statusPreview,
         resultContent: resultContent,
         resultByteLength: resultByteLength,
         errorCode: errorCode,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [BackgroundWorkRecord]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  BackgroundWorkRecord copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? conversationId,
    int? conversationToolCallId,
    Object? originatingMessageId = _Undefined,
    String? stableId,
    String? toolCallId,
    String? toolKind,
    Object? runtimeServerId = _Undefined,
    String? status,
    Object? statusPreview = _Undefined,
    Object? resultContent = _Undefined,
    int? resultByteLength,
    Object? errorCode = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BackgroundWorkRecord(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      conversationToolCallId:
          conversationToolCallId ?? this.conversationToolCallId,
      originatingMessageId: originatingMessageId is int?
          ? originatingMessageId
          : this.originatingMessageId,
      stableId: stableId ?? this.stableId,
      toolCallId: toolCallId ?? this.toolCallId,
      toolKind: toolKind ?? this.toolKind,
      runtimeServerId: runtimeServerId is String?
          ? runtimeServerId
          : this.runtimeServerId,
      status: status ?? this.status,
      statusPreview: statusPreview is String?
          ? statusPreview
          : this.statusPreview,
      resultContent: resultContent is String?
          ? resultContent
          : this.resultContent,
      resultByteLength: resultByteLength ?? this.resultByteLength,
      errorCode: errorCode is String? ? errorCode : this.errorCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
