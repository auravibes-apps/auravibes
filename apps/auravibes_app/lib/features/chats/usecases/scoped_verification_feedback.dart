import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';

const int _feedbackValueCount = 2;

/// Keeps state and repair authority inside the engine's ordinary context cap.
/// Full normalized paths and check output remain in the durable result record.
Map<String, Object?> buildScopedVerificationFeedback(
  String toolResult,
  ScopedVerificationResult result,
) {
  final verification = _verificationFeedback(result);
  final feedback = _emptyFeedback(verification);
  final budget = _perValueByteBudget(feedback);
  final output = _jsonPrefix(result.output, budget);
  final original = _jsonPrefix(toolResult, budget);
  _writeFeedbackText((
    feedback: feedback,
    verification: verification,
    result: result,
    toolResult: toolResult,
    output: output,
    original: original,
  ));

  return feedback;
}

Map<String, Object?> _verificationFeedback(ScopedVerificationResult result) {
  return <String, Object?>{
    ...result.toJson(),
    'pathCount': result.paths.length,
    'output': '',
  }..remove('paths');
}

Map<String, Object?> _emptyFeedback(Map<String, Object?> verification) => {
  'verification': verification,
  'toolResult': '',
  'toolResultTruncated': false,
};

int _perValueByteBudget(Map<String, Object?> feedback) {
  final overhead = utf8.encode(jsonEncode(feedback)).length;

  return (defaultToolOutputBytes - overhead) ~/ _feedbackValueCount;
}

typedef _FeedbackTextWrite = ({
  Map<String, Object?> feedback,
  Map<String, Object?> verification,
  ScopedVerificationResult result,
  String toolResult,
  String output,
  String original,
});

void _writeFeedbackText(_FeedbackTextWrite request) {
  final feedback = request.feedback;
  final verification = request.verification;
  final result = request.result;
  final toolResult = request.toolResult;
  final output = request.output;
  final original = request.original;
  _writeVerificationFeedback(verification, result, output);
  _writeOriginalFeedback(feedback, original, toolResult);
}

void _writeVerificationFeedback(
  Map<String, Object?> verification,
  ScopedVerificationResult result,
  String output,
) {
  verification['output'] = output;
  verification['outputTruncated'] =
      result.outputTruncated || output != result.output;
}

void _writeOriginalFeedback(
  Map<String, Object?> feedback,
  String original,
  String toolResult,
) {
  feedback['toolResult'] = original;
  feedback['toolResultTruncated'] = original != toolResult;
}

String _jsonPrefix(String source, int budget) {
  final high = _maximumEncodedPrefixLength(source, budget);
  final safe = _avoidSplitSurrogate(source, high);

  return String.fromCharCodes(source.codeUnits.take(safe));
}

int _maximumEncodedPrefixLength(String source, int budget) {
  var low = 0;
  var high = source.length;
  while (low < high) {
    final middle = (low + high + 1) ~/ 2;
    if (_encodedPrefixFits(source, middle, budget)) {
      low = middle;
    } else {
      high = middle - 1;
    }
  }

  return low;
}

bool _encodedPrefixFits(String source, int length, int budget) {
  final prefix = String.fromCharCodes(source.codeUnits.take(length));

  return utf8.encode(jsonEncode(prefix)).length <= budget;
}

int _avoidSplitSurrogate(String source, int length) =>
    _splitsSurrogatePair(source, length) ? length - 1 : length;

bool _splitsSurrogatePair(String source, int length) =>
    length > 0 &&
    length < source.length &&
    _isHighSurrogate(source.codeUnitAt(length - 1)) &&
    _isLowSurrogate(source.codeUnitAt(length));

bool _isHighSurrogate(int codeUnit) => codeUnit >= 0xd800 && codeUnit <= 0xdbff;

bool _isLowSurrogate(int codeUnit) => codeUnit >= 0xdc00 && codeUnit <= 0xdfff;
