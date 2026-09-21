import 'package:auravibes_app/domain/entities/skill_resource_entity.dart';
import 'package:auravibes_app/features/markdown/markdown_editor_launcher.dart';
import 'package:auravibes_app/features/markdown/widgets/markdown_preview_field.dart';
import 'package:auravibes_app/features/skills/models/skill_detail.dart';
import 'package:auravibes_app/features/skills/providers/skill_detail_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_resources_provider.dart';
import 'package:auravibes_app/features/skills/usecases/resolved_skill_resource.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show AppSkillResourceDefinition;
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const _skillResourceContentMaxCharacters = 50000;

typedef _SkillResourceViewData = ({
  AsyncValue<SkillResourceEntity?>? resourceAsync,
  SkillResourceEntity? resource,
  AppSkillResourceDefinition? staticResource,
});

class const SkillResourceEditScreen({
  required final String workspaceId,
  required final String skillId,
  final String? resourceId,
  super.key,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<SkillResourceEditScreen> createState() =>
      _SkillResourceEditScreenState();
}

class _SkillResourceEditScreenState
    extends ConsumerState<SkillResourceEditScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  bool _initialized = false;
  bool _isSaving = false;

  bool get _isCreate => widget.resourceId == null;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      skillDetailProvider(widget.workspaceId, widget.skillId),
    );
    final viewData = _viewData(detailAsync.value);
    _initialize(viewData.resource, viewData.staticResource);

    return _SkillResourceScreenView(
      state: this,
      viewData: viewData,
      titleKey: _titleKey(viewData.staticResource),
    );
  }

  _SkillResourceViewData _viewData(SkillDetail? detail) {
    final resourceId = widget.resourceId;
    final resourceAsync = resourceId == null
        ? null
        : ref.watch(skillResourceProvider(widget.workspaceId, resourceId));

    return (
      resourceAsync: resourceAsync,
      resource: resourceAsync?.value,
      staticResource: _staticResource(detail),
    );
  }

  String _titleKey(AppSkillResourceDefinition? staticResource) {
    if (_isCreate) return LocaleKeys.skills_resource_create_title;
    if (staticResource != null) return LocaleKeys.skills_resource_view_title;

    return LocaleKeys.skills_resource_edit_title;
  }

  AppSkillResourceDefinition? _staticResource(SkillDetail? detail) {
    final resourceId = widget.resourceId;
    if (resourceId == null || detail == null || detail.isUserSkill) return null;

    return detail.appResources
        .where((resource) => resource.slug == resourceId)
        .firstOrNull;
  }

  void _initialize(
    SkillResourceEntity? resource,
    AppSkillResourceDefinition? staticResource,
  ) {
    if (_initialized) return;
    if (!_isCreate && resource == null && staticResource == null) return;

    if (resource case final value?) {
      _setFieldValues(value.title, value.description, value.content);
    } else if (staticResource case final value?) {
      _setFieldValues(value.title, value.description, value.content);
    }
    _initialized = true;
  }

  void _setFieldValues(String title, String description, String content) {
    _titleController.text = title;
    _descriptionController.text = description;
    _contentController.text = content;
  }

  void _updateState(VoidCallback callback) => setState(callback);
}

