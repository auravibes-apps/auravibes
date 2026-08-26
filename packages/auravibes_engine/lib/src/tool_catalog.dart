import 'dart:convert';

import 'package:auravibes_engine/src/tool_spec.dart';
import 'package:crypto/crypto.dart';

final _validToolName = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

class ToolCatalogCandidate<T> {
  factory ToolCatalogCandidate.reserved({
    required ToolSpec spec,
    required T target,
  }) => ToolCatalogCandidate._(spec, target);

  factory ToolCatalogCandidate.external({
    required ToolSpec spec,
    required T target,
    required String sourceId,
  }) => ToolCatalogCandidate._(spec, target, sourceId);

  const ToolCatalogCandidate._(this.spec, this.target, [this._sourceId]);

  final ToolSpec spec;
  final T target;
  final String? _sourceId;
}

class ToolCatalog<T> {
  ToolCatalog._(List<ToolSpec> specs, Map<String, T> targets)
    : specs = List.unmodifiable(specs),
      _targets = Map.unmodifiable(targets);

  final List<ToolSpec> specs;
  final Map<String, T> _targets;

  T? resolve(String modelName) => _targets[modelName];
}

ToolCatalog<T> buildToolCatalog<T>(
  Iterable<ToolCatalogCandidate<T>> candidates,
) {
  final specs = <ToolSpec>[];
  final targets = <String, T>{};

  for (final candidate in candidates) {
    final sourceId = candidate._sourceId;
    final finalName = sourceId == null
        ? _validatedReservedName(candidate.spec.name)
        : _externalToolName(candidate.spec.name, sourceId);

    if (targets.containsKey(finalName)) {
      throw StateError('Duplicate tool name: $finalName');
    }

    specs.add(
      ToolSpec(
        name: finalName,
        description: candidate.spec.description,
        inputJsonSchema: candidate.spec.inputJsonSchema,
      ),
    );
    targets[finalName] = candidate.target;
  }

  return ToolCatalog._(specs, targets);
}

String stableToolNameSuffix(String sourceId) => base64Url
    .encode(sha256.convert(utf8.encode(sourceId)).bytes.take(8).toList())
    .replaceAll('=', '')
    .substring(0, 10);

String _validatedReservedName(String name) {
  if (!_validToolName.hasMatch(name)) {
    throw ArgumentError.value(name, 'name', 'Invalid reserved tool name');
  }
  return name;
}

String _externalToolName(String preferredName, String sourceId) {
  final readableName = preferredName
      .replaceAll(RegExp('[^A-Za-z0-9_-]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  final readableLength = readableName.length > 53 ? 53 : readableName.length;
  return '${readableName.substring(0, readableLength)}_'
      '${stableToolNameSuffix('$sourceId\u0000$preferredName')}';
}
