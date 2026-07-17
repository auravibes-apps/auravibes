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

abstract class PutWorkspaceSecretResponse implements _i1.SerializableModel {
  PutWorkspaceSecretResponse._({
    required this.configured,
    this.displaySuffix,
    required this.revision,
    required this.sequence,
  });

  factory PutWorkspaceSecretResponse({
    required bool configured,
    String? displaySuffix,
    required int revision,
    required int sequence,
  }) = _PutWorkspaceSecretResponseImpl;

  factory PutWorkspaceSecretResponse.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PutWorkspaceSecretResponse(
      configured: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['configured'],
      ),
      displaySuffix: jsonSerialization['displaySuffix'] as String?,
      revision: jsonSerialization['revision'] as int,
      sequence: jsonSerialization['sequence'] as int,
    );
  }

  bool configured;

  String? displaySuffix;

  int revision;

  int sequence;

  /// Returns a shallow copy of this [PutWorkspaceSecretResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PutWorkspaceSecretResponse copyWith({
    bool? configured,
    String? displaySuffix,
    int? revision,
    int? sequence,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PutWorkspaceSecretResponse',
      'configured': configured,
      if (displaySuffix != null) 'displaySuffix': displaySuffix,
      'revision': revision,
      'sequence': sequence,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PutWorkspaceSecretResponseImpl extends PutWorkspaceSecretResponse {
  _PutWorkspaceSecretResponseImpl({
    required bool configured,
    String? displaySuffix,
    required int revision,
    required int sequence,
  }) : super._(
         configured: configured,
         displaySuffix: displaySuffix,
         revision: revision,
         sequence: sequence,
       );

  /// Returns a shallow copy of this [PutWorkspaceSecretResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PutWorkspaceSecretResponse copyWith({
    bool? configured,
    Object? displaySuffix = _Undefined,
    int? revision,
    int? sequence,
  }) {
    return PutWorkspaceSecretResponse(
      configured: configured ?? this.configured,
      displaySuffix: displaySuffix is String?
          ? displaySuffix
          : this.displaySuffix,
      revision: revision ?? this.revision,
      sequence: sequence ?? this.sequence,
    );
  }
}
