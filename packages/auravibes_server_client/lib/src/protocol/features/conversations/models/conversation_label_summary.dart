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

abstract class ConversationLabelSummary
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ConversationLabelSummary._({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationLabelSummary({
    required String id,
    required int workspaceId,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ConversationLabelSummaryImpl;

  factory ConversationLabelSummary.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConversationLabelSummary(
      id: jsonSerialization['id'] as String,
      workspaceId: jsonSerialization['workspaceId'] as int,
      name: jsonSerialization['name'] as String,
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

  String name;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [ConversationLabelSummary]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ConversationLabelSummary copyWith({
    String? id,
    int? workspaceId,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationLabelSummary',
      'id': id,
      'workspaceId': workspaceId,
      'name': name,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConversationLabelSummary',
      'id': id,
      'workspaceId': workspaceId,
      'name': name,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _ConversationLabelSummaryImpl extends ConversationLabelSummary {
  _ConversationLabelSummaryImpl({
    required String id,
    required int workspaceId,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         name: name,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ConversationLabelSummary]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ConversationLabelSummary copyWith({
    String? id,
    int? workspaceId,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationLabelSummary(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
