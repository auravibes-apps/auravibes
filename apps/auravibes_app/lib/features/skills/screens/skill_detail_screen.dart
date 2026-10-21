// Required: Existing UI spacing uses small numeric values.
// Required: Form callbacks stay local to this screen.

import 'dart:async';

import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_resource_entity.dart';
import 'package:auravibes_app/features/markdown/markdown_editor_launcher.dart';
import 'package:auravibes_app/features/markdown/widgets/markdown_preview_field.dart';
import 'package:auravibes_app/features/skills/models/skill_detail.dart';
import 'package:auravibes_app/features/skills/providers/skill_detail_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_resources_provider.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/skills/usecases/clone_app_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/delete_cloud_routed_skill_usecases.dart';
import 'package:auravibes_app/features/skills/usecases/duplicate_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_usecase.dart';
import 'package:auravibes_app/features/skills/widgets/connector_tool_reference_picker.dart';
import 'package:auravibes_app/features/skills/widgets/skill_access_status_view.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/app_screen.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/bottom_padding.dart';
import 'package:auravibes_app/widgets/draft_exit_scope.dart';
import 'package:auravibes_app/widgets/feature_destinations.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show AppSkillResourceDefinition;
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:textf/textf.dart';

const _skillDescriptionMaxCharacters = 1024;

typedef _SkillDetailFormValues = ({
  String title,
  String description,
  String content,
  String connectorToolIds,
  bool isEnabled,
});

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
  Set<String> _connectorToolIds = {};
  bool _isEnabled = true;
  bool _initialized = false;
  final _exitGuard = DraftExitGuard();
  bool _isSaving = false;
  bool _isDirty = false;
  bool _isUserSkill = false;
  String? _createdSkillId;
  _SkillDetailFormValues _savedFormValues = (
    title: '',
    description: '',
    content: '',
    connectorToolIds: '',
    isEnabled: true,
  );

  @override
  void initState() {
    super.initState();
    _initialized = widget.skillId == null;
    _titleController.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _exitGuard.bind(
      readers: (isDirty: () => _isDirty, isSaving: () => _isSaving),
      callbacks: .new(
        confirm: _confirmDiscard,
        onReturn: (context) =>
            SkillsRoute(workspaceId: widget.workspaceId).go(context),
      ),
    );

    return DraftExitScope(
      guard: _exitGuard,
      child: _SkillDetailScreenContent(state: this),
    );
  }

  void _onTitleChanged() {
    if (!_initialized) return;

    setState(() {
      _isDirty = _isEditable && _currentFormValues() != _savedFormValues;
    });
  }

  void _updateState(VoidCallback callback) {
    setState(() {
      callback();
      _isDirty = _isEditable && _currentFormValues() != _savedFormValues;
    });
  }
}

extension on _SkillDetailScreenState {
  bool get _isCreate => widget.skillId == null;

  bool get _isEditable => _isCreate || _isUserSkill;

