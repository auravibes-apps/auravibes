// Required: Feature widgets keep closely related private widgets together.

import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/service_connections/models/cloud_service_connection.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_operations_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_definitions_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_operations.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show SkillCredentialAttributeDefinition;
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class const ServiceConnectionEditScreen({
  required final String workspaceId,
  required final String connectionId,
  super.key,
}) extends ConsumerStatefulWidget {
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
    _future = _loadConnectionEditState(
      ref,
      widget.workspaceId,
      widget.connectionId,
    );
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
    return _ConnectionEditScreenView(owner: this);
  }

  void _initialize(_ConnectionEditState state) {
    if (_initialized) return;
    _initializeEditControllers(
      state,
      .new(
        nameController: _nameController,
        modelUrlController: _modelUrlController,
        nonSecretControllers: _nonSecretControllers,
        secretControllers: _secretControllers,
      ),
    );
    _initialized = true;
  }

  void _refreshForm() => setState(() => _initialized = true);

  Future<void> _saveSkillCredential(BuildContext context) async {
    setState(() => _isSaving = true);
    await _runEditSave(
      context,
      () => _updateSkillCredential(
        ref,
        widget.workspaceId,
        _skillCredentialUpdateData(this, widget.connectionId),
      ),
      LocaleKeys.skill_credentials_save_error,
    );
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _saveModelProvider(BuildContext context) async {
    setState(() => _isSaving = true);
    await _runEditSave(
      context,
      () => _updateModelProvider(
        ref,
        widget.workspaceId,
        _modelProviderUpdateData(this, widget.connectionId),
      ),
      LocaleKeys.service_connections_save_error,
    );
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _saveGenericConnection(
    BuildContext context,
    _GenericServiceConnectionEditState state,
  ) async {
    setState(() => _isSaving = true);
    await _runEditSave(
      context,
      () => _updateGenericConnection(
        ref,
        widget.workspaceId,
        _genericConnectionUpdateData(state, this),
      ),
      LocaleKeys.service_connections_save_error,
    );
    if (mounted) setState(() => _isSaving = false);
  }
}

Future<_ConnectionEditState> _loadConnectionEditState(
  WidgetRef ref,
  String workspaceId,
  String connectionId,
) async {
  final operations = await ref.read(
    serviceConnectionOperationsProvider(workspaceId).future,
  );
  final generic = await operations.getGenericForEdit(connectionId);
  if (generic != null) {
    return _GenericServiceConnectionEditState(connection: generic);
  }

  return await _loadCredentialOrModel(ref, workspaceId, connectionId);
}

Future<_ConnectionEditState> _loadCredentialOrModel(
  WidgetRef ref,
  String workspaceId,
  String connectionId,
) async {
  final credential = await _loadSkillCredentialForEdit(
    ref,
    workspaceId,
    connectionId,
  );
  if (credential != null) return credential;

  return await _loadModelOrThrow(ref, workspaceId, connectionId);
}

Future<_ConnectionEditState> _loadModelOrThrow(
  WidgetRef ref,
  String workspaceId,
  String connectionId,
) async {
  final model = await _loadModelProviderForEdit(ref, workspaceId, connectionId);
  if (model != null) return model;
  throw StateError('Service connection not found: $connectionId');
}

Future<_SkillCredentialEditState?> _loadSkillCredentialForEdit(
  WidgetRef ref,
  String workspaceId,
  String connectionId,
) async {
  final credential = await ref
      .read(skillCredentialOperationsProvider(workspaceId))
      .getForEdit(connectionId);
  if (credential == null) return null;

  final definition = await _loadSkillCredentialDefinition(
    ref,
    workspaceId,
    credential.credentialDefinitionId,
  );

  return _SkillCredentialEditState(
    credential: credential,
    definition: definition,
  );
}

Future<SkillCredentialDefinitionEntity> _loadSkillCredentialDefinition(
  WidgetRef ref,
  String workspaceId,
  String definitionId,
) async {
  final definition = await ref.read(
    skillCredentialDefinitionProvider(workspaceId, definitionId).future,
  );
  if (definition == null) {
    throw StateError('Skill credential definition not found.');
  }

  return definition;
}

Future<_ModelProviderEditState?> _loadModelProviderForEdit(
  WidgetRef ref,
  String workspaceId,
  String connectionId,
) async {
  final store = await ref.read(
    modelConnectionStoreProvider(workspaceId).future,
  );
  final connection = await store.getModelConnectionForEdit(connectionId);
  if (connection == null) return null;

  return _ModelProviderEditState(connection: connection);
}

class const _ConnectionEditControllers({
  required final TextEditingController nameController,
  required final TextEditingController modelUrlController,
  required final Map<String, TextEditingController> nonSecretControllers,
  required final Map<String, TextEditingController> secretControllers,
});

void _initializeEditControllers(
  _ConnectionEditState state,
  _ConnectionEditControllers controllers,
) {
  switch (state) {
    case final _SkillCredentialEditState skillState:
      _initializeSkillCredentialControllers(skillState, controllers);
    case final _ModelProviderEditState modelState:
      _initializeModelProviderControllers(modelState, controllers);
    case final _GenericServiceConnectionEditState genericState:
      _initializeNameController(genericState.connection.name, controllers);
  }
}

void _initializeModelProviderControllers(
  _ModelProviderEditState state,
  _ConnectionEditControllers controllers,
) {
  controllers.nameController.text = state.connection.name;
  controllers.modelUrlController.text = state.connection.url ?? '';
}

void _initializeNameController(
  String name,
  _ConnectionEditControllers controllers,
) {
  controllers.nameController.text = name;
}

void _initializeSkillCredentialControllers(
  _SkillCredentialEditState state,
  _ConnectionEditControllers controllers,
) {
  controllers.nameController.text = state.credential.name;
  final attributes = SkillCredentialAttributeDefinition.parseMap(
    state.definition.attributesJson,
  );
  for (final entry in attributes.entries) {
    _initializeCredentialAttribute(entry, state.credential, controllers);
  }
}

void _initializeCredentialAttribute(
  MapEntry<String, SkillCredentialAttributeDefinition> entry,
  SkillCredentialForEdit credential,
  _ConnectionEditControllers controllers,
) {
  if (entry.value.secret) {
    _initializeSecretController(entry.key, controllers.secretControllers);

    return;
  }

  _initializeNonSecretController(
    entry,
    credential.nonSecretAttributes,
    controllers.nonSecretControllers,
  );
}

void _initializeSecretController(
  String name,
  Map<String, TextEditingController> controllers,
) {
  final _ = controllers.putIfAbsent(name, TextEditingController.new);
}

void _initializeNonSecretController(
  MapEntry<String, SkillCredentialAttributeDefinition> entry,
  Map<String, String> values,
  Map<String, TextEditingController> controllers,
) {
  final _ = controllers.putIfAbsent(
    entry.key,
    () => TextEditingController(text: values[entry.key] ?? ''),
  );
}

class const _SkillCredentialUpdateData({
  required final String connectionId,
  required final String name,
  required final Map<String, String> nonSecretAttributes,
  required final Map<String, String> secretAttributes,
  required final Set<String> clearSecretAttributeNames,
});

_SkillCredentialUpdateData _skillCredentialUpdateData(
  _ServiceConnectionEditScreenState state,
  String connectionId,
) => _SkillCredentialUpdateData(
  connectionId: connectionId,
  name: state._nameController.text.trim(),
  nonSecretAttributes: _controllerValues(state._nonSecretControllers),
  secretAttributes: _nonEmptyControllerValues(state._secretControllers),
  clearSecretAttributeNames: state._clearedSecrets,
);

Future<void> _updateSkillCredential(
  WidgetRef ref,
  String workspaceId,
  _SkillCredentialUpdateData data,
) async {
  final _ = await ref
      .read(skillCredentialOperationsProvider(workspaceId))
      .update(
        data.connectionId,
        .new(
          name: data.name,
          nonSecretAttributes: data.nonSecretAttributes,
          secretAttributes: data.secretAttributes,
          clearSecretAttributeNames: data.clearSecretAttributeNames,
        ),
      );
}

Map<String, String> _controllerValues(
  Map<String, TextEditingController> controllers,
) => controllers.map((key, controller) => MapEntry(key, controller.text));

Map<String, String> _nonEmptyControllerValues(
  Map<String, TextEditingController> controllers,
) => Map.fromEntries(
  controllers.entries
      .map((entry) => MapEntry(entry.key, entry.value.text))
      .where((entry) => entry.value.isNotEmpty),
);

class const _ModelProviderUpdateData({
  required final String connectionId,
  required final String name,
  required final String? key,
  required final String url,
});

_ModelProviderUpdateData _modelProviderUpdateData(
  _ServiceConnectionEditScreenState state,
  String connectionId,
) {
  final key = state._modelKeyController.text.trim();

  return _ModelProviderUpdateData(
    connectionId: connectionId,
    name: state._nameController.text.trim(),
    key: key.isEmpty ? null : key,
    url: state._modelUrlController.text.trim(),
  );
}

Future<void> _updateModelProvider(
  WidgetRef ref,
  String workspaceId,
  _ModelProviderUpdateData data,
) async {
  final store = await ref.read(
    modelConnectionStoreProvider(workspaceId).future,
  );
  final _ = await store.updateModelConnection(
    data.connectionId,
    .new(name: data.name, key: data.key, url: data.url),
  );
}

class const _GenericConnectionUpdateData({
  required final GenericServiceConnectionForEdit connection,
  required final String name,
  required final ServiceConnectionSecretEdit secretEdit,
  required final String? secret,
});

_GenericConnectionUpdateData _genericConnectionUpdateData(
  _GenericServiceConnectionEditState state,
  _ServiceConnectionEditScreenState screenState,
) {
  final connection = state.connection;
  final name = screenState._nameController.text.trim();
  final secret = screenState._modelKeyController.text.trim();
  final isCleared = screenState._clearedSecrets.contains('secret');
  final secretEdit = _secretEditFor(secret, isCleared);

  return _GenericConnectionUpdateData(
    connection: connection,
    name: name,
    secretEdit: secretEdit,
    secret: secretEdit == ServiceConnectionSecretEdit.replace ? secret : null,
  );
}

ServiceConnectionSecretEdit _secretEditFor(String secret, bool isCleared) {
  return switch ((isCleared: isCleared, isEmpty: secret.isEmpty)) {
    (isCleared: true, isEmpty: _) => ServiceConnectionSecretEdit.clear,
    (isCleared: false, isEmpty: true) => ServiceConnectionSecretEdit.preserve,
    (isCleared: false, isEmpty: false) => ServiceConnectionSecretEdit.replace,
  };
}

Future<void> _updateGenericConnection(
  WidgetRef ref,
  String workspaceId,
  _GenericConnectionUpdateData data,
) async {
  final operations = await ref.read(
    serviceConnectionOperationsProvider(workspaceId).future,
  );
  await operations.updateGeneric(
    data.connection,
    .new(name: data.name, secretEdit: data.secretEdit, secret: data.secret),
  );
}

Future<void> _runEditSave(
  BuildContext context,
  Future<void> Function() operation,
  String errorKey,
) async {
  try {
    await operation();
    if (!context.mounted) return;
    Navigator.of(context).pop(true);
  } on Object {
    if (!context.mounted) return;
    _showEditSaveError(context, errorKey);
  }
}

void _showEditSaveError(BuildContext context, String localeKey) {
  final _ = AuraSnackBars.show(
    context: context,
    content: TextLocale(localeKey),
    variant: .error,
  );
}

class const _ConnectionEditScreenView({
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraScreen(
      child: _ConnectionEditBody(owner: owner),
      appBar: const _ConnectionEditAppBar(),
    );
  }
}

class const _ConnectionEditAppBar()
    extends StatelessWidget
    implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AuraAppBar(
      title: const TextLocale(LocaleKeys.service_connections_edit_title),
      leading: AuraIconButton(
        icon: Icons.arrow_back,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class const _ConnectionEditBody({
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ConnectionEditState>(
      future: owner._future,
      builder: (context, snapshot) =>
          _ConnectionEditSnapshotView(snapshot: snapshot, owner: owner),
    );
  }
}

class const _ConnectionEditSnapshotView({
  required final AsyncSnapshot<_ConnectionEditState> snapshot,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) {
      return const Center(
        child: TextLocale(LocaleKeys.service_connections_load_error),
      );
    }
    final state = snapshot.data;
    if (state == null) return const Center(child: AuraSpinner());
    owner._initialize(state);

    return _ConnectionEditFormSelector(state: state, owner: owner);
  }
}

class const _ConnectionEditFormSelector({
  required final _ConnectionEditState state,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return switch (state) {
      final _SkillCredentialEditState skillState => _SkillCredentialEditForm(
        state: skillState,
        owner: owner,
      ),
      final _ModelProviderEditState modelState => _ModelProviderEditForm(
        state: modelState,
        owner: owner,
      ),
      final _GenericServiceConnectionEditState genericState =>
        _GenericServiceConnectionEditForm(state: genericState, owner: owner),
    };
  }
}

sealed class _ConnectionEditState;

class _SkillCredentialEditState({
  required final SkillCredentialForEdit credential,
  required final SkillCredentialDefinitionEntity definition,
}) extends _ConnectionEditState;

class _ModelProviderEditState({
  required final ModelConnectionForEdit connection,
}) extends _ConnectionEditState;

class _GenericServiceConnectionEditState({
  required final GenericServiceConnectionForEdit connection,
}) extends _ConnectionEditState;

class const _SkillCredentialEditForm({
  required final _SkillCredentialEditState state,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _ConnectionEditFormShell(
      children: [
        _ConnectionEditHeader(text: state.definition.title),
        _SkillCredentialEditFields(state: state, owner: owner),
        _SkillCredentialEditSaveButton(owner: owner),
      ],
    );
  }
}

class const _ConnectionEditFormShell({required final List<Widget> children})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        AuraCard(
          child: AuraColumn(
            children: children,
            spacing: .md,
            crossAxisAlignment: .start,
          ),
        ),
      ],
    );
  }
}

