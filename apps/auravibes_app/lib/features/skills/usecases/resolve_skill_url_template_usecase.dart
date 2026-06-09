import 'dart:convert';

import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/features/skills/models/skill_url_template.dart';
import 'package:auravibes_app/services/url/models/url_request_method.dart';
import 'package:liquify/liquify.dart';
import 'package:riverpod/riverpod.dart';

class ResolveSkillUrlTemplateUsecase {
  const ResolveSkillUrlTemplateUsecase();

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

  String? _resolveBody(
    SkillUrlTemplate template,
    _TemplateContext context,
  ) {
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
    } on FormatException catch (error) {
      throw FormatException(
        'Rendered JSON body is invalid: ${error.message}',
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
      return _liquid.parse(source).render(context.values);
    } on Object catch (error) {
      throw FormatException('Liquid template render failed: $error');
    }
  }
}

final resolveSkillUrlTemplateUsecaseProvider =
    Provider<ResolveSkillUrlTemplateUsecase>(
      (_) => const ResolveSkillUrlTemplateUsecase(),
    );

final _liquid = Liquid();
final _liquidReferencePattern = RegExp(
  r'\b(input|credential)\.([A-Za-z0-9_]+)\b',
);
final _legacyPlaceholderPattern = RegExp(
  r'\{(input|credential):([A-Za-z0-9_]+)\}',
);
final _legacyWholeJsonPlaceholderPattern = RegExp(
  r'"\{(input|credential):([A-Za-z0-9_]+)\}"',
);

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
