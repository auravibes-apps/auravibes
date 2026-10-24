import 'dart:async';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceViewCreation({required final String workspaceId,required final String? parentId,
  required final ValueChanged<String> onOpenView,super.key}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final name = useTextEditingController();
    final selected = useState<WorkspaceTable?>(null);
    final pending = useState(false);
    final failure = useState<Object?>(null);
    final tables = ref.watch(workspaceTablesProvider(workspaceId,parentId));
    Future<void> create() async {
      final table = selected.value;
      if (table == null || pending.value) return;
      pending.value = true;
      failure.value = null;
      try {
        final usecase = await ref.read(workspaceViewUsecaseProvider(workspaceId).future);
        final view = await usecase.create(name:name.text,table:table,columnIds:[table.labelColumnId],parentId:parentId);
        if (!context.mounted) return;
        ref.invalidate(workspaceViewsProvider(workspaceId,parentId));
        onOpenView(view.id);
      } on Object catch (error) {
        if (context.mounted) failure.value = error;
      } finally { if (context.mounted) pending.value = false; }
    }
    return Column(mainAxisSize:MainAxisSize.min,children:[
      AuraInput(controller:name,label:const TextLocale(LocaleKeys.workspace_views_name),identifier:'workspace_view_name'),
      const TextLocale(LocaleKeys.workspace_views_bindings),
      switch(tables) {
        AsyncData(:final value) => Column(mainAxisSize:MainAxisSize.min,children:[for (final table in value.where((table)=>table.canManage)) ListTile(
          title:Text(table.name),selected:selected.value?.id == table.id,onTap:()=>selected.value=table)]),
        AsyncError(:final error) => WorkspaceItemFailure(error:error),
        AsyncLoading() => const CircularProgressIndicator(),
      },
      AuraButton(onPressed:()=>unawaited(create()),disabled:selected.value==null || pending.value,isLoading:pending.value,
        identifier:'workspace_view_create',child:const TextLocale(LocaleKeys.workspace_views_create)),
      if (failure.value case final error?) WorkspaceItemFailure(error:error),
    ]);
  }
}
