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

abstract class ModelSyncResult
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ModelSyncResult._({
    required this.providerId,
    required this.modelIds,
  });

  factory ModelSyncResult({
    required String providerId,
    required List<String> modelIds,
  }) = _ModelSyncResultImpl;

  factory ModelSyncResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return ModelSyncResult(
      providerId: jsonSerialization['providerId'] as String,
      modelIds: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['modelIds'],
      ),
    );
  }

  String providerId;

  List<String> modelIds;

  /// Returns a shallow copy of this [ModelSyncResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ModelSyncResult copyWith({
    String? providerId,
    List<String>? modelIds,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ModelSyncResult',
      'providerId': providerId,
      'modelIds': modelIds.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ModelSyncResult',
      'providerId': providerId,
      'modelIds': modelIds.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ModelSyncResultImpl extends ModelSyncResult {
  _ModelSyncResultImpl({
    required String providerId,
    required List<String> modelIds,
  }) : super._(
         providerId: providerId,
         modelIds: modelIds,
       );

  /// Returns a shallow copy of this [ModelSyncResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ModelSyncResult copyWith({
    String? providerId,
    List<String>? modelIds,
  }) {
    return ModelSyncResult(
      providerId: providerId ?? this.providerId,
      modelIds: modelIds ?? this.modelIds.map((e0) => e0).toList(),
    );
  }
}