class const _ConnectionEditSaveButton({
  required final VoidCallback onPressed,
  required final bool isSaving,
  required final bool canSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: AuraButton(
        onPressed: onPressed,
        child: const TextLocale(LocaleKeys.common_save),
        isLoading: isSaving,
        disabled: isSaving || !canSave,
      ),
    );
  }
}

class const _ConnectionEditHeader({required final String text})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraText(child: Text(text), style: .heading6);
  }
}

class const _SkillCredentialEditSaveButton({
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _ConnectionEditSaveButton(
      onPressed: () => owner._saveSkillCredential(context),
      isSaving: owner._isSaving,
      canSave: owner._nameController.text.trim().isNotEmpty,
    );
  }
}

class const _SkillCredentialEditFields({
  required final _SkillCredentialEditState state,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _SkillCredentialNameInput(owner: owner),
        _SkillCredentialEditAttributes(state: state, owner: owner),
      ],
      spacing: .md,
      crossAxisAlignment: .start,
    );
  }
}

class const _SkillCredentialNameInput({
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraInput(
      controller: owner._nameController,
      label: Text(LocaleKeys.skill_credentials_name_label.tr(context: context)),
      onChanged: (_) => owner._refreshForm(),
    );
  }
}

class const _SkillCredentialEditAttributes({
  required final _SkillCredentialEditState state,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final attributes = SkillCredentialAttributeDefinition.parseMap(
      state.definition.attributesJson,
    );

    return AuraColumn(
      children: [
        for (final entry in attributes.entries)
          _SkillCredentialAttributeInput(entry, editState: state, owner: owner),
      ],
      spacing: .md,
      crossAxisAlignment: .start,
    );
  }
}

