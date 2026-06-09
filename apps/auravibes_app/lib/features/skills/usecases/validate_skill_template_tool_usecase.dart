import 'dart:convert';

import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/features/skills/models/skill_url_template.dart';
import 'package:liquify/liquify.dart';
import 'package:riverpod/riverpod.dart';

class ValidateSkillTemplateToolUsecase {
  const ValidateSkillTemplateToolUsecase();

  void call({
    required String templateJson,
    required String inputsJson,
    required Map<String, SkillCredentialAttributeDefinition>
    credentialDefinitions,
  }) {
    final template = SkillUrlTemplate.fromJsonString(templateJson);
    final inputDefinitions = SkillTemplateInputDefinition.parseMap(inputsJson);

    _validateReservedInputNames(inputDefinitions);
    _validateTemplatePlaceholders(
      template: template,
      inputDefinitions: inputDefinitions,
      credentialDefinitions: credentialDefinitions,
    );
  }

  String canonicalTemplateJson(String templateJson) {
    return SkillUrlTemplate.fromJsonString(templateJson).toJsonString();
  }

  void _validateTemplatePlaceholders({
    required SkillUrlTemplate template,
    required Map<String, SkillTemplateInputDefinition> inputDefinitions,
    required Map<String, SkillCredentialAttributeDefinition>
    credentialDefinitions,
  }) {
    _validateTextPlaceholders(
      template.url,
      inputDefinitions: inputDefinitions,
      credentialDefinitions: credentialDefinitions,
    );
    for (final value in template.headers.values) {
      _validateTextPlaceholders(
        value,
        inputDefinitions: inputDefinitions,
        credentialDefinitions: credentialDefinitions,
      );
    }
    for (final value in template.query.values) {
      _validateTextPlaceholders(
        value,
        inputDefinitions: inputDefinitions,
        credentialDefinitions: credentialDefinitions,
      );
    }
    final body = template.body;
    if (body == null) return;
    _validateBody(
      body: body,
      bodyFormat: template.resolvedBodyFormat,
      inputDefinitions: inputDefinitions,
      credentialDefinitions: credentialDefinitions,
    );
  }

  void _validateBody({
    required String body,
    required SkillUrlTemplateBodyFormat bodyFormat,
    required Map<String, SkillTemplateInputDefinition> inputDefinitions,
    required Map<String, SkillCredentialAttributeDefinition>
    credentialDefinitions,
  }) {
    _validateTextPlaceholders(
      body,
      inputDefinitions: inputDefinitions,
      credentialDefinitions: credentialDefinitions,
    );
    if (bodyFormat == SkillUrlTemplateBodyFormat.text) {
      return;
    }

    _validateJsonBodyValueFilters(body, inputDefinitions: inputDefinitions);
    for (final rendered in _renderJsonBodySamples(
      body,
      inputDefinitions: inputDefinitions,
      credentialDefinitions: credentialDefinitions,
    )) {
      try {
        final _ = jsonDecode(rendered);
      } on FormatException catch (error, stackTrace) {
        Error.throwWithStackTrace(
          FormatException('Rendered JSON body is invalid: ${error.message}'),
          stackTrace,
        );
      }
    }
  }

  void _validateReservedInputNames(
    Map<String, SkillTemplateInputDefinition> inputDefinitions,
  ) {
    if (!inputDefinitions.containsKey(_credentialIdInputName)) return;
    throw const FormatException(
      'credentialId is reserved for skill credential selection.',
    );
  }

  void _validateJsonBodyValueFilters(
    String body, {
    required Map<String, SkillTemplateInputDefinition> inputDefinitions,
  }) {
    for (final output in _liquidOutputPattern.allMatches(body)) {
      final expression = output.group(1) ?? '';
      final reference = _liquidReferencePattern.firstMatch(expression);
      if (reference == null || reference.group(1) != 'input') continue;

      final inputName = reference.group(2) ?? '';
      final definition = inputDefinitions[inputName];
      if (definition == null || !_requiresJsonFilter(definition.type)) {
        continue;
      }
      if (_jsonFilterPattern.hasMatch(expression)) continue;

      throw FormatException(
        'JSON body input "$inputName" with type ${definition.type} must use '
        'the json filter.',
      );
    }
  }

  void _validateTextPlaceholders(
    String value, {
    required Map<String, SkillTemplateInputDefinition> inputDefinitions,
    required Map<String, SkillCredentialAttributeDefinition>
    credentialDefinitions,
  }) {
    _parseLiquid(value);
    final locals = _loopLocals(value);
    for (final reference in _references(value)) {
      if (locals.contains(reference.source)) continue;
      final isKnown = switch (reference.source) {
        'input' => inputDefinitions.containsKey(reference.key),
        'credential' => credentialDefinitions.containsKey(reference.key),
        _ => false,
      };
      if (!isKnown) _throwUnknownReference(reference);
    }

    for (final reference in _unsupportedBareReferences(value)) {
      if (_allowedTopLevelReferences.contains(reference)) continue;
      if (locals.contains(reference)) continue;
      throw FormatException(
        'Unsupported Liquid reference: $reference. Use input.name or '
        'credential.name.',
      );
    }
  }

