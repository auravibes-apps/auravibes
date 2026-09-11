// Required: Existing UI spacing uses small numeric values.
// Required: Form callbacks stay local to this screen.
import 'dart:async';

import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/markdown/markdown_editor_launcher.dart';
import 'package:auravibes_app/features/markdown/widgets/markdown_preview_field.dart';
import 'package:auravibes_app/features/skills/models/skill_detail.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_definitions_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credentials_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_detail_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart'
    show appSkillRegistryProvider;
import 'package:auravibes_app/features/skills/providers/skill_template_tools_provider.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/delete_cloud_routed_skill_usecases.dart';
import 'package:auravibes_app/features/skills/usecases/duplicate_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/duplicate_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show AppSkillToolDefinition;
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:textf/textf.dart';

const _skillDescriptionMaxCharacters = 1024;

class const SkillDetailScreen({
  required final String workspaceId,
  final String? skillId,
  super.key,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends ConsumerState<SkillDetailScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextfEditingController();
  final _contentController = TextEditingController();
  String? _credentialDefinitionId;
  bool _isCredentialOptional = false;
  bool _isEnabled = true;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewData = _detailViewData();

    return AuraScreen(
      child: _SkillDetailBody(state: this, detailAsync: viewData.detailAsync),
      appBar: _SkillDetailAppBar(
        state: this,
        currentDetail: viewData.currentDetail,
        userSkillDetail: viewData.userSkillDetail,
      ),
    );
  }

  void _updateState(VoidCallback callback) => setState(callback);
}

extension on _SkillDetailScreenState {
  bool get _isCreate => widget.skillId == null;

  AsyncValue<SkillDetail?>? _detailAsync() {
    final skillId = widget.skillId;
    if (skillId == null) return null;

    return ref.watch(skillDetailProvider(widget.workspaceId, skillId));
  }

  SkillDetail? _userSkillDetail(SkillDetail? detail) =>
      detail?.isUserSkill == true ? detail : null;

  ({
    AsyncValue<SkillDetail?>? detailAsync,
    SkillDetail? currentDetail,
    SkillDetail? userSkillDetail,
  })
  _detailViewData() {
    final detailAsync = _detailAsync();
    final currentDetail = detailAsync?.value;

    return (
      detailAsync: detailAsync,
      currentDetail: currentDetail,
      userSkillDetail: _userSkillDetail(currentDetail),
    );
  }

  Future<void> _editDescription(BuildContext context) async {
    final result = await MarkdownEditorLauncher.show(
      context,
      initialMarkdown: _descriptionController.text,
      maxCharacters: _skillDescriptionMaxCharacters,
    );
    if (result == null || !mounted) return;

    _updateState(() => _descriptionController.text = result);
  }

  Future<void> _editContent(BuildContext context) async {
    final result = await MarkdownEditorLauncher.show(
      context,
      initialMarkdown: _contentController.text,
    );
    if (result == null || !mounted) return;

    _updateState(() => _contentController.text = result);
  }

  void _setCredentialDefinition(String? value) {
    _updateState(() {
      _credentialDefinitionId = value;
      if (value == null) _isCredentialOptional = false;
    });
  }

  void _setCredentialOptional(bool value) {
    _updateState(() => _isCredentialOptional = value);
  }

  void _setEnabled(bool value) {
    _updateState(() => _isEnabled = value);
  }

  void _initializeForm(BuildContext context, SkillDetail detail) {
    if (_initialized) return;

    _initializeTextFields(context, detail);
    _credentialDefinitionId = detail.credentialDefinitionId;
    _isCredentialOptional = detail.isCredentialOptional;
    _isEnabled = detail.isEnabled;
    _initialized = true;
  }

  void _initializeTextFields(BuildContext context, SkillDetail detail) {
    _setTitleText(context, detail);
    _setDescriptionText(context, detail);
    _setContentText(context, detail);
  }

  void _setTitleText(BuildContext context, SkillDetail detail) {
    _titleController.text = _localizedValue(
      context,
      detail.titleKey,
      detail.title,
    );
  }

  void _setDescriptionText(BuildContext context, SkillDetail detail) {
    _descriptionController.text = _localizedValue(
      context,
      detail.descriptionKey,
      detail.description,
    );
  }

  void _setContentText(BuildContext context, SkillDetail detail) {
    _contentController.text = _localizedValue(
      context,
      detail.contentKey,
      detail.content,
    );
  }
}

String _localizedValue(BuildContext context, String? key, String fallback) =>
    key?.tr(context: context) ?? fallback;

extension on _SkillDetailScreenState {
  Future<void> _save(BuildContext context) async {
    if (_isSaving) return;
    _updateState(() => _isSaving = true);
    final didSave = await _trySave(context);

    if (!didSave || !context.mounted) return;
    _navigateAfterSave(context);
  }

  Future<bool> _trySave(BuildContext context) async {
    try {
      await _saveSkill();

      return true;
    } on Object {
      if (context.mounted) _showSaveError(context);

      return false;
    } finally {
      if (mounted) _updateState(() => _isSaving = false);
    }
  }

  Future<void> _saveSkill() async {
    if (_isCreate) {
      await _createSkill();

      return;
    }

    final skillId = widget.skillId;
    if (skillId == null) return;
    await _updateSkill(skillId);
  }

  Future<void> _createSkill() async {
    final usecase = ref.read(createSkillUsecaseProvider(widget.workspaceId));
    final _ = await usecase.call(widget.workspaceId, _createSkillValue());
  }

