import 'dart:convert';

import 'package:auravibes_engine/src/a2ui/a2ui_chat_contract.dart';
import 'package:auravibes_engine/src/a2ui/a2ui_validation.dart';

enum A2uiOperationKind {
  createSurface,
  updateComponents,
  updateDataModel,
  deleteSurface,
}

class A2uiOperation {
  const new({required this.kind, required this.json});

  final A2uiOperationKind kind;
  final Map<String, Object?> json;

  Map<String, Object?> get body =>
      Map<String, Object?>.from(json[kind.name]! as Map);

  String get surfaceId => body['surfaceId']! as String;

  String? get catalogId => body['catalogId'] as String?;

  List<Map<String, Object?>> get components {
    final values = body['components'];
    if (values is! List) return const [];
    return [
      for (final value in values.whereType<Map<Object?, Object?>>())
        Map<String, Object?>.from(value),
    ];
  }
}

class A2uiEnvelope {
  const new({
    required this.envelopeVersion,
    required this.wireVersion,
    required this.interactionMode,
    required this.operation,
    required this.payloadJson,
  });

  final String envelopeVersion;
  final String wireVersion;
  final String interactionMode;
  final A2uiOperation operation;
  final String payloadJson;
}

class A2uiDecodeResult {
  // ignore: unnecessary-nullable, valid and invalid results share one value type.
  const new valid(this.envelope)
    : issue = null,
      wireSurfaceId = null,
      diagnosticPayloadJson = null;

  // ignore: unnecessary-nullable, valid and invalid results share one value type.
  const new invalid(
    this.issue, {
    this.wireSurfaceId,
    this.diagnosticPayloadJson,
  }) : envelope = null;

  final A2uiEnvelope? envelope;
  final A2uiIssueCode? issue;
  final String? wireSurfaceId;
  final String? diagnosticPayloadJson;
}

abstract interface class A2uiWireCodec {
  String get wireVersion;

  A2uiDecodeResult decode(Object? value, {bool allowLegacyBindings = false});

  Iterable<A2uiDecodeResult> decodeAll(
    Object? value, {
    bool allowLegacyBindings = false,
  });

  bool looksLikeCandidate(Object? value);

  String? recoverSurfaceId(Object value);
}

class A2uiV09Codec implements A2uiWireCodec {
  const new();

  @override
  String get wireVersion => a2uiChatWireVersion;

  @override
  A2uiDecodeResult decode(Object? value, {bool allowLegacyBindings = false}) =>
      decodeAll(value, allowLegacyBindings: allowLegacyBindings).first;

  @override
  Iterable<A2uiDecodeResult> decodeAll(
    Object? value, {
    bool allowLegacyBindings = false,
  }) {
    if (value is Map && value['initialSurface'] is Map) {
      return _decodeInitialSurface(
        Map<String, Object?>.from(value),
        allowLegacyBindings: allowLegacyBindings,
      );
    }
    return [_decodeSingle(value, allowLegacyBindings: allowLegacyBindings)];
  }

  A2uiDecodeResult _decodeSingle(
    Object? value, {
    required bool allowLegacyBindings,
  }) {
    if (value is! Map) {
      return const A2uiDecodeResult.invalid(A2uiIssueCode.malformedPayload);
    }
    final outer = Map<String, Object?>.from(value);
    final diagnosticPayloadJson = jsonEncode(outer);
    final raw = outer['message'] is Map
        ? Map<String, Object?>.from(outer['message']! as Map)
        : outer;
    final create = raw['createSurface'];
    if (create is Map && create['sendDataModel'] == true) {
      raw['createSurface'] = {
        ...Map<String, Object?>.from(create),
        'sendDataModel': false,
      };
    }
    final envelopeVersion = outer['protocolVersion'];
    if (envelopeVersion != null && envelopeVersion != a2uiChatProtocolVersion) {
      return A2uiDecodeResult.invalid(
        A2uiIssueCode.unsupportedProtocol,
        wireSurfaceId: recoverSurfaceId(outer),
        diagnosticPayloadJson: diagnosticPayloadJson,
      );
    }
    final mode = outer['interactionMode'];
    if (mode != null && mode is! String) {
      return A2uiDecodeResult.invalid(
        A2uiIssueCode.invalidInteractionMode,
        wireSurfaceId: recoverSurfaceId(raw),
        diagnosticPayloadJson: diagnosticPayloadJson,
      );
    }
    final interactionMode = mode is String ? mode : 'passive';
    if (!a2uiChatInteractionModes.contains(interactionMode)) {
      return A2uiDecodeResult.invalid(
        A2uiIssueCode.invalidInteractionMode,
        wireSurfaceId: recoverSurfaceId(raw),
        diagnosticPayloadJson: diagnosticPayloadJson,
      );
    }
    final issue = A2uiChatContract.validateMessage(
      raw,
      interactionMode: interactionMode,
      allowLegacyBindings: allowLegacyBindings,
    );
    if (issue != null) {
      return A2uiDecodeResult.invalid(
        issue,
        wireSurfaceId: recoverSurfaceId(raw),
        diagnosticPayloadJson: diagnosticPayloadJson,
      );
    }
    final normalizedCreate = raw['createSurface'];
    if (normalizedCreate is Map) {
      raw['createSurface'] = {
        ...Map<String, Object?>.from(normalizedCreate),
        'sendDataModel': false,
      };
    }
    final kind = A2uiOperationKind.values
        .where((candidate) => raw.containsKey(candidate.name))
        .single;
    final payloadJson = jsonEncode({
      'protocolVersion': a2uiChatProtocolVersion,
      'interactionMode': interactionMode,
      'message': raw,
    });
    return A2uiDecodeResult.valid(
      A2uiEnvelope(
        envelopeVersion: a2uiChatProtocolVersion,
        wireVersion: wireVersion,
        interactionMode: interactionMode,
        operation: A2uiOperation(kind: kind, json: raw),
        payloadJson: payloadJson,
      ),
    );
  }

