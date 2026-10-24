import 'dart:async';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_editor.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_surface.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceViewScreen({required final String workspaceId,required final String viewId,
  required final VoidCallback onBack,super.key}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final editing = useState(false);
    final data = ref.watch(workspaceViewDataProvider(workspaceId,viewId));
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds:10),(_) => ref.invalidate(workspaceViewDataProvider(workspaceId,viewId)));
      return timer.cancel;
    },[workspaceId,viewId]);
    return Column(children:[
      Row(children:[AuraIconButton(icon:Icons.arrow_back,onPressed:onBack),
        const Expanded(child:TextLocale(LocaleKeys.workspace_views_title)),
        AuraIconButton(icon:Icons.refresh,onPressed:()=>ref.invalidate(workspaceViewDataProvider(workspaceId,viewId))),
        if (data.value?.table.canManage ?? false) PopupMenuButton<String>(
          onSelected:(action) { if (action == 'edit') { editing.value=true; } else { unawaited(_history(context,ref,data.requireValue)); } },
          itemBuilder:(_) => [const PopupMenuItem(value:'edit',child:TextLocale(LocaleKeys.workspace_views_edit)),
            const PopupMenuItem(value:'history',child:TextLocale(LocaleKeys.workspace_views_history))]),
      ]),
      Expanded(child:switch(data) {
        AsyncData(:final value) => editing.value
          ? WorkspaceViewEditor(workspaceId:workspaceId,data:value,onDone:() { editing.value=false; ref.invalidate(workspaceViewDataProvider(workspaceId,viewId)); })
          : _ViewContent(data:value),
        AsyncError(:final error) => Center(child:WorkspaceItemFailure(error:error)),
        AsyncLoading() => const Center(child:CircularProgressIndicator()),
      }),
    ]);
  }
  Future<void> _history(BuildContext context,WidgetRef ref,WorkspaceViewData data) async {
    try {
      final usecase = await ref.read(workspaceViewUsecaseProvider(workspaceId).future);
      final revisions = await usecase.history(viewId);
      if (!context.mounted) return;
      await showDialog<void>(context:context,builder:(dialogContext) => AlertDialog(
        title:const TextLocale(LocaleKeys.workspace_views_history),
        content:SizedBox(width:400,height:400,child:ListView(children:[for (final revision in revisions.reversed) ListTile(
          title:Text('${revision.name} · ${revision.revision}'),
          subtitle:const TextLocale(LocaleKeys.workspace_views_restore),
          onTap:() async {
            try {
              final _ = await usecase.restore(data.view,revision);
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              ref.invalidate(workspaceViewDataProvider(workspaceId,viewId));
            } on Object catch (error) {
              if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content:WorkspaceItemFailure(error:error)));
            }
          },
        )])),
      ));
    } on Object catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:WorkspaceItemFailure(error:error)));
    }
  }
}
class const _ViewContent({required final WorkspaceViewData data}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(padding:const EdgeInsets.all(16),children:[
    Text(data.view.name),
    const TextLocale(LocaleKeys.workspace_views_display_only),
    if (data.needsRepair) const TextLocale(LocaleKeys.workspace_views_repair)
    else if (data.records.isEmpty) const TextLocale(LocaleKeys.workspace_views_empty)
    else WorkspaceViewSurface(data:data),
    if (data.records.length >= 100) const TextLocale(LocaleKeys.workspace_views_limit),
  ]);
}