  SkillToCreate _createSkillValue() => .new(
    kind: SkillKind.template,
    title: _titleController.text,
    description: _descriptionController.text,
    content: _contentController.text,
    credentialDefinitionId: _credentialDefinitionId,
    isCredentialOptional: _isCredentialOptional,
    isEnabled: _isEnabled,
  );

  Future<void> _updateSkill(String skillId) {
    return ref
        .read(updateSkillUsecaseProvider(widget.workspaceId))
        .call(skillId, _skillUpdateValue());
  }

  SkillToUpdate _skillUpdateValue() => .new(
    title: _titleController.text,
    description: _descriptionController.text,
    content: _contentController.text,
    credentialDefinitionId: _credentialDefinitionId,
    clearCredentialDefinition: _credentialDefinitionId == null,
    isCredentialOptional: _isCredentialOptional,
    isEnabled: _isEnabled,
  );

  void _navigateAfterSave(BuildContext context) {
    try {
      _popOrGo(context);
    } on Object {
      // Save already succeeded, so navigation failures are not save errors.
    }
  }

  void _popOrGo(BuildContext context) {
    if (context.canPop()) {
      context.pop(true);

      return;
    }

    context.go('/workspaces/${widget.workspaceId}/more/skills');
  }

  Future<void> _duplicateSkill(BuildContext context, SkillDetail detail) async {
    _updateState(() => _isSaving = true);
    try {
      await _duplicateSkillRecord(detail.id);
      if (!context.mounted) return;

      _finishDuplicate(context);
    } on Object {
      if (context.mounted) _showSaveError(context);
    } finally {
      if (mounted) _updateState(() => _isSaving = false);
    }
  }

  void _finishDuplicate(BuildContext context) {
    ref.invalidate(workspaceSkillsProvider(widget.workspaceId));
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _duplicateSkillRecord(String skillId) async {
    final usecase = ref.read(duplicateSkillUsecaseProvider(widget.workspaceId));
    final _ = await usecase.call(skillId);
  }
}

extension on _SkillDetailScreenState {
  Future<void> _confirmDelete(BuildContext context, SkillDetail detail) async {
    final shouldDelete = await _showDeleteConfirmation(context);
    if (shouldDelete != true) return;
    if (!context.mounted) return;

    await _deleteSkillAndClose(context, detail.id);
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => _SkillDeleteDialog(),
    );
  }

  Future<void> _deleteSkillAndClose(
    BuildContext context,
    String skillId,
  ) async {
    await ref.read(deleteSkillProvider(widget.workspaceId))(skillId);
    ref.invalidate(workspaceSkillsProvider(widget.workspaceId));
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  void _showSaveError(BuildContext context) {
    if (!context.mounted) return;
    final _ = AuraSnackBars.show(
      context: context,
      content: Text(LocaleKeys.skills_screen_save_error.tr(context: context)),
      variant: .error,
    );
  }
}

sealed class const _SkillDetailBodyState();

class const _SkillDetailCreateState() extends _SkillDetailBodyState;

class const _SkillDetailReadyState({required final SkillDetail detail})
    extends _SkillDetailBodyState;

class const _SkillDetailNotFoundState() extends _SkillDetailBodyState;

class const _SkillDetailLoadingState() extends _SkillDetailBodyState;

class const _SkillDetailErrorState() extends _SkillDetailBodyState;

_SkillDetailBodyState _skillDetailBodyState(
  AsyncValue<SkillDetail?>? detailAsync,
) {
  if (detailAsync == null) return const _SkillDetailCreateState();
  if (detailAsync case AsyncData(:final value)) {
    return _skillDetailStateForValue(value);
  }
  if (detailAsync case AsyncLoading(value: final value, hasValue: true)) {
    return _skillDetailLoadingValueState(value);
  }

  return _skillDetailAsyncState(detailAsync);
}

_SkillDetailBodyState _skillDetailStateForValue(SkillDetail? detail) {
  return detail == null
      ? const _SkillDetailNotFoundState()
      : _SkillDetailReadyState(detail: detail);
}

_SkillDetailBodyState _skillDetailLoadingValueState(SkillDetail? detail) =>
    detail == null
    ? const _SkillDetailLoadingState()
    : _SkillDetailReadyState(detail: detail);

_SkillDetailBodyState _skillDetailAsyncState(
  AsyncValue<SkillDetail?> detailAsync,
) {
  return switch (detailAsync) {
    AsyncLoading() => const _SkillDetailLoadingState(),
    AsyncError() => const _SkillDetailErrorState(),
    AsyncData() => const _SkillDetailNotFoundState(),
  };
}

class const _SkillDetailBody({
  required final _SkillDetailScreenState state,
  required final AsyncValue<SkillDetail?>? detailAsync,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (_skillDetailBodyState(
    detailAsync,
  )) {
    _SkillDetailCreateState() => _SkillDetailForm(state: state, detail: null),
    _SkillDetailReadyState(:final detail) => _SkillDetailReadyForm(
      state: state,
      detail: detail,
    ),
    _SkillDetailNotFoundState() => const _SkillNotFound(),
    _SkillDetailLoadingState() => const _SkillLoading(),
    _SkillDetailErrorState() => const _SkillLoadError(),
  };
}

class const _SkillDetailReadyForm({
  required final _SkillDetailScreenState state,
  required final SkillDetail detail,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    state._initializeForm(context, detail);

    return _SkillDetailForm(state: state, detail: detail);
  }
}

class const _SkillNotFound() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: TextLocale(LocaleKeys.skills_screen_not_found));
  }
}

class const _SkillLoading() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: AuraSpinner());
  }
}

class const _SkillLoadError() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: TextLocale(LocaleKeys.skills_screen_load_error));
  }
}

