import 'package:auravibes_app/features/chats/models/mcp_elicitation_form.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:mcp_client/mcp_client.dart'
    show JsonSchemaException, JsonSchemaValidator;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mcp_elicitation_form_usecase.g.dart';

@riverpod
McpElicitationFormUsecase mcpElicitationFormUsecase(Ref _) =>
    const McpElicitationFormUsecase();

class const McpElicitationFormUsecase() {
  McpElicitationForm? parse(Map<String, Object?>? schema) =>
      _McpElicitationFormSchemaParser.parse(schema);

  Map<String, Object?> validate(
    McpElicitationForm form,
    Map<String, Object?> values,
  ) =>
      _McpElicitationFormValidator.validate(form, values) ??
      (throw const McpElicitationFormValidationException());
}

final class const McpElicitationFormValidationException() implements Exception {
  String get localizationKey => LocaleKeys.mcp_elicitation_invalid;

  @override
  String toString() => localizationKey;
}

final class _McpElicitationFormSchemaParser {
  static const _maxFields = 64;
  static const _schemaKeys = {
    'type',
    'properties',
    'required',
    'title',
    'description',
  };
  static const _fieldKeys = {
    'type',
    'title',
    'description',
    'default',
    'enum',
    'oneOf',
    'pattern',
    'format',
    'minimum',
    'maximum',
    'minLength',
    'maxLength',
  };

  static McpElicitationForm? parse(Map<String, Object?>? schema) {
    if (schema == null) return null;
    final rawProperties = _parseRootProperties(schema);
    if (rawProperties == null) return null;

    final properties = _parseProperties(rawProperties);
    if (properties == null) return null;

    return _createForm(schema, properties);
  }

  static Map<Object?, Object?>? _parseRootProperties(
    Map<String, Object?> schema,
  ) {
    if (schema['type'] != 'object') return null;
    if (!_hasOnlyKnownSchemaKeys(schema)) return null;

    return _parseRequiredProperties(schema);
  }

  static bool _hasOnlyKnownSchemaKeys(Map<String, Object?> schema) =>
      schema.keys.every(_schemaKeys.contains);

  static Map<Object?, Object?>? _parseRequiredProperties(
    Map<String, Object?> schema,
  ) {
    final properties = schema['properties'];
    if (properties is! Map<Object?, Object?> ||
        properties.length > _maxFields) {
      return null;
    }
    if (!_hasValidRequiredNames(schema['required'], properties)) return null;

    return properties;
  }

  static McpElicitationForm? _createForm(
    Map<String, Object?> schema,
    Map<String, Map<String, Object?>> properties,
  ) {
    final normalizedSchema = {...schema, 'properties': properties};
    try {
      JsonSchemaValidator(normalizedSchema, assertFormat: true);
    } on JsonSchemaException {
      return null;
    }

    return .new(schema: normalizedSchema, properties: properties);
  }

  static bool _hasValidRequiredNames(
    Object? required,
    Map<Object?, Object?> properties,
  ) {
    if (required == null) return true;
    if (required is! List || required.length > _maxFields) return false;

    return required.every(
      (name) => name is String && properties.containsKey(name),
    );
  }

  static Map<String, Map<String, Object?>>? _parseProperties(
    Map<Object?, Object?> raw,
  ) {
    final properties = <String, Map<String, Object?>>{};
    for (final entry in raw.entries) {
      if (entry.key case final String key) {
        final property = _parseProperty(entry.value);
        if (property == null) return null;
        properties[key] = property;
      } else {
        return null;
      }
    }

    return properties;
  }

  static Map<String, Object?>? _parseProperty(Object? rawProperty) {
    if (rawProperty is! Map<Object?, Object?> ||
        !_hasOnlyKnownFieldKeys(rawProperty)) {
      return null;
    }
    final property = Map<String, Object?>.from(rawProperty);
    if (!_normalizeOneOf(property)) return null;
    if (!_McpElicitationPropertyValidator.isSupported(property)) return null;

    return property;
  }

  static bool _hasOnlyKnownFieldKeys(Map<Object?, Object?> property) =>
      property.keys.every((key) => key is String && _fieldKeys.contains(key));

