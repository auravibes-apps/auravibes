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
import 'package:auravibes_server/src/generated/protocol.dart' as _i2;

abstract class ConversationExecutionView
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ConversationExecutionView._({
    required this.id,
    required this.status,
    required this.attempt,
    required this.claimedMessageIds,
    this.assistantMessageId,
    required this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
    this.terminalAt,
  });

  factory ConversationExecutionView({
    required String id,
    required String status,
    required int attempt,
    required List<String> claimedMessageIds,
    String? assistantMessageId,
    required String createdByUserId,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? terminalAt,
  }) = _ConversationExecutionViewImpl;

  factory ConversationExecutionView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConversationExecutionView(
      id: jsonSerialization['id'] as String,
      status: jsonSerialization['status'] as String,
      attempt: jsonSerialization['attempt'] as int,
      claimedMessageIds: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['claimedMessageIds'],
      ),
      assistantMessageId: jsonSerialization['assistantMessageId'] as String?,
      createdByUserId: jsonSerialization['createdByUserId'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      terminalAt: jsonSerialization['terminalAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['terminalAt']),
    );
  }

  String id;

  String status;

  int attempt;

  List<String> claimedMessageIds;

  String? assistantMessageId;

  String createdByUserId;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? terminalAt;

  /// Returns a shallow copy of this [ConversationExecutionView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConversationExecutionView copyWith({
    String? id,
    String? status,
    int? attempt,
    List<String>? claimedMessageIds,
    String? assistantMessageId,
    String? createdByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? terminalAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationExecutionView',
      'id': id,
      'status': status,
      'attempt': attempt,
      'claimedMessageIds': claimedMessageIds.toJson(),
      if (assistantMessageId != null) 'assistantMessageId': assistantMessageId,
      'createdByUserId': createdByUserId,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (terminalAt != null) 'terminalAt': terminalAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConversationExecutionView',
      'id': id,
      'status': status,
      'attempt': attempt,
      'claimedMessageIds': claimedMessageIds.toJson(),
      if (assistantMessageId != null) 'assistantMessageId': assistantMessageId,
      'createdByUserId': createdByUserId,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (terminalAt != null) 'terminalAt': terminalAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConversationExecutionViewImpl extends ConversationExecutionView {
  _ConversationExecutionViewImpl({
    required String id,
    required String status,
    required int attempt,
    required List<String> claimedMessageIds,
    String? assistantMessageId,
    required String createdByUserId,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? terminalAt,
  }) : super._(
         id: id,
         status: status,
         attempt: attempt,
         claimedMessageIds: claimedMessageIds,
         assistantMessageId: assistantMessageId,
         createdByUserId: createdByUserId,
         createdAt: createdAt,
         updatedAt: updatedAt,
         terminalAt: terminalAt,
       );

  /// Returns a shallow copy of this [ConversationExecutionView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConversationExecutionView copyWith({
    String? id,
    String? status,
    int? attempt,
    List<String>? claimedMessageIds,
    Object? assistantMessageId = _Undefined,
    String? createdByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? terminalAt = _Undefined,
  }) {
    return ConversationExecutionView(
      id: id ?? this.id,
      status: status ?? this.status,
      attempt: attempt ?? this.attempt,
      claimedMessageIds:
          claimedMessageIds ?? this.claimedMessageIds.map((e0) => e0).toList(),
      assistantMessageId: assistantMessageId is String?
          ? assistantMessageId
          : this.assistantMessageId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      terminalAt: terminalAt is DateTime? ? terminalAt : this.terminalAt,
    );
  }
}
