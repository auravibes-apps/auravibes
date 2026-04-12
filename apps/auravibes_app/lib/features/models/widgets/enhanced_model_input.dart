import 'package:auravibes_app/features/models/models/add_model_provider_model.dart';
import 'package:auravibes_app/features/models/providers/add_model_provider_providers.dart';
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
    final (value, error, hint, label, placeholder, keyboardType) =
        _getFieldData(fieldType, state);

    final controller = useTextEditingController(text: value ?? '');

    return AuraInput(
      controller: controller,
      placeholder: TextLocale(placeholder),
      label: TextLocale(label),
      hint: hint != null ? TextLocale(hint) : null,
      error: error != null ? Text(error) : null,
      keyboardType: keyboardType,
      focusNode: focusNode,
      onChanged: (newValue) => _onFieldChanged(fieldType, newValue, notifier),
      onSubmitted: (_) => onSubmitted?.call(),
      textInputAction: _getTextInputAction(fieldType),
      autofocus: fieldType == ModelInputFieldType.name && focusNode == null,
      isRequired: _isRequired(fieldType),
      state: error != null ? AuraInputState.error : AuraInputState.normal,
    );
  }

  (String?, String?, String?, String, String, TextInputType) _getFieldData(
    ModelInputFieldType type,
    AddModelProviderModel state,
  ) {
    switch (type) {
      case ModelInputFieldType.name:
        return (
          state.name,
          state.validateName(),
          LocaleKeys.models_screens_add_provider_fields_name_hint,
          LocaleKeys.models_screens_add_provider_fields_name_label,
          LocaleKeys.models_screens_add_provider_fields_name_placeholder,
          TextInputType.text,
        );

      case ModelInputFieldType.key:
        return (
          state.key,
          state.validateKey(),
          LocaleKeys.models_screens_add_provider_fields_key_hint,
          LocaleKeys.models_screens_add_provider_fields_key_label,
          LocaleKeys.models_screens_add_provider_fields_key_placeholder,
          TextInputType.visiblePassword,
        );

      case ModelInputFieldType.url:
        return (
          state.url,
          state.validateUrl(),
          LocaleKeys.models_screens_add_provider_fields_url_hint,
          LocaleKeys.models_screens_add_provider_fields_url_label,
          LocaleKeys.models_screens_add_provider_fields_url_placeholder,
          TextInputType.url,
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