abstract class _SkillCredentialAttributeInput extends StatelessWidget {
  const _SkillCredentialAttributeInput._();

  factory _SkillCredentialAttributeInput(
    MapEntry<String, SkillCredentialAttributeDefinition> entry, {
    required _SkillCredentialEditState editState,
    required _ServiceConnectionEditScreenState owner,
  }) {
    if (entry.value.secret) {
      return _SecretAttributeInput.fromEntry(entry, editState, owner);
    }

    return _NonSecretAttributeInput.fromEntry(entry, owner);
  }
}

class _NonSecretAttributeInput extends _SkillCredentialAttributeInput {
  const _NonSecretAttributeInput({
    required this.name,
    required this.definition,
    required this.controller,
    required this.onChanged,
  }) : super._();

  _NonSecretAttributeInput.fromEntry(
    MapEntry<String, SkillCredentialAttributeDefinition> entry,
    _ServiceConnectionEditScreenState owner,
  ) : this(
        name: entry.key,
        definition: entry.value,
        controller: owner._nonSecretControllers[entry.key],
        onChanged: owner._refreshForm,
      );

  final String name;
  final SkillCredentialAttributeDefinition definition;
  final TextEditingController? controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final description = definition.description;

    return AuraInput(
      controller: controller,
      label: Text(name),
      hint: description.isEmpty ? null : Text(description),
      isRequired: !definition.optional,
      onChanged: (_) => onChanged(),
    );
  }
}

