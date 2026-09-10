// Required: Existing code repeats lookups where extraction adds noise.

import 'package:auravibes_app/features/models/models/add_model_provider_model.dart';
import 'package:auravibes_app/features/models/providers/add_model_provider_state.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

typedef _ModelInputFieldData = ({
  String? value,
  String? error,
  String? hint,
  String label,
  String placeholder,
  TextInputType keyboardType,
});

/// Enhanced input widget for the add model provider form with validation.
class const EnhancedModelInput({
  required super.workspaceId,
  required super.fieldType,
  super.focusNode,
  super.onSubmitted,
  super.key,
}) extends _EnhancedModelInput {}

class const _EnhancedModelInput({
  required final String workspaceId,
  required final ModelInputFieldType fieldType,
  final FocusNode? focusNode,
  final VoidCallback? onSubmitted,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addModelProviderStateProvider(workspaceId));
    final notifier = ref.read(
      addModelProviderStateProvider(workspaceId).notifier,
    );

    return _EnhancedModelInputField(
      fieldType: fieldType,
      fieldData: _getFieldData(fieldType, state),
      onChanged: (value) => _onFieldChanged(fieldType, value, notifier),
      focusNode: focusNode,
      onSubmitted: onSubmitted,
    );
  }

  _ModelInputFieldData _getFieldData(
    ModelInputFieldType type,
    AddModelProviderModel state,
  ) => switch (type) {
    .name => _nameFieldData(state),
    .key => _keyFieldData(state),
    .url => _urlFieldData(state),
  };

  void _onFieldChanged(
    ModelInputFieldType type,
    String value,
    AddModelProviderState notifier,
  ) {
    switch (type) {
      case .name:
        notifier.setName(value);
      case .key:
        notifier.setKey(value);
      case .url:
        notifier.setUrl(value.isEmpty ? null : value);
    }
  }
}

_ModelInputFieldData _nameFieldData(AddModelProviderModel state) => (
  value: state.name,
  error: state.validateName(),
  hint: LocaleKeys.models_screens_add_provider_fields_name_hint,
  label: LocaleKeys.models_screens_add_provider_fields_name_label,
  placeholder: LocaleKeys.models_screens_add_provider_fields_name_placeholder,
  keyboardType: TextInputType.text,
);

_ModelInputFieldData _keyFieldData(AddModelProviderModel state) => (
  value: state.key,
  error: state.validateKey(),
  hint: LocaleKeys.models_screens_add_provider_fields_key_hint,
  label: LocaleKeys.models_screens_add_provider_fields_key_label,
  placeholder: LocaleKeys.models_screens_add_provider_fields_key_placeholder,
  keyboardType: TextInputType.visiblePassword,
);

_ModelInputFieldData _urlFieldData(AddModelProviderModel state) => (
  value: state.url,
  error: state.validateUrl(),
  hint: LocaleKeys.models_screens_add_provider_fields_url_hint,
  label: LocaleKeys.models_screens_add_provider_fields_url_label,
  placeholder: LocaleKeys.models_screens_add_provider_fields_url_placeholder,
  keyboardType: TextInputType.url,
);

class const _EnhancedModelInputField({
  required final ModelInputFieldType fieldType,
  required final _ModelInputFieldData fieldData,
  required final ValueChanged<String> onChanged,
  final FocusNode? focusNode,
  final VoidCallback? onSubmitted,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: fieldData.value ?? '');

    return _input(context, controller);
  }

  Widget _input(BuildContext context, TextEditingController controller) =>
      AuraInput(
        controller: controller,
        placeholder: TextLocale(fieldData.placeholder),
        label: TextLocale(fieldData.label),
        hint: fieldData.hint != null ? TextLocale(fieldData.hint!) : null,
        error: fieldData.error != null ? Text(fieldData.error!) : null,
        isRequired: fieldType._isRequired,
        state: fieldData.error != null
            ? AuraInputState.error
            : AuraInputState.normal,
        keyboardType: fieldData.keyboardType,
        textInputAction: fieldType._textInputAction,
        obscureText: fieldType == ModelInputFieldType.key,
        autofocus: fieldType == ModelInputFieldType.name && focusNode == null,
        onChanged: onChanged,
        onSubmitted: (_) => onSubmitted?.call(),
        focusNode: focusNode,
      );
}

extension on ModelInputFieldType {
  TextInputAction get _textInputAction => switch (this) {
    .name || .key => TextInputAction.next,
    .url => TextInputAction.done,
  };

  bool get _isRequired => this != .url;
}

/// Enum representing the different input field types in the form.
enum ModelInputFieldType { name, key, url }
