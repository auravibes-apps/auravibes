import 'dart:convert';

import 'package:auravibes_engine/src/a2ui/a2ui_action.dart';
import 'package:auravibes_engine/src/a2ui/a2ui_catalog.dart';
import 'package:auravibes_engine/src/a2ui/a2ui_form_validation.dart';
import 'package:auravibes_engine/src/a2ui/a2ui_validation.dart';
import 'package:auravibes_engine/src/public_url_classifier.dart';

const a2uiChatProtocolVersion = 'v1';
const a2uiChatWireVersion = 'v0.9';
const a2uiChatCatalogId = 'urn:auravibes:a2ui:chat:v1';
const a2uiChatFormCatalogId = 'urn:auravibes:a2ui:chat:form:v1';
const a2uiChatCatalogIds = <String>{a2uiChatCatalogId, a2uiChatFormCatalogId};
const a2uiChatActionMetadataKey = 'a2uiAction';
const a2uiChatFormSubmitComponentId = '__aura_form_submit__';
const a2uiChatFormSubmitActionName = 'submit';
const int maxA2uiChatPayloadBytes = 512 * 1024;
const maxA2uiChatNestingDepth = 32;

const baselineA2uiChatComponents = <String>{
  'Button',
  'Card',
  'CheckBox',
  'ChoicePicker',
  'Column',
  'DateTimeInput',
  'Divider',
  'Icon',
  'Image',
  'List',
  'Modal',
  'Row',
  'Slider',
  'Tabs',
  'Text',
  'TextField',
};

const supportedA2uiChatComponents = <String>{
  ...baselineA2uiChatComponents,
  'Progress',
  'Badge',
  'Avatar',
  'AvatarGroup',
  'Table',
  'Chart',
  'EmptyState',
  'LoadingIndicator',
  'AnimatedContent',
  'Accordion',
  'Alert',
  'CodeBlock',
  'Fieldset',
  'FlexItem',
  'Form',
  'Grid',
  'KeyValue',
  'Link',
  'Rating',
  'Section',
  'Skeleton',
  'Spacer',
  'Stat',
  'Stepper',
  'Tab',
  'TagInput',
  'Timeline',
  'Tooltip',
  'Wrap',
};

const a2uiChatInteractionModes = <String>{'passive', 'requiresUserAction'};

/// Pure-Dart protocol and catalog rules shared by app and server.
abstract final class A2uiChatContract {
  static String get systemPrompt =>
      systemPromptForComponents(supportedA2uiChatComponents);