class _SecretAttributeInput extends _SkillCredentialAttributeInput {
  const _SecretAttributeInput({
    required this.name,
    required this.definition,
    required this.state,
    required this.controller,
    required this.clearedSecrets,
    required this.onChanged,
  }) : super._();

  _SecretAttributeInput.fromEntry(
    MapEntry<String, SkillCredentialAttributeDefinition> entry,
    _SkillCredentialEditState editState,
    _ServiceConnectionEditScreenState owner,
  ) : this(
        name: entry.key,
        definition: entry.value,
        state: editState.credential.secretAttributes[entry.key],
        controller: owner._secretControllers[entry.key]!,
        clearedSecrets: owner._clearedSecrets,
        onChanged: owner._refreshForm,
      );

  final String name;
  final SkillCredentialAttributeDefinition definition;
  final SkillCredentialSecretState? state;
  final TextEditingController controller;
  final Set<String> clearedSecrets;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) =>
      _SecretAttributeAuraInput(this, context);

  void _onChanged(String _) {
    final _ = clearedSecrets.remove(name);
    onChanged();
  }

  void _clearSecret() {
    controller.clear();
    final _ = clearedSecrets.add(name);
    onChanged();
  }
}

class _SecretAttributeAuraInput extends AuraInput {
  _SecretAttributeAuraInput(_SecretAttributeInput input, BuildContext context)
    : super(
        controller: input.controller,
        placeholder: switch (_secretPlaceholder(context, input.state)) {
          final value? => Text(value),
          _ => null,
        },
        label: Text(input.name),
        hint: _descriptionHint(input.definition.description),
        isRequired: !input.definition.optional,
        suffixIcon: input.definition.optional
            ? _SecretAttributeClearButton(onPressed: input._clearSecret)
            : null,
        keyboardType: .visiblePassword,
        obscureText: true,
        onChanged: input._onChanged,
      );
}