typedef _SkillDetailAppBarActionsRequest = ({
  _SkillDetailScreenState state,
  bool isCreate,
  SkillDetail? currentDetail,
  SkillDetail? userSkillDetail,
});

class _SkillDetailAppBarActions {
  new(_SkillDetailAppBarActionsRequest request)
    : values = [
        if (!request.isCreate)
          if (request.userSkillDetail case final detail?) ...[
            _SkillDetailDuplicateButton(state: request.state, detail: detail),
            _SkillDetailDeleteButton(state: request.state, detail: detail),
          ],
        if (request.isCreate || request.currentDetail?.isUserSkill == true)
          _SkillDetailSaveButton(state: request.state),
      ];

  final List<Widget> values;
}

class const _SkillDetailAppBar({
  required final _SkillDetailScreenState state,
  required final SkillDetail? currentDetail,
  required final SkillDetail? userSkillDetail,
}) extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isCreate = state._isCreate;

    return AuraAppBar(
      title: _SkillDetailAppBarTitle(isCreate: isCreate),
      actions: _SkillDetailAppBarActions((
        state: state,
        isCreate: isCreate,
        currentDetail: currentDetail,
        userSkillDetail: userSkillDetail,
      )).values,
      leading: _SkillDetailBackButton(),
    );
  }
}

class const _SkillDetailAppBarTitle({required final bool isCreate})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextLocale(
    isCreate
        ? LocaleKeys.skills_screen_create_title
        : LocaleKeys.skills_screen_detail_title,
  );
}

class const _SkillDetailDuplicateButton({
  required final _SkillDetailScreenState state,
  required final SkillDetail detail,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: Icons.copy_outlined,
      onPressed: state._isSaving
          ? null
          : () => state._duplicateSkill(context, detail),
      tooltip: LocaleKeys.skills_screen_duplicate.tr(context: context),
    );
  }
}

class const _SkillDetailDeleteButton({
  required final _SkillDetailScreenState state,
  required final SkillDetail detail,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: Icons.delete_outline,
      onPressed: state._isSaving
          ? null
          : () => state._confirmDelete(context, detail),
      tooltip: LocaleKeys.skills_screen_delete.tr(context: context),
    );
  }
}

class const _SkillDetailSaveButton({
  required final _SkillDetailScreenState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: Icons.save_outlined,
      onPressed: state._isSaving ? null : () => state._save(context),
      tooltip: LocaleKeys.skills_screen_save.tr(context: context),
    );
  }
}

class _SkillDetailBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: Icons.arrow_back,
      onPressed: () => Navigator.of(context).pop(),
    );
  }
}

class _SkillDeleteDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraConfirmDialog(
      title: const TextLocale(LocaleKeys.skills_screen_delete),
      message: const TextLocale(LocaleKeys.skills_screen_delete_confirm),
      confirmLabel: Text(LocaleKeys.skills_screen_delete.tr(context: context)),
      cancelLabel: Text(LocaleKeys.common_cancel.tr(context: context)),
      isDestructive: true,
    );
  }
}

class const _SkillDetailForm({
  required final _SkillDetailScreenState state,
  required final SkillDetail? detail,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        AuraCard(
          child: _SkillDetailFormFields(state: state, detail: detail),
        ),
        _SkillDetailRelatedContent(
          workspaceId: state.widget.workspaceId,
          detail: detail,
        ),
      ],
    );
  }
}

class const _SkillDetailFormFields({
  required final _SkillDetailScreenState state,
  required final SkillDetail? detail,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: _SkillDetailFormChildren(
      state: state,
      detail: detail,
      context: context,
    ).values,
    spacing: .md,
    crossAxisAlignment: .start,
  );
}

class _SkillDetailFormChildren {
  new({
    required _SkillDetailScreenState state,
    required SkillDetail? detail,
    required BuildContext context,
  }) : values = [
         ..._SkillIdentityFields(
           state: state,
           detail: detail,
           context: context,
         ).values,
         ..._SkillMarkdownFields(
           state: state,
           detail: detail,
           context: context,
         ).values,
         _SkillEnabledField(
           value: state._isEnabled,
           onChanged: detail == null || detail.isUserSkill
               ? state._setEnabled
               : null,
           disabled: detail != null && !detail.isUserSkill,
         ),
         ..._SkillCredentialFields(state: state, detail: detail).values,
         if (detail == null || detail.isUserSkill)
           _SkillSaveField(
             onPressed: () => state._save(context),
             isCreate: detail == null,
             disabled: state._isSaving,
           ),
       ];

  final List<Widget> values;
}

class _SkillIdentityFields {
  new({
    required _SkillDetailScreenState state,
    required SkillDetail? detail,
    required BuildContext context,
  }) : values = [
         if (detail != null && !detail.isUserSkill)
           const AuraText(
             child: TextLocale(LocaleKeys.skills_screen_app_read_only),
           ),
         if (detail != null)
           _ReadOnlyField(
             labelKey: LocaleKeys.skills_screen_slug_label,
             value: detail.slug,
           ),
         AuraInput(
           controller: state._titleController,
           label: Text(
             LocaleKeys.skills_screen_title_label.tr(context: context),
           ),
           enabled: detail == null || detail.isUserSkill,
         ),
       ];

  final List<Widget> values;
}

class _SkillMarkdownFields {
  new({
    required _SkillDetailScreenState state,
    required SkillDetail? detail,
    required BuildContext context,
  }) : values = [
         _SkillDescriptionField(
           controller: state._descriptionController,
           onEdit: () => state._editDescription(context),
           isReadOnly: detail != null && !detail.isUserSkill,
         ),
         _SkillContentField(
           controller: state._contentController,
           onEdit: () => state._editContent(context),
           isReadOnly: detail != null && !detail.isUserSkill,
         ),
       ];