  /// Advertises only the components supported by the receiving client.
  static String systemPromptForComponents(Set<String> supportedComponents) {
    if (!supportedComponents.any(a2uiChatComponentSchemas.containsKey)) {
      return '';
    }
    return '''
Use A2UI $a2uiChatWireVersion with one of these catalogs:
- "$a2uiChatCatalogId" for passive response surfaces only.
- "$a2uiChatFormCatalogId" for requiresUserAction form surfaces only.
Wrap each message in protocolVersion "$a2uiChatProtocolVersion" and the
interactionMode matching its catalog. Create each logical surface once; use
updateComponents only to complete or change that surface. Every component
tree needs one root component. Never stop after createSurface: immediately
emit updateComponents for that surface. Emit each envelope as a separate JSON
object. Never put protocol JSON in ordinary text.
Form submission is owned by the application. Do not emit component actions;
the application adds the submit control after the form surface.
Passive response controls may use literal values or data-model path bindings.
Form controls must use {"path":"/field"} bindings. Template descendants may
use relative bindings such as {"path":"label"}. Slider precision is the
number of decimal places (default 2, minimum 0); slider step defaults to 1.
Text.text and control labels accept literal strings or data-model path bindings.
Text is plain text; Markdown formatting is unsupported.
DateTimeInput values use "YYYY-MM-DD" for date, "HH:mm" for time, and RFC3339
with an explicit offset or Z for dateTime.
TextField variant "number" requests a numeric keyboard; it does not filter input.
Dashboard data accepts literals or {"path":"/field"} root-model bindings.
Initialize bound values with updateDataModel before referencing them.
Chart series values must match labels in length. Table rows must match columns
in width and contain only JSON scalars. Progress values range from 0 to 1.

${supportedComponents.contains('Text') ? '''
COMPLETE_SURFACE_EXAMPLE_START
{"protocolVersion":"v1","interactionMode":"passive","message":{"version":"v0.9","createSurface":{"surfaceId":"example","catalogId":"urn:auravibes:a2ui:chat:v1","sendDataModel":false}}}
{"protocolVersion":"v1","interactionMode":"passive","message":{"version":"v0.9","updateComponents":{"surfaceId":"example","components":[{"id":"root","component":"Text","text":"Example"}]}}}
COMPLETE_SURFACE_EXAMPLE_END
''' : ''}
${supportedComponents.contains('Tabs') && supportedComponents.contains('Text') ? '''
BOUND_TABS_EXAMPLE_START
{"protocolVersion":"v1","interactionMode":"passive","message":{"version":"v0.9","createSurface":{"surfaceId":"bound-tabs","catalogId":"urn:auravibes:a2ui:chat:v1","sendDataModel":false}}}
{"protocolVersion":"v1","interactionMode":"passive","message":{"version":"v0.9","updateDataModel":{"surfaceId":"bound-tabs","path":"/","value":{"activeTab":0}}}}
{"protocolVersion":"v1","interactionMode":"passive","message":{"version":"v0.9","updateComponents":{"surfaceId":"bound-tabs","components":[{"id":"root","component":"Tabs","tabs":[{"label":"Overview","content":"overview"},{"label":"Details","content":"details"}],"activeTab":{"path":"/activeTab"}},{"id":"overview","component":"Text","text":"Overview"},{"id":"details","component":"Text","text":"Details"}]}}}
BOUND_TABS_EXAMPLE_END
''' : ''}

CATALOG_SCHEMA_START
${jsonEncode({for (final entry in a2uiChatComponentSchemas.entries)
      if (supportedComponents.contains(entry.key)) entry.key: entry.value})}
CATALOG_EXAMPLES_START
${jsonEncode({for (final entry in a2uiChatComponentExamples.entries)
      if (supportedComponents.contains(entry.key)) entry.key: entry.value})}
CATALOG_END
''';
  }

  static String encodeEnvelope(
    Map<String, Object?> message, {
    String interactionMode = 'passive',
  }) => jsonEncode({
    'protocolVersion': a2uiChatProtocolVersion,
    'interactionMode': interactionMode,
    'message': message,
  });

  static bool isValidEnvelope(
    Object? value, {
    bool allowLegacyBindings = false,
  }) {
    if (value is! Map) return false;
    final envelope = Map<String, Object?>.from(value);
    final initialSurface = envelope['initialSurface'];
    if (initialSurface is Map) {
      final mode = envelope['interactionMode'];
      return envelope['protocolVersion'] == a2uiChatProtocolVersion &&
          mode is String &&
          a2uiChatInteractionModes.contains(mode) &&
          validateInitialSurface(
                Map<String, Object?>.from(initialSurface),
                interactionMode: mode,
                allowLegacyBindings: allowLegacyBindings,
              ) ==
              null;
    }
    final message = envelope['message'];
    final mode = envelope['interactionMode'];
    if (envelope['protocolVersion'] != a2uiChatProtocolVersion ||
        message is! Map ||
        mode is! String ||
        !a2uiChatInteractionModes.contains(mode)) {
      return false;
    }
    return isValidMessage(
      Map<String, Object?>.from(message),
      interactionMode: mode,
      allowLegacyBindings: allowLegacyBindings,
    );
  }

  // ignore: unnecessary-nullable, callers may validate an unenveloped message.
  static bool isValidMessage(
    Map<String, Object?> message, {
    String? interactionMode,
    bool allowLegacyBindings = false,
  }) {
    if (validateMessage(
          message,
          interactionMode: interactionMode,
          allowLegacyBindings: allowLegacyBindings,
        ) !=
        null) {
      return false;
    }
    return true;
  }

