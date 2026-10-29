import 'dart:convert';

/// Keeps JSON structure and types while dropping all sample values.
Object? connectorToolSampleShape(Object? sample) {
  final value = sample is String ? _decode(sample) : sample;

  return switch (value) {
    Map() => {
      for (final entry in value.entries)
        if (entry.key is String) entry.key as String: _placeholder(entry.value),
    },
    List() => const <Object?>[],
    bool() => false,
    int() => 0,
    num() => 0.0,
    String() => '',
    _ => null,
  };
}

Object? _decode(String sample) {
  try {
    return jsonDecode(sample);
  } on FormatException {
    return sample;
  }
}

Object? _placeholder(Object? value) => switch (value) {
  Map() => const <String, Object?>{},
  List() => const <Object?>[],
  bool() => false,
  int() => 0,
  num() => 0.0,
  String() => '',
  _ => null,
};