  Iterable<A2uiDecodeResult> _decodeInitialSurface(
    Map<String, Object?> outer, {
    required bool allowLegacyBindings,
  }) {
    final diagnosticPayloadJson = jsonEncode(outer);
    final mode = outer['interactionMode'];
    final initialSurface = outer['initialSurface'];
    if (outer['protocolVersion'] != a2uiChatProtocolVersion) {
      return [
        A2uiDecodeResult.invalid(
          A2uiIssueCode.unsupportedProtocol,
          wireSurfaceId: recoverSurfaceId(outer),
          diagnosticPayloadJson: diagnosticPayloadJson,
        ),
      ];
    }
    if (mode is! String || !a2uiChatInteractionModes.contains(mode)) {
      return [
        A2uiDecodeResult.invalid(
          A2uiIssueCode.invalidInteractionMode,
          wireSurfaceId: recoverSurfaceId(outer),
          diagnosticPayloadJson: diagnosticPayloadJson,
        ),
      ];
    }
    if (initialSurface is! Map) {
      return [
        A2uiDecodeResult.invalid(
          A2uiIssueCode.malformedPayload,
          diagnosticPayloadJson: diagnosticPayloadJson,
        ),
      ];
    }
    final surface = Map<String, Object?>.from(initialSurface);
    final issue = A2uiChatContract.validateInitialSurface(
      surface,
      interactionMode: mode,
      allowLegacyBindings: allowLegacyBindings,
    );
    if (issue != null) {
      return [
        A2uiDecodeResult.invalid(
          issue,
          wireSurfaceId: recoverSurfaceId(outer),
          diagnosticPayloadJson: diagnosticPayloadJson,
        ),
      ];
    }
    final surfaceId = surface['surfaceId']! as String;
    final normalized = <Map<String, Object?>>[
      {
        'version': a2uiChatWireVersion,
        'createSurface': {
          'surfaceId': surfaceId,
          'catalogId': surface['catalogId'],
          'sendDataModel': false,
        },
      },
      if (surface['dataModel'] != null)
        {
          'version': a2uiChatWireVersion,
          'updateDataModel': {
            'surfaceId': surfaceId,
            'path': '/',
            'value': surface['dataModel'],
          },
        },
      {
        'version': a2uiChatWireVersion,
        'updateComponents': {
          'surfaceId': surfaceId,
          'components': surface['components'],
        },
      },
    ];
    return [
      for (final message in normalized)
        _decodeSingle({
          'protocolVersion': a2uiChatProtocolVersion,
          'interactionMode': mode,
          'message': message,
        }, allowLegacyBindings: allowLegacyBindings),
    ];
  }

  @override
  bool looksLikeCandidate(Object? value) {
    if (value is! Map) return false;
    if (value['initialSurface'] is Map) return true;
    final raw = value['message'] is Map ? value['message'] as Map : value;
    return A2uiOperationKind.values.any(
      (operation) => raw.containsKey(operation.name),
    );
  }

  @override
  String? recoverSurfaceId(Object value) {
    if (value is! Map) return null;
    String? read(Map<Object?, Object?> source) {
      final surfaceId = source['surfaceId'];
      return surfaceId is String &&
              surfaceId.isNotEmpty &&
              surfaceId.length <= 200
          ? surfaceId
          : null;
    }

    final direct = read(value);
    if (direct != null) return direct;
    final message = value['message'];
    final raw = message is Map ? message : value;
    final initialSurface = value['initialSurface'];
    if (initialSurface is Map) {
      final surfaceId = read(initialSurface);
      if (surfaceId != null) return surfaceId;
    }
    for (final operation in A2uiOperationKind.values) {
      final body = raw[operation.name];
      if (body is Map) {
        final surfaceId = read(body);
        if (surfaceId != null) return surfaceId;
      }
    }
    return null;
  }
}

const activeA2uiWireCodec = A2uiV09Codec();

String appendA2uiSurfacesToPrompt(String content, Object? metadata) {
  if (metadata is! Map || metadata['a2uiMessages'] is! List) return content;
  final validated = <String>[];
  var totalBytes = 0;
  for (final payload
      in (metadata['a2uiMessages'] as List).whereType<String>()) {
    if (validated.length >= 16) break;
    try {
      for (final result in activeA2uiWireCodec.decodeAll(
        jsonDecode(payload),
        allowLegacyBindings: true,
      )) {
        final envelope = result.envelope;
        if (envelope == null) continue;
        final bytes = utf8.encode(envelope.payloadJson).length;
        if (totalBytes + bytes > maxA2uiChatPayloadBytes) break;
        totalBytes += bytes;
        validated.add(envelope.payloadJson);
      }
    } on Object catch (_) {
      continue;
    }
  }
  if (validated.isEmpty) return content;
  final separator = content.isEmpty ? '' : '\n\n';
  return '$content${separator}The assistant presented this interface:\n'
      '${validated.join('\n')}';
}
