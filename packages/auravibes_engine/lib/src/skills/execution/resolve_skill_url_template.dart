import 'dart:convert';

import 'package:auravibes_engine/src/skills/models/skill_credential_attribute_definition.dart';
import 'package:auravibes_engine/src/skills/models/skill_template_definition.dart';
import 'package:auravibes_engine/src/skills/models/skill_template_input_definition.dart';
import 'package:auravibes_engine/src/skills/models/skill_url_template.dart';
import 'package:auravibes_engine/src/skills/models/url_request.dart';
import 'package:liquify/liquify.dart';

class const ResolveSkillUrlTemplate() {
  UrlRequest call({
    required SkillUrlTemplate template,
    required Map<String, dynamic> inputs,
    required Map<String, String> credentials,
    required Map<String, SkillTemplateInputDefinition> inputDefinitions,
    Map<String, dynamic>? schema,
    Map<String, SkillCredentialAttributeDefinition> credentialDefinitions =
        const {},
  }) {
    final normalizedInputs = normalizeSkillTemplateInputs(
      inputs,
      inputDefinitions,
      schema: schema,
    );
    final context = _TemplateContext(
      inputs: normalizedInputs,
      credentials: credentials,
      inputDefinitions: inputDefinitions,
      credentialDefinitions: credentialDefinitions,
    );
    final resolvedQuery = _resolveEntryMap(template.query, context);
    final resolvedUrl = _appendQuery(
      _render(_canonicalizeTemplate(template.url), context),
      resolvedQuery,
    );

    return UrlRequest(
      url: resolvedUrl,
      method: template.method,
      headers: _resolveEntryMap(template.headers, context),
      body: _resolveBody(template, context),
      timeout: template.timeout,
      format: template.format,
    );
  }

  Map<String, String> _resolveEntryMap(
    Map<String, String> values,
    _TemplateContext context,
  ) {
    final result = <String, String>{};
    for (final entry in values.entries) {
      final value = _canonicalizeTemplate(entry.value);
      context.ensureRequiredReferences(value);
      final rendered = _render(value, context);
      if (rendered.trim().isEmpty) continue;
      result[entry.key] = rendered;
    }

    return result;
  }

  String? _resolveBody(SkillUrlTemplate template, _TemplateContext context) {
    final body = template.body;
    if (body == null) return null;
    final bodyTemplate = _canonicalizeBody(body);
    context.ensureRequiredReferences(bodyTemplate);
    final rendered = _render(bodyTemplate, context);
    if (template.resolvedBodyFormat
        case SkillUrlTemplateBodyFormat.text ||
            SkillUrlTemplateBodyFormat.form) {
      return rendered;
    }

    try {
      return jsonEncode(jsonDecode(rendered));
    } on FormatException catch (_, stackTrace) {
      Error.throwWithStackTrace(
        const FormatException('Rendered JSON body is invalid.'),
        stackTrace,
      );
    }
  }

  String _appendQuery(String url, Map<String, String> query) {
    if (query.isEmpty) return url;
    final uri = Uri.parse(url);
    final mergedQuery = {...uri.queryParameters, ...query};

    return uri.replace(queryParameters: mergedQuery).toString();
  }

  String _render(String source, _TemplateContext context) {
    try {
      _ensureSkillTemplateLiquidFilters();
      return Liquid().parse(source).render(context.values);
    } on Object catch (_, stackTrace) {
      Error.throwWithStackTrace(
        const FormatException('Liquid template render failed.'),
        stackTrace,
      );
    }
  }
}

Map<String, dynamic> normalizeSkillTemplateInputs(
  Map<String, dynamic> inputs,
  Map<String, SkillTemplateInputDefinition> definitions, {
  Map<String, dynamic>? schema,
}) {
  final normalized = <String, dynamic>{};
  for (final entry in inputs.entries) {
    if (entry.key == 'credentialId') continue;
    if (!definitions.containsKey(entry.key)) {
      throw FormatException('Unknown input: ${entry.key}.');
    }
  }
  for (final entry in definitions.entries) {
    final value = inputs[entry.key] ?? entry.value.defaultValue;
    if (value == null) {
      if (!entry.value.optional) {
        throw FormatException('Missing required input: ${entry.key}.');
      }
      continue;
    }
    _validateInputValue(entry.key, value, entry.value);
    normalized[entry.key] = value;
  }
  _validateSchemaAlternatives(schema, normalized);
  return normalized;
}

