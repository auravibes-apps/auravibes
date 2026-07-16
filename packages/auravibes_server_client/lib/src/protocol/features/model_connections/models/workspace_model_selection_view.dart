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

abstract class WorkspaceModelSelectionView implements _i1.SerializableModel {
  WorkspaceModelSelectionView._({
    required this.id,
    required this.connectionId,
    required this.connectionName,
    this.connectionUrl,
    required this.connectionHasSecret,
    this.connectionKeySuffix,
    required this.providerId,
    required this.modelId,
    required this.modelName,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkspaceModelSelectionView({
    required String id,
    required String connectionId,
    required String connectionName,
    String? connectionUrl,
    required bool connectionHasSecret,
    String? connectionKeySuffix,
    required String providerId,
    required String modelId,
    required String modelName,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _WorkspaceModelSelectionViewImpl;

  factory WorkspaceModelSelectionView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceModelSelectionView(
      id: jsonSerialization['id'] as String,
      connectionId: jsonSerialization['connectionId'] as String,
      connectionName: jsonSerialization['connectionName'] as String,
      connectionUrl: jsonSerialization['connectionUrl'] as String?,
      connectionHasSecret: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['connectionHasSecret'],
      ),
      connectionKeySuffix: jsonSerialization['connectionKeySuffix'] as String?,
      providerId: jsonSerialization['providerId'] as String,
      modelId: jsonSerialization['modelId'] as String,
      modelName: jsonSerialization['modelName'] as String,
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

  String connectionId;

  String connectionName;

  String? connectionUrl;

  bool connectionHasSecret;

  String? connectionKeySuffix;

  String providerId;

  String modelId;

  String modelName;

  int revision;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [WorkspaceModelSelectionView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceModelSelectionView copyWith({
    String? id,
    String? connectionId,
    String? connectionName,
    String? connectionUrl,
    bool? connectionHasSecret,
    String? connectionKeySuffix,
    String? providerId,
    String? modelId,
    String? modelName,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceModelSelectionView',
      'id': id,
      'connectionId': connectionId,
      'connectionName': connectionName,
      if (connectionUrl != null) 'connectionUrl': connectionUrl,
      'connectionHasSecret': connectionHasSecret,
      if (connectionKeySuffix != null)
        'connectionKeySuffix': connectionKeySuffix,
      'providerId': providerId,
      'modelId': modelId,
      'modelName': modelName,
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

class _WorkspaceModelSelectionViewImpl extends WorkspaceModelSelectionView {
  _WorkspaceModelSelectionViewImpl({
    required String id,
    required String connectionId,
    required String connectionName,
    String? connectionUrl,
    required bool connectionHasSecret,
    String? connectionKeySuffix,
    required String providerId,
    required String modelId,
    required String modelName,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         connectionId: connectionId,
         connectionName: connectionName,
         connectionUrl: connectionUrl,
         connectionHasSecret: connectionHasSecret,
         connectionKeySuffix: connectionKeySuffix,
         providerId: providerId,
         modelId: modelId,
         modelName: modelName,
         revision: revision,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [WorkspaceModelSelectionView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceModelSelectionView copyWith({
    String? id,
    String? connectionId,
    String? connectionName,
    Object? connectionUrl = _Undefined,
    bool? connectionHasSecret,
    Object? connectionKeySuffix = _Undefined,
    String? providerId,
    String? modelId,
    String? modelName,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkspaceModelSelectionView(
      id: id ?? this.id,
      connectionId: connectionId ?? this.connectionId,
      connectionName: connectionName ?? this.connectionName,
      connectionUrl: connectionUrl is String?
          ? connectionUrl
          : this.connectionUrl,
      connectionHasSecret: connectionHasSecret ?? this.connectionHasSecret,
      connectionKeySuffix: connectionKeySuffix is String?
          ? connectionKeySuffix
          : this.connectionKeySuffix,
      providerId: providerId ?? this.providerId,
      modelId: modelId ?? this.modelId,
      modelName: modelName ?? this.modelName,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
