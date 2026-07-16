// Required: Feature widgets keep closely related private widgets together.

import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/service_connections/models/cloud_service_connection.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_operations_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_definitions_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_operations_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show SkillCredentialAttributeDefinition;
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([serviceConnectionOperations])
class ServiceConnectionEditScreen extends ConsumerStatefulWidget {
  const ServiceConnectionEditScreen({
    required this.workspaceId,
    required this.connectionId,
    super.key,
  });

  final String workspaceId;
  final String connectionId;

  @override
  ConsumerState<ServiceConnectionEditScreen> createState() =>
      _ServiceConnectionEditScreenState();
}

class _ServiceConnectionEditScreenState
    extends ConsumerState<ServiceConnectionEditScreen> {
  final _nameController = TextEditingController();
  final _modelKeyController = TextEditingController();
  final _modelUrlController = TextEditingController();
  final _nonSecretControllers = <String, TextEditingController>{};
  final _secretControllers = <String, TextEditingController>{};
  final _clearedSecrets = <String>{};
  Future<_ConnectionEditState>? _future;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelKeyController.dispose();
    _modelUrlController.dispose();
    for (final controller in _nonSecretControllers.values) {
      controller.dispose();
    }
    for (final controller in _secretControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuraScreen(
      child: FutureBuilder<_ConnectionEditState>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: TextLocale(LocaleKeys.service_connections_load_error),
            );
          }
          final state = snapshot.data;
          if (state == null) {
            return const Center(child: AuraSpinner());
          }
          _initialize(state);

          return switch (state) {
            _SkillCredentialEditState() => _SkillCredentialEditForm(
              state: state,
              nameController: _nameController,
              nonSecretControllers: _nonSecretControllers,
              secretControllers: _secretControllers,
              clearedSecrets: _clearedSecrets,
              isSaving: _isSaving,
              onChanged: () => setState(() {
                final _ = Object();
              }),
              onSave: () => _saveSkillCredential(context),
            ),
            _ModelProviderEditState() => _ModelProviderEditForm(
              state: state,
              nameController: _nameController,
              keyController: _modelKeyController,
              urlController: _modelUrlController,
              isSaving: _isSaving,
              onChanged: () => setState(() {
                final _ = Object();
              }),
              onSave: () => _saveModelProvider(context),
            ),
            _GenericServiceConnectionEditState() =>
              _GenericServiceConnectionEditForm(
                state: state,
                nameController: _nameController,
                secretController: _modelKeyController,
                clearSecret: _clearedSecrets.contains('secret'),
                isSaving: _isSaving,
                onChanged: () => setState(() {
                  final _ = Object();
                }),
                onClearSecret: () => setState(() {
                  _modelKeyController.clear();
                  final _ = _clearedSecrets.add('secret');
                }),
                onSave: () => _saveGenericConnection(context, state),
              ),
          };
        },
      ),
      appBar: AuraAppBar(
        title: const TextLocale(LocaleKeys.service_connections_edit_title),
        leading: AuraIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<_ConnectionEditState> _load() async {
    final operations = await ref.read(
      serviceConnectionOperationsProvider(widget.workspaceId).future,
    );
    final generic = await operations.getGenericForEdit(widget.connectionId);
    if (generic != null) {
      return _GenericServiceConnectionEditState(connection: generic);
    }
    final credential = await ref
        .read(skillCredentialOperationsProvider)
        .getForEdit(
          widget.connectionId,
        );
    if (credential != null) {
      final definition = await ref.read(
        skillCredentialDefinitionProvider(
          credential.credentialDefinitionId,
        ).future,
      );
      if (definition == null) {
        throw StateError('Skill credential definition not found.');
      }

      return _SkillCredentialEditState(
        credential: credential,
        definition: definition,
      );
    }

    final modelConnection = await (await ref.read(
      modelConnectionStoreProvider(widget.workspaceId).future,
    )).getModelConnectionForEdit(widget.connectionId);
    if (modelConnection != null) {
      return _ModelProviderEditState(connection: modelConnection);
    }
    throw StateError('Service connection not found: ${widget.connectionId}');
  }

  void _initialize(_ConnectionEditState state) {
    if (_initialized) return;
    switch (state) {
      case _SkillCredentialEditState(
        :final credential,
        :final definition,
      ):
        _nameController.text = credential.name;
        final attributes = SkillCredentialAttributeDefinition.parseMap(
          definition.attributesJson,
        );
        for (final entry in attributes.entries) {
          if (entry.value.secret) {
            final _ = _secretControllers.putIfAbsent(
              entry.key,
              TextEditingController.new,
            );
          } else {
            final _ = _nonSecretControllers.putIfAbsent(
              entry.key,
              () => TextEditingController(
                text: credential.nonSecretAttributes[entry.key] ?? '',
              ),
            );
          }
        }
      case _ModelProviderEditState(:final connection):
        _nameController.text = connection.name;
        _modelUrlController.text = connection.url ?? '';
      case _GenericServiceConnectionEditState(:final connection):
        _nameController.text = connection.name;
    }
    _initialized = true;
  }

  Future<void> _saveSkillCredential(BuildContext context) async {
    setState(() => _isSaving = true);
    try {
      final _ = await ref
          .read(skillCredentialOperationsProvider)
          .update(
            widget.connectionId,
            SkillCredentialToUpdate(
              name: _nameController.text.trim(),
              nonSecretAttributes: {
                for (final entry in _nonSecretControllers.entries)
                  entry.key: entry.value.text,
              },
              secretAttributes: {
                for (final entry in _secretControllers.entries)
                  if (entry.value.text.isNotEmpty) entry.key: entry.value.text,
              },
              clearSecretAttributeNames: _clearedSecrets,
            ),
          );
      if (!context.mounted) return;
      Navigator.of(context).pop(true);
    } on Object {
      if (!context.mounted) return;
      final _ = showAuraSnackBar(
        context: context,
        content: const TextLocale(LocaleKeys.skill_credentials_save_error),
        variant: AuraSnackBarVariant.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveModelProvider(BuildContext context) async {
    setState(() => _isSaving = true);
    try {
      final _ =
          await (await ref.read(
            modelConnectionStoreProvider(widget.workspaceId).future,
          )).updateModelConnection(
            widget.connectionId,
            ModelConnectionToUpdate(
              name: _nameController.text.trim(),
              key: _modelKeyController.text.trim().isEmpty
                  ? null
                  : _modelKeyController.text.trim(),
              url: _modelUrlController.text.trim(),
            ),
          );
      if (!context.mounted) return;
      Navigator.of(context).pop(true);
    } on Object {
      if (!context.mounted) return;
      final _ = showAuraSnackBar(
        context: context,
        content: const TextLocale(
          LocaleKeys.service_connections_save_error,
        ),
        variant: AuraSnackBarVariant.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveGenericConnection(
    BuildContext context,
    _GenericServiceConnectionEditState state,
  ) async {
    setState(() => _isSaving = true);
    try {
      final secret = _modelKeyController.text.trim();
      final secretEdit = switch ((
        isCleared: _clearedSecrets.contains('secret'),
        isEmpty: secret.isEmpty,
      )) {
        (isCleared: true, isEmpty: _) => ServiceConnectionSecretEdit.clear,
        (isCleared: false, isEmpty: true) =>
          ServiceConnectionSecretEdit.preserve,
        (isCleared: false, isEmpty: false) =>
          ServiceConnectionSecretEdit.replace,
      };
      final operations = await ref.read(
        serviceConnectionOperationsProvider(widget.workspaceId).future,
      );
      await operations.updateGeneric(
        state.connection,
        GenericServiceConnectionUpdate(
          name: _nameController.text.trim(),
          secretEdit: secretEdit,
          secret: secretEdit == ServiceConnectionSecretEdit.replace
              ? secret
              : null,
        ),
      );
      if (!context.mounted) return;
      Navigator.of(context).pop(true);
    } on Object {
      if (!context.mounted) return;
      final _ = showAuraSnackBar(
        context: context,
        content: const TextLocale(LocaleKeys.service_connections_save_error),
        variant: AuraSnackBarVariant.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

sealed class _ConnectionEditState {}

class _SkillCredentialEditState extends _ConnectionEditState {
  _SkillCredentialEditState({
    required this.credential,
    required this.definition,
  });

  final SkillCredentialForEdit credential;
  final SkillCredentialDefinitionEntity definition;
}

class _ModelProviderEditState extends _ConnectionEditState {
  _ModelProviderEditState({required this.connection});

  final ModelConnectionForEdit connection;
}

class _GenericServiceConnectionEditState extends _ConnectionEditState {
  _GenericServiceConnectionEditState({required this.connection});

  final GenericServiceConnectionForEdit connection;
}

class _SkillCredentialEditForm extends StatelessWidget {
  const _SkillCredentialEditForm({
    required this.state,
    required this.nameController,
    required this.nonSecretControllers,
    required this.secretControllers,
    required this.clearedSecrets,
    required this.isSaving,
    required this.onChanged,
    required this.onSave,
  });

  final _SkillCredentialEditState state;
  final TextEditingController nameController;
  final Map<String, TextEditingController> nonSecretControllers;
  final Map<String, TextEditingController> secretControllers;
  final Set<String> clearedSecrets;
  final bool isSaving;
  final VoidCallback onChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final attributes = SkillCredentialAttributeDefinition.parseMap(
      state.definition.attributesJson,
    );

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        AuraCard(
          child: AuraColumn(
            children: [
              AuraText(
                child: Text(state.definition.title),
                style: AuraTextStyle.heading6,
              ),
              AuraInput(
                controller: nameController,
                label: Text(
                  LocaleKeys.skill_credentials_name_label.tr(
                    context: context,
                  ),
                ),
                onChanged: (_) => onChanged(),
              ),
              for (final entry in attributes.entries)
                _SkillCredentialAttributeInput(
                  entry,
                  editState: state,
                  secretControllers: secretControllers,
                  nonSecretControllers: nonSecretControllers,
                  clearedSecrets: clearedSecrets,
                  onChanged: onChanged,
                ),
              Align(
                alignment: Alignment.centerRight,
                child: AuraButton(
                  onPressed: onSave,
                  child: const TextLocale(LocaleKeys.common_save),
                  isLoading: isSaving,
                  disabled: isSaving || nameController.text.trim().isEmpty,
                ),
              ),
            ],
            spacing: AuraSpacing.md,
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
        ),
      ],
    );
  }
}

class _SkillCredentialAttributeInput extends StatelessWidget {
  const _SkillCredentialAttributeInput(
    this.entry, {
    required this.editState,
    required this.secretControllers,
    required this.nonSecretControllers,
    required this.clearedSecrets,
    required this.onChanged,
  });

  final MapEntry<String, SkillCredentialAttributeDefinition> entry;
  final _SkillCredentialEditState editState;
  final Map<String, TextEditingController> secretControllers;
  final Map<String, TextEditingController> nonSecretControllers;
  final Set<String> clearedSecrets;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (entry.value.secret) {
      return _SecretAttributeInput(
        name: entry.key,
        definition: entry.value,
        state: editState.credential.secretAttributes[entry.key],
        controller: secretControllers[entry.key]!,
        clearedSecrets: clearedSecrets,
        onChanged: onChanged,
      );
    }

    final description = entry.value.description;
    final hint = description.isEmpty ? null : Text(description);

    return AuraInput(
      controller: nonSecretControllers[entry.key],
      label: Text(entry.key),
      hint: hint,
      isRequired: !entry.value.optional,
      onChanged: (_) => onChanged(),
    );
  }
}

class _SecretAttributeInput extends StatelessWidget {
  const _SecretAttributeInput({
    required this.name,
    required this.definition,
    required this.state,
    required this.controller,
    required this.clearedSecrets,
    required this.onChanged,
  });

  final String name;
  final SkillCredentialAttributeDefinition definition;
  final SkillCredentialSecretState? state;
  final TextEditingController controller;
  final Set<String> clearedSecrets;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final keySuffix = state?.keySuffix;
    String? placeholder;
    if (state?.hasValue == true) {
      final suffix = keySuffix == null ? '' : ' ****$keySuffix';
      placeholder =
          '${LocaleKeys.skill_credentials_secret_saved.tr(context: context)}'
          '$suffix';
    }

    return AuraInput(
      controller: controller,
      placeholder: placeholder == null ? null : Text(placeholder),
      label: Text(name),
      hint: definition.description.isEmpty
          ? null
          : Text(definition.description),
      isRequired: !definition.optional,
      suffixIcon: definition.optional
          ? AuraIconButton(
              icon: Icons.clear,
              onPressed: () {
                controller.clear();
                final _ = clearedSecrets.add(name);
                onChanged();
              },
              tooltip: LocaleKeys.skill_credentials_clear_secret.tr(
                context: context,
              ),
            )
          : null,
      keyboardType: TextInputType.visiblePassword,
      obscureText: true,
      onChanged: (_) {
        final _ = clearedSecrets.remove(name);
        onChanged();
      },
    );
  }
}

class _ModelProviderEditForm extends StatelessWidget {
  const _ModelProviderEditForm({
    required this.state,
    required this.nameController,
    required this.keyController,
    required this.urlController,
    required this.isSaving,
    required this.onChanged,
    required this.onSave,
  });

  final _ModelProviderEditState state;
  final TextEditingController nameController;
  final TextEditingController keyController;
  final TextEditingController urlController;
  final bool isSaving;
  final VoidCallback onChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final suffix = state.connection.keySuffix;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        AuraCard(
          child: AuraColumn(
            children: [
              AuraText(
                child: Text(state.connection.modelId),
                style: AuraTextStyle.heading6,
              ),
              AuraInput(
                controller: nameController,
                label: const TextLocale(
                  LocaleKeys.models_screens_add_provider_fields_name_label,
                ),
                onChanged: (_) => onChanged(),
              ),
              AuraInput(
                controller: keyController,
                placeholder: Text(
                  suffix == null
                      ? LocaleKeys.skill_credentials_secret_saved.tr(
                          context: context,
                        )
                      : '${LocaleKeys.skill_credentials_secret_saved.tr(
                              context: context,
                            )} '
                            '****$suffix',
                ),
                label: const TextLocale(
                  LocaleKeys.models_screens_add_provider_fields_key_label,
                ),
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
                onChanged: (_) => onChanged(),
              ),
              AuraInput(
                controller: urlController,
                label: const TextLocale(
                  LocaleKeys.models_screens_add_provider_fields_url_label,
                ),
                keyboardType: TextInputType.url,
                onChanged: (_) => onChanged(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: AuraButton(
                  onPressed: onSave,
                  child: const TextLocale(LocaleKeys.common_save),
                  isLoading: isSaving,
                  disabled: isSaving || nameController.text.trim().isEmpty,
                ),
              ),
            ],
            spacing: AuraSpacing.md,
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
        ),
      ],
    );
  }
}

class _GenericServiceConnectionEditForm extends StatelessWidget {
  const _GenericServiceConnectionEditForm({
    required this.state,
    required this.nameController,
    required this.secretController,
    required this.clearSecret,
    required this.isSaving,
    required this.onChanged,
    required this.onClearSecret,
    required this.onSave,
  });

  final _GenericServiceConnectionEditState state;
  final TextEditingController nameController;
  final TextEditingController secretController;
  final bool clearSecret;
  final bool isSaving;
  final VoidCallback onChanged;
  final VoidCallback onClearSecret;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final suffix = state.connection.keySuffix;
    final savedSecret = state.connection.hasSecret && !clearSecret;
    final savedSecretSuffix = suffix == null ? '' : ' ****$suffix';

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        AuraCard(
          child: AuraColumn(
            children: [
              AuraText(
                child: Text(state.connection.serviceId),
                style: AuraTextStyle.heading6,
              ),
              AuraInput(
                controller: nameController,
                label: Text(
                  LocaleKeys.skill_credentials_name_label.tr(context: context),
                ),
                onChanged: (_) => onChanged(),
              ),
              AuraInput(
                controller: secretController,
                placeholder: savedSecret
                    ? Text(
                        '${LocaleKeys.skill_credentials_secret_saved.tr(
                          context: context,
                        )}$savedSecretSuffix',
                      )
                    : null,
                label: Text(
                  _genericCredentialValueLabel(
                    context,
                    state.connection.serviceId,
                  ),
                ),
                suffixIcon: AuraIconButton(
                  icon: Icons.clear,
                  onPressed: onClearSecret,
                  tooltip: LocaleKeys.skill_credentials_clear_secret.tr(
                    context: context,
                  ),
                ),
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
                onChanged: (_) => onChanged(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: AuraButton(
                  onPressed: onSave,
                  child: const TextLocale(LocaleKeys.common_save),
                  isLoading: isSaving,
                  disabled: isSaving || nameController.text.trim().isEmpty,
                ),
              ),
            ],
            spacing: AuraSpacing.md,
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
        ),
      ],
    );
  }
}

String _genericCredentialValueLabel(BuildContext context, String serviceId) {
  final key = switch (serviceId) {
    'searxng' => LocaleKeys.service_connections_create_base_url_label,
    _ => LocaleKeys.service_connections_create_api_key_label,
  };

  return key.tr(context: context);
}
