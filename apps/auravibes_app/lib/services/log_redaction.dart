import 'package:genkit/plugin.dart';

abstract final class LogRedaction {
  static const _redacted = '[REDACTED]';

  static final _secretPatterns = <RegExp>[
    RegExp(
      r'\b(authorization\s*[:=]\s*bearer\s+)[^\s,;]+',
      caseSensitive: false,
    ),
    RegExp(r'\b(bearer\s+)[^\s,;]+', caseSensitive: false),
    RegExp(
      r'\b((?:api[_-]?key|access[_-]?token|refresh[_-]?token|client[_-]?secret|id[_-]?token|code[_-]?verifier|authorization[_-]?code|verification[_-]?code|token|secret|password|code|state|nonce)\s*[:=]\s*)[^\s,;&]+',
      caseSensitive: false,
    ),
    RegExp(
      '(["\'](?:api[_-]?key|access[_-]?token|refresh[_-]?token|'
      'client[_-]?secret|id[_-]?token|code[_-]?verifier|authorization[_-]?code|verification[_-]?code|token|secret|password|code|state|nonce)["\']\\s*:\\s*["\'])'
      '[^"\']+',
      caseSensitive: false,
    ),
    RegExp(
      r'([?&](?:api[_-]?key|access[_-]?token|refresh[_-]?token|client[_-]?secret|id[_-]?token|code[_-]?verifier|authorization[_-]?code|verification[_-]?code|token|secret|password|code|state|nonce)=)[^&#\s]+',
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
    final GenkitException error => _genkitExceptionText(error),
    _ => '${value.runtimeType}',
  };

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

    return '$prefix$_redacted';
  }
}