  static A2uiIssueCode? validateMessage(
    Map<String, Object?> message, {
    String? interactionMode,
    bool allowLegacyBindings = false,
  }) {
    if (message['version'] != a2uiChatWireVersion) {
      return A2uiIssueCode.unsupportedProtocol;
    }
    if (_depth(message) > maxA2uiChatNestingDepth) {
      return A2uiIssueCode.malformedPayload;
    }
    if (!_isJsonObject(message)) return A2uiIssueCode.malformedPayload;
    if (_encodedBytes(message) > maxA2uiChatPayloadBytes) {
      return A2uiIssueCode.oversizedPayload;
    }
    final operations = [
      'createSurface',
      'updateComponents',
      'updateDataModel',
      'deleteSurface',
    ].where(message.containsKey).toList(growable: false);
    if (operations.length != 1) return A2uiIssueCode.malformedPayload;
    final operation = message[operations.single];
    if (operation is! Map ||
        operation['surfaceId'] is! String ||
        (operation['surfaceId'] as String).isEmpty) {
      return A2uiIssueCode.malformedPayload;
    }
    final create = message['createSurface'];
    if (create != null && create is! Map) {
      return A2uiIssueCode.malformedPayload;
    }
    if (create is Map) {
      if (create.keys.any(
        (key) =>
            key is! String ||
            !(const {'surfaceId', 'catalogId', 'sendDataModel'}.contains(key)),
      )) {
        return A2uiIssueCode.malformedPayload;
      }
      final catalogId = create['catalogId'];
      if (catalogId is! String || !a2uiChatCatalogIds.contains(catalogId)) {
        return A2uiIssueCode.unsupportedCatalog;
      }
      if (interactionMode != null &&
          !isCatalogAllowedForMode(catalogId, interactionMode)) {
        return A2uiIssueCode.invalidInteractionMode;
      }
      if (create['sendDataModel'] is! bool? ||
          (create['sendDataModel'] == true && !allowLegacyBindings)) {
        return A2uiIssueCode.malformedPayload;
      }
    }
    final update = message['updateComponents'];
    if (update != null && update is! Map) {
      return A2uiIssueCode.malformedPayload;
    }
    final updateDataModel = message['updateDataModel'];
    if (updateDataModel != null && updateDataModel is! Map) {
      return A2uiIssueCode.malformedPayload;
    }
    if (updateDataModel is Map) {
      final hasUnsupportedKey = updateDataModel.keys.any(
        (key) =>
            key is! String ||
            !(const {'surfaceId', 'path', 'value'}.contains(key)),
      );
      final path = updateDataModel['path'];
      if (hasUnsupportedKey ||
          (path != null &&
              (path is! String ||
                  (!path.startsWith('/') && !allowLegacyBindings)))) {
        return A2uiIssueCode.malformedPayload;
      }
    }
    final delete = message['deleteSurface'];
    if (delete != null && delete is! Map) {
      return A2uiIssueCode.malformedPayload;
    }
    if (update is! Map) return null;
    final components = update['components'];
    if (components is! List) return A2uiIssueCode.malformedPayload;
    return _validateComponents(
      components,
      interactionMode,
      allowLegacyBindings: allowLegacyBindings,
    );
  }

  static bool isCatalogAllowedForMode(String catalogId, String mode) {
    return switch (mode) {
      'passive' => catalogId == a2uiChatCatalogId,
      'requiresUserAction' => catalogId == a2uiChatFormCatalogId,
      _ => false,
    };
  }

  static A2uiIssueCode? validateInitialSurface(
    Map<String, Object?> surface, {
    required String interactionMode,
    bool allowLegacyBindings = false,
  }) {
    if (surface.keys.any(
      (key) => !(const {
        'surfaceId',
        'catalogId',
        'dataModel',
        'components',
      }.contains(key)),
    )) {
      return A2uiIssueCode.malformedPayload;
    }
    final surfaceId = surface['surfaceId'];
    final catalogId = surface['catalogId'];
    final components = surface['components'];
    final dataModel = surface['dataModel'];
    if (!_nonEmpty(surfaceId) ||
        catalogId is! String ||
        !isCatalogAllowedForMode(catalogId, interactionMode) ||
        components is! List ||
        dataModel != null && !_isJsonObject(dataModel)) {
      return A2uiIssueCode.malformedPayload;
    }
    return _validateComponents(
      components,
      interactionMode,
      allowLegacyBindings: allowLegacyBindings,
    );
  }

  static bool containsAgentAction(Object? value) {
    if (value is Map) {
      if (value.containsKey('message')) {
        return containsAgentAction(value['message']);
      }
      if (value.containsKey('updateDataModel')) return false;
      if (value.containsKey('updateComponents')) {
        return containsAgentAction(value['updateComponents']);
      }
      if (value['component'] is String &&
          (value.containsKey('action') ||
              value.containsKey('onSubmittedAction'))) {
        return true;
      }
      return containsAgentAction(value['components']);
    }
    if (value is List) return value.any(containsAgentAction);
    return false;
  }

