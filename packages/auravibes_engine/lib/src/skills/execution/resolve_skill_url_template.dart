import 'dart:convert';

import 'package:auravibes_engine/src/skills/models/skill_credential_attribute_definition.dart';
import 'package:auravibes_engine/src/skills/models/skill_template_input_definition.dart';
import 'package:auravibes_engine/src/skills/models/skill_url_template.dart';
import 'package:auravibes_engine/src/skills/models/url_request.dart';
import 'package:liquify/liquify.dart';

class ResolveSkillUrlTemplate {
  const ResolveSkillUrlTemplate();

  UrlRequest call({
    required SkillUrlTemplate template,
    required Map<String, dynamic> inputs,
    required Map<String, String> credentials,
    required Map<String, SkillTemplateInputDefinition> inputDefinitions,
    Map<String, SkillCredentialAttributeDefinition> credentialDefinitions =
        const {},
  }) {
    final context = _TemplateContext(
      inputs: inputs,
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
    if (template.resolvedBodyFormat == SkillUrlTemplateBodyFormat.text) {
      return rendered;
    }

    try {
      return jsonEncode(jsonDecode(rendered));
    } on FormatException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        FormatException('Rendered JSON body is invalid: ${error.message}'),
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
      return Liquid().parse(source).render(context.values);
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        FormatException('Liquid template render failed: $error'),
        stackTrace,
      );
    }
  }
}

void validateSkillTemplateTool({
  required String templateJson,
  required String inputsJson,
  required Map<String, SkillCredentialAttributeDefinition>
  credentialDefinitions,
}) {
  final template = SkillUrlTemplate.fromJsonString(templateJson);
  final inputDefinitions = SkillTemplateInputDefinition.parseMap(inputsJson);
  if (inputDefinitions.containsKey('credentialId')) {
    throw const FormatException(
      'credentialId is reserved for skill credential selection.',
    );
  }

  void validateText(String value) {
    _parseLiquid(value);
    final locals = _loopLocals(value);
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

  validateText(template.url);
  template.headers.values.forEach(validateText);
  template.query.values.forEach(validateText);
  final body = template.body;
  if (body == null) return;
  validateText(body);
  if (template.resolvedBodyFormat == SkillUrlTemplateBodyFormat.text) return;

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

  for (final rendered in _renderJsonBodySamples(
    body,
    inputDefinitions: inputDefinitions,
    credentialDefinitions: credentialDefinitions,
  )) {
    try {
      jsonDecode(rendered);
    } on FormatException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        FormatException('Rendered JSON body is invalid: ${error.message}'),
        stackTrace,
      );
    }
  }
}

String canonicalSkillUrlTemplateJson(String templateJson) =>
    SkillUrlTemplate.fromJsonString(templateJson).toJsonString();

final _liquidReferencePattern = RegExp(
  r'\b(input|credential)\.([A-Za-z0-9_]+)\b',
);
final _legacyPlaceholderPattern = RegExp(
  r'\{(input|credential):([A-Za-z0-9_]+)\}',
);
final _legacyWholeJsonPlaceholderPattern = RegExp(
  r'"\{(input|credential):([A-Za-z0-9_]+)\}"',
);
final _forTagPattern = RegExp(
  r'\{%\s*for\s+([A-Za-z_][A-Za-z0-9_]*)\s+in\b',
);
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
};

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
  } on Object catch (error, stackTrace) {
    Error.throwWithStackTrace(
      FormatException('Invalid Liquid template: $error'),
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
  }) {
    Object? sampleInput(SkillTemplateInputDefinition definition) =>
        switch (definition.type.trim().toLowerCase()) {
          'array' => const ['sample'],
          'boolean' => true,
          'number' || 'integer' => 1,
          'object' => const {'sample': 'value'},
          _ => 'sample',
        };
    try {
      return Liquid().parse(value).render({
        'input': {
          for (final entry in inputDefinitions.entries)
            if (!omittedInputKeys.contains(entry.key))
              entry.key: sampleInput(entry.value),
        },
        'credential': {
          for (final entry in credentialDefinitions.entries)
            if (!omittedCredentialKeys.contains(entry.key))
              entry.key: 'credential-value',
        },
      });
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        FormatException('Liquid template render failed: $error'),
        stackTrace,
      );
    }
  }

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

bool _requiresJsonFilter(String type) => switch (type.trim().toLowerCase()) {
  'array' || 'boolean' || 'integer' || 'number' || 'object' => true,
  _ => false,
};

class _TemplateReference {
  const _TemplateReference({required this.source, required this.key});

  final String source;
  final String key;
}

class _TemplateContext {
  const _TemplateContext({
    required this.inputs,
    required this.credentials,
    required this.inputDefinitions,
    required this.credentialDefinitions,
  });

  final Map<String, dynamic> inputs;
  final Map<String, String> credentials;
  final Map<String, SkillTemplateInputDefinition> inputDefinitions;
  final Map<String, SkillCredentialAttributeDefinition> credentialDefinitions;

  Map<String, dynamic> get values => {
    'input': inputs,
    'credential': credentials,
  };

  void ensureRequiredReferences(String value) {
    for (final match in _liquidReferencePattern.allMatches(value)) {
      final source = match.group(1) ?? '';
      final key = match.group(2) ?? '';
      final isOptional = switch (source) {
        'input' => inputDefinitions[key]?.optional ?? false,
        'credential' => credentialDefinitions[key]?.optional ?? false,
        _ => false,
      };
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
}