String? _secretPlaceholder(
  BuildContext context,
  SkillCredentialSecretState? state,
) {
  if (state?.hasValue != true) return null;
  final suffix = state?.keySuffix == null ? '' : ' ****${state?.keySuffix}';

  return '${LocaleKeys.skill_credentials_secret_saved.tr(context: context)}'
      '$suffix';
}

Text? _descriptionHint(String description) {
  return description.isEmpty ? null : Text(description);
}

class const _SecretAttributeClearButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: Icons.clear,
      onPressed: onPressed,
      tooltip: LocaleKeys.skill_credentials_clear_secret.tr(context: context),
    );
  }
}

class const _ModelProviderEditForm({
  required final _ModelProviderEditState state,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final connection = state.connection;

    return _ConnectionEditFormShell(
      children: [
        _ConnectionEditHeader(text: connection.modelId),
        _ModelProviderEditFields(owner: owner, suffix: connection.keySuffix),
        _ModelProviderEditSaveButton(owner: owner),
      ],
    );
  }
}

class const _ModelProviderEditFields({
  required final _ServiceConnectionEditScreenState owner,
  required final String? suffix,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _ModelProviderNameInput(owner: owner),
        _ModelProviderKeyInput(owner: owner, suffix: suffix),
        _ModelProviderUrlInput(owner: owner),
      ],
      spacing: .md,
      crossAxisAlignment: .start,
    );
  }
}

class const _ModelProviderEditSaveButton({
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _ConnectionEditSaveButton(
      onPressed: () => owner._saveModelProvider(context),
      isSaving: owner._isSaving,
      canSave: owner._nameController.text.trim().isNotEmpty,
    );
  }
}

class const _ModelProviderNameInput({
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraInput(
      controller: owner._nameController,
      label: const TextLocale(
        LocaleKeys.models_screens_add_provider_fields_name_label,
      ),
      onChanged: (_) => owner._refreshForm(),
    );
  }
}