  final List<Widget> values;
}

class _SkillCredentialFields {
  new({required _SkillDetailScreenState state, required SkillDetail? detail})
    : values = [
        if (detail == null || detail.isUserSkill)
          _CredentialDefinitionSelector(
            workspaceId: state.widget.workspaceId,
            value: state._credentialDefinitionId,
            onChanged: state._setCredentialDefinition,
          ),
        if ((detail == null || detail.isUserSkill) &&
            state._credentialDefinitionId != null)
          _SkillCredentialOptionalField(
            value: state._isCredentialOptional,
            onChanged: state._setCredentialOptional,
          ),
        if (detail != null)
          if (state._credentialDefinitionId case final credentialDefinitionId?)
            _SkillCredentialsHint(
              workspaceId: state.widget.workspaceId,
              credentialDefinitionId: credentialDefinitionId,
              isCredentialOptional: state._isCredentialOptional,
            ),
      ];

  final List<Widget> values;
}

class const _SkillMarkdownField({
  required final TextEditingController controller,
  required final String titleKey,
  required final String editKey,
  required final String emptyKey,
  required final VoidCallback onEdit,
  required final bool isReadOnly,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MarkdownPreviewField(
    controller: controller,
    titleKey: titleKey,
    editKey: editKey,
    emptyKey: emptyKey,
    onEdit: onEdit,
    isReadOnly: isReadOnly,
  );
}

class const _SkillDescriptionField({
  required final TextEditingController controller,
  required final VoidCallback onEdit,
  required final bool isReadOnly,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SkillMarkdownField(
    controller: controller,
    titleKey: LocaleKeys.skills_screen_description_label,
    editKey: LocaleKeys.skills_screen_edit_description,
    emptyKey: LocaleKeys.skills_screen_description_empty,
    onEdit: onEdit,
    isReadOnly: isReadOnly,
  );
}

class const _SkillContentField({
  required final TextEditingController controller,
  required final VoidCallback onEdit,
  required final bool isReadOnly,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SkillMarkdownField(
    controller: controller,
    titleKey: LocaleKeys.skills_screen_content_label,
    editKey: LocaleKeys.skills_screen_edit_content,
    emptyKey: LocaleKeys.skills_screen_content_empty,
    onEdit: onEdit,
    isReadOnly: isReadOnly,
  );
}

class const _SkillEnabledField({
  required final bool value,
  required final ValueChanged<bool>? onChanged,
  required final bool disabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
      AuraSwitch(value: value, onChanged: onChanged, disabled: disabled),
      const Expanded(
        child: AuraText(
          child: TextLocale(LocaleKeys.skills_screen_enabled_label),
        ),
      ),
    ],
    spacing: .md,
  );
}

class const _SkillCredentialOptionalField({
  required final bool value,
  required final ValueChanged<bool> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCheckboxListTile(
    value: value,
    onChanged: onChanged,
    title: const TextLocale(LocaleKeys.skills_screen_credential_optional_label),
    subtitle: const TextLocale(
      LocaleKeys.skills_screen_credential_optional_hint,
    ),
  );
}

class const _SkillSaveField({
  required final VoidCallback onPressed,
  required final bool isCreate,
  required final bool disabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: AuraButton(
      onPressed: onPressed,
      child: TextLocale(
        isCreate
            ? LocaleKeys.skills_screen_create
            : LocaleKeys.skills_screen_save,
      ),
      disabled: disabled,
    ),
  );
}

class const _SkillDetailRelatedContent({
  required final String workspaceId,
  required final SkillDetail? detail,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final detail = this.detail;
    final children = <Widget>[];
    _addRelatedSections(children, detail);

    return Column(children: children);
  }

  void _addRelatedSections(List<Widget> children, SkillDetail? detail) {
    _addAppSkillCredentials(children, detail);
    _addSkillTools(children, detail);
    _addAppSkillTools(children, detail);
  }

  void _addAppSkillCredentials(List<Widget> children, SkillDetail? detail) {
    if (detail == null) return;
    if (detail.isUserSkill ||
        !detail.appTools.any((tool) => tool.requiresCredential)) {
      return;
    }

    children.addAll([
      const SizedBox(height: 12),
      _AppSkillCredentialsHint(workspaceId: workspaceId, appSkillId: detail.id),
    ]);
  }

  void _addSkillTools(List<Widget> children, SkillDetail? detail) {
    if (detail == null || !detail.isUserSkill) return;

    children
      ..add(const SizedBox(height: 12))
      ..add(_SkillToolsCard(workspaceId: workspaceId, skillId: detail.id));
  }

  void _addAppSkillTools(List<Widget> children, SkillDetail? detail) {
    if (detail == null || detail.isUserSkill || detail.appTools.isEmpty) {
      return;
    }

    children
      ..add(const SizedBox(height: 12))
      ..add(_AppSkillToolsCard(tools: detail.appTools));
  }
}

class const _SkillToolsCard({
  required final String workspaceId,
  required final String skillId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SkillToolsCardContent(workspaceId: workspaceId, skillId: skillId);
  }
}

class const _SkillToolsCardContent({
  required final String workspaceId,
  required final String skillId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = _SkillToolsCardActions(
      context: context,
      ref: ref,
      workspaceId: workspaceId,
      skillId: skillId,
    );

    return AuraCard(
      child: _SkillToolsCardBody(
        toolsAsync: ref.watch(skillTemplateToolsProvider(workspaceId, skillId)),
        actions: actions,
      ),
    );
  }
}

class _SkillToolsCardActions {
  new({
    required this.context,
    required this.ref,
    required this.workspaceId,
    required this.skillId,
  });

  final BuildContext context;
  final WidgetRef ref;
  final String workspaceId;
  final String skillId;

  void _create() => unawaited(_openTool());

  Future<void> _open(String toolId) => _openTool(toolId);

  Future<void> _openTool([String? toolId]) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final result = await context.push<bool>(
      '/workspaces/$workspaceId/more/skills/$skillId/tools/${toolId ?? 'new'}',
    );
    if (result == true) {
      _scheduleToolsRefresh(container);
    }
  }

  void _scheduleToolsRefresh(ProviderContainer container) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshToolsAfterFrame(container));
    });
  }

  Future<void> _refreshToolsAfterFrame(ProviderContainer container) async {
    await container.pump();
    container.invalidate(skillTemplateToolsProvider(workspaceId, skillId));
  }

  Future<void> _duplicate(SkillTemplateToolEntity tool) async {
    final usecase = ref.read(
      duplicateSkillTemplateToolUsecaseProvider(workspaceId),
    );
    final _ = await usecase.call(tool.id);
    ref.invalidate(skillTemplateToolsProvider(workspaceId, skillId));
  }

  Future<void> _delete(SkillTemplateToolEntity tool) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => const _SkillToolDeleteDialog(),
    );
    if (shouldDelete != true) return;

    await ref.read(deleteSkillTemplateToolProvider(workspaceId))(tool.id);
    ref.invalidate(skillTemplateToolsProvider(workspaceId, skillId));
  }
}