class const _SkillResourceScreenView({
  required final _SkillResourceEditScreenState state,
  required final _SkillResourceViewData viewData,
  required final String titleKey,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraScreen(
    child: _SkillResourceBody(
      state: state,
      resourceAsync: viewData.resourceAsync,
      resource: viewData.resource,
      staticResource: viewData.staticResource,
    ),
    appBar: AuraAppBarWithDrawer(title: TextLocale(titleKey)),
  );
}

extension on _SkillResourceEditScreenState {
  Future<void> _editDescription(BuildContext context) async {
    final result = await MarkdownEditorLauncher.show(
      context,
      initialMarkdown: _descriptionController.text,
      maxCharacters: 240,
    );
    if (result == null || !mounted) return;

    _updateState(() => _descriptionController.text = result);
  }

  Future<void> _editContent(BuildContext context) async {
    final result = await MarkdownEditorLauncher.show(
      context,
      initialMarkdown: _contentController.text,
      maxCharacters: _skillResourceContentMaxCharacters,
    );
    if (result == null || !mounted) return;

    _updateState(() => _contentController.text = result);
  }

  Future<void> _save(BuildContext context) async {
    if (_isSaving) return;
    _updateState(() => _isSaving = true);
    try {
      await _saveResource();
      ref.invalidate(
        skillResourcesProvider(widget.workspaceId, widget.skillId),
      );
      if (context.mounted) context.pop(true);
    } on Object {
      if (context.mounted) _showSaveError(context);
    } finally {
      if (mounted) _updateState(() => _isSaving = false);
    }
  }

  Future<void> _saveResource() async {
    if (_isCreate) {
      final _ = await ref.read(
        createSkillResourceUsecaseProvider(widget.workspaceId),
      )(widget.skillId, _createValue());

      return;
    }
    final resourceId = widget.resourceId;
    if (resourceId == null) return;
    final _ = await ref.read(
      updateSkillResourceUsecaseProvider(widget.workspaceId),
    )(resourceId, _updateValue());
  }

  SkillResourceToCreate _createValue() => SkillResourceToCreate(
    title: _titleController.text,
    description: _descriptionController.text,
    content: _contentController.text,
  );

  SkillResourceToUpdate _updateValue() => SkillResourceToUpdate(
    title: _titleController.text,
    description: _descriptionController.text,
    content: _contentController.text,
  );

  Future<void> _delete(BuildContext context) async {
    final resourceId = widget.resourceId;
    if (resourceId == null) return;
    if (!await _confirmDelete(context) || !context.mounted) return;

    _updateState(() => _isSaving = true);
    await _performDelete(context, resourceId);
  }

  Future<void> _performDelete(BuildContext context, String resourceId) async {
    try {
      final _ = await ref.read(deleteSkillResourceProvider(widget.workspaceId))(
        resourceId,
      );
      ref.invalidate(
        skillResourcesProvider(widget.workspaceId, widget.skillId),
      );
      if (context.mounted) context.pop(true);
    } on Object {
      if (context.mounted) _showSaveError(context);
    } finally {
      if (mounted) _updateState(() => _isSaving = false);
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const _SkillResourceDeleteDialog(),
    );

    return result == true;
  }

  void _showSaveError(BuildContext context) {
    final _ = AuraSnackBars.show(
      context: context,
      content: Text(LocaleKeys.skills_resource_save_error.tr(context: context)),
      variant: .error,
    );
  }
}

class const _SkillResourceBody({
  required final _SkillResourceEditScreenState state,
  required final AsyncValue<SkillResourceEntity?>? resourceAsync,
  required final SkillResourceEntity? resource,
  required final AppSkillResourceDefinition? staticResource,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (resourceAsync case AsyncError()) {
      return const Center(
        child: AuraText(
          child: TextLocale(LocaleKeys.skills_resource_load_error),
          tint: .error,
        ),
      );
    }
    if (state.widget.resourceId != null &&
        resource == null &&
        staticResource == null) {
      return _SkillResourceNotFound(resourceAsync: resourceAsync);
    }

    return _SkillResourceForm(
      state: state,
      resource: resource,
      staticResource: staticResource,
    );
  }
}

class const _SkillResourceNotFound({
  required final AsyncValue<SkillResourceEntity?>? resourceAsync,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (resourceAsync == null || resourceAsync is AsyncLoading) {
      return const Center(child: AuraSpinner());
    }

    return const Center(
      child: AuraText(child: TextLocale(LocaleKeys.skills_resource_not_found)),
    );
  }
}

class const _SkillResourceForm({
  required final _SkillResourceEditScreenState state,
  required final SkillResourceEntity? resource,
  required final AppSkillResourceDefinition? staticResource,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isReadOnly = staticResource != null;
    final slug = resource?.slug ?? staticResource?.slug;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _SkillResourceFormCard(
          state: state,
          isReadOnly: isReadOnly,
          slug: slug,
        ),
      ],
    );
  }
}

