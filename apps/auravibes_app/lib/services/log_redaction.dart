import 'package:genkit/plugin.dart';

abstract final class LogRedaction {
  static const _redacted = '[REDACTED]';

  static final _secretPatterns = <RegExp>[
    RegExp(r'(\b)(?:sk|rk)-[A-Za-z0-9_-]+\b'),
    RegExp(
      r'\b(authorization\s*[:=]\s*bearer\s+)[^\s,;]+',
      caseSensitive: false,
    ),
    RegExp(
      r'\b(authorization\s*[:=]\s*basic\s+)[^\s,;]+',
      caseSensitive: false,
    ),
    RegExp(r'\b(bearer\s+)[^\s,;]+', caseSensitive: false),
    RegExp(
      r'(?<![\x22\x27])\b((?:set-cookie|cookie)\s*:\s*)[^\r\n]+',
      caseSensitive: false,
    ),
    RegExp(
      r'\b((?:api[_-]?key|access[_-]?token|refresh[_-]?token|auth[_-]?token|oauth[_-]?token|bearer[_-]?token|client[_-]?secret|id[_-]?token|code[_-]?verifier|authorization[_-]?code|verification[_-]?code|token|secret|password|code|state|nonce)\s*[:=]\s*)[^\s,;&]+',
      caseSensitive: false,
    ),
    RegExp(r'(\b[a-z][a-z0-9+.-]*://)(?:[^/@\s]+)(@)', caseSensitive: false),
    RegExp(
      '(["\'](?:x[_-]?api[_-]?key|authorization|api[_-]?key|'
      'access[_-]?token|refresh[_-]?token|'
      'auth[_-]?token|oauth[_-]?token|bearer[_-]?token|client[_-]?secret|'
      'id[_-]?token|code[_-]?verifier|authorization[_-]?code|'
      'verification[_-]?code|token|secret|password|code|state|nonce|'
      'cookie|set-cookie)["\']\\s*:\\s*["\'])'
      '[^"\']+',
      caseSensitive: false,
    ),
    RegExp(
      r'([?&](?:api[_-]?key|access[_-]?token|refresh[_-]?token|auth[_-]?token|oauth[_-]?token|bearer[_-]?token|client[_-]?secret|id[_-]?token|code[_-]?verifier|authorization[_-]?code|verification[_-]?code|x-amz-signature|x-goog-signature|signature|sig|token|secret|password|code|state|nonce)=)[^&#\s\x22\x27]+',
      caseSensitive: false,
    ),
  ];

  // Null is rendered as `null` for defensive logging callers.
  // ignore: unnecessary-nullable
  static String redact(Object? value) => _redact(_textFor(value));

  static String _textFor(Object? value) => switch (value) {
    null => 'null',
    String() => value,
    StackTrace() => '$value',
    final FormatException error => _formatExceptionText(error),
    final GenkitException error => _genkitExceptionText(error),
    _ => '${value.runtimeType}',
  };

  static String _formatExceptionText(FormatException error) {
    final message = error.message;

    return message.isEmpty ? 'FormatException' : 'FormatException: $message';
  }

  static String _genkitExceptionText(GenkitException error) {
    final details = error.details;
    if (details == null || details.isEmpty) return error.message;

    return '${error.message}\nDetails: $details';
  }

  static String _redact(String text) {
    var redacted = text;
    for (final pattern in _secretPatterns) {
      redacted = redacted.replaceAllMapped(pattern, _replaceMatch);
    }

    return redacted;
  }

  static String _replaceMatch(Match match) {
    final prefix = match.group(1) ?? '';
    if (match.groupCount == 2) {
      return '$prefix$_redacted${match.group(2)}';
    }

    return '$prefix$_redacted';
  }
}