  static bool isRenderableComponentGraph(
    Map<String, Map<String, Object?>> components,
  ) {
    if (!components.containsKey('root')) return false;
    final visiting = <String>{};
    final visited = <String>{};

    bool visit(String id) {
      if (visited.contains(id)) return true;
      if (!visiting.add(id)) return false;
      final component = components[id];
      if (component == null) return false;
      final references = <String>[];
      for (final key in const ['child', 'trigger', 'content']) {
        final reference = component[key];
        if (reference is String) references.add(reference);
      }
      final children = component['children'];
      if (children is List) {
        if (children.any((child) => child is! String)) return false;
        references.addAll(children.cast<String>());
      } else if (children is Map) {
        final templateId = children['componentId'];
        if (templateId is! String || templateId.isEmpty) return false;
        references.add(templateId);
      }
      final tabs = component['tabs'];
      if (tabs is List) {
        for (final tab in tabs) {
          if (tab is! Map || tab['content'] is! String) return false;
          references.add(tab['content'] as String);
        }
      } else if (tabs is Map) {
        final templateId = tabs['componentId'];
        if (templateId is! String || templateId.isEmpty) return false;
        final template = components[templateId];
        if (template?['component'] != 'Tab') return false;
        references.add(templateId);
      }
      final items = component['items'];
      if (items is List) {
        for (final item in items) {
          if (item is! Map || item['content'] is! String) return false;
          references.add(item['content'] as String);
        }
      }
      for (final reference in references) {
        if (!visit(reference)) return false;
      }
      visiting.remove(id);
      visited.add(id);
      return true;
    }

    return visit('root');
  }

  // ignore: unnecessary-nullable, action metadata is an untrusted boundary.
  static bool isValidAction(Object? value, {required String conversationId}) {
    if (value is! Map ||
        !_isJsonObject(value) ||
        _depth(value) > maxA2uiChatNestingDepth ||
        _encodedBytes(value) > maxA2uiChatPayloadBytes) {
      return false;
    }
    final action = Map<String, Object?>.from(value);
    if (action['protocolVersion'] != a2uiChatProtocolVersion ||
        action['conversationId'] != conversationId ||
        (action['assistantMessageId'] != null &&
            !_nonEmpty(action['assistantMessageId'])) ||
        !_nonEmpty(action['turnId']) ||
        !_nonEmpty(action['surfaceId']) ||
        !_nonEmpty(action['componentId']) ||
        !_nonEmpty(action['actionName']) ||
        !_nonEmpty(action['messageText']) ||
        !_isJsonObject(action['context'])) {
      return false;
    }
    final messageText = action['messageText']! as String;
    final wireSurfaceId = action['wireSurfaceId'];
    final answers = action['answers'];
    return messageText.length <= 10000 &&
        (wireSurfaceId == null || _nonEmpty(wireSurfaceId)) &&
        (answers == null || _isJsonObject(answers)) &&
        _stringList(action['touchedPaths']) &&
        _stringList(action['unansweredPaths']) &&
        _validSubmissionTime(action['submittedAtUtc']);
  }

  static A2uiChatAction? decodeActionMetadata(
    Object? value, {
    required String conversationId,
  }) {
    if (value is Map) {
      final directAction = value[a2uiChatActionMetadataKey];
      if (directAction != null) {
        return decodeAction(directAction, conversationId: conversationId);
      }
      final modelMetadata = value['modelMetadata'];
      if (modelMetadata is Map &&
          modelMetadata[a2uiChatActionMetadataKey] != null) {
        return decodeAction(
          modelMetadata[a2uiChatActionMetadataKey],
          conversationId: conversationId,
        );
      }
    }
    return decodeAction(value, conversationId: conversationId);
  }

  static String appendAnswersToPrompt(String content, A2uiChatAction? action) {
    if (action == null) return content;
    final submittedAt = action.submittedAtUtc;
    return '$content\n\nForm submission context:\n'
        'surface: ${action.wireSurfaceId ?? action.surfaceId}\n'
        'assistant turn: ${action.assistantMessageId ?? action.turnId}\n'
        '${submittedAt == null ? '' : 'submitted at: $submittedAt\n'}'
        'answers: ${jsonEncode(action.answers)}\n'
        'unanswered optional fields: ${jsonEncode(action.unansweredPaths)}';
  }

