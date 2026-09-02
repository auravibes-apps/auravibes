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
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class ConversationTurnView._({
  required var String id,
  required var String conversationId,
  var String? userMessageId,
  var String? assistantMessageId,
  required var String status,
  required var int revision,
  required var int acceptedSequence,
  var DateTime? cancellationRequestedAt,
  var DateTime? terminalAt,
  required var DateTime createdAt,
  required var DateTime updatedAt,
}) implements _i1.SerializableModel {
  factory({
    required String id,
    required String conversationId,
    String? userMessageId,
    String? assistantMessageId,
    required String status,
    required int revision,
    required int acceptedSequence,
    DateTime? cancellationRequestedAt,
    DateTime? terminalAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ConversationTurnViewImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConversationTurnView(
      id: jsonSerialization['id'] as String,
      conversationId: jsonSerialization['conversationId'] as String,
      userMessageId: jsonSerialization['userMessageId'] as String?,
      assistantMessageId: jsonSerialization['assistantMessageId'] as String?,
      status: jsonSerialization['status'] as String,
      revision: jsonSerialization['revision'] as int,
      acceptedSequence: jsonSerialization['acceptedSequence'] as int,
      cancellationRequestedAt:
          jsonSerialization['cancellationRequestedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['cancellationRequestedAt'],
            ),
      terminalAt: jsonSerialization['terminalAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['terminalAt']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// Returns a shallow copy of this [ConversationTurnView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConversationTurnView copyWith({
    String? id,
    String? conversationId,
    String? userMessageId,
    String? assistantMessageId,
    String? status,
    int? revision,
    int? acceptedSequence,
    DateTime? cancellationRequestedAt,
    DateTime? terminalAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationTurnView',
      'id': id,
      'conversationId': conversationId,
      if (userMessageId != null) 'userMessageId': userMessageId,
      if (assistantMessageId != null) 'assistantMessageId': assistantMessageId,
      'status': status,
      'revision': revision,
      'acceptedSequence': acceptedSequence,
      if (cancellationRequestedAt != null)
        'cancellationRequestedAt': cancellationRequestedAt?.toJson(),
      if (terminalAt != null) 'terminalAt': terminalAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined;

class _ConversationTurnViewImpl({
  required String id,
  required String conversationId,
  String? userMessageId,
  String? assistantMessageId,
  required String status,
  required int revision,
  required int acceptedSequence,
  DateTime? cancellationRequestedAt,
  DateTime? terminalAt,
  required DateTime createdAt,
  required DateTime updatedAt,
}) extends ConversationTurnView {
  this
    : super._(
        id: id,
        conversationId: conversationId,
        userMessageId: userMessageId,
        assistantMessageId: assistantMessageId,
        status: status,
        revision: revision,
        acceptedSequence: acceptedSequence,
        cancellationRequestedAt: cancellationRequestedAt,
        terminalAt: terminalAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Returns a shallow copy of this [ConversationTurnView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConversationTurnView copyWith({
    String? id,
    String? conversationId,
    Object? userMessageId = _Undefined,
    Object? assistantMessageId = _Undefined,
    String? status,
    int? revision,
    int? acceptedSequence,
    Object? cancellationRequestedAt = _Undefined,
    Object? terminalAt = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationTurnView(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      userMessageId: userMessageId is String?
          ? userMessageId
          : this.userMessageId,
      assistantMessageId: assistantMessageId is String?
          ? assistantMessageId
          : this.assistantMessageId,
      status: status ?? this.status,
      revision: revision ?? this.revision,
      acceptedSequence: acceptedSequence ?? this.acceptedSequence,
      cancellationRequestedAt: cancellationRequestedAt is DateTime?
          ? cancellationRequestedAt
          : this.cancellationRequestedAt,
      terminalAt: terminalAt is DateTime? ? terminalAt : this.terminalAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