void _validateSchemaAlternatives(
  Map<String, dynamic>? schema,
  Map<String, dynamic> inputs,
) {
  final alternatives = schema?['anyOf'] ?? schema?['oneOf'];
  if (alternatives is! List || alternatives.isEmpty) return;
  final satisfied = alternatives.any((alternative) {
    if (alternative is! Map) return false;
    final required = alternative['required'];
    if (required is! List) return true;
    return required.whereType<String>().every(inputs.containsKey);
  });
  if (!satisfied) {
    throw const FormatException('Input does not satisfy schema alternatives.');
  }
}

void _validateInputValue(
  String name,
  Object? value,
  SkillTemplateInputDefinition definition,
) {
  final validType = switch (definition.type.trim().toLowerCase()) {
    'string' => value is String,
    'boolean' => value is bool,
    'integer' => value is int,
    'number' => value is num,
    'array' => value is List,
    'object' => value is Map,
    _ => throw FormatException('Unsupported input type: ${definition.type}.'),
  };
  if (!validType) {
    throw FormatException('Input $name must be a ${definition.type}.');
  }
  if (definition.enumValues.isNotEmpty &&
      !definition.enumValues.any((candidate) => candidate == value)) {
    throw FormatException(
      'Input $name must be one of ${definition.enumValues}.',
    );
  }
  if (value is num &&
      ((definition.minimum != null && value < definition.minimum!) ||
          (definition.maximum != null && value > definition.maximum!))) {
    throw FormatException('Input $name is outside its allowed range.');
  }
  if (value is List && definition.items != null) {
    for (final item in value) {
      _validateInputValue('$name[]', item, definition.items!);
    }
  }
  if (value is Map) {
    if (!definition.additionalProperties &&
        value.keys.any((key) => !definition.properties.containsKey(key))) {
      throw FormatException('Input $name contains an unknown property.');
    }
    for (final entry in definition.properties.entries) {
      final nestedValue = value[entry.key];
      if (nestedValue == null) {
        if (!entry.value.optional) {
          throw FormatException('Missing required input: $name.${entry.key}.');
        }
        continue;
      }
      _validateInputValue('$name.${entry.key}', nestedValue, entry.value);
    }
  }
}

void validateSkillTemplateDefinition(SkillTemplateDefinition definition) {
  if (definition.version != 1) {
    throw FormatException(
      'Unsupported skill template version: ${definition.version}.',
    );
  }
  _validateInputDefinitions(definition.inputs);
  _validateInputSchema(definition.inputSchema);

  final template = definition.request;
  final uri = Uri.tryParse(_templateUrlForValidation(template.url));
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    throw const FormatException('Skill template URL must use HTTP or HTTPS.');
  }
  if (template.timeout <= Duration.zero) {
    throw const FormatException('Skill template timeout must be positive.');
  }

  final inputDefinitions = definition.inputs;
  final credentialDefinitions = definition.credentialDefinitions;
  if (inputDefinitions.containsKey('credentialId')) {
    throw const FormatException(
      'credentialId is reserved for skill credential selection.',
    );
  }

  final references =
      _TemplateValidationReferences(
          inputDefinitions: inputDefinitions,
          credentialDefinitions: credentialDefinitions,
        )
        ..validate(template.url)
        ..validateAll(template.headers.values)
        ..validateAll(template.query.values);
  final body = template.body;
  if (body == null) return;
  references.validate(body);
  if (template.resolvedBodyFormat
      case SkillUrlTemplateBodyFormat.text || SkillUrlTemplateBodyFormat.form) {
    return;
  }

  _validateJsonFilters(body, inputDefinitions);

  for (final rendered in _renderJsonBodySamples(
    body,
    inputDefinitions: inputDefinitions,
    credentialDefinitions: credentialDefinitions,
  )) {
    try {
      jsonDecode(rendered);
    } on FormatException catch (_, stackTrace) {
      Error.throwWithStackTrace(
        const FormatException('Rendered JSON body is invalid.'),
        stackTrace,
      );
    }
  }
}

