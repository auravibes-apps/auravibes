import 'dart:async';

import 'package:auravibes_app/features/chats/agent_adapters/aura_chat_catalog_adapter.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_surface_data.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:genui/genui.dart';
import 'package:material_ui/material_ui.dart';

/// Display-only workspace surface. It has no model or Conversation runtime.
class WorkspaceViewSurface extends StatefulWidget {
  const new({required this.data, super.key});
  final WorkspaceViewData data;
  @override
  State<WorkspaceViewSurface> createState() => _WorkspaceViewSurfaceState();
}

class _WorkspaceViewSurfaceState extends State<WorkspaceViewSurface> {
  SurfaceController _controller = .new(catalogs: auraChatCatalogs());
  StreamSubscription<SurfaceUpdate>? _updates;
  var _failed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    unawaited(_updates?.cancel());
    _disposeController();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WorkspaceViewSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data)) _load();
  }

  @override
  Widget build(BuildContext context) => _failed
      ? const TextLocale(LocaleKeys.workspace_views_repair)
      : _ReadySurface(_controller);

  void _load() {
    _reset();
    try {
      _render();
    } on Object {
      _failed = true;
    }
    _updates = _controller.surfaceUpdates.listen(_surfaceUpdated);
  }

  void _reset() {
    unawaited(_updates?.cancel());
    _disposeController();
    _controller = .new(catalogs: auraChatCatalogs());
    _failed = false;
  }

  void _disposeController() => _controller.dispose();

  void _render() {
    activeA2uiWireCodec
        .decodeAll(WorkspaceViewSurfaceData.envelope(widget.data))
        .forEach(_handle);
  }

  void _handle(A2uiDecodeResult decoded) {
    final operation = decoded.envelope?.operation;
    if (operation == null) {
      _failed = true;

      return;
    }
    _controller.handleMessage(.fromJson(operation.json));
  }

  void _surfaceUpdated(SurfaceUpdate _) {
    if (mounted) {
      setState(() {
        const _ = 0;
      });
    }
  }
}

class _ReadOnlyActions implements ActionDelegate {
  const new();
  @override
  bool handleEvent(
    BuildContext context,
    UiEvent event,
    SurfaceContext genuiContext,
    Widget Function(SurfaceDefinition, Catalog, String, DataContext)
    buildWidget,
  ) => true;
}

class const _ReadySurface(final SurfaceController controller)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInteractionScope(
    policy: const AuraInteractionPolicy.readOnly(),
    child: Surface(
      surfaceContext: controller.contextFor('view'),
      actionDelegate: const _ReadOnlyActions(),
    ),
  );
}
