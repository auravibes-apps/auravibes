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
import 'package:serverpod/serverpod.dart' as _i1;

abstract class ConversationToolCallView
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ConversationToolCallView._({
    required this.id,
    required this.turnId,
    required this.messageId,
    required this.name,
    required this.argumentsJson,
    required this.argumentsDigest,
    required this.status,
    this.decision,
    this.resultJson,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationToolCallView({
    required String id,
    required String turnId,
    required String messageId,
    required String name,
    required String argumentsJson,
    required String argumentsDigest,
    required String status,
    String? decision,
    String? resultJson,
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
      status: jsonSerialization['status'] as String,
      decision: jsonSerialization['decision'] as String?,
      resultJson: jsonSerialization['resultJson'] as String?,
      revision: jsonSerialization['revision'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
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

  String status;

  String? decision;

  String? resultJson;

  int revision;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [ConversationToolCallView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConversationToolCallView copyWith({
    String? id,
    String? turnId,
    String? messageId,
    String? name,
    String? argumentsJson,
    String? argumentsDigest,
    String? status,
    String? decision,
    String? resultJson,
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
      'status': status,
      if (decision != null) 'decision': decision,
      if (resultJson != null) 'resultJson': resultJson,
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
      'status': status,
      if (decision != null) 'decision': decision,
      if (resultJson != null) 'resultJson': resultJson,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
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
    required String status,
    String? decision,
    String? resultJson,
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
         status: status,
         decision: decision,
         resultJson: resultJson,
         revision: revision,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ConversationToolCallView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConversationToolCallView copyWith({
    String? id,
    String? turnId,
    String? messageId,
    String? name,
    String? argumentsJson,
    String? argumentsDigest,
    String? status,
    Object? decision = _Undefined,
    Object? resultJson = _Undefined,
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
      status: status ?? this.status,
      decision: decision is String? ? decision : this.decision,
      resultJson: resultJson is String? ? resultJson : this.resultJson,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
