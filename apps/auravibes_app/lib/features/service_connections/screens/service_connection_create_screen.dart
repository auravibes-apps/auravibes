// Required: Feature widgets keep closely related private widgets together.

import 'dart:async';

import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/features/models/providers/add_model_provider_state.dart';
import 'package:auravibes_app/features/models/widgets/add_model_provider_widget.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_operations_provider.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_definitions_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_operations_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

final _logger = Logger('service_connection_create_screen');

@Dependencies([
  workspaceSession,
  cloudWorkspaceStateGateway,
  serviceConnectionOperations,
  serviceConnections,
])
class ServiceConnectionCreateScreen extends ConsumerStatefulWidget {
  const ServiceConnectionCreateScreen({
    required this.workspaceId,
    this.initialType,
    this.initialCredentialDefinitionId,
    this.initialAppSkillId,
    super.key,
  });

  final String workspaceId;
  final ServiceConnectionCreateType? initialType;
  final String? initialCredentialDefinitionId;
  final String? initialAppSkillId;

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
  String? _appSkillId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initialAppSkill = _appSkillCredentialOption(widget.initialAppSkillId);
    _type = initialAppSkill == null && widget.initialAppSkillId != null
        ? ServiceConnectionCreateType.modelProvider
        : widget.initialType ?? _type;
    _definitionId = widget.initialCredentialDefinitionId;
    _appSkillId = initialAppSkill?.identifier;
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
                  _appSkillId = null;
                  _resetAttributeControllers();
                });
              },
            ),
          ),
          Expanded(
            child: switch (_type) {
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
                onNameChanged: (_) => setState(() {
                  final _ = Object();
                }),
                onDefinitionChanged: (value) {
                  setState(() {
                    _definitionId = value;
                    _resetAttributeControllers();
                  });
                },
                onSave: () => unawaited(_saveSkillCredential()),
              ),
              ServiceConnectionCreateType.appSkillCredential =>
                _AppSkillCredentialForm(
                  selectedAppSkillId: _appSkillId,
                  nameController: _nameController,
                  apiKeyController: _attributeControllers.putIfAbsent(
                    'apiKey',
                    TextEditingController.new,
                  ),
                  isSaving: _isSaving,
                  onNameChanged: (_) => setState(() {
                    final _ = Object();
                  }),
                  onAppSkillChanged: (value) {
                    setState(() => _appSkillId = value);
                  },
                  onApiKeyChanged: (_) => setState(() {
                    final _ = Object();
                  }),
                  onSave: () => unawaited(_saveAppSkillCredential()),
                ),
            },
          ),
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

  Future<void> _saveAppSkillCredential() async {
    if (_isSaving) return;
    final appSkillId = _appSkillId;
    final apiKey = _attributeControllers['apiKey']?.text.trim();
    final name = _nameController.text.trim();
    if (appSkillId == null ||
        name.isEmpty ||
        apiKey == null ||
        apiKey.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final operations = await ref.read(
        serviceConnectionOperationsProvider(widget.workspaceId).future,
      );
      final _ = await operations.createAppSkillCredential(
        workspaceId: widget.workspaceId,
        appSkillServiceId: appSkillId,
        name: name,
        apiKey: apiKey,
      );
      await _closeAfterSave(resetModelMutation: false);
    } on Object catch (error, stackTrace) {
      _logger.severe(
        'debug:app skill credential save failed '
        'workspace=${widget.workspaceId} appSkillId=$appSkillId '
        'nameLength=${name.length}',
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
          .read(skillCredentialOperationsProvider)
          .create(
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
  appSkillCredential,
}

extension ServiceConnectionCreateTypeQuery on ServiceConnectionCreateType {
  static ServiceConnectionCreateType? fromQueryValue(String? value) {
    return switch (value) {
      'modelProvider' => ServiceConnectionCreateType.modelProvider,
      'skillCredential' => ServiceConnectionCreateType.skillCredential,
      'appSkillCredential' => ServiceConnectionCreateType.appSkillCredential,
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
        AuraDropdownOption(
          value: ServiceConnectionCreateType.appSkillCredential,
          child: Text(
            LocaleKeys.service_connections_type_app_skill_credential.tr(
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
      AsyncData(:final value) => _CredentialFormContent(
        definitions: value,
        selectedDefinitionId: selectedDefinitionId,
        nameController: nameController,
        attributeControllers: attributeControllers,
        isSaving: isSaving,
        onNameChanged: onNameChanged,
        onDefinitionChanged: onDefinitionChanged,
        onSave: onSave,
      ),
      AsyncLoading(value: final value?, hasValue: true) =>
        _CredentialFormContent(
          definitions: value,
          selectedDefinitionId: selectedDefinitionId,
          nameController: nameController,
          attributeControllers: attributeControllers,
          isSaving: isSaving,
          onNameChanged: onNameChanged,
          onDefinitionChanged: onDefinitionChanged,
          onSave: onSave,
        ),
      _ => const Center(child: AuraSpinner()),
    };
  }
}

class _AppSkillCredentialForm extends StatelessWidget {
  const _AppSkillCredentialForm({
    required this.selectedAppSkillId,
    required this.nameController,
    required this.apiKeyController,
    required this.isSaving,
    required this.onNameChanged,
    required this.onAppSkillChanged,
    required this.onApiKeyChanged,
    required this.onSave,
  });

  final String? selectedAppSkillId;
  final TextEditingController nameController;
  final TextEditingController apiKeyController;
  final bool isSaving;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String?> onAppSkillChanged;
  final ValueChanged<String> onApiKeyChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final skills = _appSkillCredentialOptions();
    final canSave =
        selectedAppSkillId != null &&
        nameController.text.trim().isNotEmpty &&
        apiKeyController.text.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        AuraCard(
          child: AuraColumn(
            children: [
              AuraDropdownSelector<String>(
                options: [
                  for (final skill in skills)
                    AuraDropdownOption(
                      value: skill.identifier,
                      child: Text(skill.title),
                    ),
                ],
                value: selectedAppSkillId,
                onChanged: onAppSkillChanged,
                label: Text(
                  LocaleKeys.service_connections_create_app_skill_label.tr(
                    context: context,
                  ),
                ),
              ),
              AuraInput(
                controller: nameController,
                label: Text(
                  LocaleKeys.skill_credentials_name_label.tr(context: context),
                ),
                onChanged: onNameChanged,
              ),
              AuraInput(
                controller: apiKeyController,
                label: Text(
                  _credentialValueLabel(context, selectedAppSkillId),
                ),
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
                onChanged: onApiKeyChanged,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: AuraButton(
                  onPressed: onSave,
                  child: const TextLocale(LocaleKeys.common_save),
                  isLoading: isSaving,
                  disabled: isSaving || !canSave,
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

List<AppSkillDefinition> _appSkillCredentialOptions() {
  return serviceSkillDefinitions.where(_canCreateAppSkillCredential).toList();
}

AppSkillDefinition? _appSkillCredentialOption(String? appSkillId) {
  if (appSkillId == null) return null;

  return _appSkillCredentialOptions()
      .where((skill) => skill.identifier == appSkillId)
      .firstOrNull;
}

bool _canCreateAppSkillCredential(AppSkillDefinition skill) {
  if (skill.compatibleModelProviderIds.isNotEmpty) return false;

  return skill.requiresCredential ||
      skill.nativeTools.any((tool) => tool.requiresCredential);
}

String _credentialValueLabel(BuildContext context, String? appSkillId) {
  if (appSkillId == 'searxng') {
    return LocaleKeys.service_connections_create_base_url_label.tr(
      context: context,
    );
  }

  return LocaleKeys.service_connections_create_api_key_label.tr(
    context: context,
  );
}

class _CredentialFormContent extends StatelessWidget {
  const _CredentialFormContent({
    required this.definitions,
    required this.selectedDefinitionId,
    required this.nameController,
    required this.attributeControllers,
    required this.isSaving,
    required this.onNameChanged,
    required this.onDefinitionChanged,
    required this.onSave,
  });

  final List<SkillCredentialDefinitionEntity> definitions;
  final String? selectedDefinitionId;
  final TextEditingController nameController;
  final Map<String, TextEditingController> attributeControllers;
  final bool isSaving;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String?> onDefinitionChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
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
