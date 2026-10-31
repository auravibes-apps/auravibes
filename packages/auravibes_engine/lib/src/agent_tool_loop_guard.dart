import 'dart:convert';

import 'package:auravibes_engine/src/tool_content_digest.dart';
import 'package:auravibes_engine/src/tool_execution_dispatcher.dart';
import 'package:crypto/crypto.dart';

const maxAgentToolLoopCycleLength = 4;
const maxRecentAgentToolLoopFingerprints = maxAgentToolLoopCycleLength * 2;

String agentToolOutcomeFingerprint({
  required String toolName,
  required String argumentsRaw,
  required AgentToolResultStatus resultStatus,
  String? responseRaw,
  String? responseContextRaw,
  String? outputDigest,
  List<AgentToolResultMedia> media = const [],
}) {
  final canonicalArguments = _canonicalArguments(argumentsRaw);
  final mediaDigests = [
    for (final item in media)
      <String, Object>{
        'bytes': sha256.convert(item.bytes).toString(),
        'mimeType': item.mimeType,
        'size': item.bytes.length,
      },
  ];
  final material = jsonEncode({
    'argumentsDigest': sha256Utf8(canonicalArguments),
    'media': mediaDigests,
    'response': outputDigest == null ? responseRaw : null,
    'responseContext': outputDigest == null ? responseContextRaw : null,
    'responseDigest': outputDigest,
    'status': resultStatus.name,
    'tool': toolName,
  });

  return sha256Utf8(material);
}

String agentToolIterationFingerprint(List<String> outcomeFingerprints) =>
    sha256Utf8(jsonEncode(outcomeFingerprints));

bool hasRepeatedNoProgressToolCycle(
  List<String> previousFingerprints,
  String nextFingerprint,
) {
  final recent = [...previousFingerprints, nextFingerprint];
  final longestCycle = recent.length ~/ 2 < maxAgentToolLoopCycleLength
      ? recent.length ~/ 2
      : maxAgentToolLoopCycleLength;
  for (var cycleLength = 1; cycleLength <= longestCycle; cycleLength++) {
    final repeatedWindowStart = recent.length - cycleLength * 2;
    var matches = true;
    for (var index = 0; index < cycleLength; index++) {
      if (recent[repeatedWindowStart + index] !=
          recent[repeatedWindowStart + cycleLength + index]) {
        matches = false;
        break;
      }
    }
    if (matches) return true;
  }

  return false;
}

String _canonicalArguments(String argumentsRaw) {
  try {
    return jsonEncode(_canonicalJsonValue(jsonDecode(argumentsRaw)));
  } on FormatException {
    return argumentsRaw;
  }
}

Object? _canonicalJsonValue(Object? value) => switch (value) {
  final Map<String, dynamic> map => _canonicalJsonMap(map),
  final List<dynamic> list => list.map(_canonicalJsonValue).toList(),
  _ => value,
};

Map<String, Object?> _canonicalJsonMap(Map<String, dynamic> map) {
  final keys = map.keys.toList()..sort();

  return {for (final key in keys) key: _canonicalJsonValue(map[key])};
}
