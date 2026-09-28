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
import 'package:auravibes_server/src/generated/protocol.dart' as _if5qez1k;
import 'package:serverpod/serverpod.dart' as _is;

abstract class VerifyModelConnectionResult
    implements _is.SerializableModel, _is.ProtocolSerialization {
  VerifyModelConnectionResult._({
    required this.providerId,
    required this.modelIds,
    required this.verificationReceipt,
    required this.expiresAt,
  });

  factory VerifyModelConnectionResult({
    required String providerId,
    required List<String> modelIds,
    required String verificationReceipt,
    required DateTime expiresAt,
  }) = _VerifyModelConnectionResultImpl;

  factory VerifyModelConnectionResult.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return VerifyModelConnectionResult(
      providerId: jsonSerialization['providerId'] as String,
      modelIds: _if5qez1k.Protocol().deserialize<List<String>>(
        jsonSerialization['modelIds'],
      ),
      verificationReceipt: jsonSerialization['verificationReceipt'] as String,
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
    );
  }

  String providerId;

  List<String> modelIds;

  String verificationReceipt;

  DateTime expiresAt;

  /// Returns a shallow copy of this [VerifyModelConnectionResult]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  VerifyModelConnectionResult copyWith({
    String? providerId,
    List<String>? modelIds,
    String? verificationReceipt,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VerifyModelConnectionResult',
      'providerId': providerId,
      'modelIds': modelIds.toJson(),
      'verificationReceipt': verificationReceipt,
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'VerifyModelConnectionResult',
      'providerId': providerId,
      'modelIds': modelIds.toJson(),
      'verificationReceipt': verificationReceipt,
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _VerifyModelConnectionResultImpl extends VerifyModelConnectionResult {
  _VerifyModelConnectionResultImpl({
    required String providerId,
    required List<String> modelIds,
    required String verificationReceipt,
    required DateTime expiresAt,
  }) : super._(
         providerId: providerId,
         modelIds: modelIds,
         verificationReceipt: verificationReceipt,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [VerifyModelConnectionResult]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  VerifyModelConnectionResult copyWith({
    String? providerId,
    List<String>? modelIds,
    String? verificationReceipt,
    DateTime? expiresAt,
  }) {
    return VerifyModelConnectionResult(
      providerId: providerId ?? this.providerId,
      modelIds: modelIds ?? this.modelIds.map((e0) => e0).toList(),
      verificationReceipt: verificationReceipt ?? this.verificationReceipt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
