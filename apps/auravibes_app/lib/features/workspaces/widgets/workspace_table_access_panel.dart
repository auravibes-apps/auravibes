import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

final _logger = Logger('workspace_table_access_panel');

class const WorkspaceTableAccessPanel({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final VoidCallback onChanged,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usecase = ref.watch(
      workspaceTableUsecaseProvider(workspaceId).future,
    );
    final members = useFuture(
      useMemoized(() async => await (await usecase).members(table.id), [
        usecase,
        table.revision,
      ]),
    );
    final pending = useState(false);
    final failure = useState<Object?>(null);
    Future<void> grant(WorkspaceTableMember member, String? access) async {
      if (pending.value) return;
      pending.value = true;
      failure.value = null;
      try {
        await (await usecase).setMemberAccess(
          table: table,
          userId: member.userId,
          access: access,
        );
        if (context.mounted) onChanged();
      } on Object catch (error, stackTrace) {
        _logger.warning(
          'Table grant failed: ${error.runtimeType}',
          null,
          stackTrace,
        );
        if (context.mounted) failure.value = error;
      } finally {
        if (context.mounted) pending.value = false;
      }
    }

    if (members.error case final error?) {
      return WorkspaceItemFailure(error: error);
    }
    final values = members.data;
    if (values == null) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        const TextLocale(LocaleKeys.workspace_items_table_access),
        if (failure.value case final error?) WorkspaceItemFailure(error: error),
        for (final member in values)
          ListTile(
            title: Text(member.label),
            subtitle: Wrap(
              spacing: 8,
              children: [
                for (final access in [null, 'read', 'edit'])
                  AuraButton(
                    onPressed: () => unawaited(grant(member, access)),
                    child: TextLocale(switch (access) {
                      'read' => LocaleKeys.workspace_items_access_read,
                      'edit' => LocaleKeys.workspace_items_access_edit,
                      _ => LocaleKeys.workspace_items_access_none,
                    }),
                    disabled: pending.value || member.access == access,
                    identifier:
                        'workspace_table_access_${member.userId}_'
                        '${access ?? 'none'}',
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
