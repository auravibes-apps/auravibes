import 'dart:convert';
import 'dart:math' as math;

import 'package:auravibes_engine/src/a2ui/a2ui_validation.dart';

/// A deterministic validation result for application-owned A2UI form submit.
class A2uiFormValidationResult {
  const new({required this.errorsByPath, required this.unansweredPaths});

  final Map<String, String> errorsByPath;
  final List<String> unansweredPaths;

  bool get isValid => errorsByPath.isEmpty;
}

typedef _FormIssue = ({String path, String? error, bool unanswered});

/// Validates form data with the input metadata advertised by the chat catalog.
/// The types remain JSON-only so app and server share the same decision.
A2uiFormValidationResult validateA2uiFormValues({
  required Iterable<Map<String, Object?>> components,
  required Map<String, Object?> values,
  Iterable<String> touchedPaths = const [],
}) {
  final touched = touchedPaths.toSet();
  final errors = <String, String>{};
  final unanswered = <String>[];
  for (final component in components) {
    final issue = _validateComponent(component, values, touched);
    if (issue == null) continue;
    if (issue.unanswered) {
      unanswered.add(issue.path);
      continue;
    }
    errors[issue.path] = issue.error!;
  }
  return A2uiFormValidationResult(
    errorsByPath: .unmodifiable(errors),
    unansweredPaths: .unmodifiable(unanswered),
  );
}

_FormIssue? _validateComponent(
  Map<String, Object?> component,
  Map<String, Object?> values,
  Set<String> touched,
) {
  final kind = _inputKind(component);
  if (kind == null) return null;
  final path = _componentPath(component['value']);
  if (path == null) return null;
  final value = _valueAtPath(values, path);
  final isEmpty = _isEmpty(value);
  final required = component['required'] == true;
  if (_isUnanswered(required, isEmpty, touched.contains(path))) {
    return (path: path, error: null, unanswered: true);
  }
  if (_isRequiredValueInvalid(kind, required, isEmpty, value)) {
    return (path: path, error: 'required', unanswered: false);
  }
  if (isEmpty) return null;
  final error = _validateValue(kind, component, value);
  return error == null ? null : (path: path, error: error, unanswered: false);
}

String? _inputKind(Map<String, Object?> component) {
  final kind = component['component'];
  if (kind is! String) return null;
  return _inputComponents.contains(kind) ? kind : null;
}

String? _componentPath(Object? reference) {
  if (reference is! Map) return null;
  final path = reference['path'];
  if (path is! String || !path.startsWith('/')) return null;
  return path;
}

bool _isUnanswered(bool required, bool isEmpty, bool isTouched) =>
    !required && isEmpty && !isTouched;

bool _isRequiredValueInvalid(
  String kind,
  bool required,
  bool isEmpty,
  Object? value,
) => required && (isEmpty || kind == 'CheckBox' && value != true);

/// Returns a JSON-safe form snapshot with slider values aligned to their
/// advertised step and decimal precision.
Map<String, Object?> normalizeA2uiFormValues({
  required Iterable<Map<String, Object?>> components,
  required Map<String, Object?> values,
}) {
  final normalized = Map<String, Object?>.from(
    jsonDecode(jsonEncode(values)) as Map,
  );
  for (final component in components) {
    _normalizeSliderComponent(normalized, component);
  }
  return normalized;
}

void _normalizeSliderComponent(
  Map<String, Object?> values,
  Map<String, Object?> component,
) {
  if (component['component'] != 'Slider') return;
  final path = _componentPath(component['value']);
  if (path == null) return;
  final current = _valueAtPath(values, path);
  final min = component['min'];
  final max = component['max'];
  if (current is! num || min is! num || max is! num) return;
  final parameters = _sliderParameters(component);
  if (parameters == null) return;
  _setValueAtPath(
    values,
    path,
    _normalizeSliderValue(
      current.toDouble(),
      min.toDouble(),
      max.toDouble(),
      parameters.step,
      parameters.precision,
    ),
  );
}

({double step, int precision})? _sliderParameters(
  Map<String, Object?> component,
) {
  final stepValue = component['step'];
  final step = stepValue == null ? 1.0 : (stepValue as num).toDouble();
  final precisionValue = component['precision'];
  final precision = precisionValue == null ? 2 : precisionValue as int;
  if (step <= 0 || precision < 0 || precision > 20) return null;
  return (step: step, precision: precision);
}

const _inputComponents = <String>{
  'CheckBox',
  'ChoicePicker',
  'DateTimeInput',
  'Rating',
  'Slider',
  'TagInput',
  'TextField',
};

Object? _valueAtPath(Map<String, Object?> values, String path) {
  Object? current = values;
  for (final segment in path.substring(1).split('/')) {
    if (segment.isEmpty || current is! Map) return null;
    current = current[segment.replaceAll('~1', '/').replaceAll('~0', '~')];
  }
  return current;
}

