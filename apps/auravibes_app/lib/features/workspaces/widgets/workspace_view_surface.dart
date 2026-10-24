import 'dart:async';
import 'dart:convert';
import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:auravibes_app/features/chats/agent_adapters/aura_chat_catalog_adapter.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:genui/genui.dart';
import 'package:material_ui/material_ui.dart';

/// Display-only workspace surface. It has no model or Conversation runtime.
class WorkspaceViewSurface extends StatefulWidget {
  const WorkspaceViewSurface({required this.data,super.key});
  final WorkspaceViewData data;
  @override
  State<WorkspaceViewSurface> createState() => _WorkspaceViewSurfaceState();
}
class _WorkspaceViewSurfaceState extends State<WorkspaceViewSurface> {
  SurfaceController? _controller;
  StreamSubscription<SurfaceUpdate>? _updates;
  @override
  void initState() { super.initState(); _load(); }
  @override
  void didUpdateWidget(covariant WorkspaceViewSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data,widget.data)) _load();
  }
  void _load() {
    unawaited(_updates?.cancel());
    _controller?.dispose();
    final controller = SurfaceController(catalogs:auraChatCatalogs());
    _controller = controller;
    final envelope = {'protocolVersion':'v1','interactionMode':'passive','initialSurface':{
      'surfaceId':'view','catalogId':a2uiChatCatalogId,
      'components':widget.data.view.definition.components,
      'dataModel':workspaceViewModel(widget.data),
    }};
    for (final decoded in activeA2uiWireCodec.decodeAll(envelope)) {
      final operation = decoded.envelope?.operation;
      if (operation != null) controller.handleMessage(core.A2uiMessage.fromJson(jsonDecode(jsonEncode(operation.json)) as Map<String,dynamic>));
    }
    _updates = controller.surfaceUpdates.listen((_) { if (mounted) setState(() {}); });
  }
  @override
  Widget build(BuildContext context) => AuraInteractionScope(
    policy: const AuraInteractionPolicy.readOnly(),
    child: Surface(surfaceContext:_controller!.contextFor('view'),actionDelegate:const _ReadOnlyActions()),
  );
  @override
  void dispose() { unawaited(_updates?.cancel()); _controller?.dispose(); super.dispose(); }
}
class _ReadOnlyActions implements ActionDelegate {
  const _ReadOnlyActions();
  @override
  bool handleEvent(BuildContext context,UiEvent event,SurfaceContext genuiContext,
    Widget Function(SurfaceDefinition,Catalog,String,DataContext) buildWidget) => true;
}
Map<String,Object?> workspaceViewModel(WorkspaceViewData data) {
  final ids = data.view.bindings.values.toList();
  final columns = {for (final column in data.table.columns) column.id:column.name};
  return {
    'columns':[for (final id in ids) columns[id]],
    'rows':[for (final record in data.records.take(100)) [for (final id in ids) _scalar(record.values[id])]],
    if (data.records.isNotEmpty) ...{
      for (final entry in data.view.bindings.entries) entry.key:_scalar(data.records.first.values[entry.value]),
    },
  };
}
Object? _scalar(Object? value) {
  if (value is Map && value['amount'] is String && value['currency'] is String) return '${value['amount']} ${value['currency']}';
  if (value is List) return value.join(', ');
  return value == null || value is String || value is num || value is bool ? value : '';
}