String _templateUrlForValidation(String value) => value.replaceAllMapped(
  RegExp(r'\{\{.*?\}\}'),
  (match) => match.group(0)?.contains('credential.') == true
      ? 'https://example.com'
      : 'value',
);

void _validateInputSchema(Map<String, Object?> schema) {
  if (schema['type'] != null && schema['type'] != 'object') {
    throw const FormatException('Skill inputSchema must be an object schema.');
  }
  if (schema['additionalProperties'] != false) {
    throw const FormatException(
      'Skill inputSchema must reject unknown inputs.',
    );
  }
  final properties = schema['properties'];
  if (properties is! Map) {
    throw const FormatException('Skill inputSchema requires properties.');
  }
  if (properties.keys.any((key) => key is! String) ||
      properties.values.any((value) => value is! Map)) {
    throw const FormatException(
      'Skill inputSchema properties must be named objects.',
    );
  }
  final required = schema['required'];
  if (required != null &&
      (required is! List || !required.every((value) => value is String))) {
    throw const FormatException('Skill inputSchema required must be strings.');
  }
  final propertyNames = properties.keys.map((key) => '$key').toSet();
  final requiredNames = required is List
      ? required.whereType<String>().toSet()
      : const <String>{};
  if (!requiredNames.every(propertyNames.contains)) {
    throw const FormatException(
      'Skill inputSchema required fields must be declared properties.',
    );
  }
}

void _validateInputDefinitions(
  Map<String, SkillTemplateInputDefinition> definitions,
) {
  for (final entry in definitions.entries) {
    _validateInputDefinition(entry.key, entry.value);
  }
}

void _validateInputDefinition(
  String name,
  SkillTemplateInputDefinition definition,
) {
  const supportedTypes = {
    'string',
    'number',
    'integer',
    'boolean',
    'array',
    'object',
  };
  final type = definition.type.trim().toLowerCase();
  if (!supportedTypes.contains(type)) {
    throw FormatException('Unsupported input type: ${definition.type}.');
  }
  if (definition.minimum != null &&
      definition.maximum != null &&
      definition.minimum! > definition.maximum!) {
    throw FormatException('Input $name has an invalid range.');
  }
  if (definition.enumValues.isNotEmpty) {
    for (final value in definition.enumValues) {
      _validateInputValue('$name enum', value, definition);
    }
  }
  if (definition.defaultValue != null) {
    _validateInputValue('$name default', definition.defaultValue, definition);
  }
  if (type != 'array' && definition.items != null) {
    throw FormatException('Only array input $name may declare items.');
  }
  if (type != 'object' && definition.properties.isNotEmpty) {
    throw FormatException('Only object input $name may declare properties.');
  }
  if (definition.items != null) {
    _validateInputDefinition('$name[]', definition.items!);
  }
  for (final entry in definition.properties.entries) {
    _validateInputDefinition('$name.${entry.key}', entry.value);
  }
}

class const _TemplateValidationReferences({
  required final Map<String, SkillTemplateInputDefinition> inputDefinitions,
  required final Map<String, SkillCredentialAttributeDefinition>
  credentialDefinitions,
}) {
  void validate(String value) {
    _parseLiquid(value);
    final locals = _loopLocals(value);
    _validateKnownReferences(value, locals);
    _validateBareReferences(value, locals);
  }

  void validateAll(Iterable<String> values) => values.forEach(validate);

  void _validateKnownReferences(String value, Set<String> locals) {
    for (final reference in _references(value)) {
      if (locals.contains(reference.source)) continue;
      final isKnown = switch (reference.source) {
        'input' => inputDefinitions.containsKey(reference.key),
        'credential' => credentialDefinitions.containsKey(reference.key),
        _ => false,
      };
      if (!isKnown) {
        throw FormatException(
          'Unknown ${reference.source} placeholder: ${reference.key}.',
        );
      }
    }
  }

  void _validateBareReferences(String value, Set<String> locals) {
    for (final reference in _unsupportedBareReferences(value)) {
      if (_allowedTopLevelReferences.contains(reference) ||
          locals.contains(reference)) {
        continue;
      }
      throw FormatException(
        'Unsupported Liquid reference: $reference. Use input.name or '
        'credential.name.',
      );
    }
  }
}

