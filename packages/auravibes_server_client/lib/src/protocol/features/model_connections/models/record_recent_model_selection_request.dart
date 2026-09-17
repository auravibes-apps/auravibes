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

abstract class RecordRecentModelSelectionRequest
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  RecordRecentModelSelectionRequest._({
    required this.workspaceId,
    required this.selectionId,
  });

  factory RecordRecentModelSelectionRequest({
    required int workspaceId,
    required String selectionId,
  }) = _RecordRecentModelSelectionRequestImpl;

  factory RecordRecentModelSelectionRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RecordRecentModelSelectionRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      selectionId: jsonSerialization['selectionId'] as String,
    );
  }

  int workspaceId;

  String selectionId;

  /// Returns a shallow copy of this [RecordRecentModelSelectionRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  RecordRecentModelSelectionRequest copyWith({
    int? workspaceId,
    String? selectionId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RecordRecentModelSelectionRequest',
      'workspaceId': workspaceId,
      'selectionId': selectionId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RecordRecentModelSelectionRequest',
      'workspaceId': workspaceId,
      'selectionId': selectionId,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _RecordRecentModelSelectionRequestImpl
    extends RecordRecentModelSelectionRequest {
  _RecordRecentModelSelectionRequestImpl({
    required int workspaceId,
    required String selectionId,
  }) : super._(
         workspaceId: workspaceId,
         selectionId: selectionId,
       );

  /// Returns a shallow copy of this [RecordRecentModelSelectionRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  RecordRecentModelSelectionRequest copyWith({
    int? workspaceId,
    String? selectionId,
  }) {
    return RecordRecentModelSelectionRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      selectionId: selectionId ?? this.selectionId,
    );
  }
}
