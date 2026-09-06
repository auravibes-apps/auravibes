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

abstract class GetTurnRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  GetTurnRequest._({
    required this.workspaceId,
    required this.turnId,
    this.a2uiSupportedComponents,
  });

  factory GetTurnRequest({
    required int workspaceId,
    required String turnId,
    List<String>? a2uiSupportedComponents,
  }) = _GetTurnRequestImpl;

  factory GetTurnRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return GetTurnRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      turnId: jsonSerialization['turnId'] as String,
      a2uiSupportedComponents:
          jsonSerialization['a2uiSupportedComponents'] == null
          ? null
          : _if5qez1k.Protocol().deserialize<List<String>>(
              jsonSerialization['a2uiSupportedComponents'],
            ),
    );
  }

  int workspaceId;

  String turnId;

  List<String>? a2uiSupportedComponents;

  /// Returns a shallow copy of this [GetTurnRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  GetTurnRequest copyWith({
    int? workspaceId,
    String? turnId,
    List<String>? a2uiSupportedComponents,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GetTurnRequest',
      'workspaceId': workspaceId,
      'turnId': turnId,
      if (a2uiSupportedComponents != null)
        'a2uiSupportedComponents': a2uiSupportedComponents?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GetTurnRequest',
      'workspaceId': workspaceId,
      'turnId': turnId,
      if (a2uiSupportedComponents != null)
        'a2uiSupportedComponents': a2uiSupportedComponents?.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GetTurnRequestImpl extends GetTurnRequest {
  _GetTurnRequestImpl({
    required int workspaceId,
    required String turnId,
    List<String>? a2uiSupportedComponents,
  }) : super._(
         workspaceId: workspaceId,
         turnId: turnId,
         a2uiSupportedComponents: a2uiSupportedComponents,
       );

  /// Returns a shallow copy of this [GetTurnRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  GetTurnRequest copyWith({
    int? workspaceId,
    String? turnId,
    Object? a2uiSupportedComponents = _Undefined,
  }) {
    return GetTurnRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      turnId: turnId ?? this.turnId,
      a2uiSupportedComponents: a2uiSupportedComponents is List<String>?
          ? a2uiSupportedComponents
          : this.a2uiSupportedComponents?.map((e0) => e0).toList(),
    );
  }
}
