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

abstract class RecentModelSelection
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  RecentModelSelection._({
    this.id,
    required this.workspaceId,
    required this.userId,
    required this.selectionId,
    required this.selectedAt,
  });

  factory RecentModelSelection({
    int? id,
    required int workspaceId,
    required String userId,
    required String selectionId,
    required DateTime selectedAt,
  }) = _RecentModelSelectionImpl;

  factory RecentModelSelection.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RecentModelSelection(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      userId: jsonSerialization['userId'] as String,
      selectionId: jsonSerialization['selectionId'] as String,
      selectedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['selectedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int workspaceId;

  String userId;

  String selectionId;

  DateTime selectedAt;

  /// Returns a shallow copy of this [RecentModelSelection]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  RecentModelSelection copyWith({
    int? id,
    int? workspaceId,
    String? userId,
    String? selectionId,
    DateTime? selectedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RecentModelSelection',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'userId': userId,
      'selectionId': selectionId,
      'selectedAt': selectedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RecentModelSelection',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'userId': userId,
      'selectionId': selectionId,
      'selectedAt': selectedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RecentModelSelectionImpl extends RecentModelSelection {
  _RecentModelSelectionImpl({
    int? id,
    required int workspaceId,
    required String userId,
    required String selectionId,
    required DateTime selectedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         userId: userId,
         selectionId: selectionId,
         selectedAt: selectedAt,
       );

  /// Returns a shallow copy of this [RecentModelSelection]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  RecentModelSelection copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? userId,
    String? selectionId,
    DateTime? selectedAt,
  }) {
    return RecentModelSelection(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      userId: userId ?? this.userId,
      selectionId: selectionId ?? this.selectionId,
      selectedAt: selectedAt ?? this.selectedAt,
    );
  }
}