  static bool _normalizeOneOf(Map<String, Object?> property) {
    if (!property.containsKey('oneOf')) return true;
    if (property.containsKey('enum')) return false;
    final choices = _McpElicitationOneOfParser.parseTypedChoices(property);
    if (choices == null) return false;
    final inferredType = choices.firstOrNull?.type;
    if (inferredType == null) return false;
    property['type'] = property['type'] ?? inferredType;
    property['enum'] = choices.map((choice) => choice.value).toList();

    return true;
  }
}

final class _McpElicitationOneOfParser {
  static const _maxEnumValues = 64;

  static List<({Object value, String type})>? parse(Object? raw) {
    if (raw is! List || raw.isEmpty || raw.length > _maxEnumValues) return null;
    final choices = <({Object value, String type})>[];
    for (final choice in raw) {
      if (!_appendChoice(choices, choice)) return null;
    }

    return choices;
  }

  static bool matchesType(
    Object? type,
    List<({Object value, String type})> choices,
  ) =>
      type == null ||
      choices.every(
        (choice) => _McpElicitationPropertyValidator.matchesPrimitiveType(
          type,
          choice.value,
        ),
      );

  static List<({Object value, String type})>? parseTypedChoices(
    Map<String, Object?> property,
  ) {
    final choices = parse(property['oneOf']);
    if (choices == null || !matchesType(property['type'], choices)) {
      return null;
    }

    return choices;
  }

  static bool _appendChoice(
    List<({Object value, String type})> choices,
    Object? rawChoice,
  ) {
    final choice = _parseChoice(rawChoice);
    if (choice == null || !_canAddChoice(choices, choice)) return false;
    choices.add(choice);

    return true;
  }

  static bool _canAddChoice(
    List<({Object value, String type})> choices,
    ({Object value, String type}) choice,
  ) =>
      !choices.any((item) => item.value == choice.value) &&
      (choices.isEmpty || choices.lastOrNull?.type == choice.type);

  static ({Object value, String type})? _parseChoice(Object? choice) {
    if (choice is! Map<Object?, Object?> || !_isChoiceShape(choice)) {
      return null;
    }
    final value = choice['const'];
    final type = _McpElicitationPropertyValidator.primitiveTypeOf(value);
    if (type == null) return null;

    return switch (value) {
      final Object parsedValue => (value: parsedValue, type: type),
      _ => null,
    };
  }

  static bool _isChoiceShape(Map<Object?, Object?> choice) =>
      choice['title'] is String &&
      choice.containsKey('const') &&
      choice.keys.every((key) => key == 'const' || key == 'title');
}

final class _McpElicitationPropertyValidator {
  static const _maxEnumValues = 64;

  static bool isSupported(Map<String, Object?> property) {
    final type = property['type'];
    if (!_isPrimitiveType(type)) return false;

    return _hasValidEnum(type, property['enum']) &&
        _hasValidPattern(type, property) &&
        _hasValidStringLengths(type, property) &&
        _hasValidBounds(property);
  }

  static bool matchesPrimitiveType(Object? type, Object? value) =>
      switch (type) {
        'string' => value is String,
        'number' => value is num && value.isFinite,
        'integer' => value is num && value.isFinite && value % 1 == 0,
        'boolean' => value is bool,
        _ => false,
      };

  static String? primitiveTypeOf(Object? value) => switch (value) {
    String() => 'string',
    num _ => 'number',
    bool() => 'boolean',
    _ => null,
  };

  static bool _isPrimitiveType(Object? type) => switch (type) {
    'string' || 'number' || 'integer' || 'boolean' => true,
    _ => false,
  };

  static bool _hasValidEnum(Object? type, Object? enumValues) {
    if (enumValues == null) return true;
    if (enumValues is! List ||
        enumValues.isEmpty ||
        enumValues.length > _maxEnumValues) {
      return false;
    }

    return enumValues.every((value) => matchesPrimitiveType(type, value));
  }

  static bool _hasValidPattern(Object? type, Map<String, Object?> property) {
    if (!property.containsKey('pattern')) return true;
    final pattern = property['pattern'];
    if (type != 'string' ||
        pattern is! String ||
        !_McpElicitationPatternValidator.isSafe(pattern)) {
      return false;
    }
    final minimumLength = property['minLength'];

    return minimumLength is! int ||
        minimumLength <= McpElicitationForm.maxPatternInputLength;
  }