class const _SkillToolsCardBody({
  required final AsyncValue<List<SkillTemplateToolEntity>> toolsAsync,
  required final _SkillToolsCardActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: _SkillToolsCardChildren(
      toolsAsync: toolsAsync,
      actions: actions,
    ).values,
    spacing: .sm,
    crossAxisAlignment: .start,
  );
}

class _SkillToolsCardChildren {
  new({
    required AsyncValue<List<SkillTemplateToolEntity>> toolsAsync,
    required _SkillToolsCardActions actions,
  }) : values = [
         _SkillToolsHeader(onCreate: actions._create),
         _SkillToolsAsyncContent(
           toolsAsync: toolsAsync,
           onOpenTool: actions._open,
           onDuplicateTool: actions._duplicate,
           onDeleteTool: actions._delete,
         ),
       ];

  final List<Widget> values;
}

class const _SkillToolsHeader({required final VoidCallback onCreate})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(
        child: AuraText(
          child: TextLocale(LocaleKeys.skills_tool_section_title),
          style: .heading4,
        ),
      ),
      _SkillToolsCreateButton(onPressed: onCreate),
    ],
  );
}

class const _SkillToolsCreateButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.add,
    onPressed: onPressed,
    tooltip: LocaleKeys.skills_tool_create_title.tr(context: context),
  );
}

class const _SkillToolsAsyncContent({
  required final AsyncValue<List<SkillTemplateToolEntity>> toolsAsync,
  required final Future<void> Function(String) onOpenTool,
  required final Future<void> Function(SkillTemplateToolEntity) onDuplicateTool,
  required final Future<void> Function(SkillTemplateToolEntity) onDeleteTool,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (toolsAsync) {
    AsyncData(:final value) => _SkillToolsDataContent(
      tools: value,
      onOpenTool: onOpenTool,
      onDuplicateTool: onDuplicateTool,
      onDeleteTool: onDeleteTool,
    ),
    AsyncLoading(value: final value?, hasValue: true) =>
      _SkillToolsLoadingContent(tools: value),
    AsyncLoading() => const _SkillToolsLoadingContent(),
    AsyncError() => const _SkillToolsLoadError(),
  };
}

class const _SkillToolsLoadError() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraText(
    child: TextLocale(LocaleKeys.skills_tool_load_error),
    tint: .error,
  );
}

class const _SkillToolsDataContent({
  required final List<SkillTemplateToolEntity> tools,
  required final Future<void> Function(String) onOpenTool,
  required final Future<void> Function(SkillTemplateToolEntity) onDuplicateTool,
  required final Future<void> Function(SkillTemplateToolEntity) onDeleteTool,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (tools.isEmpty) {
      return const AuraText(child: TextLocale(LocaleKeys.skills_tool_empty));
    }

    return _SkillToolsList(
      tools: tools,
      onOpenTool: onOpenTool,
      onDuplicateTool: onDuplicateTool,
      onDeleteTool: onDeleteTool,
    );
  }
}

class const _SkillToolsLoadingContent({
  final List<SkillTemplateToolEntity>? tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tools = this.tools;

    return tools == null
        ? const Center(child: AuraSpinner())
        : AuraText(child: Text('${tools.length}'));
  }
}

class const _SkillToolsList({
  required final List<SkillTemplateToolEntity> tools,
  required final Future<void> Function(String) onOpenTool,
  required final Future<void> Function(SkillTemplateToolEntity) onDuplicateTool,
  required final Future<void> Function(SkillTemplateToolEntity) onDeleteTool,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        for (final tool in tools)
          _SkillToolTile(
            tool: tool,
            onOpen: () => onOpenTool(tool.id),
            onDuplicate: () => onDuplicateTool(tool),
            onDelete: () => onDeleteTool(tool),
          ),
      ],
    );
  }
}