class const _ModelProviderKeyInput({
  required final _ServiceConnectionEditScreenState owner,
  required final String? suffix,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _ModelProviderKeyAuraInput(this, context);
}

class _ModelProviderKeyAuraInput extends AuraInput {
  _ModelProviderKeyAuraInput(_ModelProviderKeyInput input, BuildContext context)
    : super(
        controller: input.owner._modelKeyController,
        placeholder: Text(_modelProviderKeyPlaceholder(context, input.suffix)),
        label: const TextLocale(
          LocaleKeys.models_screens_add_provider_fields_key_label,
        ),
        keyboardType: .visiblePassword,
        obscureText: true,
        onChanged: (_) => input.owner._refreshForm(),
      );
}

class const _ModelProviderUrlInput({
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraInput(
      controller: owner._modelUrlController,
      label: const TextLocale(
        LocaleKeys.models_screens_add_provider_fields_url_label,
      ),
      keyboardType: .url,
      onChanged: (_) => owner._refreshForm(),
    );
  }
}

class const _GenericServiceConnectionEditForm({
  required final _GenericServiceConnectionEditState state,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final connection = state.connection;

    return _ConnectionEditFormShell(
      children: [
        _ConnectionEditHeader(text: connection.serviceId),
        _GenericServiceConnectionEditFields(state: state, owner: owner),
        _GenericServiceConnectionEditSaveButton(state: state, owner: owner),
      ],
    );
  }
}

class const _GenericServiceConnectionEditFields({
  required final _GenericServiceConnectionEditState state,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _GenericServiceConnectionNameInput(owner: owner),
        _GenericServiceConnectionSecretInput(state: state, owner: owner),
      ],
      spacing: .md,
      crossAxisAlignment: .start,
    );
  }
}

class const _GenericServiceConnectionEditSaveButton({
  required final _GenericServiceConnectionEditState state,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _ConnectionEditSaveButton(
      onPressed: () => owner._saveGenericConnection(context, state),
      isSaving: owner._isSaving,
      canSave: owner._nameController.text.trim().isNotEmpty,
    );
  }
}

class const _GenericServiceConnectionNameInput({
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraInput(
      controller: owner._nameController,
      label: Text(LocaleKeys.skill_credentials_name_label.tr(context: context)),
      onChanged: (_) => owner._refreshForm(),
    );
  }
}

class const _GenericServiceConnectionSecretInput({
  required final _GenericServiceConnectionEditState state,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _GenericServiceConnectionSecretAuraInput(this, context);

  void _clearSecret() {
    owner._modelKeyController.clear();
    final _ = owner._clearedSecrets.add('secret');
    owner._refreshForm();
  }

  void _onChanged(String _) => owner._refreshForm();
}

class _GenericServiceConnectionSecretAuraInput extends AuraInput {
  _GenericServiceConnectionSecretAuraInput(
    _GenericServiceConnectionSecretInput input,
    BuildContext context,
  ) : super(
        controller: input.owner._modelKeyController,
        placeholder: switch (_genericSecretPlaceholder(
          context,
          input.state.connection.hasSecret &&
              !input.owner._clearedSecrets.contains('secret'),
          input.state.connection.keySuffix,
        )) {
          final value? => Text(value),
          _ => null,
        },
        label: Text(
          _genericCredentialValueLabel(
            context,
            input.state.connection.serviceId,
          ),
        ),
        suffixIcon: _GenericSecretClearButton(onPressed: input._clearSecret),
        keyboardType: .visiblePassword,
        obscureText: true,
        onChanged: input._onChanged,
      );
}

String _modelProviderKeyPlaceholder(BuildContext context, String? suffix) {
  final label = LocaleKeys.skill_credentials_secret_saved.tr(context: context);

  return suffix == null ? label : '$label ****$suffix';
}

class const _GenericSecretClearButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: Icons.clear,
      onPressed: onPressed,
      tooltip: LocaleKeys.skill_credentials_clear_secret.tr(context: context),
    );
  }
}

String? _genericSecretPlaceholder(
  BuildContext context,
  bool hasSavedSecret,
  String? suffix,
) {
  if (!hasSavedSecret) return null;
  final label = LocaleKeys.skill_credentials_secret_saved.tr(context: context);
  final suffixText = suffix == null ? '' : ' ****$suffix';

  return '$label$suffixText';
}

String _genericCredentialValueLabel(BuildContext context, String serviceId) {
  final key = switch (serviceId) {
    'searxng' => LocaleKeys.service_connections_create_base_url_label,
    _ => LocaleKeys.service_connections_create_api_key_label,
  };

  return key.tr(context: context);
}