  static bool _hasValidStringLengths(
    Object? type,
    Map<String, Object?> property,
  ) {
    if (type != 'string') return true;
    final minimum = property['minLength'];
    final maximum = property['maxLength'];
    if (property.containsKey('minLength') && (minimum is! int || minimum < 0)) {
      return false;
    }
    if (property.containsKey('maxLength') && (maximum is! int || maximum < 0)) {
      return false;
    }

    return minimum is! int || maximum is! int || maximum >= minimum;
  }

  static bool _hasValidBounds(Map<String, Object?> property) =>
      (!property.containsKey('format') || property['format'] is String) &&
      (!property.containsKey('minimum') || property['minimum'] is num) &&
      (!property.containsKey('maximum') || property['maximum'] is num);
}

final class _McpElicitationFormValidator {
  static Map<String, Object?>? validate(
    McpElicitationForm form,
    Map<String, Object?> values,
  ) {
    final content = _McpElicitationFormValueConverter.convert(form, values);
    if (content == null) return null;

    try {
      final result = JsonSchemaValidator(
        form.schema,
        assertFormat: true,
      ).validate(content);
      if (!result.valid ||
          !_McpElicitationDateTimeValidator.hasValidLeapSecondDates(
            form,
            content,
          )) {
        return null;
      }
    } on JsonSchemaException {
      return null;
    }

    return content;
  }
}

final class _McpElicitationFormValueConverter {
  static Map<String, Object?>? convert(
    McpElicitationForm form,
    Map<String, Object?> values,
  ) {
    final result = <String, Object?>{};
    for (final entry in values.entries) {
      final converted = _convertEntry(form, entry);
      if (converted == null) return null;
      if (converted.include) result[entry.key] = converted.value;
    }

    return result;
  }

  static ({bool include, Object? value})? _convertEntry(
    McpElicitationForm form,
    MapEntry<String, Object?> entry,
  ) {
    final value = entry.value;
    if (value == null) return (include: false, value: null);
    final property = form.properties[entry.key];
    if (_hasOversizedPatternInput(value, property)) return null;
    if (_isOptionalEmptyValue(form, entry.key, value, property)) {
      return (include: false, value: null);
    }

    return _convertPresentValue(value, property);
  }

  static ({bool include, Object? value})? _convertPresentValue(
    Object value,
    Map<String, Object?>? property,
  ) {
    final type = property?['type'];
    final converted = _convertValue(type is String ? type : null, value);
    if (converted == null) return null;

    return (include: true, value: converted);
  }

  static bool _hasOversizedPatternInput(
    Object value,
    Map<String, Object?>? property,
  ) =>
      value is String &&
      property?['pattern'] is String &&
      value.runes.length > McpElicitationForm.maxPatternInputLength;

  static bool _isOptionalEmptyValue(
    McpElicitationForm form,
    String name,
    Object value,
    Map<String, Object?>? property,
  ) =>
      value == '' &&
      !form.isRequired(name) &&
      (property?['type'] == 'integer' ||
          property?['type'] == 'number' ||
          (property?['type'] == 'string' && property?['enum'] is! List));
}

McpElicitationFieldValue _convertValue(String? type, Object value) {
  if (type == 'integer') return _convertInteger(value);
  if (type == 'number') return _convertNumber(value);

  return value;
}

McpElicitationFieldValue _convertInteger(Object value) {
  if (value is num) {
    if (!value.isFinite || value % 1 != 0) return null;

    return value.toInt();
  }
  if (value is String) return int.tryParse(value);

  return value;
}

McpElicitationFieldValue _convertNumber(Object value) {
  if (value is! String) return value;
  final parsed = num.tryParse(value);
  if (parsed == null || !parsed.isFinite) return null;

  return parsed;
}

final class _McpElicitationPatternValidator {
  static const _maxPatternLength = 128;

  static bool isSafe(String pattern) =>
      pattern.length <= _maxPatternLength &&
      _McpElicitationPatternParser(pattern).parse();
}