class const _SkillToolTile({
  required final SkillTemplateToolEntity tool,
  required final VoidCallback onOpen,
  required final VoidCallback onDuplicate,
  required final VoidCallback onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraTile(
      child: _SkillToolInfo(tool: tool),
      onTap: onOpen,
      variant: .ghost,
      leading: const AuraIcon(Icons.link_outlined),
      trailing: _SkillToolActions(onDuplicate: onDuplicate, onDelete: onDelete),
    );
  }
}

class const _SkillToolInfo({required final SkillTemplateToolEntity tool})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        AuraText(child: Text(tool.title)),
        AuraText(child: Text(tool.slug)),
      ],
      spacing: .xs,
      crossAxisAlignment: .start,
    );
  }
}

class const _SkillToolActions({
  required final VoidCallback onDuplicate,
  required final VoidCallback onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraRow(
      children: [
        AuraIconButton(icon: Icons.copy_outlined, onPressed: onDuplicate),
        AuraIconButton(icon: Icons.delete_outline, onPressed: onDelete),
        const AuraIcon(Icons.chevron_right),
      ],
      mainAxisSize: .min,
    );
  }
}

class const _SkillToolDeleteDialog() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraConfirmDialog(
      title: const TextLocale(LocaleKeys.skills_tool_delete_title),
      message: const TextLocale(LocaleKeys.skills_tool_delete_confirm),
      confirmLabel: Text(LocaleKeys.common_delete.tr(context: context)),
      cancelLabel: Text(LocaleKeys.common_cancel.tr(context: context)),
      isDestructive: true,
    );
  }
}

class const _AppSkillToolsCard({
  required final List<AppSkillToolDefinition> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraCard(child: _AppSkillToolsContent(tools: tools));
  }
}

class const _AppSkillToolsContent({
  required final List<AppSkillToolDefinition> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        const AuraText(
          child: TextLocale(LocaleKeys.skills_tool_section_title),
          style: .heading4,
        ),
        for (final tool in tools) _AppSkillToolTile(tool: tool),
      ],
      spacing: .sm,
      crossAxisAlignment: .start,
    );
  }
}

class const _AppSkillToolTile({required final AppSkillToolDefinition tool})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraTile(
      child: _AppSkillToolInfo(tool: tool),
      variant: .ghost,
      leading: const AuraIcon(Icons.code_outlined),
    );
  }
}

class const _AppSkillToolInfo({required final AppSkillToolDefinition tool})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _AppSkillToolTitle(tool: tool),
      _AppSkillToolBadge(slug: tool.slug),
      _AppSkillToolDescription(tool: tool),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}

class const _AppSkillToolBadge({required final String slug})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraBadge.text(
    child: Text(
      slug,
      style: .new(fontFamily: context.auraTheme.typography.monoFontFamily),
    ),
    variant: .outlined,
    size: .small,
  );
}

class const _AppSkillToolTitle({required final AppSkillToolDefinition tool})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraText(
      child: switch (tool.titleKey) {
        null => Text(tool.title),
        final titleKey => TextLocale(titleKey),
      },
    );
  }
}

class const _AppSkillToolDescription({
  required final AppSkillToolDefinition tool,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraText(
      child: switch (tool.descriptionKey) {
        null => Text(tool.description),
        final descriptionKey => TextLocale(descriptionKey),
      },
    );
  }
}

class const _CredentialDefinitionSelector({
  required final String workspaceId,
  required final String? value,
  required final ValueChanged<String?> onChanged,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definitionsAsync = ref.watch(
      skillCredentialDefinitionsProvider(workspaceId),
    );

    return _CredentialDefinitionSelectorResult(
      definitionsAsync: definitionsAsync,
      value: value,
      onChanged: onChanged,
    );
  }
}

class const _CredentialDefinitionSelectorResult({
  required final AsyncValue<List<SkillCredentialDefinitionEntity>>
  definitionsAsync,
  required final String? value,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return switch (definitionsAsync) {
      AsyncData(:final value) => _CredentialDefinitionSelectContent(
        definitions: value,
        value: this.value,
        onChanged: onChanged,
      ),
      AsyncLoading() => const AuraSpinner(size: .small),
      AsyncError() => const AuraText(
        child: TextLocale(LocaleKeys.skill_credentials_definitions_error),
        tint: .error,
      ),
    };
  }
}

class const _CredentialDefinitionSelectContent({
  required final List<SkillCredentialDefinitionEntity> definitions,
  required final String? value,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _CredentialDefinitionSelectView(
      definitions: definitions,
      value: value,
      onChanged: onChanged,
    );
  }
}

class const _CredentialDefinitionSelectView({
  required final List<SkillCredentialDefinitionEntity> definitions,
  required final String? value,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selection = _credentialDefinitionSelection(definitions, value);

    return _CredentialDefinitionSelectLayout(
      definitions: definitions,
      value: selection.value,
      hasMissingDefinition: selection.hasMissingDefinition,
      onChanged: onChanged,
    );
  }
}

class const _CredentialDefinitionSelection({
  required final String value,
  required final bool hasMissingDefinition,
});

_CredentialDefinitionSelection _credentialDefinitionSelection(
  List<SkillCredentialDefinitionEntity> definitions,
  String? value,
) {
  String? selectedValue;
  if (value != null &&
      definitions.any((definition) => definition.id == value)) {
    selectedValue = value;
  }

  return _CredentialDefinitionSelection(
    value: selectedValue ?? '',
    hasMissingDefinition: value != null && selectedValue == null,
  );
}

class const _CredentialDefinitionSelectLayout({
  required final List<SkillCredentialDefinitionEntity> definitions,
  required final String value,
  required final bool hasMissingDefinition,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _CredentialDefinitionDropdown(
        definitions: definitions,
        value: value,
        onChanged: onChanged,
      ),
      if (hasMissingDefinition) const _MissingCredentialDefinition(),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}

class const _MissingCredentialDefinition() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraText(
    child: TextLocale(LocaleKeys.skill_credentials_definitions_not_found),
    tint: .error,
  );
}

