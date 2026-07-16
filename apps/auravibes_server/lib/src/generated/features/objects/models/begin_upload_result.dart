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

abstract class BeginUploadResult
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  BeginUploadResult._({
    required this.objectId,
    required this.revision,
    required this.uploadUrl,
    required this.headers,
    required this.expiresAt,
  });

  factory BeginUploadResult({
    required int objectId,
    required int revision,
    required String uploadUrl,
    required Map<String, String> headers,
    required DateTime expiresAt,
  }) = _BeginUploadResultImpl;

  factory BeginUploadResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return BeginUploadResult(
      objectId: jsonSerialization['objectId'] as int,
      revision: jsonSerialization['revision'] as int,
      uploadUrl: jsonSerialization['uploadUrl'] as String,
      headers: _i2.Protocol().deserialize<Map<String, String>>(
        jsonSerialization['headers'],
      ),
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
    );
  }

  int objectId;

  int revision;

  String uploadUrl;

  Map<String, String> headers;

  DateTime expiresAt;

  /// Returns a shallow copy of this [BeginUploadResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BeginUploadResult copyWith({
    int? objectId,
    int? revision,
    String? uploadUrl,
    Map<String, String>? headers,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BeginUploadResult',
      'objectId': objectId,
      'revision': revision,
      'uploadUrl': uploadUrl,
      'headers': headers.toJson(),
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BeginUploadResult',
      'objectId': objectId,
      'revision': revision,
      'uploadUrl': uploadUrl,
      'headers': headers.toJson(),
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _BeginUploadResultImpl extends BeginUploadResult {
  _BeginUploadResultImpl({
    required int objectId,
    required int revision,
    required String uploadUrl,
    required Map<String, String> headers,
    required DateTime expiresAt,
  }) : super._(
         objectId: objectId,
         revision: revision,
         uploadUrl: uploadUrl,
         headers: headers,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [BeginUploadResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BeginUploadResult copyWith({
    int? objectId,
    int? revision,
    String? uploadUrl,
    Map<String, String>? headers,
    DateTime? expiresAt,
  }) {
    return BeginUploadResult(
      objectId: objectId ?? this.objectId,
      revision: revision ?? this.revision,
      uploadUrl: uploadUrl ?? this.uploadUrl,
      headers:
          headers ??
          this.headers.map(
            (
              key0,
              value0,
            ) => MapEntry(
              key0,
              value0,
            ),
          ),
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
