enum A2uiIssueCode {
  malformedPayload,
  oversizedPayload,
  unsupportedProtocol,
  unsupportedCatalog,
  invalidInteractionMode,
  unsupportedComponent,
  missingRoot,
  emptySurface,
  renderFailure,
}

A2uiIssueCode? a2uiIssueCodeFromName(String value) {
  for (final issue in A2uiIssueCode.values) {
    if (issue.name == value) return issue;
  }
  return null;
}

/// Validates the documented A2UI date/time wire value for [variant].
bool isValidA2uiDateTimeValue(Object? variant, String value) {
  bool isDate(String candidate) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(candidate);
    if (match == null) return false;
    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    final parsed = DateTime.utc(year, month, day);
    return parsed.year == year && parsed.month == month && parsed.day == day;
  }

  if (variant == 'date') return isDate(value);
  if (variant == 'time') {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
    return match != null &&
        int.parse(match[1]!) <= 23 &&
        int.parse(match[2]!) <= 59;
  }
  return value.length >= 10 &&
      isDate(value.substring(0, 10)) &&
      DateTime.tryParse(value) != null &&
      (value.endsWith('Z') || RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(value));
}