class const _CredentialDefinitionDropdown({
  required final List<SkillCredentialDefinitionEntity> definitions,
  required final String value,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  static const _noneValue = '';

  @override
  Widget build(BuildContext context) {
    final optionData = _CredentialDefinitionDropdownOptions(definitions);

    return AuraDropdownSelector<String>(
      options: optionData.values,
      value: value,
      onChanged: _handleChanged,
      label: const TextLocale(LocaleKeys.skill_credentials_definition_label),
    );
  }

  void _handleChanged(String? value) {
    onChanged(value == _noneValue ? null : value);
  }
}

class _CredentialDefinitionDropdownOptions {
  static const _noneValue = '';

  new(this.definitions)
    : values = [
        const AuraDropdownOption<String>(
          value: _noneValue,
          child: TextLocale(LocaleKeys.skill_credentials_none),
        ),
        for (final definition in definitions)
          AuraDropdownOption<String>(
            value: definition.id,
            child: Text(definition.title),
          ),
      ];

  final List<SkillCredentialDefinitionEntity> definitions;
  final List<AuraDropdownOption<String>> values;
}

enum _CredentialHintKind { empty, loaded, loading, error }

class const _CredentialHintViewData({
  required final _CredentialHintKind kind,
  final List<SkillCredentialEntity> credentials = const [],
});

_CredentialHintViewData _credentialHintViewData(
  AsyncValue<SkillCredentialDefinitionEntity?> definitionAsync,
  AsyncValue<List<SkillCredentialEntity>> credentialsAsync,
) {
  if (definitionAsync case AsyncData(value: null)) {
    return const _CredentialHintViewData(kind: .empty);
  }

  if (definitionAsync case AsyncData()) {
    return _credentialHintForLoadedDefinition(credentialsAsync);
  }

  return _credentialHintForPendingDefinition(credentialsAsync);
}

_CredentialHintViewData _credentialHintForLoadedDefinition(
  AsyncValue<List<SkillCredentialEntity>> credentialsAsync,
) => switch (credentialsAsync) {
  AsyncData(:final value) => _CredentialHintViewData(
    kind: .loaded,
    credentials: value,
  ),
  AsyncLoading() => const _CredentialHintViewData(kind: .loading),
  AsyncError() => const _CredentialHintViewData(kind: .error),
};

_CredentialHintViewData _credentialHintForPendingDefinition(
  AsyncValue<List<SkillCredentialEntity>> credentialsAsync,
) => switch (credentialsAsync) {
  AsyncLoading() => const _CredentialHintViewData(kind: .loading),
  AsyncData() || AsyncError() => const _CredentialHintViewData(kind: .error),
};

class const _SkillCredentialsHint({
  required final String workspaceId,
  required final String credentialDefinitionId,
  required final bool isCredentialOptional,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _SkillCredentialsHintResult(
        data: .new(
          ref: ref,
          workspaceId: workspaceId,
          credentialDefinitionId: credentialDefinitionId,
        ),
        isCredentialOptional: isCredentialOptional,
        onCreateCredential: () => _openCredentialCreate(context),
      );

  Future<void> _openCredentialCreate(BuildContext context) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final result = await _pushCredentialCreate(context);
    if (!context.mounted || result != true) return;

    _scheduleCredentialRefresh(container, workspaceId, credentialDefinitionId);
  }

  Future<bool?> _pushCredentialCreate(BuildContext context) {
    return ServiceConnectionCreateRoute(
      workspaceId: workspaceId,
      type: 'skillCredential',
      credentialDefinitionId: credentialDefinitionId,
    ).push<bool>(context);
  }

  void _scheduleCredentialRefresh(
    ProviderContainer container,
    String workspaceId,
    String credentialDefinitionId,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        _refreshCredentialAfterFrame(
          container,
          workspaceId,
          credentialDefinitionId,
        ),
      );
    });
  }

  Future<void> _refreshCredentialAfterFrame(
    ProviderContainer container,
    String workspaceId,
    String credentialDefinitionId,
  ) async {
    await container.pump();
    container.invalidate(
      skillCredentialsForDefinitionProvider(
        workspaceId,
        credentialDefinitionId,
      ),
    );
  }
}

class _SkillCredentialsHintData {
  new({
    required WidgetRef ref,
    required String workspaceId,
    required String credentialDefinitionId,
  }) : definitionAsync = ref.watch(
         skillCredentialDefinitionProvider(workspaceId, credentialDefinitionId),
       ),
       credentialsAsync = ref.watch(
         skillCredentialsForDefinitionProvider(
           workspaceId,
           credentialDefinitionId,
         ),
       ) {
    viewData = _credentialHintViewData(definitionAsync, credentialsAsync);
  }

  final AsyncValue<SkillCredentialDefinitionEntity?> definitionAsync;
  final AsyncValue<List<SkillCredentialEntity>> credentialsAsync;
  _CredentialHintViewData viewData = const _CredentialHintViewData(
    kind: .error,
  );
}

