import 'dart:convert';

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';

// Presentation only: the common Connector validator remains authoritative.
class const WorkspaceConnectedInputs({
  required final ConnectorToolDefinition tool,
  required final TextEditingController controller,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final text = useValueListenable(controller);
    final fields = _fields(tool.inputJsonSchema);
    if (fields == null) return _AdvancedInputs(controller);

    return _InputsBody(fields, _values(text.text), controller);
  }
}

typedef _Field = ({
  String name,
  String label,
  String type,
  bool required,
  List<Object?>? choices,
});
const _primitiveTypes = {'string', 'integer', 'number', 'boolean'};
const _complexKeys = {
  'oneOf',
  'anyOf',
  'allOf',
  'if',
  'then',
  'else',
  r'$ref',
  'patternProperties',
  'dependentSchemas',
};
const _advancedLines = 8;

List<_Field>? _fields(Map<String, dynamic> schema) {
  final properties = _properties(schema);
  if (properties == null) return null;

  return _propertyFields(properties, _required(schema));
}

Map<String, dynamic>? _properties(Map<String, dynamic> schema) {
  if ((schema['type'] != null && schema['type'] != 'object') ||
      schema.keys.any(_complexKeys.contains)) {
    return null;
  }

  return schema['properties'] as Map<String, dynamic>? ?? const {};
}

Set<String> _required(Map<String, dynamic> schema) =>
    (schema['required'] as List? ?? const []).whereType<String>().toSet();

List<_Field>? _propertyFields(
  Map<String, dynamic> properties,
  Set<String> required,
) {
  final fields = <_Field>[];
  for (final entry in properties.entries) {
    final field = _field(entry.key, entry.value, required);
    if (field == null) return null;
    fields.add(field);
  }

  return fields;
}

_Field? _field(String name, Object? value, Set<String> required) {
  final schema = _primitiveSchema(value);
  if (schema == null) return null;

  return _descriptor(name, schema, isRequired: required.contains(name));
}

Map<String, dynamic>? _primitiveSchema(Object? value) {
  if (value is! Map<String, dynamic> || value.keys.any(_complexKeys.contains)) {
    return null;
  }
  final type = value['type'];
  if (type is! String ||
      !_primitiveTypes.contains(type) ||
      !_simpleChoices(value['enum'])) {
    return null;
  }

  return value;
}

bool _simpleChoices(Object? value) =>
    value == null || (value is List && value.every(_scalar));
bool _scalar(Object? value) => value is String || value is num || value is bool;

_Field _descriptor(
  String name,
  Map<String, dynamic> schema, {
  required bool isRequired,
}) => (
  name: name,
  label: schema['title'] as String? ?? name,
  type: schema['type'] as String,
  required: isRequired,
  choices: (schema['enum'] as List?)?.cast<Object?>(),
);

Map<String, dynamic> _values(String text) {
  try {
    return Map<String, dynamic>.from(jsonDecode(text) as Map);
  } on FormatException {
    return {};
  }
}

void _write(TextEditingController controller, String name, Object? value) {
  final values = _values(controller.text);
  if (value == null) {
    final _ = values.remove(name);
  } else {
    values[name] = value;
  }
  controller.text = jsonEncode(values);
}

class _InputsBody extends Column {
  new(
    List<_Field> fields,
    Map<String, dynamic> values,
    TextEditingController controller,
  ) : super(
        mainAxisSize: .min,
        children: [
          _InputRepair(fields, values, controller),
          _PrimitiveInputs(fields, values, controller),
        ],
      );
}

class const _PrimitiveInputs(
  final List<_Field> fields,
  final Map<String, dynamic> values,
  final TextEditingController controller,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      for (final field in fields.where((field) => field.required))
        _Primitive(
          field,
          values[field.name],
          controller,
          key: ValueKey(field.name),
        ),
      if (fields.any((field) => !field.required))
        _OptionalInputs(fields, values, controller),
    ],
  );
}

class const _InputRepair(
  final List<_Field> fields,
  final Map<String, dynamic> values,
  final TextEditingController controller,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!_unknownInputs(fields, values)) return const SizedBox.shrink();

    return AuraButton(
      onPressed: () => _removeUnknown(fields, controller),
      child: const TextLocale(
        LocaleKeys.workspace_connected_remove_extra_inputs,
      ),
    );
  }
}

