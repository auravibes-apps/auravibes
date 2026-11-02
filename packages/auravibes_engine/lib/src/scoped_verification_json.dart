import 'dart:convert';

Map<String, Object?> verificationObject(Object? value, Set<String> keys) {
  if (value is! Map<String, Object?> ||
      value.keys.any((key) => !keys.contains(key))) {
    throw const FormatException('Invalid verification object.');
  }

  return value;
}

String verificationString(Object? value, {int maxBytes = 512}) {
  if (value is! String || value.isEmpty) {
    throw const FormatException('Invalid verification string.');
  }
  validateVerificationString(value, maxBytes: maxBytes);

  return value;
}

void validateVerificationString(String value, {required int maxBytes}) {
  if (value.length > maxBytes ||
      utf8.encode(value).length > maxBytes ||
      RegExp(r'[\x00-\x1f\x7f-\x9f]').hasMatch(value)) {
    throw const FormatException('Invalid verification string.');
  }
}

List<String> verificationStrings(
  Object? value, {
  required int maxEntries,
  int maxBytes = 512,
  bool allowEmpty = false,
}) {
  if (value is! List<Object?> || value.length > maxEntries) {
    throw const FormatException('Invalid verification string list.');
  }
  final result = <String>[];
  for (final item in value) {
    if (item is! String || (!allowEmpty && item.isEmpty)) {
      throw const FormatException('Invalid verification string list.');
    }
    validateVerificationString(item, maxBytes: maxBytes);
    result.add(item);
  }

  return List.unmodifiable(result);
}

int verificationInteger(Object? value, {required int min, required int max}) {
  if (value is! int || value < min || value > max) {
    throw const FormatException('Invalid verification integer.');
  }

  return value;
}
