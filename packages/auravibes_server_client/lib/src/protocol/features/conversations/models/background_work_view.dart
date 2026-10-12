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

abstract class BackgroundWorkView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  BackgroundWorkView._({
    required this.id,
    required this.workspaceId,
    required this.conversationId,
    this.originatingMessageId,
    required this.toolCallId,
    required this.toolKind,
    required this.status,
    this.statusPreview,
    this.resultContent,
    required this.resultByteLength,
    this.errorCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BackgroundWorkView({
    required String id,
    required int workspaceId,
    required String conversationId,
    String? originatingMessageId,
    required String toolCallId,
    required String toolKind,
    required String status,
    String? statusPreview,
    String? resultContent,
    required int resultByteLength,
    String? errorCode,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _BackgroundWorkViewImpl;

  factory BackgroundWorkView.fromJson(Map<String, dynamic> jsonSerialization) {
    return BackgroundWorkView(
      id: jsonSerialization['id'] as String,
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as String,
      originatingMessageId:
          jsonSerialization['originatingMessageId'] as String?,
      toolCallId: jsonSerialization['toolCallId'] as String,
      toolKind: jsonSerialization['toolKind'] as String,
      status: jsonSerialization['status'] as String,
      statusPreview: jsonSerialization['statusPreview'] as String?,
      resultContent: jsonSerialization['resultContent'] as String?,
      resultByteLength: jsonSerialization['resultByteLength'] as int,
      errorCode: jsonSerialization['errorCode'] as String?,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  String id;

  int workspaceId;

  String conversationId;

  String? originatingMessageId;

  String toolCallId;

  String toolKind;

  String status;

  String? statusPreview;

  String? resultContent;

  int resultByteLength;

  String? errorCode;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [BackgroundWorkView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  BackgroundWorkView copyWith({
    String? id,
    int? workspaceId,
    String? conversationId,
    String? originatingMessageId,
    String? toolCallId,
    String? toolKind,
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
      '__className__': 'BackgroundWorkView',
      'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      if (originatingMessageId != null)
        'originatingMessageId': originatingMessageId,
      'toolCallId': toolCallId,
      'toolKind': toolKind,
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
      '__className__': 'BackgroundWorkView',
      'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      if (originatingMessageId != null)
        'originatingMessageId': originatingMessageId,
      'toolCallId': toolCallId,
      'toolKind': toolKind,
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

class _BackgroundWorkViewImpl extends BackgroundWorkView {
  _BackgroundWorkViewImpl({
    required String id,
    required int workspaceId,
    required String conversationId,
    String? originatingMessageId,
    required String toolCallId,
    required String toolKind,
    required String status,
    String? statusPreview,
    String? resultContent,
    required int resultByteLength,
    String? errorCode,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         conversationId: conversationId,
         originatingMessageId: originatingMessageId,
         toolCallId: toolCallId,
         toolKind: toolKind,
         status: status,
         statusPreview: statusPreview,
         resultContent: resultContent,
         resultByteLength: resultByteLength,
         errorCode: errorCode,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [BackgroundWorkView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  BackgroundWorkView copyWith({
    String? id,
    int? workspaceId,
    String? conversationId,
    Object? originatingMessageId = _Undefined,
    String? toolCallId,
    String? toolKind,
    String? status,
    Object? statusPreview = _Undefined,
    Object? resultContent = _Undefined,
    int? resultByteLength,
    Object? errorCode = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BackgroundWorkView(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      originatingMessageId: originatingMessageId is String?
          ? originatingMessageId
          : this.originatingMessageId,
      toolCallId: toolCallId ?? this.toolCallId,
      toolKind: toolKind ?? this.toolKind,
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
