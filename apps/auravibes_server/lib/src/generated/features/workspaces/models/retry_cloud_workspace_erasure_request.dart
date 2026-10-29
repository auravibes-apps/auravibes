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
import 'package:serverpod/serverpod.dart' as _is;

abstract class RetryCloudWorkspaceErasureRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  RetryCloudWorkspaceErasureRequest._({required this.requestId});

  factory RetryCloudWorkspaceErasureRequest({required String requestId}) =
      _RetryCloudWorkspaceErasureRequestImpl;

  factory RetryCloudWorkspaceErasureRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RetryCloudWorkspaceErasureRequest(
      requestId: jsonSerialization['requestId'] as String,
    );
  }

  String requestId;

  /// Returns a shallow copy of this [RetryCloudWorkspaceErasureRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  RetryCloudWorkspaceErasureRequest copyWith({String? requestId});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RetryCloudWorkspaceErasureRequest',
      'requestId': requestId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RetryCloudWorkspaceErasureRequest',
      'requestId': requestId,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _RetryCloudWorkspaceErasureRequestImpl
    extends RetryCloudWorkspaceErasureRequest {
  _RetryCloudWorkspaceErasureRequestImpl({required String requestId})
    : super._(requestId: requestId);

  /// Returns a shallow copy of this [RetryCloudWorkspaceErasureRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  RetryCloudWorkspaceErasureRequest copyWith({String? requestId}) {
    return RetryCloudWorkspaceErasureRequest(
      requestId: requestId ?? this.requestId,
    );
  }
}