class const _SkillResourceFormCard({
  required final _SkillResourceEditScreenState state,
  required final bool isReadOnly,
  required final String? slug,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCard(
    child: AuraColumn(
      children: [
        _SkillResourceIdentityFields(
          state: state,
          isReadOnly: isReadOnly,
          slug: slug,
        ),
        _SkillResourceContentFields(state: state, isReadOnly: isReadOnly),
        if (!isReadOnly) _SkillResourceFormActions(state: state),
      ],
      spacing: .md,
      crossAxisAlignment: .start,
    ),
  );
}

class const _SkillResourceIdentityFields({
  required final _SkillResourceEditScreenState state,
  required final bool isReadOnly,
  required final String? slug,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      if (slug case final slug?) _SkillResourceSlugField(slug: slug),
      AuraInput(
        controller: state._titleController,
        label: Text(
          LocaleKeys.skills_resource_title_label.tr(context: context),
        ),
        enabled: !isReadOnly,
      ),
    ],
    spacing: .md,
    crossAxisAlignment: .start,
  );
}

class const _SkillResourceContentFields({
  required final _SkillResourceEditScreenState state,
  required final bool isReadOnly,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _SkillResourceDescriptionField(state: state, isReadOnly: isReadOnly),
      _SkillResourceContentField(state: state, isReadOnly: isReadOnly),
    ],
    spacing: .md,
    crossAxisAlignment: .start,
  );
}

class const _SkillResourceDescriptionField({
  required final _SkillResourceEditScreenState state,
  required final bool isReadOnly,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MarkdownPreviewField(
    controller: state._descriptionController,
    titleKey: LocaleKeys.skills_resource_description_label,
    editKey: LocaleKeys.skills_resource_edit_description,
    emptyKey: LocaleKeys.skills_resource_description_empty,
    onEdit: () => state._editDescription(context),
    isReadOnly: isReadOnly,
  );
}

class const _SkillResourceContentField({
  required final _SkillResourceEditScreenState state,
  required final bool isReadOnly,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MarkdownPreviewField(
    controller: state._contentController,
    titleKey: LocaleKeys.skills_resource_content_label,
    editKey: LocaleKeys.skills_resource_edit_content,
    emptyKey: LocaleKeys.skills_resource_content_empty,
    onEdit: () => state._editContent(context),
    isReadOnly: isReadOnly,
  );
}

class const _SkillResourceSlugField({required final String slug})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const AuraText(child: TextLocale(LocaleKeys.skills_resource_slug_label)),
      AuraSelectableText(slug),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}

class const _SkillResourceActions({
  required final _SkillResourceEditScreenState state,
  required final VoidCallback? onDelete,
  required final VoidCallback onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onDelete case final delete?)
          _SkillResourceDeleteButton(onPressed: delete),
        const Spacer(),
        AuraButton(
          onPressed: onSave,
          child: Text(LocaleKeys.skills_screen_save.tr(context: context)),
          disabled: state._isSaving,
        ),
      ],
    );
  }
}

class const _SkillResourceFormActions({
  required final _SkillResourceEditScreenState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SkillResourceActions(
    state: state,
    onDelete: state._isCreate ? null : () => state._delete(context),
    onSave: () => state._save(context),
  );
}

class const _SkillResourceDeleteButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: Text(LocaleKeys.skills_resource_delete_title.tr(context: context)),
    variant: .outlined,
  );
}

class const _SkillResourceDeleteDialog() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraConfirmDialog(
    title: const TextLocale(LocaleKeys.skills_resource_delete_title),
    message: const TextLocale(LocaleKeys.skills_resource_delete_confirm),
    confirmLabel: Text(LocaleKeys.common_delete.tr(context: context)),
    cancelLabel: Text(LocaleKeys.common_cancel.tr(context: context)),
    isDestructive: true,
  );
}