final class _McpElicitationPatternParser(final String _pattern) {
  var _index = 0;
  var _inCharacterClass = false;
  var _isEscaped = false;
  var _variableQuantifiers = 0;
  var _hasUnboundedQuantifier = false;
  var _minimumMatchedLength = 0;
  var _pendingAtomLength = 0;
  final _characterRouter = const _McpElicitationPatternCharacterRouter();

  bool parse() {
    while (_index < _pattern.length) {
      if (!_characterRouter.consume(this, _pattern[_index])) return false;
      _index++;
    }
    if (_inCharacterClass || _isEscaped) return false;
    if (!_completePendingAtom()) return false;
    if (_hasUnboundedQuantifier && !_pattern.startsWith('^')) return false;

    try {
      RegExp(_pattern, unicode: true);
    } on FormatException {
      return false;
    }

    return true;
  }

  bool _consumeEscaped(String character) {
    _isEscaped = false;
    if (_inCharacterClass) return true;
    if (!_completePendingAtom()) return false;
    _pendingAtomLength = character == 'b' || character == 'B' ? 0 : 1;

    return true;
  }

  bool _consumeCharacterClass(String character) {
    if (character != ']') return true;
    _inCharacterClass = false;
    if (!_completePendingAtom()) return false;
    _pendingAtomLength = 1;

    return true;
  }

  bool _startCharacterClass() {
    if (!_completePendingAtom()) return false;
    _inCharacterClass = true;

    return true;
  }

  bool _consumeVariableQuantifier(String character) {
    _variableQuantifiers++;
    if (_variableQuantifiers > 1) return false;
    _hasUnboundedQuantifier |= character == '*' || character == '+';
    if (character != '+') _pendingAtomLength = 0;

    return true;
  }

  bool _consumeBoundedQuantifier() {
    final close = _pattern.indexOf('}', _index + 1);
    if (close < 0) return false;
    final bounds = _McpElicitationPatternRepeatBoundsParser.parseBetween(
      _pattern,
      _index + 1,
      close,
    );
    if (bounds == null || !_canApplyRepeatBounds(bounds)) return false;

    if (!_applyRepeatBounds(bounds)) return false;
    _index = close;

    return true;
  }

  bool _canApplyRepeatBounds(({int minimum, int? maximum}) bounds) {
    if (bounds.maximum == bounds.minimum) return true;
    _variableQuantifiers++;

    return _variableQuantifiers <= 1;
  }

  bool _applyRepeatBounds(({int minimum, int? maximum}) bounds) {
    if (bounds.maximum != bounds.minimum) {
      _hasUnboundedQuantifier |= bounds.maximum == null;
    }
    _pendingAtomLength *= bounds.minimum;

    return _minimumMatchedLength + _pendingAtomLength <=
        McpElicitationForm.maxPatternInputLength;
  }

  bool _consumeLiteral() {
    if (!_completePendingAtom()) return false;
    _pendingAtomLength = 1;

    return true;
  }

  bool _completePendingAtom() {
    _minimumMatchedLength += _pendingAtomLength;
    _pendingAtomLength = 0;

    return _minimumMatchedLength <= McpElicitationForm.maxPatternInputLength;
  }
}

final class const _McpElicitationPatternCharacterRouter() {
  bool consume(_McpElicitationPatternParser parser, String character) {
    if (parser._isEscaped) return parser._consumeEscaped(character);
    if (character == r'\') {
      parser._isEscaped = true;

      return true;
    }
    if (parser._inCharacterClass) {
      return parser._consumeCharacterClass(character);
    }

    return _consumeOutsideClass(parser, character);
  }

  bool _consumeOutsideClass(
    _McpElicitationPatternParser parser,
    String character,
  ) => switch (character) {
    '[' => parser._startCharacterClass(),
    '(' || ')' || '|' => false,
    '*' || '+' || '?' => parser._consumeVariableQuantifier(character),
    '^' || r'$' => parser._completePendingAtom(),
    '{' => parser._consumeBoundedQuantifier(),
    _ => parser._consumeLiteral(),
  };
}

final class _McpElicitationPatternRepeatBoundsParser {
  static const _maxParts = 2;

