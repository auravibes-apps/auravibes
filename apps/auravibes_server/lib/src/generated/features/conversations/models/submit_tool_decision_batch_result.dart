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

abstract class SubmitToolDecisionBatchResult
    implements _is.SerializableModel, _is.ProtocolSerialization {
  SubmitToolDecisionBatchResult._({
    required this.accepted,
    required this.alreadyHandled,
    required this.conflicted,
  });

  factory SubmitToolDecisionBatchResult({
    required List<String> accepted,
    required List<String> alreadyHandled,
    required List<String> conflicted,
  }) = _SubmitToolDecisionBatchResultImpl;

  factory SubmitToolDecisionBatchResult.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return SubmitToolDecisionBatchResult(
      accepted: _if5qez1k.Protocol().deserialize<List<String>>(
        jsonSerialization['accepted'],
      ),
      alreadyHandled: _if5qez1k.Protocol().deserialize<List<String>>(
        jsonSerialization['alreadyHandled'],
      ),
      conflicted: _if5qez1k.Protocol().deserialize<List<String>>(
        jsonSerialization['conflicted'],
      ),
    );
  }

  List<String> accepted;

  List<String> alreadyHandled;

  List<String> conflicted;

  /// Returns a shallow copy of this [SubmitToolDecisionBatchResult]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SubmitToolDecisionBatchResult copyWith({
    List<String>? accepted,
    List<String>? alreadyHandled,
    List<String>? conflicted,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SubmitToolDecisionBatchResult',
      'accepted': accepted.toJson(),
      'alreadyHandled': alreadyHandled.toJson(),
      'conflicted': conflicted.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SubmitToolDecisionBatchResult',
      'accepted': accepted.toJson(),
      'alreadyHandled': alreadyHandled.toJson(),
      'conflicted': conflicted.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _SubmitToolDecisionBatchResultImpl extends SubmitToolDecisionBatchResult {
  _SubmitToolDecisionBatchResultImpl({
    required List<String> accepted,
    required List<String> alreadyHandled,
    required List<String> conflicted,
  }) : super._(
         accepted: accepted,
         alreadyHandled: alreadyHandled,
         conflicted: conflicted,
       );

  /// Returns a shallow copy of this [SubmitToolDecisionBatchResult]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SubmitToolDecisionBatchResult copyWith({
    List<String>? accepted,
    List<String>? alreadyHandled,
    List<String>? conflicted,
  }) {
    return SubmitToolDecisionBatchResult(
      accepted: accepted ?? this.accepted.map((e0) => e0).toList(),
      alreadyHandled:
          alreadyHandled ?? this.alreadyHandled.map((e0) => e0).toList(),
      conflicted: conflicted ?? this.conflicted.map((e0) => e0).toList(),
    );
  }
}