  static A2uiChatAction? decodeAction(
    Object? value, {
    required String conversationId,
  }) {
    if (value is! Map ||
        !isValidAction(value, conversationId: conversationId)) {
      return null;
    }
    final action = Map<String, Object?>.from(value);
    return A2uiChatAction(
      protocolVersion: action['protocolVersion']! as String,
      conversationId: action['conversationId']! as String,
      turnId: action['turnId']! as String,
      assistantMessageId: action['assistantMessageId'] as String?,
      surfaceId: action['surfaceId']! as String,
      wireSurfaceId: action['wireSurfaceId'] as String?,
      componentId: action['componentId']! as String,
      actionName: action['actionName']! as String,
      context: Map<String, Object?>.from(action['context']! as Map),
      messageText: action['messageText']! as String,
      answers: action['answers'] is Map
          ? Map<String, Object?>.from(action['answers']! as Map)
          : const {},
      touchedPaths:
          (action['touchedPaths'] as List?)?.whereType<String>().toList() ??
          const [],
      unansweredPaths:
          (action['unansweredPaths'] as List?)?.whereType<String>().toList() ??
          const [],
      submittedAtUtc: action['submittedAtUtc'] as String?,
    );
  }

  static A2uiFormValidationResult validateFormValues({
    required Iterable<Map<String, Object?>> components,
    required Map<String, Object?> values,
    Iterable<String> touchedPaths = const [],
  }) => validateA2uiFormValues(
    components: components,
    values: values,
    touchedPaths: touchedPaths,
  );

  static Map<String, Object?> normalizeFormValues({
    required Iterable<Map<String, Object?>> components,
    required Map<String, Object?> values,
  }) => normalizeA2uiFormValues(components: components, values: values);

  /// Validates the documented A2UI date/time wire value for [variant].
  static bool isValidDateTimeValue(Object? variant, String value) =>
      isValidA2uiDateTimeValue(variant, value);

  static bool _isDateTimeRangeValid(
    Object? variant,
    String minimum,
    String maximum,
  ) {
    DateTime parse(String value) => variant == 'time'
        ? DateTime.parse('2000-01-01T$value')
        : DateTime.parse(value);
    return !parse(minimum).isAfter(parse(maximum));
  }

  static int _encodedBytes(Object value) =>
      utf8.encode(jsonEncode(value)).length;

  static bool _nonEmpty(Object? value) => value is String && value.isNotEmpty;

  static bool _stringList(Object? value) =>
      value == null || value is List && value.every(_nonEmpty);

  static bool _validSubmissionTime(Object? value) {
    if (value == null) return true;
    return value is String &&
        value.endsWith('Z') &&
        DateTime.tryParse(value) != null;
  }