  _SkillDetailFormValues _currentFormValues() => (
    title: _titleController.text,
    description: _descriptionController.text,
    content: _contentController.text,
    connectorToolIds: (_connectorToolIds.toList()..sort()).join('\n'),
    isEnabled: _isEnabled,
  );

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
      options: (
        initialMarkdown: _descriptionController.text,
        maxCharacters: _skillDescriptionMaxCharacters,
        titleKey: LocaleKeys.markdown_editor_skill_description,
        draftHintKey: LocaleKeys.markdown_editor_skill_hint,
      ),
    );
    if (result == null || !mounted) return;

    _updateState(() => _descriptionController.text = result);
  }

  Future<void> _editContent(BuildContext context) async {
    final result = await MarkdownEditorLauncher.show(
      context,
      options: (
        initialMarkdown: _contentController.text,
        maxCharacters: null,
        titleKey: LocaleKeys.markdown_editor_skill_instructions,
        draftHintKey: LocaleKeys.markdown_editor_skill_hint,
      ),
    );
    if (result == null || !mounted) return;

    _updateState(() => _contentController.text = result);
  }

  void _setConnectorToolIds(Set<String> value) {
    _updateState(() => _connectorToolIds = .of(value));
  }

  void _setEnabled(bool value) {
    _updateState(() => _isEnabled = value);
  }

  void _initializeForm(BuildContext context, SkillDetail detail) {
    if (_initialized) return;

    _isUserSkill = detail.isUserSkill;
    _initializeTextFields(context, detail);
    _connectorToolIds = detail.connectorToolIds.toSet();
    _isEnabled = detail.isEnabled;
    _savedFormValues = _currentFormValues();
    _isDirty = false;
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
  Future<void> _handleBack(BuildContext context) => _exitGuard.pop(context);

  Future<bool?> _confirmDiscard(BuildContext context) => AuraDialogs.confirm(
    context: context,
    title: const TextLocale(LocaleKeys.skills_screen_unsaved_changes_title),
    message: const TextLocale(LocaleKeys.skills_screen_unsaved_changes_message),
    actions: const AuraConfirmDialogActions(
      confirmLabel: TextLocale(LocaleKeys.skills_screen_discard_changes),
      cancelLabel: TextLocale(LocaleKeys.skills_screen_continue),
    ),
    isDestructive: true,
  );

  Future<void> _save(BuildContext context, {bool configure = false}) async {
    if (_isSaving) return;
    _updateState(() => _isSaving = true);
    final didSave = await _trySave(context);

    if (!didSave || !context.mounted) return;
    _navigateAfterSave(context, configure: configure);
  }

  Future<bool> _trySave(BuildContext context) async {
    try {
      await _saveSkill();
      _savedFormValues = _currentFormValues();

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
      await _saveCreatedSkill();

      return;
    }

    await _saveExistingSkill();
  }

  Future<void> _saveCreatedSkill() async {
    final createdId = _createdSkillId;
    if (createdId == null) {
      final created = await _createSkill();
      _createdSkillId = created.id;
    } else {
      await _updateSkill(createdId);
    }
    ref.invalidate(workspaceSkillsProvider(widget.workspaceId));
  }

  Future<void> _saveExistingSkill() async {
    final skillId = widget.skillId;
    if (skillId == null) return;
    await _updateSkill(skillId);
    ref.invalidate(skillDetailProvider(widget.workspaceId, skillId));
  }

  Future<SkillEntity> _createSkill() async {
    final usecase = ref.read(createSkillUsecaseProvider(widget.workspaceId));

    return await usecase.call(widget.workspaceId, _createSkillValue());
  }

  SkillToCreate _createSkillValue() => .new(
    kind: SkillKind.template,
    title: _titleController.text,
    description: _descriptionController.text,
    content: _contentController.text,
    connectorToolIds: (_connectorToolIds.toList()..sort()),
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
    connectorToolIds: (_connectorToolIds.toList()..sort()),
    isEnabled: _isEnabled,
  );

  void _navigateAfterSave(BuildContext context, {required bool configure}) {
    try {
      final createdId = _createdSkillId;
      if (configure && createdId != null) {
        SkillDetailRoute(
          workspaceId: widget.workspaceId,
          skillId: createdId,
        ).replace(context);

        return;
      }
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

    context.go('/workspaces/${widget.workspaceId}/skills');
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

  Future<void> _cloneAppSkill(BuildContext context, SkillDetail detail) async {
    _updateState(() => _isSaving = true);
    try {
      final _ = await _cloneAppSkillWithUsecase(detail.slug);
      if (!context.mounted) return;

      _finishDuplicate(context);
    } on Object {
      if (context.mounted) _showSaveError(context);
    } finally {
      if (mounted) _updateState(() => _isSaving = false);
    }
  }

  Future<SkillEntity> _cloneAppSkillWithUsecase(String slug) => ref
      .read(cloneAppSkillUsecaseProvider(widget.workspaceId))
      .call(widget.workspaceId, slug);

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
    FocusManager.instance.primaryFocus?.unfocus();

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

class const _SkillDetailScreenContent({
  required final _SkillDetailScreenState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewData = state._detailViewData();

    return AppScreen(
      child: _SkillDetailBody(state: state, detailAsync: viewData.detailAsync),
      appBar: _SkillDetailAppBar(
        state: state,
        currentDetail: viewData.currentDetail,
        userSkillDetail: viewData.userSkillDetail,
      ),
    );
  }
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
          if (request.currentDetail case final detail?
              when !detail.isUserSkill && detail.kind == SkillKind.template)
            _SkillDetailCloneButton(state: request.state, detail: detail),
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

    return AuraAppBarWithDrawer(
      title: _SkillDetailAppBarTitle(isCreate: isCreate),
      actions: _SkillDetailAppBarActions((
        state: state,
        isCreate: isCreate,
        currentDetail: currentDetail,
        userSkillDetail: userSkillDetail,
      )).values,
      leading: _SkillDetailBackButton(state: state),
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

class const _SkillDetailCloneButton({
  required final _SkillDetailScreenState state,
  required final SkillDetail detail,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: Icons.copy_all_outlined,
      onPressed: state._isSaving
          ? null
          : () => state._cloneAppSkill(context, detail),
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

class const _SkillDetailBackButton({
  required final _SkillDetailScreenState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: Icons.arrow_back,
      onPressed: () => state._handleBack(context),
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
  static const _contentPadding = 12.0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(
        _contentPadding,
      ).copyWith(bottom: BottomPadding.of(context, minimum: _contentPadding)),
      children: _SkillDetailFormSections(state: state, detail: detail).values,
      keyboardDismissBehavior: .onDrag,
    );
  }
}

class _SkillDetailFormSections {
  new({required _SkillDetailScreenState state, required SkillDetail? detail})
    : values = [
        _SkillDetailFormStatus(state: state, detail: detail),
        if (detail case final savedDetail?)
          _SkillDetailAccessCard(state: state, detail: savedDetail),
        _SkillDetailFieldsCard(state: state, detail: detail),
        _SkillDetailRelatedContent(
          workspaceId: state.widget.workspaceId,
          detail: detail,
        ),
      ];

  final List<Widget> values;
}

class const _SkillDetailFormStatus({
  required final _SkillDetailScreenState state,
  required final SkillDetail? detail,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      TextLocale(
        detail != null && !state._isDirty
            ? LocaleKeys.authoring_saved
            : LocaleKeys.authoring_draft,
      ),
      TextLocale(
        state._isEnabled
            ? LocaleKeys.authoring_enabled
            : LocaleKeys.authoring_disabled,
      ),
      if (detail != null)
        const TextLocale(LocaleKeys.skill_access_saved_configuration),
    ],
  );
}

class const _SkillDetailAccessCard({
  required final _SkillDetailScreenState state,
  required final SkillDetail detail,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCard(
    child: SkillAccessStatusView(
      workspaceId: state.widget.workspaceId,
      skillId: detail.id,
      showDependencies: true,
      isAppSkill: !detail.isUserSkill,
    ),
  );
}

class const _SkillDetailFieldsCard({
  required final _SkillDetailScreenState state,
  required final SkillDetail? detail,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCard(
    child: _SkillDetailFormFields(state: state, detail: detail),
  );
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
         if (detail == null || detail.isUserSkill)
           ConnectorToolReferencePicker(
             selectedToolIds: state._connectorToolIds,
             onChanged: state._setConnectorToolIds,
           ),
         _SkillEnabledField(
           value: state._isEnabled,
           onChanged: detail == null || detail.isUserSkill
               ? state._setEnabled
               : null,
           disabled: detail != null && !detail.isUserSkill,
         ),
         if (detail == null)
           AuraButton(
             onPressed: () => state._save(context, configure: true),
             child: const TextLocale(LocaleKeys.skills_screen_create_configure),
             variant: .outlined,
             disabled: state._isSaving,
           ),
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
           textInputAction: detail == null || detail.isUserSkill ? .done : null,
           enabled: detail == null || detail.isUserSkill,
           onSubmitted:
               (detail == null || detail.isUserSkill) && !state._isSaving
               ? (_) => state._save(context)
               : null,
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
    final children = <Widget>[];
    _addBaseChildren(children, context);
    _addRelatedSections(children, detail);

    return Column(children: children);
  }

  void _addBaseChildren(List<Widget> children, BuildContext context) {
    if (detail == null) children.add(_creationStagesCard());
    children.add(_agentsButton(context));
  }

  Widget _creationStagesCard() => const AuraCard(
    child: AuraColumn(
      children: [
        TextLocale(LocaleKeys.skills_screen_create_stage),
        TextLocale(LocaleKeys.skills_screen_create_resources),
      ],
      spacing: .sm,
      crossAxisAlignment: .start,
    ),
  );

  Widget _agentsButton(BuildContext context) => AuraButton(
    onPressed: () => unawaited(
      FeatureDestinations.push<void>(
        context,
        AgentsRoute(workspaceId: workspaceId).location,
      ),
    ),
    child: const TextLocale(LocaleKeys.related_lists_workspace_agents),
    variant: .text,
  );

  void _addRelatedSections(List<Widget> children, SkillDetail? detail) {
    _addSkillResources(children, detail);
  }

  void _addSkillResources(List<Widget> children, SkillDetail? detail) {
    if (detail == null) return;
    if (!detail.isUserSkill && detail.appResources.isEmpty) return;
    children
      ..add(const SizedBox(height: 12))
      ..add(_SkillResourcesCard(workspaceId: workspaceId, detail: detail));
  }
}

class const _SkillResourcesCard({
  required final String workspaceId,
  required final SkillDetail detail,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (detail.isUserSkill) {
      return _SkillResourcesUserCard(
        workspaceId: workspaceId,
        skillId: detail.id,
      );
    }

    return _SkillResourcesAppCard(
      workspaceId: workspaceId,
      skillId: detail.id,
      resources: detail.appResources,
    );
  }
}

class const _SkillResourcesUserCard({
  required final String workspaceId,
  required final String skillId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(
      skillResourcesProvider(workspaceId, skillId),
    );
    final actions = _SkillResourcesActions(
      context: context,
      ref: ref,
      workspaceId: workspaceId,
      skillId: skillId,
    );

    return AuraCard(
      child: _SkillResourcesUserContent(
        resourcesAsync: resourcesAsync,
        onCreate: actions.create,
        onOpen: actions.open,
      ),
    );
  }
}

class const _SkillResourcesAppCard({
  required final String workspaceId,
  required final String skillId,
  required final List<AppSkillResourceDefinition> resources,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCard(
    child: _SkillResourcesAppContent(
      workspaceId: workspaceId,
      skillId: skillId,
      resources: resources,
    ),
  );
}

class _SkillResourcesActions {
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

  void create() => unawaited(_open());

  Future<void> open(String resourceId) => _open(resourceId);

  Future<void> _open([String? resourceId]) async {
    final result = await context.push<bool>(
      '/workspaces/$workspaceId/skills/$skillId/resources/'
      '${resourceId ?? 'new'}',
    );
    if (result == true && context.mounted) {
      ref.invalidate(skillResourcesProvider(workspaceId, skillId));
      final _ = AuraSnackBars.show(
        context: context,
        content: const TextLocale(LocaleKeys.skills_resource_saved),
      );
    }
  }
}

class const _SkillResourcesUserContent({
  required final AsyncValue<List<SkillResourceEntity>> resourcesAsync,
  required final VoidCallback onCreate,
  required final Future<void> Function(String) onOpen,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _SkillResourcesHeader(onCreate: onCreate),
      switch (resourcesAsync) {
        AsyncData(:final value) => _SkillResourcesDataContent(
          resources: value,
          onOpen: onOpen,
        ),
        AsyncLoading() => const Center(child: AuraSpinner(size: .small)),
        AsyncError() => const AuraText(
          child: TextLocale(LocaleKeys.skills_resource_load_error),
          tint: .error,
        ),
      },
    ],
    spacing: .sm,
    crossAxisAlignment: .start,
  );
}

class const _SkillResourcesHeader({required final VoidCallback onCreate})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(
        child: AuraText(
          child: TextLocale(LocaleKeys.skills_resource_section_title),
          style: .heading4,
        ),
      ),
      AuraIconButton(
        icon: Icons.add,
        onPressed: onCreate,
        tooltip: LocaleKeys.skills_resource_create_title.tr(context: context),
      ),
    ],
  );
}

class const _SkillResourcesDataContent({
  required final List<SkillResourceEntity> resources,
  required final Future<void> Function(String) onOpen,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (resources.isEmpty) {
      return const AuraText(
        child: TextLocale(LocaleKeys.skills_resource_empty),
      );
    }

    return AuraColumn(
      children: [
        for (final resource in resources)
          _SkillResourceTile(
            title: resource.title,
            slug: resource.slug,
            description: resource.description,
            onOpen: () => unawaited(onOpen(resource.id)),
          ),
      ],
      crossAxisAlignment: .start,
    );
  }
}

class const _SkillResourcesAppContent({
  required final String workspaceId,
  required final String skillId,
  required final List<AppSkillResourceDefinition> resources,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const _SkillResourcesAppHeader(),
      _SkillResourcesAppList(
        workspaceId: workspaceId,
        skillId: skillId,
        resources: resources,
      ),
    ],
    spacing: .sm,
    crossAxisAlignment: .start,
  );
}

class const _SkillResourcesAppHeader() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraText(
    child: TextLocale(LocaleKeys.skills_resource_section_title),
    style: .heading4,
  );
}

class const _SkillResourcesAppList({
  required final String workspaceId,
  required final String skillId,
  required final List<AppSkillResourceDefinition> resources,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      for (final resource in resources)
        _SkillResourcesAppTile(
          workspaceId: workspaceId,
          skillId: skillId,
          resource: resource,
        ),
    ],
    spacing: .sm,
    crossAxisAlignment: .start,
  );
}

class const _SkillResourcesAppTile({
  required final String workspaceId,
  required final String skillId,
  required final AppSkillResourceDefinition resource,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SkillResourceTile(
    title: resource.title,
    slug: resource.slug,
    description: resource.description,
    onOpen: () => unawaited(
      context.push<bool>(
        '/workspaces/$workspaceId/skills/$skillId/resources/'
        '${resource.slug}',
      ),
    ),
  );
}

class const _SkillResourceTile({
  required final String title,
  required final String slug,
  required final String description,
  required final VoidCallback onOpen,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraTile(
    child: _SkillResourceTileContent(
      title: title,
      slug: slug,
      description: description,
    ),
    onTap: onOpen,
    variant: .ghost,
    leading: const AuraIcon(Icons.menu_book_outlined),
    trailing: const AuraIcon(Icons.chevron_right),
  );
}

class const _SkillResourceTileContent({
  required final String title,
  required final String slug,
  required final String description,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      AuraText(child: Text(title)),
      _SkillResourceSlugBadge(slug: slug),
      if (description.trim().isNotEmpty) AuraText(child: Text(description)),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}

class const _SkillResourceSlugBadge({required final String slug})
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
