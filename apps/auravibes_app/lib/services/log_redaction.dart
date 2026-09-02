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

  static String redact(Object? value) {
    var text = switch (value) {
      null => 'null',
      String() => value,
      StackTrace() => '$value',
      _ => '${value.runtimeType}',
    };
    for (final pattern in _secretPatterns) {
      text = text.replaceAllMapped(pattern, (match) {
        final prefix = match.group(1) ?? '';

        return '$prefix$_redacted';
      });
    }

    return text;
  }
}