bool _isEmpty(Object? value) =>
    value == null ||
    value is String && value.trim().isEmpty ||
    value is List && value.isEmpty;

String? _validateValue(
  String kind,
  Map<String, Object?> component,
  Object? value,
) => switch (kind) {
  'CheckBox' => value is bool ? null : 'boolean',
  'Slider' || 'Rating' => _validateNumericValue(kind, component, value),
  'ChoicePicker' || 'TagInput' => _validateChoiceValue(kind, component, value),
  'TextField' => _validateTextValue(component, value),
  'DateTimeInput' => _validateDateTimeValue(component, value),
  _ => null,
};

String? _validateNumericValue(
  String kind,
  Map<String, Object?> component,
  Object? value,
) {
  if (value is! num || !value.isFinite) return 'number';
  final min = component['min'];
  final max = component['max'];
  if (min is num && value < min || max is num && value > max) {
    return 'range';
  }
  if (kind != 'Slider') return null;
  return _validateSliderStep(component, value, min, max);
}

String? _validateSliderStep(
  Map<String, Object?> component,
  num value,
  Object? min,
  Object? max,
) {
  final parameters = _sliderParameters(component);
  if (min is! num || parameters == null) return null;
  final normalized = _normalizeSliderValue(
    value.toDouble(),
    min.toDouble(),
    (max as num?)?.toDouble() ?? value.toDouble(),
    parameters.step,
    parameters.precision,
  );
  return normalized == value.toDouble() ? null : 'step';
}

String? _validateChoiceValue(
  String kind,
  Map<String, Object?> component,
  Object? value,
) {
  final selections = value is List ? value : [value];
  if (selections.any((item) => item is! String)) return 'choice';
  if (kind == 'ChoicePicker' &&
      !_validChoiceSelections(component, selections)) {
    return 'choice';
  }
  final max = component['maxSelections'];
  if (max is int && selections.length > max) return 'maxSelections';
  final min = component['minSelections'];
  if (min is int && selections.length < min) return 'minSelections';
  return null;
}

bool _validChoiceSelections(
  Map<String, Object?> component,
  List<Object?> selections,
) {
  final options = component['options'];
  final allowed = <String>{
    if (options is List)
      for (final option in options)
        if (option is Map && option['value'] is String)
          option['value']! as String,
  };
  return allowed.isNotEmpty && selections.every(allowed.contains);
}

String? _validateTextValue(Map<String, Object?> component, Object? value) {
  if (value is! String) return 'text';
  final min = component['minLength'];
  final max = component['maxLength'];
  if (min is int && value.length < min || max is int && value.length > max) {
    return 'length';
  }
  final pattern = component['pattern'];
  if (pattern is! String) return null;
  try {
    return RegExp(pattern).hasMatch(value) ? null : 'pattern';
  } on FormatException {
    return 'pattern';
  }
}

String? _validateDateTimeValue(Map<String, Object?> component, Object? value) {
  if (value is! String) return 'dateTime';
  if (!isValidA2uiDateTimeValue(component['variant'], value)) {
    return 'dateTime';
  }
  return _inDateTimeRange(value, component['min'], component['max'])
      ? null
      : 'range';
}

bool _inDateTimeRange(String value, Object? min, Object? max) {
  DateTime? parse(Object? candidate) => candidate is String
      ? DateTime.tryParse(
          candidate.length == 5 ? '2000-01-01T$candidate' : candidate,
        )
      : null;
  final current = parse(value);
  if (current == null) return false;
  final lower = parse(min);
  final upper = parse(max);
  return (lower == null || !current.isBefore(lower)) &&
      (upper == null || !current.isAfter(upper));
}

void _setValueAtPath(Map<String, Object?> values, String path, double value) {
  final segments = path.substring(1).split('/');
  if (segments.isEmpty || segments.any((segment) => segment.isEmpty)) return;
  var current = values;
  for (final segment in segments.take(segments.length - 1)) {
    final key = segment.replaceAll('~1', '/').replaceAll('~0', '~');
    final next = current[key];
    if (next is! Map) return;
    final nested = Map<String, Object?>.from(next);
    current[key] = nested;
    current = nested;
  }
  current[segments.last.replaceAll('~1', '/').replaceAll('~0', '~')] = value;
}

double _normalizeSliderValue(
  double value,
  double min,
  double max,
  double step,
  int precision,
) {
  final clamped = value.clamp(min, max);
  final stepped = min + ((clamped - min) / step).round() * step;
  final scale = math.pow(10, precision).toDouble();
  final rounded = (stepped * scale).round() / scale;
  return double.parse(rounded.clamp(min, max).toStringAsFixed(precision));
}
