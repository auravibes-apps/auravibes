import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_table_access_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_actions.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

typedef _GrantRequest = ({WorkspaceTableMember member, String? access});
typedef _Grant = ValueChanged<_GrantRequest>;
typedef _AccessDraft = ({
  Future<ManageWorkspaceTableAccessUsecase> usecase,
  AsyncSnapshot<List<WorkspaceTableMember>> members,
  WorkspaceTableAction action,
  BuildContext context,
});

class const WorkspaceTableAccessPanel({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final VoidCallback onChanged,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = _AccessActions.use(context, ref, this);

    return _AccessContent(
      draft: draft,
      onGrant: (request) =>
          unawaited(_AccessActions.grant(this, draft, request)),
    );
  }
}

abstract final class _AccessActions {
  static _AccessDraft use(
    BuildContext context,
    WidgetRef ref,
    WorkspaceTableAccessPanel panel,
  ) {
    final usecase = ref.watch(
      workspaceTableAccessUsecaseProvider(panel.workspaceId).future,
    );
    final members = useFuture(
      useMemoized(() => _members(usecase, panel.table), [
        usecase,
        panel.table.revision,
      ]),
    );

    return (
      usecase: usecase,
      members: members,
      action: WorkspaceTableActions.use(context),
      context: context,
    );
  }

  static Future<void> grant(
    WorkspaceTableAccessPanel panel,
    _AccessDraft draft,
    _GrantRequest request,
  ) => draft.action.run(() async {
    await _apply(draft, panel.table, request);
    if (draft.context.mounted) panel.onChanged();
  });
  static Future<void> _apply(
    _AccessDraft draft,
    WorkspaceTable table,
    _GrantRequest request,
  ) async {
    final usecase = await draft.usecase;
    await usecase.setMemberAccess(
      table: table,
      userId: request.member.userId,
      access: request.access,
    );
  }

  static Future<List<WorkspaceTableMember>> _members(
    Future<ManageWorkspaceTableAccessUsecase> usecase,
    WorkspaceTable table,
  ) async => await (await usecase).members(table);
}

class const _AccessContent({
  required final _AccessDraft draft,
  required final _Grant onGrant,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (draft.members.error case final error?) {
      return WorkspaceItemFailure(error: error);
    }
    final members = draft.members.data;
    if (members == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return _AccessList(
      members: members,
      action: draft.action,
      onGrant: onGrant,
    );
  }
}

class const _AccessList({
  required final List<WorkspaceTableMember> members,
  required final WorkspaceTableAction action,
  required final _Grant onGrant,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const TextLocale(LocaleKeys.workspace_items_table_access),
      if (action.error case final error?) WorkspaceItemFailure(error: error),
      for (final member in members)
        _AccessRow(member: member, pending: action.pending, onGrant: onGrant),
    ],
  );
}

class const _AccessRow({
  required final WorkspaceTableMember member,
  required final bool pending,
  required final _Grant onGrant,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(member.label),
    subtitle: Wrap(
      spacing: 8,
      children: [
        for (final access in [null, 'read', 'edit'])
          _AccessOption(
            member: member,
            access: access,
            pending: pending,
            onGrant: onGrant,
          ),
      ],
    ),
  );
}

class const _AccessOption({
  required final WorkspaceTableMember member,
  required final String? access,
  required final bool pending,
  required final _Grant onGrant,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => onGrant((member: member, access: access)),
    child: TextLocale(_accessLabel(access)),
    disabled: pending || member.access == access,
    identifier: 'workspace_table_access_${member.userId}_${access ?? 'none'}',
  );
}

String _accessLabel(String? access) => switch (access) {
  'read' => LocaleKeys.workspace_items_access_read,
  'edit' => LocaleKeys.workspace_items_access_edit,
  _ => LocaleKeys.workspace_items_access_none,
};
