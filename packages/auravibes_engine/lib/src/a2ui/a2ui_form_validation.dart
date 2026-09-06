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
    final kind = component['component'];
    if (kind is! String || !_inputComponents.contains(kind)) continue;
    final reference = component['value'];
    if (reference is! Map || reference['path'] is! String) continue;
    final path = reference['path']! as String;
    if (!path.startsWith('/')) continue;
    final value = _valueAtPath(values, path);
    final isTouched = touched.contains(path);
    final isEmpty = _isEmpty(value);
    final required = component['required'] == true;
    if (!required && isEmpty && !isTouched) {
      unanswered.add(path);
      continue;
    }
    if (required && (isEmpty || kind == 'CheckBox' && value != true)) {
      errors[path] = 'required';
      continue;
    }
    if (isEmpty) continue;
    final error = _validateValue(kind, component, value);
    if (error != null) errors[path] = error;
  }
  return A2uiFormValidationResult(
    errorsByPath: Map.unmodifiable(errors),
    unansweredPaths: List.unmodifiable(unanswered),
  );
}

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
    if (component['component'] != 'Slider') continue;
    final reference = component['value'];
    if (reference is! Map || reference['path'] is! String) continue;
    final path = reference['path']! as String;
    final current = _valueAtPath(normalized, path);
    final min = component['min'];
    final max = component['max'];
    if (current is! num || min is! num || max is! num) continue;
    final step = (component['step'] as num?)?.toDouble() ?? 1;
    final precision = component['precision'] as int? ?? 2;
    if (step <= 0 || precision < 0 || precision > 20) continue;
    _setValueAtPath(
      normalized,
      path,
      _normalizeSliderValue(
        current.toDouble(),
        min.toDouble(),
        max.toDouble(),
        step,
        precision,
      ),
    );
  }
  return normalized;
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
) {
  switch (kind) {
    case 'CheckBox':
      return value is bool ? null : 'boolean';
    case 'Slider' || 'Rating':
      if (value is! num || !value.isFinite) return 'number';
      final min = component['min'];
      final max = component['max'];
      if (min is num && value < min || max is num && value > max) {
        return 'range';
      }
      if (kind == 'Slider') {
        final step = (component['step'] as num?)?.toDouble() ?? 1;
        final precision = component['precision'] as int? ?? 2;
        if (min is num && step > 0 && precision >= 0 && precision <= 20) {
          final normalized = _normalizeSliderValue(
            value.toDouble(),
            min.toDouble(),
            (max as num?)?.toDouble() ?? value.toDouble(),
            step,
            precision,
          );
          if (normalized != value.toDouble()) return 'step';
        }
      }
      return null;
    case 'ChoicePicker' || 'TagInput':
      final selections = value is List ? value : [value];
      if (selections.any((item) => item is! String)) return 'choice';
      if (kind == 'ChoicePicker') {
        final options = component['options'];
        final allowed = <String>{
          if (options is List)
            for (final option in options)
              if (option is Map && option['value'] is String)
                option['value']! as String,
        };
        if (allowed.isEmpty ||
            selections.any((item) => !allowed.contains(item))) {
          return 'choice';
        }
      }
      final max = component['maxSelections'];
      if (max is int && selections.length > max) return 'maxSelections';
      final min = component['minSelections'];
      if (min is int && selections.length < min) return 'minSelections';
      return null;
    case 'TextField':
      if (value is! String) return 'text';
      final min = component['minLength'];
      final max = component['maxLength'];
      if (min is int && value.length < min ||
          max is int && value.length > max) {
        return 'length';
      }
      final pattern = component['pattern'];
      if (pattern is String) {
        try {
          if (!RegExp(pattern).hasMatch(value)) return 'pattern';
        } on FormatException {
          return 'pattern';
        }
      }
      return null;
    case 'DateTimeInput':
      if (value is! String) return 'dateTime';
      if (!isValidA2uiDateTimeValue(component['variant'], value)) {
        return 'dateTime';
      }
      if (!_inDateTimeRange(value, component['min'], component['max'])) {
        return 'range';
      }
  }
  return null;
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
