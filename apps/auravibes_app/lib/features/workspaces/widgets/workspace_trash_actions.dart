import 'package:auravibes_app/features/workflows/providers/workflow_providers.dart';
import 'package:auravibes_app/features/workflows/providers/workspace_directory_workflows_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_assets_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_references_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_trash_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

abstract final class WorkspaceTrashActions {
  static final _logger = Logger('workspace_trash_action');

  static Future<bool> trash(
    BuildContext context,
    WidgetRef ref,
    String workspaceId,
    WorkspaceTrashTarget target,
  ) async {
    final result = await AsyncValue.guard(
      () => _apply(context, ref, workspaceId, target),
    );
    if (!context.mounted) return false;

    return switch (result) {
      AsyncData(:final value) => value,
      final AsyncError<bool> failure => await _failure(context, failure),
      AsyncLoading() => false,
    };
  }

  static Future<WorkspaceTrashRestoration> restore(
    WidgetRef ref,
    String workspaceId,
    String batchId,
  ) async {
    final usecase = await ref.read(
      workspaceTrashUsecaseProvider(workspaceId).future,
    );
    final result = await usecase.restore(batchId);
    if (ref.context.mounted) refresh(ref);

    return result;
  }

  static void refresh(WidgetRef ref) {
    _refreshAssets(ref);
    _refreshTables(ref);
    _refreshViews(ref);
    _refreshWorkflows(ref);
  }

  static void _refreshAssets(WidgetRef ref) {
    ref
      ..invalidate(workspaceAssetRepositoryProvider)
      ..invalidate(workspaceFilesProvider)
      ..invalidate(workspaceFileProvider)
      ..invalidate(workspaceAssetPreviewProvider);
  }

  static void _refreshTables(WidgetRef ref) {
    ref
      ..invalidate(workspaceFoldersProvider)
      ..invalidate(workspaceTablesProvider)
      ..invalidate(workspaceTableProvider)
      ..invalidate(workspaceTableRecordsProvider)
      ..invalidate(workspaceRecordQueryProvider)
      ..invalidate(workspaceReferencedRecordProvider)
      ..invalidate(workspaceTrashProvider)
      ..invalidate(workspaceDeletedReferenceProvider);
  }

  static void _refreshViews(WidgetRef ref) {
    ref
      ..invalidate(workspaceViewsProvider)
      ..invalidate(workspaceViewDataProvider)
      ..invalidate(workspaceViewChoicesProvider)
      ..invalidate(workspaceViewHistoryProvider);
  }

  static void _refreshWorkflows(WidgetRef ref) {
    ref
      ..invalidate(workflowProvider)
      ..invalidate(workflowsProvider)
      ..invalidate(workspaceDirectoryWorkflowsProvider);
  }

  static Future<bool> _apply(
    BuildContext context,
    WidgetRef ref,
    String workspaceId,
    WorkspaceTrashTarget target,
  ) async {
    final usecase = await ref.read(
      workspaceTrashUsecaseProvider(workspaceId).future,
    );
    if (!context.mounted) return false;
    final result = await usecase.apply(
      target,
      approve: (plan) => _approve(context, plan),
    );

    if (!context.mounted) return false;

    return _complete(context, ref, result);
  }

  static Future<bool> _failure(
    BuildContext context,
    AsyncError<bool> failure,
  ) async {
    _logger.warning(
      'Trash failed: ${failure.error.runtimeType}',
      null,
      failure.stackTrace,
    );
    await showDialog<void>(
      context: context,
      builder: (_) => _TrashFailureDialog(error: failure.error),
    );

    return false;
  }

  static Future<bool> _approve(
    BuildContext context,
    WorkspaceTrashBatch plan,
  ) async {
    if (!context.mounted) return false;

    return await showDialog<bool>(
          context: context,
          builder: (_) => _ImpactDialog(plan: plan),
        ) ??
        false;
  }

  static bool _complete(
    BuildContext context,
    WidgetRef ref,
    WorkspaceTrashBatch? result,
  ) {
    if (!context.mounted || result == null) return false;
    refresh(ref);

    return true;
  }
}

class const _ImpactDialog({required final WorkspaceTrashBatch plan})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _ImpactContent(plan: plan),
        ),
      ),
    ),
  );
}

class const _ImpactContent({required final WorkspaceTrashBatch plan})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .stretch,
    children: [
      Text(
        LocaleKeys.workspace_items_trash_impact.tr(
          namedArgs: {'name': plan.name, 'count': '${plan.affectedCount}'},
        ),
      ),
      const _ImpactConfirm(),
      const _ImpactCancel(),
    ],
  );
}

class const _ImpactConfirm() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => Navigator.of(context).pop(true),
    child: const TextLocale(LocaleKeys.workspace_items_trash_action),
    identifier: 'workspace_trash_confirm',
  );
}

class const _ImpactCancel() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => Navigator.of(context).pop(false),
    child: const TextLocale(LocaleKeys.workspace_items_trash_cancel),
    variant: .ghost,
    identifier: 'workspace_trash_cancel',
  );
}

class const _TrashFailureDialog({required final Object error})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Dialog(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _FailureContent(error: error),
      ),
    ),
  );
}

class const _FailureContent({required final Object error})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      WorkspaceItemFailure(error: error),
      const _FailureClose(),
    ],
  );
}

class const _FailureClose() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => Navigator.of(context).pop(),
    child: const TextLocale(LocaleKeys.workspace_items_trash_close),
  );
}