class const _SkillCredentialsHintResult({
  required final _SkillCredentialsHintData data,
  required final bool isCredentialOptional,
  required final VoidCallback onCreateCredential,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (data.viewData) {
    _CredentialHintViewData(kind: .empty) => const SizedBox.shrink(),
    _CredentialHintViewData(kind: .loaded, :final credentials) =>
      _CredentialHintLoaded(
        credentials: credentials,
        isCredentialOptional: isCredentialOptional,
        onCreateCredential: onCreateCredential,
      ),
    _CredentialHintViewData(kind: .loading) => const AuraSpinner(size: .small),
    _CredentialHintViewData(kind: .error) => const _CredentialHintError(),
  };
}

class const _CredentialHintError() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraText(
    child: TextLocale(LocaleKeys.skill_credentials_load_error),
    tint: .error,
  );
}

class const _CredentialHintLoaded({
  required final List<SkillCredentialEntity> credentials,
  required final bool isCredentialOptional,
  required final VoidCallback onCreateCredential,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _LoadedCredentialsHint(
    credentials: credentials,
    isCredentialOptional: isCredentialOptional,
    onCreateCredential: onCreateCredential,
  );
}

class const _AppSkillCredentialsHint({
  required final String workspaceId,
  required final String appSkillId,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AppSkillCredentialsHint> createState() =>
      _AppSkillCredentialsHintState();
}

class _AppSkillCredentialsHintState
    extends ConsumerState<_AppSkillCredentialsHint> {
  Future<List<AppSkillCredentialCandidate>> _future = .value(const []);

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(_AppSkillCredentialsHint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId == widget.workspaceId &&
        oldWidget.appSkillId == widget.appSkillId) {
      return;
    }
    _future = _load();
  }

  @override
  Widget build(BuildContext context) {
    return _AppSkillCredentialsHintFuture(
      future: _future,
      onCreateCredential: () => _openCredentialCreate(context),
    );
  }

  Future<List<AppSkillCredentialCandidate>> _load() async {
    final appSkill = ref
        .read(appSkillRegistryProvider)
        .getByIdentifier(widget.appSkillId);
    if (appSkill == null) return const [];

    return await ref
        .read(listAppSkillCredentialCandidatesUsecaseProvider)
        .call(workspaceId: widget.workspaceId, skill: appSkill);
  }

  Future<void> _openCredentialCreate(BuildContext context) async {
    final result = await _pushCredentialCreate(context);
    if (!mounted || result != true) return;
    setState(() {
      _future = _load();
    });
  }

  Future<bool?> _pushCredentialCreate(BuildContext context) {
    final appSkill = ref
        .read(appSkillRegistryProvider)
        .getByIdentifier(widget.appSkillId);
    if (appSkill == null) return .value(null);
    if (appSkill.compatibleModelProviderIds.isNotEmpty) {
      return _pushModelProviderCreate(context);
    }

    return _pushAppSkillCredentialCreate(context);
  }

  Future<bool?> _pushModelProviderCreate(BuildContext context) {
    return ServiceConnectionCreateRoute(
      workspaceId: widget.workspaceId,
      type: 'modelProvider',
    ).push<bool>(context);
  }

  Future<bool?> _pushAppSkillCredentialCreate(BuildContext context) {
    return context.push<bool>(
      '/workspaces/${widget.workspaceId}/more/service-connections/new'
      '?type=appSkillCredential&appSkillId=${widget.appSkillId}',
    );
  }
}

class const _AppSkillCredentialsHintFuture({
  required final Future<List<AppSkillCredentialCandidate>> future,
  required final VoidCallback onCreateCredential,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppSkillCredentialCandidate>>(
      future: future,
      builder: (context, snapshot) => _AppSkillCredentialsHintResult(
        snapshot: snapshot,
        onCreateCredential: onCreateCredential,
      ),
    );
  }
}

class const _AppSkillCredentialsHintResult({
  required final AsyncSnapshot<List<AppSkillCredentialCandidate>> snapshot,
  required final VoidCallback onCreateCredential,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError || snapshot.data?.isEmpty == true) {
      return _MissingCredentialHint(
        isCredentialOptional: false,
        onCreateCredential: onCreateCredential,
      );
    }

    final credentials = snapshot.data;
    if (credentials == null) return const AuraSpinner(size: .small);

    return _ConfiguredCredentialsCount(count: credentials.length);
  }
}

class const _ConfiguredCredentialsCount({required final int count})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraText(
      child: Text(
        LocaleKeys.skill_credentials_configured_count.plural(
          count,
          args: ['$count'],
          context: context,
        ),
      ),
    );
  }
}

class const _LoadedCredentialsHint({
  required final List<SkillCredentialEntity> credentials,
  required final bool isCredentialOptional,
  required final VoidCallback onCreateCredential,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (credentials.isEmpty) {
      return _MissingCredentialHint(
        isCredentialOptional: isCredentialOptional,
        onCreateCredential: onCreateCredential,
      );
    }

    return _ConfiguredCredentialsCount(count: credentials.length);
  }
}

class const _MissingCredentialHint({
  required final bool isCredentialOptional,
  required final VoidCallback onCreateCredential,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _CredentialHintMessage(isOptional: isCredentialOptional)),
      AuraButton(
        onPressed: onCreateCredential,
        child: const TextLocale(LocaleKeys.skill_credentials_add_title),
        size: .small,
      ),
    ],
  );
}

class const _CredentialHintMessage({required final bool isOptional})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hintKey = isOptional
        ? LocaleKeys.skill_credentials_optional_missing_hint
        : LocaleKeys.skill_credentials_missing_hint;

    return AuraText(
      child: TextLocale(hintKey),
      tint: isOptional ? null : AuraTint.error,
    );
  }
}

class const _ReadOnlyField({
  required final String labelKey,
  required final String value,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        AuraText(child: TextLocale(labelKey)),
        AuraSelectableText(value),
      ],
      spacing: .xs,
      crossAxisAlignment: .start,
    );
  }
}
