const _maxProviderErrorLength = 500;
const _providerErrorTruncationSuffix = '... [truncated]';

final _providerSecretPatterns = <RegExp>[
  RegExp(
    r"""([\"']?(?:authorization|proxy-authorization|x-api-key)[\"']?\s*[:=]\s*(?:[\"']?(?:[A-Za-z]+\s+)?))[^,\s}\"']+""",
    caseSensitive: false,
  ),
  RegExp(
    r"""([\"']?(?:api[_-]?key|access[_-]?token|refresh[_-]?token|client[_-]?secret|id[_-]?token|token|secret|password)[\"']?\s*[:=]\s*[\"']?)(?:Bearer\s+)?[^,\s}\"']+""",
    caseSensitive: false,
  ),
  RegExp(r'''\bBearer\s+[^\s,;}"']+''', caseSensitive: false),
  RegExp(r'\b(?:sk|rk)-[A-Za-z0-9][A-Za-z0-9_-]*', caseSensitive: false),
];

/// Redacts provider credentials and caps details before they are persisted.
String sanitizeProviderErrorDetail(String message) {
  var sanitized = message.replaceAll(RegExp(r'\s+'), ' ').trim();
  for (final pattern in _providerSecretPatterns) {
    sanitized = sanitized.replaceAllMapped(
      pattern,
      (match) =>
          '${match.groupCount > 0 ? match.group(1) ?? '' : ''}[REDACTED]',
    );
  }

  if (sanitized.length <= _maxProviderErrorLength) return sanitized;

  const prefixLength =
      _maxProviderErrorLength - _providerErrorTruncationSuffix.length;
  final prefix = sanitized.substring(0, prefixLength);

  return '$prefix$_providerErrorTruncationSuffix';
}
