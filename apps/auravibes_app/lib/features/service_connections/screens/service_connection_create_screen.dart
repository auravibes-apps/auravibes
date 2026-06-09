// ignore_for_file: prefer-single-widget-per-file
// Required: Feature widgets keep closely related private widgets together.

import 'dart:async';

import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/features/models/providers/add_model_provider_state.dart';
import 'package:auravibes_app/features/models/widgets/add_model_provider_widget.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_definitions_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';

final _logger = Logger('service_connection_create_screen');

class ServiceConnectionCreateScreen extends ConsumerStatefulWidget {
  const ServiceConnectionCreateScreen({
    required this.workspaceId,
    this.initialType,
    this.initialCredentialDefinitionId,
    super.key,
  });

  final String workspaceId;
  final ServiceConnectionCreateType? initialType;
  final String? initialCredentialDefinitionId;

  @override
  ConsumerState<ServiceConnectionCreateScreen> createState() =>
      _ServiceConnectionCreateScreenState();
}

class _ServiceConnectionCreateScreenState
    extends ConsumerState<ServiceConnectionCreateScreen> {
  final _nameController = TextEditingController();
  final _attributeControllers = <String, TextEditingController>{};
  ServiceConnectionCreateType _type = ServiceConnectionCreateType.modelProvider;
  String? _definitionId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? _type;
    _definitionId = widget.initialCredentialDefinitionId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final controller in _attributeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuraScreen(
      child: AuraColumn(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: _TypeSelector(
              value: _type,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _type = value;
                  _definitionId = null;
                  _resetAttributeControllers();
                });
              },
            ),
          ),
          Expanded(child: _buildSelectedForm(context)),
        ],
      ),
      appBar: AuraAppBar(
        title: const TextLocale(LocaleKeys.service_connections_create_title),
        leading: AuraIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Widget _buildSelectedForm(BuildContext context) {
    return switch (_type) {
      ServiceConnectionCreateType.modelProvider => Padding(
        padding: const EdgeInsets.all(12),
        child: AddModelProviderWidget(
          workspaceId: widget.workspaceId,
          onCreated: () => unawaited(_closeAfterSave()),
          showHeader: false,
        ),
      ),
      ServiceConnectionCreateType.skillCredential => _CredentialForm(
        workspaceId: widget.workspaceId,
        selectedDefinitionId: _definitionId,
        nameController: _nameController,
        attributeControllers: _attributeControllers,
        isSaving: _isSaving,
        onNameChanged: (_) => setState(() {}),
        onDefinitionChanged: (value) {
          setState(() {
            _definitionId = value;
            _resetAttributeControllers();
          });
        },
        onSave: () => unawaited(_saveSkillCredential()),
      ),
    };
  }

  Future<void> _saveSkillCredential() async {
    if (_isSaving) {
      _logger.info(
        'debug:skill credential save ignored workspace=${widget.workspaceId} '
        'reason=already_saving type=${_type.name}',
      );
      return;
    }
    final definitionId = _definitionId;
    if (definitionId == null) {
      _logger.warning(
        'debug:skill credential save blocked workspace=${widget.workspaceId} '
        'reason=missing_definition type=${_type.name}',
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final attributes = _attributeControllers.map(
        (key, controller) => MapEntry(key, controller.text),
      );
      _logger.info(
        'debug:skill credential save start workspace=${widget.workspaceId} '
        'definitionId=$definitionId type=${_type.name} '
        'nameLength=${_nameController.text.trim().length} '
        'attributes=${_describeAttributes(attributes)}',
      );
      final credential = await ref
          .read(skillCredentialsRepositoryProvider)
          .createCredential(
            widget.workspaceId,
            SkillCredentialToCreate(
              credentialDefinitionId: definitionId,
              name: _nameController.text.trim(),
              attributes: attributes,
            ),
          );
      _logger.info(
        'debug:skill credential save success workspace=${widget.workspaceId} '
        'definitionId=$definitionId credentialId=${credential.id} '
        'attributeKeys=${attributes.keys.join(',')}',
      );
      await _closeAfterSave(
        refreshServiceConnections: false,
        resetModelMutation: false,
      );
    } on Object catch (error, stackTrace) {
      _logger.severe(
        'debug:skill credential save failed workspace=${widget.workspaceId} '
        'definitionId=$definitionId type=${_type.name} '
        'nameLength=${_nameController.text.trim().length} '
        'attributeKeys=${_attributeControllers.keys.join(',')}',
        error,
        stackTrace,
      );
      if (!mounted) return;
      final _ = showAuraSnackBar(
        context: context,
        content: Text(
          LocaleKeys.skill_credentials_save_error.tr(context: context),
        ),
        variant: AuraSnackBarVariant.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _closeAfterSave({
    bool refreshServiceConnections = true,
    bool resetModelMutation = true,
  }) async {
    if (!mounted) return;
    if (resetModelMutation) {
      addCredentialsModelMutationProvider.reset(ref);
    }
    if (refreshServiceConnections) {
      ref.invalidate(serviceConnectionsProvider(widget.workspaceId));
    }
    final didPop = await Navigator.of(context).maybePop(true);
    if (didPop) {
      return;
    }
    if (!mounted) return;
    context.go('/workspaces/${widget.workspaceId}/more/service-connections');
  }

  void _resetAttributeControllers() {
    for (final controller in _attributeControllers.values) {
      controller.dispose();
    }
    _attributeControllers.clear();
  }

  String _describeAttributes(Map<String, String> attributes) {
    return attributes.entries
        .map(
          (entry) =>
              '${entry.key}:length=${entry.value.length},'
              'empty=${entry.value.isEmpty}',
        )
        .join('|');
  }
}

enum ServiceConnectionCreateType {
  modelProvider,
  skillCredential,
}

extension ServiceConnectionCreateTypeQuery on ServiceConnectionCreateType {
  static ServiceConnectionCreateType? fromQueryValue(String? value) {
    return switch (value) {
      'modelProvider' => ServiceConnectionCreateType.modelProvider,
      'skillCredential' => ServiceConnectionCreateType.skillCredential,
      _ => null,
    };
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.value, required this.onChanged});

  final ServiceConnectionCreateType value;
  final ValueChanged<ServiceConnectionCreateType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return AuraDropdownSelector<ServiceConnectionCreateType>(
      options: [
        AuraDropdownOption(
          value: ServiceConnectionCreateType.modelProvider,
          child: Text(
            LocaleKeys.service_connections_type_model_provider.tr(
              context: context,
            ),
          ),
        ),
        AuraDropdownOption(
          value: ServiceConnectionCreateType.skillCredential,
          child: Text(
            LocaleKeys.service_connections_type_skill_credential.tr(
              context: context,
            ),
          ),
        ),
      ],
      value: value,
      onChanged: onChanged,
      label: Text(
        LocaleKeys.service_connections_create_type_label.tr(context: context),
      ),
    );
  }
}

class _CredentialForm extends ConsumerWidget {
  const _CredentialForm({
    required this.workspaceId,
    required this.selectedDefinitionId,
    required this.nameController,
    required this.attributeControllers,
    required this.isSaving,
    required this.onNameChanged,
    required this.onDefinitionChanged,
    required this.onSave,
  });

  final String workspaceId;
  final String? selectedDefinitionId;
  final TextEditingController nameController;
  final Map<String, TextEditingController> attributeControllers;
  final bool isSaving;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String?> onDefinitionChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definitionsAsync = ref.watch(
      skillCredentialDefinitionsProvider(workspaceId),
    );

    return switch (definitionsAsync) {
      AsyncData(:final value) => _buildForm(
        context,
        value,
      ),
      AsyncLoading(value: final value?, hasValue: true) => _buildForm(
        context,
        value,
      ),
      _ => const Center(child: AuraSpinner()),
    };
  }

  Widget _buildForm(
    BuildContext context,
    List<SkillCredentialDefinitionEntity> definitions,
  ) {
    final selectedDefinition = definitions
        .where((definition) => definition.id == selectedDefinitionId)
        .firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        AuraCard(
          child: AuraColumn(
            children: [
              _DefinitionSelector(
                definitions: definitions,
                selectedDefinitionId: selectedDefinitionId,
                onChanged: onDefinitionChanged,
              ),
              if (selectedDefinition == null)
                AuraText(
                  child: Text(
                    LocaleKeys.skill_credentials_no_definitions.tr(
                      context: context,
                    ),
                  ),
                  color: AuraColorVariant.onSurfaceVariant,
                )
              else ...[
                AuraInput(
                  controller: nameController,
                  label: Text(
                    LocaleKeys.skill_credentials_name_label.tr(
                      context: context,
                    ),
                  ),
                  onChanged: onNameChanged,
                ),
                _CredentialAttributesFields(
                  definition: selectedDefinition,
                  controllers: attributeControllers,
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
            ],
            spacing: AuraSpacing.md,
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
        ),
      ],
    );
  }
}

class _DefinitionSelector extends StatelessWidget {
  const _DefinitionSelector({
    required this.definitions,
    required this.selectedDefinitionId,
    required this.onChanged,
  });

  final List<SkillCredentialDefinitionEntity> definitions;
  final String? selectedDefinitionId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return AuraDropdownSelector<String>(
      options: [
        for (final definition in definitions)
          AuraDropdownOption(
            value: definition.id,
            child: Text(definition.title),
          ),
      ],
      value: selectedDefinitionId,
      onChanged: onChanged,
      label: Text(
        LocaleKeys.skill_credentials_definition_label.tr(context: context),
      ),
    );
  }
}

class _CredentialAttributesFields extends StatelessWidget {
  const _CredentialAttributesFields({
    required this.definition,
    required this.controllers,
  });

  final SkillCredentialDefinitionEntity definition;
  final Map<String, TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    final attributes = SkillCredentialAttributeDefinition.parseMap(
      definition.attributesJson,
    );

    return AuraColumn(
      children: [
        for (final entry in attributes.entries)
          AuraInput(
            controller: controllers.putIfAbsent(
              entry.key,
              TextEditingController.new,
            ),
            label: Text(entry.key),
            hint: entry.value.description.isEmpty
                ? null
                : Text(entry.value.description),
            isRequired: !entry.value.optional,
            keyboardType: entry.value.secret
                ? TextInputType.visiblePassword
                : TextInputType.text,
            obscureText: entry.value.secret,
          ),
      ],
      spacing: AuraSpacing.md,
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}