void _validateJsonFilters(
  String body,
  Map<String, SkillTemplateInputDefinition> inputDefinitions,
) {
  for (final output in _liquidOutputPattern.allMatches(body)) {
    final expression = output.group(1) ?? '';
    final reference = _liquidReferencePattern.firstMatch(expression);
    if (reference == null || reference.group(1) != 'input') continue;
    final inputName = reference.group(2) ?? '';
    final definition = inputDefinitions[inputName];
    if (definition == null ||
        !_requiresJsonFilter(definition.type) ||
        _jsonFilterPattern.hasMatch(expression)) {
      continue;
    }
    throw FormatException(
      'JSON body input "$inputName" with type ${definition.type} must use '
      'the json filter.',
    );
  }
}

final _liquidReferencePattern = RegExp(
  r'\b(input|credential)\.([A-Za-z0-9_]+)\b',
);
final _legacyPlaceholderPattern = RegExp(
  r'\{(input|credential):([A-Za-z0-9_]+)\}',
);
final _legacyWholeJsonPlaceholderPattern = RegExp(
  r'"\{(input|credential):([A-Za-z0-9_]+)\}"',
);
final _forTagPattern = RegExp(r'\{%\s*for\s+([A-Za-z_][A-Za-z0-9_]*)\s+in\b');
final _bareOutputPattern = RegExp(r'\{\{\s*([A-Za-z_][A-Za-z0-9_]*)\b');
final _bareConditionPattern = RegExp(
  r'\{%\s*(?:if|unless|elsif)\s+([A-Za-z_][A-Za-z0-9_]*)\b',
);
final _bareForIterablePattern = RegExp(
  r'\{%\s*for\s+[A-Za-z_][A-Za-z0-9_]*\s+in\s+([A-Za-z_][A-Za-z0-9_]*)\b',
);
final _liquidOutputPattern = RegExp(r'\{\{\s*([^}]*)\s*\}\}');
final _jsonFilterPattern = RegExp(r'\|\s*json\b');
const _allowedTopLevelReferences = {
  'and',
  'assign',
  'blank',
  'capture',
  'comment',
  'credential',
  'default',
  'else',
  'elsif',
  'empty',
  'endcapture',
  'endif',
  'endfor',
  'false',
  'for',
  'if',
  'in',
  'input',
  'json',
  'nil',
  'not',
  'null',
  'or',
  'true',
  'unless',
  'url_encode',
  'uri_encode',
};

void _ensureSkillTemplateLiquidFilters() {
  FilterRegistry.register(
    'uri_encode',
    (value, _, _) => Uri.encodeComponent('${value ?? ''}'),
  );
}

String _canonicalizeBody(String value) {
  return _canonicalizeTemplate(
    value.replaceAllMapped(_legacyWholeJsonPlaceholderPattern, (match) {
      return '{{ ${match.group(1)}.${match.group(2)} | json }}';
    }),
  );
}

String _canonicalizeTemplate(String value) {
  return value.replaceAllMapped(_legacyPlaceholderPattern, (match) {
    return '{{ ${match.group(1)}.${match.group(2)} }}';
  });
}

void _parseLiquid(String value) {
  try {
    Liquid().parse(value);
  } on Object catch (_, stackTrace) {
    Error.throwWithStackTrace(
      const FormatException('Invalid Liquid template.'),
      stackTrace,
    );
  }
}

Iterable<_TemplateReference> _references(String value) =>
    _liquidReferencePattern
        .allMatches(value)
        .map(
          (match) => _TemplateReference(
            source: match.group(1) ?? '',
            key: match.group(2) ?? '',
          ),
        );

Iterable<String> _unsupportedBareReferences(String value) => [
  ..._bareOutputPattern.allMatches(value),
  ..._bareConditionPattern.allMatches(value),
  ..._bareForIterablePattern.allMatches(value),
].map((match) => match.group(1) ?? '').where((value) => value.isNotEmpty);