  static bool _isJsonObject(Object? value) {
    final pending = <Object?>[value];
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      if (current is Map) {
        if (current.keys.any((key) => key is! String)) return false;
        pending.addAll(current.values);
      } else if (current is List) {
        pending.addAll(current);
      } else if (current is num && !current.isFinite) {
        return false;
      } else if (current != null &&
          current is! String &&
          current is! num &&
          current is! bool) {
        return false;
      }
    }
    return true;
  }

  static A2uiIssueCode? _validateComponents(
    List<Object?> components,
    String? interactionMode, {
    required bool allowLegacyBindings,
  }) {
    final ids = <String>{};
    final byId = <String, Map<Object?, Object?>>{};
    for (final value in components) {
      if (value is! Map ||
          value['id'] is! String ||
          value['component'] is! String ||
          !ids.add(value['id'] as String)) {
        return A2uiIssueCode.malformedPayload;
      }
      byId[value['id']! as String] = value;
    }
    final templateDescendants = _templateDescendants(byId);
    for (final value in byId.values) {
      final component = value['component'];
      if (component is String) {
        final schema = a2uiChatComponentSchemas[component];
        if (schema == null) return A2uiIssueCode.unsupportedComponent;
        final required = schema['required'];
        final properties = schema['properties'];
        if (required is! List || properties is! Map) {
          return A2uiIssueCode.malformedPayload;
        }
        if (required.any(
          (field) => field is! String || !value.containsKey(field),
        )) {
          return A2uiIssueCode.malformedPayload;
        }
        final allowed = properties.keys.whereType<String>().toSet();
        if (value.keys.any(
          (key) =>
              key is! String ||
              (!allowed.contains(key) &&
                  key != 'action' &&
                  key != 'onSubmittedAction'),
        )) {
          return A2uiIssueCode.malformedPayload;
        }
        for (final entry in value.entries) {
          final schemaValue = properties[entry.key];
          // Accept historical names without advertising them in new prompts.
          if ((component == 'Icon' &&
                  entry.key == 'name' &&
                  entry.value is String) ||
              (component == 'Button' &&
                  entry.key == 'variant' &&
                  entry.value == 'borderless') ||
              (component == 'Image' &&
                  entry.key == 'variant' &&
                  const {
                    'icon',
                    'smallFeature',
                    'mediumFeature',
                    'largeFeature',
                    'header',
                  }.contains(entry.value))) {
            continue;
          }
          if (schemaValue is Map &&
              !_matchesSchema(
                entry.value,
                Map<Object?, Object?>.from(schemaValue),
              )) {
            return A2uiIssueCode.malformedPayload;
          }
        }
        if (!_hasValidBindingPaths(
          value,
          allowRelative: templateDescendants.contains(value['id']),
          allowLegacyBindings: allowLegacyBindings,
        )) {
          return A2uiIssueCode.malformedPayload;
        }
        final componentIssue = _validateComponentRules(
          component,
          value,
          interactionMode,
        );
        if (componentIssue != null) return componentIssue;
      }
    }
    return null;
  }

  static Set<String> _templateDescendants(
    Map<String, Map<Object?, Object?>> components,
  ) {
    final templates = <String>{};
    for (final component in components.values) {
      for (final source in [component['children'], component['tabs']]) {
        if (source is Map<Object?, Object?> &&
            source['componentId'] is String) {
          templates.add(source['componentId']! as String);
        }
      }
    }
    final descendants = <String>{...templates};
    final pending = <String>[...templates];
    while (pending.isNotEmpty) {
      final id = pending.removeLast();
      final component = components[id];
      if (component == null) continue;
      for (final child in _referencedComponentIds(component)) {
        if (descendants.add(child)) pending.add(child);
      }
    }
    return descendants;
  }

  static Iterable<String> _referencedComponentIds(
    Map<Object?, Object?> value,
  ) sync* {
    for (final key in const ['child', 'trigger', 'content']) {
      final id = value[key];
      if (id is String) yield id;
    }
    final children = value['children'];
    if (children is List<Object?>) {
      yield* children.whereType<String>();
    }
    final tabs = value['tabs'];
    if (tabs is List<Object?>) {
      for (final tab in tabs.whereType<Map<Object?, Object?>>()) {
        final id = tab['content'];
        if (id is String) yield id;
      }
    }
    final items = value['items'];
    if (items is List<Object?>) {
      for (final item in items.whereType<Map<Object?, Object?>>()) {
        final id = item['content'];
        if (id is String) yield id;
      }
    }
  }

  static bool _hasValidBindingPaths(
    Object? value, {
    required bool allowRelative,
    required bool allowLegacyBindings,
  }) {
    if (value is List<Object?>) {
      return value.every(
        (item) => _hasValidBindingPaths(
          item,
          allowRelative: allowRelative,
          allowLegacyBindings: allowLegacyBindings,
        ),
      );
    }
    if (value is! Map<Object?, Object?>) return true;
    final path = value['path'];
    if (path is String) {
      if (path.startsWith('/')) return true;
      if (allowRelative && _isRelativePointer(path)) return true;
      if (allowLegacyBindings && path.contains('.')) return true;
      return false;
    }
    return value.values.every(
      (item) => _hasValidBindingPaths(
        item,
        allowRelative: allowRelative,
        allowLegacyBindings: allowLegacyBindings,
      ),
    );
  }

  static bool _isRelativePointer(String path) =>
      path.isNotEmpty && path.split('/').every((segment) => segment.isNotEmpty);

  static bool _matchesSchema(Object? value, Map<Object?, Object?> schema) {
    final allowed = schema['enum'];
    if (allowed is List && !allowed.contains(value)) return false;
    if (value is num) {
      if (!value.isFinite) return false;
      final min = schema['minimum'];
      final max = schema['maximum'];
      if (min is num && value < min || max is num && value > max) return false;
    }
    if (value is String) {
      final minLength = schema['minLength'];
      if (minLength is int && value.length < minLength) return false;
      if (schema['pattern'] == '^/' && !value.startsWith('/')) return false;
    }
    final oneOf = schema['oneOf'];
    if (oneOf is List) {
      return oneOf.whereType<Map<Object?, Object?>>().any(
        (candidate) =>
            _matchesSchema(value, Map<Object?, Object?>.from(candidate)),
      );
    }
    final type = schema['type'];
    if (type == 'null') return value == null;
    if (type == 'string') return value is String;
    if (type == 'number') return value is num;
    if (type == 'integer') return value is int;
    if (type == 'boolean') return value is bool;
    if (type == 'array') {
      final items = schema['items'];
      return value is List &&
          (schema['minItems'] is! int ||
              value.length >= (schema['minItems']! as int)) &&
          (items is! Map ||
              value.every(
                (item) =>
                    _matchesSchema(item, Map<Object?, Object?>.from(items)),
              ));
    }
    if (type != 'object') return true;
    final rawProperties = schema['properties'];
    if (value is! Map || rawProperties is! Map) return false;
    final properties = Map<Object?, Object?>.from(rawProperties);
    final required = schema['required'];
    return (required is! List || required.every(value.containsKey)) &&
        value.keys.every(
          (key) => key is String && properties.containsKey(key),
        ) &&
        value.entries.every((entry) {
          final property = properties[entry.key];
          return property is! Map ||
              _matchesSchema(entry.value, Map<Object?, Object?>.from(property));
        }) &&
        (!properties.containsKey('path') || _nonEmpty(value['path']));
  }

  static A2uiIssueCode? _validateComponentRules(
    String component,
    Map<Object?, Object?> value,
    String? interactionMode,
  ) {
    if (interactionMode == 'requiresUserAction' &&
        const {
          'CheckBox',
          'ChoicePicker',
          'DateTimeInput',
          'Rating',
          'Slider',
          'TagInput',
          'Tabs',
          'TextField',
        }.contains(component) &&
        !_isReference(value[component == 'Tabs' ? 'activeTab' : 'value'])) {
      return A2uiIssueCode.malformedPayload;
    }
    if (component == 'Form' &&
        interactionMode != null &&
        interactionMode != 'requiresUserAction') {
      return A2uiIssueCode.invalidInteractionMode;
    }
    switch (component) {
      case 'Avatar':
        final url = value['url'];
        if (url is String && !_isPublicImageUrl(url)) {
          return A2uiIssueCode.malformedPayload;
        }
      case 'AvatarGroup':
        final avatars = value['avatars'];
        if (avatars is List &&
            avatars.any(
              (avatar) =>
                  avatar is Map &&
                  avatar['url'] is String &&
                  !_isPublicImageUrl(avatar['url'] as String),
            )) {
          return A2uiIssueCode.malformedPayload;
        }
      case 'Table':
        final columns = value['columns'];
        final rows = value['rows'];
        if (columns is List && rows is List) {
          for (final column in columns) {
            if (column is! String &&
                (column is! Map || column['label'] is! String)) {
              return A2uiIssueCode.malformedPayload;
            }
          }
          for (final row in rows) {
            final cells = row is Map ? row['cells'] : row;
            if (cells is! List || cells.length != columns.length) {
              return A2uiIssueCode.malformedPayload;
            }
          }
        }
      case 'Chart':
        final labels = value['labels'];
        final series = value['series'];
        final minY = value['minY'];
        final maxY = value['maxY'];
        if (minY is num && maxY is num && minY > maxY) {
          return A2uiIssueCode.malformedPayload;
        }
        if (value['stacked'] == true && value['variant'] != 'bar') {
          return A2uiIssueCode.malformedPayload;
        }
        if (labels is List && series is List) {
          final invalidSeries = series.any(
            (item) =>
                item is! Map ||
                item['values'] is! List ||
                (item['values'] as List).length != labels.length ||
                (item['values'] as List).any(
                  (sample) => sample is! num || !sample.isFinite,
                ),
          );
          final pie = value['variant'] == 'pie' || value['variant'] == 'donut';
          final invalidPie =
              pie &&
              (series.length != 1 ||
                  (series.single as Map)['values'] is! List ||
                  ((series.single as Map)['values'] as List).any(
                    (sample) => sample is! num || sample < 0,
                  ));
          if (invalidSeries || invalidPie) {
            return A2uiIssueCode.malformedPayload;
          }
        }
      case 'Progress':
        if (value['indeterminate'] != true && value['value'] == null) {
          return A2uiIssueCode.malformedPayload;
        }
      case 'EmptyState':
        if (value.containsKey('icon') &&
            !a2uiChatIconNames.contains(value['icon'])) {
          return A2uiIssueCode.malformedPayload;
        }
      case 'Row' || 'Column' || 'List' || 'Grid' || 'Wrap':
        final children = value['children'];
        final isStatic =
            children is List &&
            children.every((child) => child is String && child.isNotEmpty);
        final isTemplate =
            children is Map &&
            children['path'] is String &&
            (children['path'] as String).isNotEmpty &&
            children['componentId'] is String &&
            (children['componentId'] as String).isNotEmpty;
        if (!isStatic && !isTemplate) {
          return A2uiIssueCode.malformedPayload;
        }
      case 'Slider':
        final min = value['min'];
        final max = value['max'];
        final step = value['step'] ?? 1;
        final precision = value['precision'] ?? 2;
        if (min is! num ||
            max is! num ||
            min > max ||
            step is! num ||
            step <= 0 ||
            precision is! int ||
            precision < 0 ||
            precision > 20) {
          return A2uiIssueCode.malformedPayload;
        }
      case 'DateTimeInput':
        final selected = value['value'];
        final variant = value['variant'];
        if (selected is String && !isValidDateTimeValue(variant, selected)) {
          return A2uiIssueCode.malformedPayload;
        }
        for (final bound in [value['min'], value['max']]) {
          if (bound is String && !isValidDateTimeValue(variant, bound)) {
            return A2uiIssueCode.malformedPayload;
          }
        }
        if (value['min'] is String &&
            value['max'] is String &&
            !_isDateTimeRangeValid(
              value['variant'],
              value['min']! as String,
              value['max']! as String,
            )) {
          return A2uiIssueCode.malformedPayload;
        }
      case 'ChoicePicker':
        final options = value['options'];
        if (options is! List ||
            options.any(
              (option) =>
                  option is! Map ||
                  option['value'] == null ||
                  option['label'] is! String,
            )) {
          return A2uiIssueCode.malformedPayload;
        }
        final minimum = value['minSelections'];
        final maximum = value['maxSelections'];
        if (minimum is int && maximum is int && minimum > maximum) {
          return A2uiIssueCode.malformedPayload;
        }
      case 'Tabs':
        final tabs = value['tabs'];
        final isStatic =
            tabs is List &&
            tabs.isNotEmpty &&
            tabs.every(
              (tab) =>
                  tab is Map &&
                  tab['label'] is String &&
                  (tab['label'] as String).isNotEmpty &&
                  tab['content'] is String &&
                  (tab['content'] as String).isNotEmpty,
            );
        final isTemplate =
            tabs is Map &&
            tabs['path'] is String &&
            (tabs['path'] as String).isNotEmpty &&
            tabs['componentId'] is String &&
            (tabs['componentId'] as String).isNotEmpty;
        if (!isStatic && !isTemplate) {
          return A2uiIssueCode.malformedPayload;
        }
      case 'Image':
        final url = value['url'];
        try {
          if (url is! String) throw const FormatException();
          requirePublicUriSyntax(url, requireHttps: true);
        } on FormatException catch (_) {
          return A2uiIssueCode.malformedPayload;
        }
    }
    return null;
  }

  static bool _isReference(Object? value) =>
      value is Map &&
      value['path'] is String &&
      (value['path'] as String).isNotEmpty;

  static bool _isPublicImageUrl(String url) {
    try {
      requirePublicUriSyntax(url, requireHttps: true);
      return true;
    } on FormatException {
      return false;
    }
  }

  static int _depth(Object value) {
    var deepest = 0;
    final pending = <(Object?, int)>[(value, 0)];
    while (pending.isNotEmpty) {
      final (current, depth) = pending.removeLast();
      if (depth > deepest) deepest = depth;
      if (deepest > maxA2uiChatNestingDepth) return deepest;
      if (current is Map) {
        for (final child in current.values) {
          pending.add((child, depth + 1));
        }
      } else if (current is List) {
        for (final child in current) {
          pending.add((child, depth + 1));
        }
      }
    }
    return deepest;
  }
}
