import 'dart:async';
import 'dart:convert';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceViewEditor({required final String workspaceId,required final WorkspaceViewData data,
  required final VoidCallback onDone,super.key}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final name = useTextEditingController(text:data.view.name);
    final layout = useTextEditingController(text:const JsonEncoder.withIndent('  ').convert(data.view.definition.toJson()));
    final selected = useState(data.view.bindings.values.toSet());
    final error = useState<Object?>(null);
    final pending = useState(false);
    Future<void> save() async {
      if (pending.value) return;
      pending.value=true; error.value=null;
      try {
        final definition = A2uiSavedDefinition.fromJson(Map<String,Object?>.from(jsonDecode(layout.text) as Map));
        final usecase = await ref.read(workspaceViewUsecaseProvider(workspaceId).future);
        final existing = data.view.bindings;
        final bindings = {for (final entry in existing.entries) if (selected.value.contains(entry.value)) entry.key:entry.value};
        for (final id in selected.value.where((id)=>!bindings.containsValue(id))) {
          var index = 0;
          while (bindings.containsKey('field$index')) { index++; }
          bindings['field$index']=id;
        }
        final _ = await usecase.save(WorkspaceView(id:data.view.id,name:name.text,tableId:data.view.tableId,
          bindings:bindings,columnTypes:{for(final column in data.table.columns) if(selected.value.contains(column.id)) column.id:column.type.name},definition:definition,revision:data.view.revision,parentId:data.view.parentId));
        if (context.mounted) onDone();
      } on Object catch (failure) { if (context.mounted) error.value=failure; }
      finally { if (context.mounted) pending.value=false; }
    }
    return ListView(padding:const EdgeInsets.all(16),children:[
      ListTile(leading:const Icon(Icons.arrow_back),title:Text(data.view.name),onTap:pending.value?null:onDone),
      AuraInput(controller:name,label:const TextLocale(LocaleKeys.workspace_views_name)),
      const TextLocale(LocaleKeys.workspace_views_bindings),
      for (final column in data.table.columns) CheckboxListTile(title:Text(column.name),value:selected.value.contains(column.id),
        onChanged:pending.value?null:(checked) => selected.value=checked==true?{...selected.value,column.id}:({...selected.value}..remove(column.id))),
      ExpansionTile(title:const TextLocale(LocaleKeys.workspace_views_definition),children:[AuraInput(controller:layout,maxLines:12)]),
      AuraButton(onPressed:()=>unawaited(save()),disabled:pending.value,isLoading:pending.value,
        identifier:'workspace_view_save',child:const TextLocale(LocaleKeys.workspace_views_edit)),
      if (error.value case final failure?) WorkspaceItemFailure(error:failure),
    ]);
  }
}