Set<String> _loopLocals(String value) => _forTagPattern
    .allMatches(value)
    .map((match) => match.group(1) ?? '')
    .where((value) => value.isNotEmpty)
    .toSet();

Iterable<String> _renderJsonBodySamples(
  String value, {
  required Map<String, SkillTemplateInputDefinition> inputDefinitions,
  required Map<String, SkillCredentialAttributeDefinition>
  credentialDefinitions,
}) sync* {
  String render({
    Set<String> omittedInputKeys = const {},
    Set<String> omittedCredentialKeys = const {},
  }) => _renderJsonBodySample(
    value,
    inputDefinitions: inputDefinitions,
    credentialDefinitions: credentialDefinitions,
    omittedInputKeys: omittedInputKeys,
    omittedCredentialKeys: omittedCredentialKeys,
  );

  yield render();
  final optionalInputKeys = [
    for (final entry in inputDefinitions.entries)
      if (entry.value.optional) entry.key,
  ];
  final optionalCredentialKeys = [
    for (final entry in credentialDefinitions.entries)
      if (entry.value.optional) entry.key,
  ];
  for (final key in optionalInputKeys) {
    yield render(omittedInputKeys: {key});
  }
  for (final key in optionalCredentialKeys) {
    yield render(omittedCredentialKeys: {key});
  }
  if (optionalInputKeys.length + optionalCredentialKeys.length > 1) {
    yield render(
      omittedInputKeys: optionalInputKeys.toSet(),
      omittedCredentialKeys: optionalCredentialKeys.toSet(),
    );
  }
}

String _renderJsonBodySample(
  String value, {
  required Map<String, SkillTemplateInputDefinition> inputDefinitions,
  required Map<String, SkillCredentialAttributeDefinition>
  credentialDefinitions,
  required Set<String> omittedInputKeys,
  required Set<String> omittedCredentialKeys,
}) {
  try {
    _ensureSkillTemplateLiquidFilters();
    return Liquid().parse(value).render({
      'input': {
        for (final entry in inputDefinitions.entries)
          if (!omittedInputKeys.contains(entry.key))
            entry.key: _sampleInput(entry.value),
      },
      'credential': {
        for (final entry in credentialDefinitions.entries)
          if (!omittedCredentialKeys.contains(entry.key))
            entry.key: 'credential-value',
      },
    });
  } on Object catch (_, stackTrace) {
    Error.throwWithStackTrace(
      const FormatException('Liquid template render failed.'),
      stackTrace,
    );
  }
}

Object? _sampleInput(SkillTemplateInputDefinition definition) =>
    switch (definition.type.trim().toLowerCase()) {
      'array' => const ['sample'],
      'boolean' => true,
      'number' || 'integer' => 1,
      'object' => const {'sample': 'value'},
      _ => 'sample',
    };

bool _requiresJsonFilter(String type) => switch (type.trim().toLowerCase()) {
  'array' || 'boolean' || 'integer' || 'number' || 'object' => true,
  _ => false,
};

class const _TemplateReference({
  required final String source,
  required final String key,
});

class const _TemplateContext({
  required final Map<String, dynamic> inputs,
  required final Map<String, String> credentials,
  required final Map<String, SkillTemplateInputDefinition> inputDefinitions,
  required final Map<String, SkillCredentialAttributeDefinition>
  credentialDefinitions,
}) {
  Map<String, dynamic> get values => {
    'input': inputs,
    'credential': credentials,
  };

  void ensureRequiredReferences(String value) {
    for (final match in _liquidReferencePattern.allMatches(value)) {
      final source = match.group(1) ?? '';
      final key = match.group(2) ?? '';
      final isOptional = _isOptionalReference(source, key);
      if (isOptional) continue;
      final exists = switch (source) {
        'input' => inputs.containsKey(key) && inputs[key] != null,
        'credential' => credentials[key] != null,
        _ => false,
      };
      if (!exists) {
        throw FormatException('Missing required $source: $key.');
      }
    }
  }

  bool _isOptionalReference(String source, String key) => switch (source) {
    'input' => inputDefinitions[key]?.optional ?? false,
    'credential' => credentialDefinitions[key]?.optional ?? false,
    _ => false,
  };
}
