import 'dart:convert';

class const ReasoningOption._({
  required final String type,
  final List<String> values = const [],
  final int? min,
  final int? max,
  final Map<String, dynamic>? raw,
}) {
  /// Keeps the public named constructor const while using the package's
  /// constructor shorthand conventions.
  // ignore: unnecessary_type_name_in_constructor
  const ReasoningOption.toggle() : this._(type: 'toggle');

  factory effort(Iterable<String> values) =>
      ReasoningOption._(type: 'effort', values: List.unmodifiable(values));

  factory budgetTokens(int min, int max) =>
      ReasoningOption._(type: 'budget_tokens', min: min, max: max);

  factory unknown(String type, Map<String, dynamic> raw) =>
      ReasoningOption._(type: type, raw: Map.unmodifiable(raw));

  bool get isToggle => type == 'toggle';
  bool get isEffort => type == 'effort';
  bool get isBudgetTokens => type == 'budget_tokens';

  Map<String, dynamic> toJson() {
    final raw = this.raw;
    if (raw != null) return Map<String, dynamic>.from(raw);
    if (isToggle) return const {'type': 'toggle'};
    if (isEffort) return {'type': type, 'values': values};

    return {'type': type, 'min': min, 'max': max};
  }

  static ReasoningOption? fromJson(Object? value) {
    if (value is! Map || value['type'] is! String) return null;
    final type = (value['type'] as String).trim();
    if (type.isEmpty) return null;
    final raw = Map<String, dynamic>.from(value);

    switch (type) {
      case 'toggle':
        return const ReasoningOption.toggle();
      case 'effort':
        final values = value['values'];
        if (values is! List || !values.every((item) => item is String)) {
          return null;
        }
        final normalized = values
            .cast<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList(growable: false);
        return normalized.isEmpty ? null : ReasoningOption.effort(normalized);
      case 'budget_tokens':
        final min = value['min'];
        final max = value['max'];
        if (min is! int || max is! int || min < 0 || max < min) return null;
        return ReasoningOption.budgetTokens(min, max);
      default:
        return ReasoningOption.unknown(type, raw);
    }
  }
}

class const ReasoningConfiguration({
  final bool? enabled,
  final String? effort,
  final int? budgetTokens,
}) {
  factory fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Reasoning configuration must be an object.');
    }
    final enabled = value['enabled'];
    final effort = value['effort'];
    final budgetTokens = value['budget_tokens'];
    if (enabled != null && enabled is! bool) {
      throw const FormatException(
        'Reasoning configuration enabled must be boolean.',
      );
    }
    if (effort != null && effort is! String) {
      throw const FormatException(
        'Reasoning configuration effort must be string.',
      );
    }
    if (budgetTokens != null && budgetTokens is! int) {
      throw const FormatException(
        'Reasoning configuration budget_tokens must be integer.',
      );
    }

    return ReasoningConfiguration(
      enabled: enabled as bool?,
      effort: effort as String?,
      budgetTokens: budgetTokens as int?,
    );
  }

  static ReasoningConfiguration? tryFromJson(Object? value) {
    if (value == null) return null;
    try {
      return ReasoningConfiguration.fromJson(value);
    } on FormatException {
      return null;
    }
  }

  static ReasoningConfiguration? decode(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      return tryFromJson(jsonDecode(value));
    } on FormatException {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
    'enabled': ?enabled,
    'effort': ?effort,
    'budget_tokens': ?budgetTokens,
  };

  String encode() => jsonEncode(toJson());

  ReasoningConfiguration copyWith({
    bool? enabled,
    String? effort,
    int? budgetTokens,
  }) => ReasoningConfiguration(
    enabled: enabled ?? this.enabled,
    effort: effort ?? this.effort,
    budgetTokens: budgetTokens ?? this.budgetTokens,
  );

  bool isValidFor(Iterable<ReasoningOption> options) {
    final supported = options.where(
      (option) => option.isToggle || option.isEffort || option.isBudgetTokens,
    );
    if (!supported.any((_) => true)) return false;
    if (enabled == false) return supported.any((option) => option.isToggle);

    final effortOption = supported
        .where((option) => option.isEffort)
        .firstOrNull;
    if (effort != null &&
        (effortOption == null || !effortOption.values.contains(effort))) {
      return false;
    }
    final budgetOption = supported
        .where((option) => option.isBudgetTokens)
        .firstOrNull;
    if (budgetTokens != null &&
        (budgetOption == null ||
            budgetTokens! < budgetOption.min! ||
            budgetTokens! > budgetOption.max!)) {
      return false;
    }

    return true;
  }
}
