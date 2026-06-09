// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: prefer-moving-to-variable
// Required: Existing code repeats lookups where extraction adds noise.

import 'package:auravibes_app/features/models/models/add_model_provider_model.dart';
import 'package:auravibes_app/features/models/providers/add_model_provider_state.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Enhanced input widget for the add model provider form with validation
class EnhancedModelInput extends HookConsumerWidget {
  const EnhancedModelInput({
    required this.workspaceId,
    required this.fieldType,
    this.focusNode,
    this.onSubmitted,
    super.key,
  });

  final String workspaceId;
  final ModelInputFieldType fieldType;
  final FocusNode? focusNode;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addModelProviderStateProvider(workspaceId));
    final notifier = ref.read(
      addModelProviderStateProvider(workspaceId).notifier,
    );

    // Get field-specific values
    final fieldData = _getFieldData(fieldType, state);
    final hint = fieldData.hint;
    final error = fieldData.error;

    final controller = useTextEditingController(text: fieldData.value ?? '');

    return AuraInput(
      controller: controller,
      placeholder: TextLocale(fieldData.placeholder),
      label: TextLocale(fieldData.label),
      hint: hint != null ? TextLocale(hint) : null,
      error: error != null ? Text(error) : null,
      isRequired: _isRequired(fieldType),
      state: error != null ? AuraInputState.error : AuraInputState.normal,
      keyboardType: fieldData.keyboardType,
      textInputAction: _getTextInputAction(fieldType),
      obscureText: fieldType == ModelInputFieldType.key,
      autofocus: fieldType == ModelInputFieldType.name && focusNode == null,
      onChanged: (newValue) => _onFieldChanged(fieldType, newValue, notifier),
      onSubmitted: (_) => onSubmitted?.call(),
      focusNode: focusNode,
    );
  }

  ({
    String? value,
    String? error,
    String? hint,
    String label,
    String placeholder,
    TextInputType keyboardType,
  })
  _getFieldData(
    ModelInputFieldType type,
    AddModelProviderModel state,
  ) {
    switch (type) {
      case ModelInputFieldType.name:
        return (
          value: state.name,
          error: state.validateName(),
          hint: LocaleKeys.models_screens_add_provider_fields_name_hint,
          label: LocaleKeys.models_screens_add_provider_fields_name_label,
          placeholder:
              LocaleKeys.models_screens_add_provider_fields_name_placeholder,
          keyboardType: TextInputType.text,
        );

      case ModelInputFieldType.key:
        return (
          value: state.key,
          error: state.validateKey(),
          hint: LocaleKeys.models_screens_add_provider_fields_key_hint,
          label: LocaleKeys.models_screens_add_provider_fields_key_label,
          placeholder:
              LocaleKeys.models_screens_add_provider_fields_key_placeholder,
          keyboardType: TextInputType.visiblePassword,
        );

      case ModelInputFieldType.url:
        return (
          value: state.url,
          error: state.validateUrl(),
          hint: LocaleKeys.models_screens_add_provider_fields_url_hint,
          label: LocaleKeys.models_screens_add_provider_fields_url_label,
          placeholder:
              LocaleKeys.models_screens_add_provider_fields_url_placeholder,
          keyboardType: TextInputType.url,
        );
    }
  }

  void _onFieldChanged(
    ModelInputFieldType type,
    String value,
    AddModelProviderState notifier,
  ) {
    switch (type) {
      case ModelInputFieldType.name:
        notifier.setName(value);
      case ModelInputFieldType.key:
        notifier.setKey(value);
      case ModelInputFieldType.url:
        notifier.setUrl(value.isEmpty ? null : value);
    }
  }

  TextInputAction _getTextInputAction(ModelInputFieldType type) {
    switch (type) {
      case ModelInputFieldType.name:
        return TextInputAction.next;
      case ModelInputFieldType.key:
        return TextInputAction.next;
      case ModelInputFieldType.url:
        return TextInputAction.done;
    }
  }

  bool _isRequired(ModelInputFieldType type) {
    return type != ModelInputFieldType.url;
  }
}

/// Enum representing the different input field types in the form
enum ModelInputFieldType {
  name,
  key,
  url,
}