  static ({int minimum, int? maximum})? parse(String source) {
    final parts = source.split(',');
    if (parts.length > _maxParts) return null;
    final minimum = _parseMinimum(parts.firstOrNull ?? '');
    if (minimum == null) return null;
    final maximum = _parseMaximum(parts, minimum);
    if (!maximum.valid) return null;

    return (minimum: minimum, maximum: maximum.value);
  }

  static ({int minimum, int? maximum})? parseBetween(
    String pattern,
    int start,
    int end,
  ) => parse(.fromCharCodes(pattern.codeUnits.getRange(start, end)));

  static int? _parseMinimum(String source) {
    final value = int.tryParse(source);
    if (value == null ||
        value < 0 ||
        value > McpElicitationForm.maxPatternInputLength) {
      return null;
    }

    return value;
  }

  static ({bool valid, int? value}) _parseMaximum(
    List<String> parts,
    int minimum,
  ) {
    if (parts.length == 1) return (valid: true, value: minimum);
    if (parts.last.isEmpty) return (valid: true, value: null);
    final maximum = int.tryParse(parts.last);
    if (maximum == null ||
        maximum < minimum ||
        maximum > McpElicitationForm.maxPatternInputLength) {
      return (valid: false, value: null);
    }

    return (valid: true, value: maximum);
  }
}

final class _McpElicitationDateTimeValidator {
  // Shortcut: Bundled IERS history ends in 2016. Refresh after announcements.
  static const _positiveLeapSecondDates = {
    '1972-06-30',
    '1972-12-31',
    '1973-12-31',
    '1974-12-31',
    '1975-12-31',
    '1976-12-31',
    '1977-12-31',
    '1978-12-31',
    '1979-12-31',
    '1981-06-30',
    '1982-06-30',
    '1983-06-30',
    '1985-06-30',
    '1987-12-31',
    '1989-12-31',
    '1990-12-31',
    '1992-06-30',
    '1993-06-30',
    '1994-06-30',
    '1995-12-31',
    '1997-06-30',
    '1998-12-31',
    '2005-12-31',
    '2008-12-31',
    '2012-06-30',
    '2015-06-30',
    '2016-12-31',
  };
  static const _leapSecond = '60';
  static const _lastHourOfDay = 23;
  static const _lastMinuteOfHour = 59;
  static const _lastSecondOfMinute = 59;
  static const _yearWidth = 4;
  static const _datePartWidth = 2;
  static final _secondsPattern = RegExp(
    r'^\d{4}-\d{2}-\d{2}[Tt]\d{2}:\d{2}:(\d{2})',
  );
  static final _leapSecondSuffixPattern = RegExp(':60(?=[.Zz+-])');

  static bool hasValidLeapSecondDates(
    McpElicitationForm form,
    Map<String, Object?> values,
  ) {
    for (final entry in values.entries) {
      if (!_isValidLeapSecondValue(form, entry)) return false;
    }

    return true;
  }

  static bool _isValidLeapSecondValue(
    McpElicitationForm form,
    MapEntry<String, Object?> entry,
  ) {
    if (form.properties[entry.key]?['format'] != 'date-time' ||
        entry.value is! String) {
      return true;
    }
    if (entry.value case final String value) {
      return _validateLeapSecondValue(value);
    }

    return true;
  }

  static bool _validateLeapSecondValue(String value) {
    if (_secondsPattern.firstMatch(value)?[1] != _leapSecond) return true;
    final normalized = value.replaceFirst(_leapSecondSuffixPattern, ':59');
    final utc = DateTime.tryParse(normalized.toUpperCase())?.toUtc();

    return utc != null && _isLeapSecondUtc(utc);
  }

  static bool _isLeapSecondUtc(DateTime value) =>
      value.hour == _lastHourOfDay &&
      value.minute == _lastMinuteOfHour &&
      value.second == _lastSecondOfMinute &&
      _positiveLeapSecondDates.contains(_formatDate(value));

  static String _formatDate(DateTime value) =>
      '${value.year.toString().padLeft(_yearWidth, '0')}-'
      '${value.month.toString().padLeft(_datePartWidth, '0')}-'
      '${value.day.toString().padLeft(_datePartWidth, '0')}';
}
