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
    final headerIssue = _validateMessageHeader(message);
    if (headerIssue != null) return headerIssue;
    final operations = _messageOperations(message);
    if (operations.length != 1) return A2uiIssueCode.malformedPayload;
    if (!_isValidSurfaceOperation(message[operations.single])) {
      return A2uiIssueCode.malformedPayload;
    }
    final createIssue = _validateCreateSurface(
      message['createSurface'],
      interactionMode,
      allowLegacyBindings: allowLegacyBindings,
    );
    if (createIssue != null) return createIssue;
    final dataModelIssue = _validateUpdateDataModel(
      message['updateDataModel'],
      allowLegacyBindings: allowLegacyBindings,
    );
    if (dataModelIssue != null) return dataModelIssue;
    final update = message['updateComponents'];
    if (update != null && update is! Map) {
      return A2uiIssueCode.malformedPayload;
    }
    final delete = message['deleteSurface'];
    if (delete != null && delete is! Map) {
      return A2uiIssueCode.malformedPayload;
    }
    return _validateUpdatedComponents(
      update,
      interactionMode,
      allowLegacyBindings: allowLegacyBindings,
    );
  }

  static A2uiIssueCode? _validateMessageHeader(Map<String, Object?> message) {
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
    return null;
  }

  static List<String> _messageOperations(Map<String, Object?> message) => [
    'createSurface',
    'updateComponents',
    'updateDataModel',
    'deleteSurface',
  ].where(message.containsKey).toList(growable: false);

  static bool _isValidSurfaceOperation(Object? operation) =>
      operation is Map && _nonEmpty(operation['surfaceId']);

  static A2uiIssueCode? _validateCreateSurface(
    Object? create,
    String? interactionMode, {
    required bool allowLegacyBindings,
  }) {
    if (create == null) return null;
    if (create is! Map) return A2uiIssueCode.malformedPayload;
    if (_hasUnsupportedKeys(create, const {
      'surfaceId',
      'catalogId',
      'sendDataModel',
    })) {
      return A2uiIssueCode.malformedPayload;
    }
    final catalogId = create['catalogId'];
    final catalogIssue = _validateCreateCatalog(catalogId, interactionMode);
    if (catalogIssue != null) return catalogIssue;
    return _validateSendDataModel(create['sendDataModel'], allowLegacyBindings);
  }

  static A2uiIssueCode? _validateCreateCatalog(
    Object? catalogId,
    String? interactionMode,
  ) {
    if (catalogId is! String || !a2uiChatCatalogIds.contains(catalogId)) {
      return A2uiIssueCode.unsupportedCatalog;
    }
    if (interactionMode != null &&
        !isCatalogAllowedForMode(catalogId, interactionMode)) {
      return A2uiIssueCode.invalidInteractionMode;
    }
    return null;
  }

  static A2uiIssueCode? _validateSendDataModel(
    Object? sendDataModel,
    bool allowLegacyBindings,
  ) {
    if (sendDataModel is! bool? ||
        (sendDataModel == true && !allowLegacyBindings)) {
      return A2uiIssueCode.malformedPayload;
    }
    return null;
  }

  static A2uiIssueCode? _validateUpdateDataModel(
    Object? updateDataModel, {
    required bool allowLegacyBindings,
  }) {
    if (updateDataModel == null) return null;
    if (updateDataModel is! Map) return A2uiIssueCode.malformedPayload;
    if (_hasUnsupportedKeys(updateDataModel, const {
      'surfaceId',
      'path',
      'value',
    })) {
      return A2uiIssueCode.malformedPayload;
    }
    final path = updateDataModel['path'];
    if (path == null) return null;
    if (path is! String) return A2uiIssueCode.malformedPayload;
    if (!path.startsWith('/') && !allowLegacyBindings) {
      return A2uiIssueCode.malformedPayload;
    }
    return null;
  }

  static A2uiIssueCode? _validateUpdatedComponents(
    Object? update,
    String? interactionMode, {
    required bool allowLegacyBindings,
  }) {
    if (update is! Map) return null;
    final components = update['components'];
    if (components is! List) return A2uiIssueCode.malformedPayload;
    return _validateComponents(
      components,
      interactionMode,
      allowLegacyBindings: allowLegacyBindings,
    );
  }

  static bool _hasUnsupportedKeys(
    Map<Object?, Object?> value,
    Set<String> allowed,
  ) => value.keys.any((key) => key is! String || !allowed.contains(key));

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

    return _visitComponent('root', components, visiting, visited);
  }

  static bool _visitComponent(
    String id,
    Map<String, Map<String, Object?>> components,
    Set<String> visiting,
    Set<String> visited,
  ) {
    if (visited.contains(id)) return true;
    if (!visiting.add(id)) return false;
    final component = components[id];
    if (component == null) return false;
    final references = _componentReferences(component, components);
    if (references == null) return false;
    for (final reference in references) {
      if (!_visitComponent(reference, components, visiting, visited)) {
        return false;
      }
    }
    visiting.remove(id);
    visited.add(id);
    return true;
  }

  static List<String>? _componentReferences(
    Map<String, Object?> component,
    Map<String, Map<String, Object?>> components,
  ) {
    final references = <String>[
      for (final key in const ['child', 'trigger', 'content'])
        if (component[key] is String) component[key]! as String,
    ];
    final children = _childrenReferences(component['children']);
    if (children == null) return null;
    references.addAll(children);
    final tabs = _tabReferences(component['tabs'], components);
    if (tabs == null) return null;
    references.addAll(tabs);
    final items = _itemReferences(component['items']);
    if (items == null) return null;
    references.addAll(items);
    return references;
  }

  static List<String>? _childrenReferences(Object? children) {
    if (children is List) {
      if (children.any((child) => child is! String)) return null;
      return children.cast<String>().toList(growable: false);
    }
    if (children is Map) {
      final templateId = children['componentId'];
      if (!_nonEmpty(templateId)) return null;
      return [templateId as String];
    }
    return const [];
  }

  static List<String>? _tabReferences(
    Object? tabs,
    Map<String, Map<String, Object?>> components,
  ) {
    if (tabs is List) {
      final references = <String>[];
      for (final tab in tabs) {
        if (tab is! Map || tab['content'] is! String) return null;
        references.add(tab['content'] as String);
      }
      return references;
    }
    if (tabs is Map) {
      final templateId = tabs['componentId'];
      if (!_nonEmpty(templateId)) return null;
      final template = components[templateId as String];
      if (template?['component'] != 'Tab') return null;
      return [templateId];
    }
    return const [];
  }

  static List<String>? _itemReferences(Object? items) {
    if (items is! List) return const [];
    final references = <String>[];
    for (final item in items) {
      if (item is! Map || item['content'] is! String) return null;
      references.add(item['content'] as String);
    }
    return references;
  }

  // ignore: unnecessary-nullable, action metadata is an untrusted boundary.
  static bool isValidAction(Object? value, {required String conversationId}) {
    if (!_isValidActionPayload(value)) return false;
    final action = Map<String, Object?>.from(value! as Map);
    if (!_hasValidActionFields(action, conversationId)) return false;
    return _hasValidActionDetails(action);
  }

  static bool _isValidActionPayload(Object? value) =>
      value is Map &&
      _isJsonObject(value) &&
      _depth(value) <= maxA2uiChatNestingDepth &&
      _encodedBytes(value) <= maxA2uiChatPayloadBytes;

  static bool _hasValidActionFields(
    Map<String, Object?> action,
    String conversationId,
  ) =>
      action['protocolVersion'] == a2uiChatProtocolVersion &&
      action['conversationId'] == conversationId &&
      (action['assistantMessageId'] == null ||
          _nonEmpty(action['assistantMessageId'])) &&
      _nonEmpty(action['turnId']) &&
      _nonEmpty(action['surfaceId']) &&
      _nonEmpty(action['componentId']) &&
      _nonEmpty(action['actionName']) &&
      _nonEmpty(action['messageText']) &&
      _isJsonObject(action['context']);

  static bool _hasValidActionDetails(Map<String, Object?> action) {
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
      if (!_addJsonValues(current, pending)) return false;
    }
    return true;
  }

  static bool _addJsonValues(Object? current, List<Object?> pending) {
    if (current is Map) {
      if (current.keys.any((key) => key is! String)) return false;
      pending.addAll(current.values);
      return true;
    }
    if (current is List) {
      pending.addAll(current);
      return true;
    }
    if (current is num && !current.isFinite) return false;
    return current == null ||
        current is String ||
        current is num ||
        current is bool;
  }

  static A2uiIssueCode? _validateComponents(
    List<Object?> components,
    String? interactionMode, {
    required bool allowLegacyBindings,
  }) {
    final byId = _indexComponents(components);
    if (byId == null) return A2uiIssueCode.malformedPayload;
    final templateDescendants = _templateDescendants(byId);
    for (final value in byId.values) {
      final issue = _validateComponent(
        value,
        interactionMode,
        templateDescendants: templateDescendants,
        allowLegacyBindings: allowLegacyBindings,
      );
      if (issue != null) return issue;
    }
    return null;
  }

  static Map<String, Map<Object?, Object?>>? _indexComponents(
    List<Object?> components,
  ) {
    final ids = <String>{};
    final byId = <String, Map<Object?, Object?>>{};
    for (final value in components) {
      if (value is! Map ||
          value['id'] is! String ||
          value['component'] is! String) {
        return null;
      }
      final id = value['id']! as String;
      if (!ids.add(id)) return null;
      byId[id] = value;
    }
    return byId;
  }

  static A2uiIssueCode? _validateComponent(
    Map<Object?, Object?> value,
    String? interactionMode, {
    required Set<String> templateDescendants,
    required bool allowLegacyBindings,
  }) {
    final component = value['component'];
    if (component is! String) return A2uiIssueCode.malformedPayload;
    final schemaIssue = _validateComponentSchema(component, value);
    if (schemaIssue != null) return schemaIssue;
    if (!_hasValidBindingPaths(
      value,
      allowRelative: templateDescendants.contains(value['id']),
      allowLegacyBindings: allowLegacyBindings,
    )) {
      return A2uiIssueCode.malformedPayload;
    }
    return _validateComponentRules(component, value, interactionMode);
  }

  static A2uiIssueCode? _validateComponentSchema(
    String component,
    Map<Object?, Object?> value,
  ) {
    final schema = a2uiChatComponentSchemas[component];
    if (schema == null) return A2uiIssueCode.unsupportedComponent;
    final required = schema['required'];
    final properties = schema['properties'];
    if (required is! List || properties is! Map) {
      return A2uiIssueCode.malformedPayload;
    }
    if (_hasMissingRequiredFields(required, value)) {
      return A2uiIssueCode.malformedPayload;
    }
    if (_hasUnsupportedComponentKeys(value, properties)) {
      return A2uiIssueCode.malformedPayload;
    }
    if (!_hasValidSchemaValues(component, value, properties)) {
      return A2uiIssueCode.malformedPayload;
    }
    return null;
  }

  static bool _hasUnsupportedComponentKeys(
    Map<Object?, Object?> value,
    Map<Object?, Object?> properties,
  ) {
    final allowed = properties.keys.whereType<String>().toSet();
    return value.keys.any((key) => !_isAllowedComponentKey(key, allowed));
  }

  static bool _isAllowedComponentKey(Object? key, Set<String> allowed) =>
      key is String &&
      (allowed.contains(key) || key == 'action' || key == 'onSubmittedAction');

  static bool _hasValidSchemaValues(
    String component,
    Map<Object?, Object?> value,
    Map<Object?, Object?> properties,
  ) {
    for (final entry in value.entries) {
      if (_isLegacyComponentProperty(component, entry.key, entry.value)) {
        continue;
      }
      final schemaValue = properties[entry.key];
      if (schemaValue is Map &&
          !_matchesSchema(
            entry.value,
            Map<Object?, Object?>.from(schemaValue),
          )) {
        return false;
      }
    }
    return true;
  }

  static bool _isLegacyComponentProperty(
    String component,
    Object? key,
    Object? value,
  ) => switch ((component, key)) {
    ('Icon', 'name') => value is String,
    ('Button', 'variant') => value == 'borderless',
    ('Image', 'variant') => const {
      'icon',
      'smallFeature',
      'mediumFeature',
      'largeFeature',
      'header',
    }.contains(value),
    _ => false,
  };

  static bool _hasMissingRequiredFields(
    List<Object?> required,
    Map<Object?, Object?> value,
  ) => required.any((field) => field is! String || !value.containsKey(field));

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
    yield* _directReferences(value);
    yield* _listReferences(value['children']);
    yield* _contentReferences(value['tabs']);
    yield* _contentReferences(value['items']);
  }

  static Iterable<String> _directReferences(Map<Object?, Object?> value) sync* {
    for (final key in const ['child', 'trigger', 'content']) {
      final id = value[key];
      if (id is String) yield id;
    }
  }

  static Iterable<String> _listReferences(Object? value) sync* {
    if (value is! List<Object?>) return;
    yield* value.whereType<String>();
  }

  static Iterable<String> _contentReferences(Object? value) sync* {
    if (value is! List<Object?>) return;
    for (final item in value.whereType<Map<Object?, Object?>>()) {
      final id = item['content'];
      if (id is String) yield id;
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
    if (!_matchesSchemaConstraints(value, schema)) return false;
    final oneOf = schema['oneOf'];
    if (oneOf is List) return _matchesAnySchema(value, oneOf);
    return _matchesSchemaType(value, schema['type'], schema);
  }

  static bool _matchesSchemaConstraints(
    Object? value,
    Map<Object?, Object?> schema,
  ) {
    final allowed = schema['enum'];
    if (allowed is List && !allowed.contains(value)) return false;
    if (value is num && !_matchesNumberConstraints(value, schema)) {
      return false;
    }
    if (value is String && !_matchesStringConstraints(value, schema)) {
      return false;
    }
    return true;
  }

  static bool _matchesNumberConstraints(
    num value,
    Map<Object?, Object?> schema,
  ) {
    if (!value.isFinite) return false;
    final min = schema['minimum'];
    final max = schema['maximum'];
    return (min is! num || value >= min) && (max is! num || value <= max);
  }

  static bool _matchesStringConstraints(
    String value,
    Map<Object?, Object?> schema,
  ) {
    final minLength = schema['minLength'];
    if (minLength is int && value.length < minLength) return false;
    return schema['pattern'] != '^/' || value.startsWith('/');
  }

  static bool _matchesAnySchema(Object? value, List<Object?> oneOf) =>
      oneOf.whereType<Map<Object?, Object?>>().any(
        (candidate) =>
            _matchesSchema(value, Map<Object?, Object?>.from(candidate)),
      );

  static bool _matchesSchemaType(
    Object? value,
    Object? type,
    Map<Object?, Object?> schema,
  ) => switch (type) {
    'null' => value == null,
    'string' => value is String,
    'number' => value is num,
    'integer' => value is int,
    'boolean' => value is bool,
    'array' => _matchesArraySchema(value, schema),
    'object' => _matchesObjectSchema(value, schema),
    _ => true,
  };

  static bool _matchesArraySchema(Object? value, Map<Object?, Object?> schema) {
    if (value is! List) return false;
    final minItems = schema['minItems'];
    if (minItems is int && value.length < minItems) return false;
    final items = schema['items'];
    if (items is! Map) return true;
    return value.every(
      (item) => _matchesSchema(item, Map<Object?, Object?>.from(items)),
    );
  }

  static bool _matchesObjectSchema(
    Object? value,
    Map<Object?, Object?> schema,
  ) {
    final rawProperties = schema['properties'];
    if (value is! Map || rawProperties is! Map) return false;
    final properties = Map<Object?, Object?>.from(rawProperties);
    final required = schema['required'];
    if (!_hasRequiredProperties(value, required)) return false;
    if (!_hasOnlySchemaProperties(value, properties)) return false;
    if (!_matchesObjectProperties(value, properties)) return false;
    return !properties.containsKey('path') || _nonEmpty(value['path']);
  }

  static bool _hasRequiredProperties(
    Map<Object?, Object?> value,
    Object? required,
  ) => required is! List || required.every(value.containsKey);

  static bool _hasOnlySchemaProperties(
    Map<Object?, Object?> value,
    Map<Object?, Object?> properties,
  ) => value.keys.every((key) => key is String && properties.containsKey(key));

  static bool _matchesObjectProperties(
    Map<Object?, Object?> value,
    Map<Object?, Object?> properties,
  ) {
    for (final entry in value.entries) {
      final property = properties[entry.key];
      if (property is Map &&
          !_matchesSchema(entry.value, Map<Object?, Object?>.from(property))) {
        return false;
      }
    }
    return true;
  }

  static A2uiIssueCode? _validateComponentRules(
    String component,
    Map<Object?, Object?> value,
    String? interactionMode,
  ) {
    final interactionIssue = _validateInteractionModeRule(
      component,
      value,
      interactionMode,
    );
    if (interactionIssue != null) return interactionIssue;
    final formIssue = _validateFormInteraction(component, interactionMode);
    if (formIssue != null) return formIssue;
    return switch (component) {
      'Avatar' => _validateAvatar(value),
      'AvatarGroup' => _validateAvatarGroup(value),
      'Table' => _validateTable(value),
      'Chart' => _validateChart(value),
      'Progress' => _validateProgress(value),
      'EmptyState' => _validateEmptyState(value),
      'Row' ||
      'Column' ||
      'List' ||
      'Grid' ||
      'Wrap' => _validateChildren(value),
      'Slider' => _validateSlider(value),
      'DateTimeInput' => _validateDateTimeInput(value),
      'ChoicePicker' => _validateChoicePicker(value),
      'Tabs' => _validateTabs(value),
      'Image' => _validateImage(value),
      _ => null,
    };
  }

  static A2uiIssueCode? _validateInteractionModeRule(
    String component,
    Map<Object?, Object?> value,
    String? interactionMode,
  ) {
    if (interactionMode != 'requiresUserAction') return null;
    final requiresReference = const {
      'CheckBox',
      'ChoicePicker',
      'DateTimeInput',
      'Rating',
      'Slider',
      'TagInput',
      'Tabs',
      'TextField',
    }.contains(component);
    final reference = value[component == 'Tabs' ? 'activeTab' : 'value'];
    if (requiresReference && !_isReference(reference)) {
      return A2uiIssueCode.malformedPayload;
    }
    return null;
  }

  static A2uiIssueCode? _validateFormInteraction(
    String component,
    String? interactionMode,
  ) {
    if (component == 'Form' &&
        interactionMode != null &&
        interactionMode != 'requiresUserAction') {
      return A2uiIssueCode.invalidInteractionMode;
    }
    return null;
  }

  static A2uiIssueCode? _validateAvatar(Map<Object?, Object?> value) {
    final url = value['url'];
    if (url is String && !_isPublicImageUrl(url)) {
      return A2uiIssueCode.malformedPayload;
    }
    return null;
  }

  static A2uiIssueCode? _validateAvatarGroup(Map<Object?, Object?> value) {
    final avatars = value['avatars'];
    if (avatars is List && avatars.any(_hasInvalidAvatar)) {
      return A2uiIssueCode.malformedPayload;
    }
    return null;
  }

  static bool _hasInvalidAvatar(Object? avatar) =>
      avatar is Map &&
      avatar['url'] is String &&
      !_isPublicImageUrl(avatar['url'] as String);

  static A2uiIssueCode? _validateTable(Map<Object?, Object?> value) {
    final columns = value['columns'];
    final rows = value['rows'];
    if (columns is! List || rows is! List) return null;
    if (!_hasValidTableColumns(columns)) {
      return A2uiIssueCode.malformedPayload;
    }
    if (!_hasValidTableRows(rows, columns.length)) {
      return A2uiIssueCode.malformedPayload;
    }
    return null;
  }

  static bool _hasValidTableColumns(List<Object?> columns) => columns.every(
    (column) =>
        column is String || (column is Map && column['label'] is String),
  );

  static bool _hasValidTableRows(List<Object?> rows, int columnCount) {
    for (final row in rows) {
      final cells = row is Map ? row['cells'] : row;
      if (cells is! List || cells.length != columnCount) return false;
    }
    return true;
  }

  static A2uiIssueCode? _validateChart(Map<Object?, Object?> value) {
    final boundsIssue = _validateChartBounds(value);
    if (boundsIssue != null) return boundsIssue;
    final labels = value['labels'];
    final series = value['series'];
    if (labels is! List || series is! List) return null;
    if (_hasInvalidChartSeries(series, labels.length)) {
      return A2uiIssueCode.malformedPayload;
    }
    if (_hasInvalidPieSeries(series, value['variant'])) {
      return A2uiIssueCode.malformedPayload;
    }
    return null;
  }

  static A2uiIssueCode? _validateChartBounds(Map<Object?, Object?> value) {
    final minY = value['minY'];
    final maxY = value['maxY'];
    if (minY is num && maxY is num && minY > maxY) {
      return A2uiIssueCode.malformedPayload;
    }
    if (value['stacked'] == true && value['variant'] != 'bar') {
      return A2uiIssueCode.malformedPayload;
    }
    return null;
  }

  static bool _hasInvalidChartSeries(List<Object?> series, int labelCount) {
    for (final item in series) {
      if (item is! Map) return true;
      final values = item['values'];
      if (values is! List ||
          values.length != labelCount ||
          values.any(_hasInvalidChartSample)) {
        return true;
      }
    }
    return false;
  }

  static bool _hasInvalidChartSample(Object? sample) =>
      sample is! num || !sample.isFinite;

  static bool _hasInvalidPieSeries(List<Object?> series, Object? variant) {
    if (variant != 'pie' && variant != 'donut') return false;
    if (series.length != 1) return true;
    final seriesItem = series.single;
    if (seriesItem is! Map) return true;
    final values = seriesItem['values'];
    if (values is! List) return true;
    return values.any((sample) => sample is! num || sample < 0);
  }

  static A2uiIssueCode? _validateProgress(Map<Object?, Object?> value) {
    if (value['indeterminate'] != true && value['value'] == null) {
      return A2uiIssueCode.malformedPayload;
    }
    return null;
  }

  static A2uiIssueCode? _validateEmptyState(Map<Object?, Object?> value) {
    if (value.containsKey('icon') &&
        !a2uiChatIconNames.contains(value['icon'])) {
      return A2uiIssueCode.malformedPayload;
    }
    return null;
  }

  static A2uiIssueCode? _validateChildren(Map<Object?, Object?> value) {
    final children = value['children'];
    if (_isStaticChildren(children) || _isTemplateChildren(children)) {
      return null;
    }
    return A2uiIssueCode.malformedPayload;
  }

  static bool _isStaticChildren(Object? children) =>
      children is List &&
      children.every((child) => child is String && child.isNotEmpty);

  static bool _isTemplateChildren(Object? children) =>
      children is Map &&
      children['path'] is String &&
      (children['path'] as String).isNotEmpty &&
      children['componentId'] is String &&
      (children['componentId'] as String).isNotEmpty;

  static A2uiIssueCode? _validateSlider(Map<Object?, Object?> value) {
    final min = value['min'];
    final max = value['max'];
    final step = value['step'] ?? 1;
    final precision = value['precision'] ?? 2;
    if (!_hasValidSliderValues(min, max, step, precision)) {
      return A2uiIssueCode.malformedPayload;
    }
    return null;
  }

  static bool _hasValidSliderValues(
    Object? min,
    Object? max,
    Object step,
    Object precision,
  ) {
    if (min is! num || max is! num || min > max) return false;
    if (step is! num || step <= 0) return false;
    if (precision is! int) return false;
    return precision >= 0 && precision <= 20;
  }

  static A2uiIssueCode? _validateDateTimeInput(Map<Object?, Object?> value) {
    final selected = value['value'];
    final variant = value['variant'];
    if (selected is String && !isValidDateTimeValue(variant, selected)) {
      return A2uiIssueCode.malformedPayload;
    }
    if (!_hasValidDateTimeBounds(value, variant)) {
      return A2uiIssueCode.malformedPayload;
    }
    return null;
  }

  static bool _hasValidDateTimeBounds(
    Map<Object?, Object?> value,
    Object? variant,
  ) {
    for (final bound in [value['min'], value['max']]) {
      if (bound is String && !isValidDateTimeValue(variant, bound)) {
        return false;
      }
    }
    final minimum = value['min'];
    final maximum = value['max'];
    return minimum is! String ||
        maximum is! String ||
        _isDateTimeRangeValid(variant, minimum, maximum);
  }

  static A2uiIssueCode? _validateChoicePicker(Map<Object?, Object?> value) {
    final options = value['options'];
    if (options is! List || !_hasValidChoiceOptions(options)) {
      return A2uiIssueCode.malformedPayload;
    }
    final minimum = value['minSelections'];
    final maximum = value['maxSelections'];
    if (minimum is int && maximum is int && minimum > maximum) {
      return A2uiIssueCode.malformedPayload;
    }
    return null;
  }

  static bool _hasValidChoiceOptions(List<Object?> options) => options.every(
    (option) =>
        option is Map && option['value'] != null && option['label'] is String,
  );

  static A2uiIssueCode? _validateTabs(Map<Object?, Object?> value) {
    final tabs = value['tabs'];
    if (_hasValidStaticTabs(tabs) || _isTemplateChildren(tabs)) {
      return null;
    }
    return A2uiIssueCode.malformedPayload;
  }

  static bool _hasValidStaticTabs(Object? tabs) =>
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

  static A2uiIssueCode? _validateImage(Map<Object?, Object?> value) {
    final url = value['url'];
    if (url is! String) return A2uiIssueCode.malformedPayload;
    try {
      requirePublicUriSyntax(url, requireHttps: true);
    } on FormatException {
      return A2uiIssueCode.malformedPayload;
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
