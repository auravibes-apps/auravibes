import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';

/// Keeps state and repair authority inside the engine's ordinary context cap.
/// Full normalized paths and check output remain in the durable result record.
Map<String, Object?> buildScopedVerificationFeedback(String toolResult, ScopedVerificationResult result) {
  final verification = <String, Object?>{
    ...result.toJson(), 'pathCount': result.paths.length, 'output': '',
  }..remove('paths');
  final feedback = <String, Object?>{
    'verification': verification, 'toolResult': '', 'toolResultTruncated': false,
  };
  final overhead = utf8.encode(jsonEncode(feedback)).length;
  final budget = (defaultToolOutputBytes - overhead) ~/ 2;
  final output = _jsonPrefix(result.output, budget);
  final original = _jsonPrefix(toolResult, budget);
  verification['output'] = output;
  verification['outputTruncated'] = result.outputTruncated || output != result.output;
  feedback['toolResult'] = original;
  feedback['toolResultTruncated'] = original != toolResult;

  return feedback;
}

String _jsonPrefix(String source, int budget) {
  var low = 0;
  var high = source.length;
  while (low < high) {
    final middle = (low + high + 1) ~/ 2;
    if (utf8.encode(jsonEncode(source.substring(0, middle))).length <= budget) {
      low = middle;
    } else {
      high = middle - 1;
    }
  }
  if (low > 0 && low < source.length &&
      source.codeUnitAt(low - 1) >= 0xd800 && source.codeUnitAt(low - 1) <= 0xdbff &&
      source.codeUnitAt(low) >= 0xdc00 && source.codeUnitAt(low) <= 0xdfff) {
    low--;
  }

  return source.substring(0, low);
}
