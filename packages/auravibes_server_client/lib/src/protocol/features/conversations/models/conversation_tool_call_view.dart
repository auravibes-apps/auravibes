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

abstract class ConversationToolCallView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ConversationToolCallView._({
    required this.id,
    required this.turnId,
    required this.messageId,
    required this.name,
    required this.argumentsJson,
    required this.argumentsDigest,
    this.userFacingDescription,
    bool? backgroundEligible,
    this.backgroundWorkStableId,
    required this.status,
    this.decision,
    this.resultJson,
    this.resultContextJson,
    bool? resultOutputTruncated,
    this.resultOriginalBytes,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
  }) : backgroundEligible = backgroundEligible ?? false,
       resultOutputTruncated = resultOutputTruncated ?? false;

  factory ConversationToolCallView({
    required String id,
    required String turnId,
    required String messageId,
    required String name,
    required String argumentsJson,
    required String argumentsDigest,
    String? userFacingDescription,
    bool? backgroundEligible,
    String? backgroundWorkStableId,
    required String status,
    String? decision,
    String? resultJson,
    String? resultContextJson,
    bool? resultOutputTruncated,
    int? resultOriginalBytes,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ConversationToolCallViewImpl;

  factory ConversationToolCallView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConversationToolCallView(
      id: jsonSerialization['id'] as String,
      turnId: jsonSerialization['turnId'] as String,
      messageId: jsonSerialization['messageId'] as String,
      name: jsonSerialization['name'] as String,
      argumentsJson: jsonSerialization['argumentsJson'] as String,
      argumentsDigest: jsonSerialization['argumentsDigest'] as String,
      userFacingDescription:
          jsonSerialization['userFacingDescription'] as String?,
      backgroundEligible: jsonSerialization['backgroundEligible'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(
              jsonSerialization['backgroundEligible'],
            ),
      backgroundWorkStableId:
          jsonSerialization['backgroundWorkStableId'] as String?,
      status: jsonSerialization['status'] as String,
      decision: jsonSerialization['decision'] as String?,
      resultJson: jsonSerialization['resultJson'] as String?,
      resultContextJson: jsonSerialization['resultContextJson'] as String?,
      resultOutputTruncated: jsonSerialization['resultOutputTruncated'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(
              jsonSerialization['resultOutputTruncated'],
            ),
      resultOriginalBytes: jsonSerialization['resultOriginalBytes'] as int?,
      revision: jsonSerialization['revision'] as int,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  String id;

  String turnId;

  String messageId;

  String name;

  String argumentsJson;

  String argumentsDigest;

  String? userFacingDescription;

  bool backgroundEligible;

  String? backgroundWorkStableId;

  String status;

  String? decision;

  String? resultJson;

  String? resultContextJson;

  bool resultOutputTruncated;

  int? resultOriginalBytes;

  int revision;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [ConversationToolCallView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ConversationToolCallView copyWith({
    String? id,
    String? turnId,
    String? messageId,
    String? name,
    String? argumentsJson,
    String? argumentsDigest,
    String? userFacingDescription,
    bool? backgroundEligible,
    String? backgroundWorkStableId,
    String? status,
    String? decision,
    String? resultJson,
    String? resultContextJson,
    bool? resultOutputTruncated,
    int? resultOriginalBytes,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationToolCallView',
      'id': id,
      'turnId': turnId,
      'messageId': messageId,
      'name': name,
      'argumentsJson': argumentsJson,
      'argumentsDigest': argumentsDigest,
      if (userFacingDescription != null)
        'userFacingDescription': userFacingDescription,
      'backgroundEligible': backgroundEligible,
      if (backgroundWorkStableId != null)
        'backgroundWorkStableId': backgroundWorkStableId,
      'status': status,
      if (decision != null) 'decision': decision,
      if (resultJson != null) 'resultJson': resultJson,
      if (resultContextJson != null) 'resultContextJson': resultContextJson,
      'resultOutputTruncated': resultOutputTruncated,
      if (resultOriginalBytes != null)
        'resultOriginalBytes': resultOriginalBytes,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConversationToolCallView',
      'id': id,
      'turnId': turnId,
      'messageId': messageId,
      'name': name,
      'argumentsJson': argumentsJson,
      'argumentsDigest': argumentsDigest,
      if (userFacingDescription != null)
        'userFacingDescription': userFacingDescription,
      'backgroundEligible': backgroundEligible,
      if (backgroundWorkStableId != null)
        'backgroundWorkStableId': backgroundWorkStableId,
      'status': status,
      if (decision != null) 'decision': decision,
      if (resultJson != null) 'resultJson': resultJson,
      if (resultContextJson != null) 'resultContextJson': resultContextJson,
      'resultOutputTruncated': resultOutputTruncated,
      if (resultOriginalBytes != null)
        'resultOriginalBytes': resultOriginalBytes,
      'revision': revision,
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

class _ConversationToolCallViewImpl extends ConversationToolCallView {
  _ConversationToolCallViewImpl({
    required String id,
    required String turnId,
    required String messageId,
    required String name,
    required String argumentsJson,
    required String argumentsDigest,
    String? userFacingDescription,
    bool? backgroundEligible,
    String? backgroundWorkStableId,
    required String status,
    String? decision,
    String? resultJson,
    String? resultContextJson,
    bool? resultOutputTruncated,
    int? resultOriginalBytes,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         turnId: turnId,
         messageId: messageId,
         name: name,
         argumentsJson: argumentsJson,
         argumentsDigest: argumentsDigest,
         userFacingDescription: userFacingDescription,
         backgroundEligible: backgroundEligible,
         backgroundWorkStableId: backgroundWorkStableId,
         status: status,
         decision: decision,
         resultJson: resultJson,
         resultContextJson: resultContextJson,
         resultOutputTruncated: resultOutputTruncated,
         resultOriginalBytes: resultOriginalBytes,
         revision: revision,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ConversationToolCallView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ConversationToolCallView copyWith({
    String? id,
    String? turnId,
    String? messageId,
    String? name,
    String? argumentsJson,
    String? argumentsDigest,
    Object? userFacingDescription = _Undefined,
    bool? backgroundEligible,
    Object? backgroundWorkStableId = _Undefined,
    String? status,
    Object? decision = _Undefined,
    Object? resultJson = _Undefined,
    Object? resultContextJson = _Undefined,
    bool? resultOutputTruncated,
    Object? resultOriginalBytes = _Undefined,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationToolCallView(
      id: id ?? this.id,
      turnId: turnId ?? this.turnId,
      messageId: messageId ?? this.messageId,
      name: name ?? this.name,
      argumentsJson: argumentsJson ?? this.argumentsJson,
      argumentsDigest: argumentsDigest ?? this.argumentsDigest,
      userFacingDescription: userFacingDescription is String?
          ? userFacingDescription
          : this.userFacingDescription,
      backgroundEligible: backgroundEligible ?? this.backgroundEligible,
      backgroundWorkStableId: backgroundWorkStableId is String?
          ? backgroundWorkStableId
          : this.backgroundWorkStableId,
      status: status ?? this.status,
      decision: decision is String? ? decision : this.decision,
      resultJson: resultJson is String? ? resultJson : this.resultJson,
      resultContextJson: resultContextJson is String?
          ? resultContextJson
          : this.resultContextJson,
      resultOutputTruncated:
          resultOutputTruncated ?? this.resultOutputTruncated,
      resultOriginalBytes: resultOriginalBytes is int?
          ? resultOriginalBytes
          : this.resultOriginalBytes,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