Set<String> _fieldNames(List<_Field> fields) =>
    fields.map((field) => field.name).toSet();
bool _unknownInputs(List<_Field> fields, Map<String, dynamic> values) {
  final names = _fieldNames(fields);

  return values.keys.any((name) => !names.contains(name));
}

void _removeUnknown(List<_Field> fields, TextEditingController controller) {
  final names = _fieldNames(fields);
  final values = _values(controller.text)
    ..removeWhere((name, _) => !names.contains(name));
  controller.text = jsonEncode(values);
}

class const _OptionalInputs(
  final List<_Field> fields,
  final Map<String, dynamic> values,
  final TextEditingController controller,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: const TextLocale(LocaleKeys.workspace_connected_options),
    children: [
      for (final field in fields.where((field) => !field.required))
        _Primitive(
          field,
          values[field.name],
          controller,
          key: ValueKey(field.name),
        ),
    ],
  );
}

class const _Primitive(
  final _Field field,
  final Object? value,
  final TextEditingController controller, {
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      field.type == 'boolean' || field.choices != null
      ? _ChoiceInput(field, value, controller)
      : _TextInput(field, value, controller);
}

class const _TextInput(
  final _Field field,
  final Object? value,
  final TextEditingController controller,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    initialValue: value?.toString() ?? '',
    label: Text(field.label),
    isRequired: field.required,
    keyboardType: _keyboard(field.type),
    onChanged: _changed,
    identifier: _identifier(field),
  );
  void _changed(String text) =>
      _write(controller, field.name, _typedValue(field, text));
}

String _identifier(_Field field) => 'workspace_connected_input_${field.name}';
TextInputType _keyboard(String type) => type == 'string'
    ? .text
    : const .numberWithOptions(signed: true, decimal: true);

Object? _typedValue(_Field field, String text) {
  if (text.isEmpty && !field.required) return null;

  return switch (field.type) {
    'integer' => int.tryParse(text) ?? text,
    'number' => _numberValue(text),
    _ => text,
  };
}

Object _numberValue(String text) {
  final value = num.tryParse(text);

  return value != null && value.isFinite ? value : text;
}

class const _ChoiceInput(
  final _Field field,
  final Object? value,
  final TextEditingController controller,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraDropdownSelector<String>(
    options: _InputChoices.options(field),
    value: value == null ? null : jsonEncode(value),
    onChanged: _changed,
    label: Text(field.label),
    isRequired: field.required,
    identifier: _identifier(field),
  );
  void _changed(String? encoded) =>
      _write(controller, field.name, _choiceValue(encoded));
}

Object? _choiceValue(String? encoded) =>
    encoded == null || encoded.isEmpty ? null : jsonDecode(encoded);

abstract final class _InputChoices {
  static List<AuraDropdownOption<String>> options(_Field field) {
    final choices = field.choices;
    final options = choices == null
        ? _booleanOptions
        : choices.map<AuraDropdownOption<String>>(_ChoiceOption.new).toList();

    return [if (!field.required) _unsetOption, ...options];
  }
}

class _ChoiceOption extends AuraDropdownOption<String> {
  new(Object? choice)
    : super(value: jsonEncode(choice), child: Text(choice.toString()));
}

const AuraDropdownOption<String> _unsetOption = .new(
  value: '',
  child: TextLocale(LocaleKeys.workspace_connected_unset),
);
const _booleanOptions = <AuraDropdownOption<String>>[
  .new(value: 'true', child: TextLocale(LocaleKeys.workspace_connected_yes)),
  .new(value: 'false', child: TextLocale(LocaleKeys.workspace_connected_no)),
];

class const _AdvancedInputs(final TextEditingController controller)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: const TextLocale(LocaleKeys.workspace_connected_advanced_inputs),
    children: [
      AuraInput(
        controller: controller,
        label: const TextLocale(LocaleKeys.workspace_connected_inputs),
        maxLines: _advancedLines,
      ),
    ],
  );
}
