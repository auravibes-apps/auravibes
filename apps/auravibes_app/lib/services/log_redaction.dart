const _redacted = '[REDACTED]';

String redactLogValue(Object? value) {
  var text = '$value';
  for (final pattern in _secretPatterns) {
    text = text.replaceAllMapped(pattern, (match) {
      final prefix = match.group(1) ?? '';

      return '$prefix$_redacted';
    });
  }

  return text;
}

final _secretPatterns = <RegExp>[
  RegExp(
    r'\b(authorization\s*[:=]\s*bearer\s+)[^\s,;]+',
    caseSensitive: false,
  ),
  RegExp(
    r'\b(bearer\s+)[^\s,;]+',
    caseSensitive: false,
  ),
  RegExp(
    r'\b((?:api[_-]?key|access[_-]?token|refresh[_-]?token|client[_-]?secret|token|secret|password)\s*[:=]\s*)[^\s,;&]+',
    caseSensitive: false,
  ),
  RegExp(
    '(["\'](?:api[_-]?key|access[_-]?token|refresh[_-]?token|'
    'client[_-]?secret|token|secret|password)["\']\\s*:\\s*["\'])'
    '[^"\']+',
    caseSensitive: false,
  ),
  RegExp(
    r'([?&](?:api[_-]?key|access[_-]?token|refresh[_-]?token|client[_-]?secret|token|secret|password)=)[^&#\s]+',
    caseSensitive: false,
  ),
];