  void _parseLiquid(String value) {
    try {
      final _ = _liquid.parse(value);
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        FormatException('Invalid Liquid template: $error'),
        stackTrace,
      );
    }
  }

  String _renderSample(
    String value, {
    required Map<String, SkillTemplateInputDefinition> inputDefinitions,
    required Map<String, SkillCredentialAttributeDefinition>
    credentialDefinitions,
    Set<String> omittedInputKeys = const {},
    Set<String> omittedCredentialKeys = const {},
  }) {
    try {
      return _liquid.parse(value).render({
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
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        FormatException('Liquid template render failed: $error'),
        stackTrace,
      );
    }
  }

  Iterable<String> _renderJsonBodySamples(
    String value, {
    required Map<String, SkillTemplateInputDefinition> inputDefinitions,
    required Map<String, SkillCredentialAttributeDefinition>
    credentialDefinitions,
  }) sync* {
    yield _renderSample(
      value,
      inputDefinitions: inputDefinitions,
      credentialDefinitions: credentialDefinitions,
    );

    final optionalInputKeys = [
      for (final entry in inputDefinitions.entries)
        if (entry.value.optional) entry.key,
    ];
    final optionalCredentialKeys = [
      for (final entry in credentialDefinitions.entries)
        if (entry.value.optional) entry.key,
    ];

    for (final key in optionalInputKeys) {
      yield _renderSample(
        value,
        inputDefinitions: inputDefinitions,
        credentialDefinitions: credentialDefinitions,
        omittedInputKeys: {key},
      );
    }
    for (final key in optionalCredentialKeys) {
      yield _renderSample(
        value,
        inputDefinitions: inputDefinitions,
        credentialDefinitions: credentialDefinitions,
        omittedCredentialKeys: {key},
      );
    }
    if (optionalInputKeys.length + optionalCredentialKeys.length <= 1) return;
    yield _renderSample(
      value,
      inputDefinitions: inputDefinitions,
      credentialDefinitions: credentialDefinitions,
      omittedInputKeys: optionalInputKeys.toSet(),
      omittedCredentialKeys: optionalCredentialKeys.toSet(),
    );
  }

  Object? _sampleInput(SkillTemplateInputDefinition definition) {
    return switch (definition.type.trim().toLowerCase()) {
      'array' => const ['sample'],
      'boolean' => true,
      'number' || 'integer' => 1,
      'object' => const {'sample': 'value'},
      _ => 'sample',
    };
  }

  Iterable<_TemplateReference> _references(String value) {
    return _liquidReferencePattern.allMatches(value).map(
      (match) {
        return _TemplateReference(
          source: match.group(1) ?? '',
          key: match.group(2) ?? '',
        );
      },
    );
  }

  Iterable<String> _unsupportedBareReferences(String value) {
    return [
      ..._bareOutputPattern.allMatches(value),
      ..._bareConditionPattern.allMatches(value),
      ..._bareForIterablePattern.allMatches(value),
    ].map((match) => match.group(1) ?? '').where((value) => value.isNotEmpty);
  }

  Set<String> _loopLocals(String value) {
    return _forTagPattern
        .allMatches(value)
        .map((match) => match.group(1) ?? '')
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  void _throwUnknownReference(_TemplateReference reference) {
    throw FormatException(
      'Unknown ${reference.source} placeholder: ${reference.key}.',
    );
  }
}

final validateSkillTemplateToolUsecaseProvider =
    Provider<ValidateSkillTemplateToolUsecase>(
      (_) => const ValidateSkillTemplateToolUsecase(),
    );

final _liquid = Liquid();
const _credentialIdInputName = 'credentialId';
final _liquidReferencePattern = RegExp(
  r'\b(input|credential)\.([A-Za-z0-9_]+)\b',
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
final _liquidOutputPattern = RegExp(r'\{\{\s*([^}]*)\s*\}\}');
final _jsonFilterPattern = RegExp(r'\|\s*json\b');

bool _requiresJsonFilter(String type) {
  return switch (type.trim().toLowerCase()) {
    'array' || 'boolean' || 'integer' || 'number' || 'object' => true,
    _ => false,
  };
}

class _TemplateReference {
  const _TemplateReference({required this.source, required this.key});

  final String source;
  final String key;
}
