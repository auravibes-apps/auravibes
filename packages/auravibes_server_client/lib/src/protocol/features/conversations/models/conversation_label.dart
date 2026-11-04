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

abstract class ConversationLabel
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ConversationLabel._({
    this.id,
    required this.workspaceId,
    required this.stableId,
    required this.name,
    required this.normalizedName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationLabel({
    int? id,
    required int workspaceId,
    required String stableId,
    required String name,
    required String normalizedName,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ConversationLabelImpl;

  factory ConversationLabel.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConversationLabel(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      stableId: jsonSerialization['stableId'] as String,
      name: jsonSerialization['name'] as String,
      normalizedName: jsonSerialization['normalizedName'] as String,
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

  String stableId;

  String name;

  String normalizedName;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [ConversationLabel]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ConversationLabel copyWith({
    int? id,
    int? workspaceId,
    String? stableId,
    String? name,
    String? normalizedName,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationLabel',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'stableId': stableId,
      'name': name,
      'normalizedName': normalizedName,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConversationLabel',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'stableId': stableId,
      'name': name,
      'normalizedName': normalizedName,
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

class _ConversationLabelImpl extends ConversationLabel {
  _ConversationLabelImpl({
    int? id,
    required int workspaceId,
    required String stableId,
    required String name,
    required String normalizedName,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         stableId: stableId,
         name: name,
         normalizedName: normalizedName,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ConversationLabel]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ConversationLabel copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? stableId,
    String? name,
    String? normalizedName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationLabel(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      stableId: stableId ?? this.stableId,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
