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

abstract class GetDownloadResult._({
  required var String downloadUrl,
  required var DateTime expiresAt,
}) implements _i1.SerializableModel {
  factory({
    required String downloadUrl,
    required DateTime expiresAt,
  }) = _GetDownloadResultImpl;

  factory fromJson(Map<String, dynamic> jsonSerialization) {
    return GetDownloadResult(
      downloadUrl: jsonSerialization['downloadUrl'] as String,
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
    );
  }

  /// Returns a shallow copy of this [GetDownloadResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GetDownloadResult copyWith({
    String? downloadUrl,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GetDownloadResult',
      'downloadUrl': downloadUrl,
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _GetDownloadResultImpl({
  required String downloadUrl,
  required DateTime expiresAt,
}) extends GetDownloadResult {
  this
    : super._(
        downloadUrl: downloadUrl,
        expiresAt: expiresAt,
      );

  /// Returns a shallow copy of this [GetDownloadResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GetDownloadResult copyWith({
    String? downloadUrl,
    DateTime? expiresAt,
  }) {
    return GetDownloadResult(
      downloadUrl: downloadUrl ?? this.downloadUrl,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
