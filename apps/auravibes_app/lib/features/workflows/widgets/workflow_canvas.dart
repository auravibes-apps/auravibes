import 'dart:math' as math;

import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_editor_state.dart';
import 'package:auravibes_app/features/workflows/models/workflow_graph_validation.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_canvas_metrics.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_connection_text.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

typedef _WorkflowLinkDrag = ({
  String sourceNodeId,
  WorkflowConditionBranch? branch,
});

typedef _WorkflowLinkPreview = ({_WorkflowLinkDrag drag, Offset pointer});

class WorkflowCanvas extends StatefulWidget {
  const WorkflowCanvas({
    required this.workflow,
    required this.editorState,
    required this.onSelectNode,
    required this.onClearSelection,
    required this.onMoveNode,
    required this.onAddNode,
    required this.onConnect,
    required this.onRemoveConnection,
    super.key,
  });

  final WorkspaceWorkflow workflow;
  final WorkflowEditorState editorState;
  final ValueChanged<String> onSelectNode;
  final VoidCallback onClearSelection;
  final void Function(String sourceNodeId, WorkflowConditionBranch? branch)
  onAddNode;
  final void Function(
    String sourceNodeId,
    String targetNodeId,
    WorkflowConditionBranch? branch,
  )
  onConnect;
  final ValueChanged<WorkflowConnection> onRemoveConnection;
  final void Function(String nodeId, double x, double y) onMoveNode;

  @override
  State<WorkflowCanvas> createState() => _WorkflowCanvasState();
}

class _WorkflowCanvasState extends State<WorkflowCanvas> {
  final GlobalKey _viewerKey = GlobalKey();
  final TransformationController _transform = TransformationController();
  final ValueNotifier<Offset?> _dragPosition = ValueNotifier(null);
  final ValueNotifier<_WorkflowLinkPreview?> _linkPreview = ValueNotifier(null);
  final Map<String, FocusNode> _nodeFocusNodes = {};
  final Map<WorkflowConnectionKey, FocusNode> _connectionFocusNodes = {};
  final Map<int, Offset> _pointerDowns = {};
  WorkspaceWorkflow? _focusOrderWorkflow;
  _WorkflowFocusOrders? _cachedFocusOrders;
  WorkspaceWorkflow? _cachedWorkflow;
  WorkflowEditorState? _cachedEditorState;
  Offset? _cachedSceneOrigin;
  Size? _cachedSceneSize;
  String? _cachedDraggedNodeId;
  WorkflowConnectionKey? _cachedSelectedConnectionKey;
  void Function(String, WorkflowConditionBranch?)? _cachedOnAddNode;
  void Function(String, String, WorkflowConditionBranch?)? _cachedOnConnect;
  _WorkflowCanvasScene? _cachedScene;
  WorkflowConnectionKey? _selectedConnectionKey;
  Offset? _pointerDownGlobalPosition;
  String? _draggedNodeId;
  Offset? _dragStartPosition;
  Offset? _dragStartPointerPosition;

  @override
  void initState() {
    super.initState();
    _syncFocusNodes();
  }

  @override
  void didUpdateWidget(covariant WorkflowCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFocusNodes();
    if (_selectedConnectionKey != null &&
        !_connectionFocusNodes.containsKey(_selectedConnectionKey)) {
      _selectedConnectionKey = null;
    }
  }

  @override
  void dispose() {
    for (final focusNode in _nodeFocusNodes.values) {
      focusNode.dispose();
    }
    for (final focusNode in _connectionFocusNodes.values) {
      focusNode.dispose();
    }
    _transform.dispose();
    _dragPosition.dispose();
    _linkPreview.dispose();
    super.dispose();
  }

  void _syncFocusNodes() {
    final nodeIds = widget.workflow.nodes.map((node) => node.id).toSet();
    for (final id in _nodeFocusNodes.keys.toList()) {
      if (nodeIds.contains(id)) continue;
      final focusNode = _nodeFocusNodes.remove(id)!;
      focusNode.unfocus();
      focusNode.dispose();
    }
    for (final id in nodeIds) {
      _nodeFocusNodes.putIfAbsent(
        id,
        () => FocusNode(debugLabel: 'Workflow node $id'),
      );
    }

    final connectionKeys = widget.workflow.connections
        .map(_connectionKey)
        .toSet();
    for (final key in _connectionFocusNodes.keys.toList()) {
      if (connectionKeys.contains(key)) continue;
      final focusNode = _connectionFocusNodes.remove(key)!;
      focusNode.unfocus();
      focusNode.dispose();
    }
    for (final key in connectionKeys) {
      _connectionFocusNodes.putIfAbsent(
        key,
        () => FocusNode(
          debugLabel: 'Workflow link ${key.fromNodeId} to ${key.toNodeId}',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final focusOrders = _focusOrders;
    final selectedConnection = widget.workflow.connections
        .where(
          (connection) => _connectionKey(connection) == _selectedConnectionKey,
        )
        .firstOrNull;

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: _onCanvasKeyEvent,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Listener(
                  onPointerDown: (event) {
                    _pointerDowns[event.pointer] = event.position;
                    _pointerDownGlobalPosition = event.position;
                  },
                  onPointerUp: _handlePointerUp,
                  child: InteractiveViewer.builder(
                    key: _viewerKey,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    maxScale: 1.8,
                    minScale: 0.45,
                    transformationController: _transform,
                    builder: (context, viewport) {
                      final points = [
                        viewport.point0,
                        viewport.point1,
                        viewport.point2,
                        viewport.point3,
                      ];
                      if (points.any(
                        (point) => !point.x.isFinite || !point.y.isFinite,
                      )) {
                        return const SizedBox.expand();
                      }
                      final bounds = Rect.fromLTRB(
                        points
                            .map((point) => point.x)
                            .reduce(
                              (left, right) => math.min(left, right).toDouble(),
                            ),
                        points
                            .map((point) => point.y)
                            .reduce(
                              (top, bottom) => math.min(top, bottom).toDouble(),
                            ),
                        points
                            .map((point) => point.x)
                            .reduce(
                              (left, right) => math.max(left, right).toDouble(),
                            ),
                        points
                            .map((point) => point.y)
                            .reduce(
                              (top, bottom) => math.max(top, bottom).toDouble(),
                            ),
                      );
                      if (bounds.width <= 0 || bounds.height <= 0) {
                        return const SizedBox.expand();
                      }
                      final spacing = WorkflowCanvasMetrics.gridSpacing;
                      final window = spacing * 8;
                      final origin = Offset(
                        (bounds.left / window).floorToDouble() * window,
                        (bounds.top / window).floorToDouble() * window,
                      );
                      final size = Size(
                        bounds.width + window + spacing,
                        bounds.height + window + spacing,
                      );
                      if (!size.width.isFinite ||
                          !size.height.isFinite ||
                          size.width <= 0 ||
                          size.height <= 0) {
                        return const SizedBox.expand();
                      }

                      return _sceneFor(origin, size, focusOrders);
                    },
                  ),
                ),
              ),
              if (selectedConnection != null && widget.workflow.canManage)
                _SelectedConnectionDeleteButton(
                  connection: selectedConnection,
                  workflow: widget.workflow,
                  transform: _transform,
                  viewportSize: constraints.biggest,
                  traversalOrder: focusOrders.nextOrder,
                  onDelete: _confirmDeleteConnection,
                ),
            ],
          ),
        ),
      ),
    );
  }

  _WorkflowFocusOrders get _focusOrders {
    if (identical(_focusOrderWorkflow, widget.workflow) &&
        _cachedFocusOrders != null) {
      return _cachedFocusOrders!;
    }
    _focusOrderWorkflow = widget.workflow;

    return _cachedFocusOrders = _WorkflowFocusOrders.forWorkflow(
      widget.workflow,
    );
  }

  Widget _sceneFor(Offset origin, Size size, _WorkflowFocusOrders focusOrders) {
    if (_cachedScene == null ||
        !identical(_cachedWorkflow, widget.workflow) ||
        !identical(_cachedEditorState, widget.editorState) ||
        _cachedSceneOrigin != origin ||
        _cachedSceneSize != size ||
        _cachedDraggedNodeId != _draggedNodeId ||
        _cachedSelectedConnectionKey != _selectedConnectionKey ||
        _cachedOnAddNode != widget.onAddNode ||
        _cachedOnConnect != widget.onConnect) {
      _cachedWorkflow = widget.workflow;
      _cachedEditorState = widget.editorState;
      _cachedSceneOrigin = origin;
      _cachedSceneSize = size;
      _cachedDraggedNodeId = _draggedNodeId;
      _cachedSelectedConnectionKey = _selectedConnectionKey;
      _cachedOnAddNode = widget.onAddNode;
      _cachedOnConnect = widget.onConnect;
      _cachedScene = _WorkflowCanvasScene(
        workflow: widget.workflow,
        editorState: widget.editorState,
        sceneOrigin: origin,
        draggedNodeId: _draggedNodeId,
        dragPosition: _dragPosition,
        linkPreview: _linkPreview,
        selectedConnectionKey: _selectedConnectionKey,
        nodeFocusNodes: _nodeFocusNodes,
        connectionFocusNodes: _connectionFocusNodes,
        focusOrders: focusOrders,
        onSelectNode: _selectNode,
        onSelectConnection: _selectConnection,
        onMoveStart: _startNodeMove,
        onMoveUpdate: _updateNodeMove,
        onMoveEnd: _finishNodeMove,
        onAddNode: widget.onAddNode,
        onConnect: widget.onConnect,
        onLinkDragUpdate: _updateLinkPreview,
        onLinkDragEnd: _clearLinkPreview,
      );
    }

    return Transform.translate(
      offset: origin,
      child: SizedBox.fromSize(size: size, child: _cachedScene),
    );
  }

  KeyEventResult _onCanvasKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _clearSelection();

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _handlePointerUp(PointerUpEvent event) {
    final down = _pointerDowns.remove(event.pointer);
    _pointerDownGlobalPosition = null;
    if (down == null || (event.position - down).distance > 8) return;
    final point = _scenePosition(event.position);
    if (point == null || _isOverNode(point)) return;

    final connection = _connectionAt(point);
    if (connection != null) {
      _selectConnection(_connectionKey(connection));
      return;
    }
    _clearSelection();
  }

  bool _isOverNode(Offset point) {
    for (final node in widget.workflow.nodes) {
      final handleExtent = switch (node.kind) {
        .outputs => 0.0,
        .condition when widget.workflow.canManage => 106.0,
        _ when widget.workflow.canManage => 42.0,
        _ => 0.0,
      };
      if (Rect.fromLTWH(
        node.x,
        node.y,
        WorkflowCanvasMetrics.nodeWidth + handleExtent,
        WorkflowCanvasMetrics.nodeHeight,
      ).contains(point)) {
        return true;
      }
    }

    return false;
  }

  WorkflowConnection? _connectionAt(Offset point) {
    WorkflowConnection? closest;
    var closestDistance = double.infinity;
    final nodes = _nodesWithDragPreview();
    for (final connection in widget.workflow.connections) {
      final path = WorkflowConnectionGeometry.pathForConnection(
        connection,
        nodes,
      );
      if (path == null) continue;
      final distance = WorkflowConnectionGeometry.distanceToPath(point, path);
      if (distance < closestDistance) {
        closest = connection;
        closestDistance = distance;
      }
    }

    return closest;
  }

  void _clearSelection() {
    if (_selectedConnectionKey != null) {
      setState(() => _selectedConnectionKey = null);
    }
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onClearSelection();
  }

  void _selectNode(String nodeId, {bool requestFocus = false}) {
    if (_selectedConnectionKey != null) {
      setState(() => _selectedConnectionKey = null);
    }
    if (requestFocus) _nodeFocusNodes[nodeId]?.requestFocus();
    if (widget.editorState.selectedNodeId != nodeId) {
      widget.onSelectNode(nodeId);
    }
  }

  void _selectConnection(WorkflowConnectionKey key) {
    final focusNode = _connectionFocusNodes[key];
    if (focusNode == null) return;
    focusNode.requestFocus();
    _focusConnection(key);
  }

  void _focusConnection(WorkflowConnectionKey key) {
    if (_selectedConnectionKey != key) {
      setState(() => _selectedConnectionKey = key);
    }
    widget.onClearSelection();
  }

  void _startNodeMove(
    String nodeId,
    double x,
    double y,
    Offset globalPosition,
  ) {
    if (_draggedNodeId != null) return;
    final pointerPosition = _scenePosition(
      _pointerDownGlobalPosition ?? globalPosition,
    );
    if (pointerPosition == null) return;
    _dragStartPosition = Offset(x, y);
    _dragStartPointerPosition = pointerPosition;
    _dragPosition.value = _dragStartPosition;
    _selectNode(nodeId, requestFocus: true);
    setState(() => _draggedNodeId = nodeId);
  }

  void _updateNodeMove(String nodeId, Offset globalPosition) {
    final start = _dragStartPosition;
    final pointerStart = _dragStartPointerPosition;
    if (_draggedNodeId != nodeId || start == null || pointerStart == null) {
      return;
    }

    final pointerPosition = _scenePosition(globalPosition);
    if (pointerPosition == null) return;
    final position = start + (pointerPosition - pointerStart);
    if (!position.dx.isFinite || !position.dy.isFinite) return;
    _dragPosition.value = position;
  }

  void _finishNodeMove(String nodeId) {
    final start = _dragStartPosition;
    final position = _dragPosition.value;
    if (_draggedNodeId != nodeId || start == null || position == null) return;

    if (position != start) {
      widget.onMoveNode(nodeId, position.dx, position.dy);
    }
    setState(() => _draggedNodeId = null);
    _dragPosition.value = null;
    _dragStartPosition = null;
    _dragStartPointerPosition = null;
  }

  void _updateLinkPreview(_WorkflowLinkDrag drag, Offset globalPosition) {
    final point = _scenePosition(globalPosition);
    if (point != null) _linkPreview.value = (drag: drag, pointer: point);
  }

  void _clearLinkPreview() => _linkPreview.value = null;

  Offset? _scenePosition(Offset globalPosition) {
    final renderObject = _viewerKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return null;
    final localPosition = renderObject.globalToLocal(globalPosition);
    final position = _transform.toScene(localPosition);

    return position.dx.isFinite && position.dy.isFinite ? position : null;
  }

  Map<String, WorkflowNode> _nodesWithDragPreview() {
    final nodes = {for (final node in widget.workflow.nodes) node.id: node};
    final previewPosition = _dragPosition.value;
    final activeNodeId = _draggedNodeId;
    if (previewPosition != null && activeNodeId != null) {
      final activeNode = nodes[activeNodeId];
      if (activeNode != null) {
        nodes[activeNodeId] = activeNode.copyWith(
          x: previewPosition.dx,
          y: previewPosition.dy,
        );
      }
    }

    return nodes;
  }

  Future<void> _confirmDeleteConnection(WorkflowConnection connection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          LocaleKeys.workflow_editor_delete_connection_confirm_title.tr(
            context: context,
          ),
        ),
        content: Text(
          LocaleKeys.workflow_editor_delete_connection_confirm_message.tr(
            context: context,
            namedArgs: {
              'connection': WorkflowConnectionText.description(
                widget.workflow,
                connection,
                context,
              ),
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(LocaleKeys.workflow_editor_cancel.tr(context: context)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              LocaleKeys.workflow_editor_confirm_delete_connection.tr(
                context: context,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onRemoveConnection(connection);
  }
}

class const _WorkflowCanvasScene({
  required final WorkspaceWorkflow workflow,
  required final WorkflowEditorState editorState,
  required final Offset sceneOrigin,
  required final String? draggedNodeId,
  required final ValueListenable<Offset?> dragPosition,
  required final ValueListenable<_WorkflowLinkPreview?> linkPreview,
  required final WorkflowConnectionKey? selectedConnectionKey,
  required final Map<String, FocusNode> nodeFocusNodes,
  required final Map<WorkflowConnectionKey, FocusNode> connectionFocusNodes,
  required final _WorkflowFocusOrders focusOrders,
  required final void Function(String, {bool requestFocus}) onSelectNode,
  required final ValueChanged<WorkflowConnectionKey> onSelectConnection,
  required final void Function(String, double, double, Offset) onMoveStart,
  required final void Function(String, Offset) onMoveUpdate,
  required final ValueChanged<String> onMoveEnd,
  required final void Function(String, WorkflowConditionBranch?) onAddNode,
  required final void Function(String, String, WorkflowConditionBranch?)
  onConnect,
  required final void Function(_WorkflowLinkDrag, Offset) onLinkDragUpdate,
  required final VoidCallback onLinkDragEnd,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final nodes = {for (final node in workflow.nodes) node.id: node};
    // Keep each left node's add handles above nearby nodes.
    final positionedNodes = [...workflow.nodes]
      ..sort((left, right) => right.x.compareTo(left.x));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _WorkflowGridPainter(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _WorkflowConnectionPainter(
                workflow: workflow,
                color: context.auraColors.primary,
                sceneOrigin: sceneOrigin,
                draggedNodeId: draggedNodeId,
                dragPosition: dragPosition,
                linkPreview: linkPreview,
                selectedConnectionKey: selectedConnectionKey,
              ),
            ),
          ),
        ),
        for (final connection in workflow.connections)
          _WorkflowCanvasConnection(
            key: ValueKey(_connectionKey(connection)),
            workflow: workflow,
            connection: connection,
            nodes: nodes,
            sceneOrigin: sceneOrigin,
            focusNode: connectionFocusNodes[_connectionKey(connection)]!,
            focusOrder:
                focusOrders.connectionOrders[_connectionKey(connection)] ?? 0,
            selected: selectedConnectionKey == _connectionKey(connection),
            onSelect: () => onSelectConnection(_connectionKey(connection)),
          ),
        for (final node in positionedNodes)
          _WorkflowPositionedNode(
            key: ValueKey(node.id),
            nodeId: node.id,
            nodePosition: Offset(node.x, node.y),
            sceneOrigin: sceneOrigin,
            draggedNodeId: draggedNodeId,
            dragPosition: dragPosition,
            child: _WorkflowCanvasNode(
              node: node,
              focusNode: nodeFocusNodes[node.id]!,
              focusOrder: focusOrders.nodeOrders[node.id] ?? 0,
              selected:
                  editorState.selectedNodeId == node.id ||
                  nodeFocusNodes[node.id]!.hasFocus,
              canEdit: workflow.canManage,
              workflow: workflow,
              onSelect: () => onSelectNode(node.id, requestFocus: true),
              onAddNode: (branch) => onAddNode(node.id, branch),
              onConnect: onConnect,
              onLinkDragUpdate: onLinkDragUpdate,
              onLinkDragEnd: onLinkDragEnd,
              onMoveStart: (position) =>
                  onMoveStart(node.id, node.x, node.y, position),
              onMove: (position) => onMoveUpdate(node.id, position),
              onMoveEnd: () => onMoveEnd(node.id),
            ),
          ),
      ],
    );
  }
}

class const _WorkflowCanvasConnection({
  super.key,
  required final WorkspaceWorkflow workflow,
  required final WorkflowConnection connection,
  required final Map<String, WorkflowNode> nodes,
  required final Offset sceneOrigin,
  required final FocusNode focusNode,
  required final double focusOrder,
  required final bool selected,
  required final VoidCallback onSelect,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final path = WorkflowConnectionGeometry.pathForConnection(
      connection,
      nodes,
    );
    final midpoint = path == null
        ? null
        : WorkflowConnectionGeometry.midpoint(path);
    if (midpoint == null) return const SizedBox.shrink();

    final label = WorkflowConnectionText.description(
      workflow,
      connection,
      context,
    );

    return Positioned(
      left: midpoint.dx - sceneOrigin.dx - 20,
      top: midpoint.dy - sceneOrigin.dy - 20,
      child: FocusTraversalOrder(
        order: NumericFocusOrder(focusOrder),
        child: Focus(
          focusNode: focusNode,
          onFocusChange: (hasFocus) {
            if (hasFocus) onSelect();
          },
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.space)) {
              onSelect();
              return KeyEventResult.handled;
            }

            return KeyEventResult.ignored;
          },
          child: Semantics(
            button: true,
            selected: selected,
            label: label,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onSelect,
              child: SizedBox(
                width: 40,
                height: 40,
                child: selected
                    ? Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.auraColors.primary,
                              width: 2,
                            ),
                          ),
                          child: const SizedBox(width: 10, height: 10),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class const _WorkflowPositionedNode({
  super.key,
  required final String nodeId,
  required final Offset nodePosition,
  required final Offset sceneOrigin,
  required final String? draggedNodeId,
  required final ValueListenable<Offset?> dragPosition,
  required final Widget child,
}) extends StatefulWidget {
  @override
  State<_WorkflowPositionedNode> createState() =>
      _WorkflowPositionedNodeState();
}

class _WorkflowPositionedNodeState extends State<_WorkflowPositionedNode> {
  Offset? _previewPosition;

  @override
  void initState() {
    super.initState();
    _previewPosition = widget.dragPosition.value;
    widget.dragPosition.addListener(_updateDragPosition);
  }

  @override
  void dispose() {
    widget.dragPosition.removeListener(_updateDragPosition);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _WorkflowPositionedNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dragPosition != widget.dragPosition) {
      oldWidget.dragPosition.removeListener(_updateDragPosition);
      widget.dragPosition.addListener(_updateDragPosition);
    }
    if (oldWidget.dragPosition != widget.dragPosition ||
        oldWidget.draggedNodeId != widget.draggedNodeId) {
      _previewPosition = widget.dragPosition.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.nodeId == widget.draggedNodeId
        ? _previewPosition ?? widget.nodePosition
        : widget.nodePosition;

    return Positioned(
      left: position.dx - widget.sceneOrigin.dx,
      top: position.dy - widget.sceneOrigin.dy,
      child: widget.child,
    );
  }

  void _updateDragPosition() {
    if (widget.nodeId == widget.draggedNodeId) {
      setState(() => _previewPosition = widget.dragPosition.value);
    }
  }
}

class const _WorkflowCanvasNode({
  required final WorkflowNode node,
  required final FocusNode focusNode,
  required final double focusOrder,
  required final bool selected,
  required final bool canEdit,
  required final WorkspaceWorkflow workflow,
  required final VoidCallback onSelect,
  required final ValueChanged<Offset> onMoveStart,
  required final ValueChanged<Offset> onMove,
  required final VoidCallback onMoveEnd,
  required final ValueChanged<WorkflowConditionBranch?> onAddNode,
  required final void Function(String, String, WorkflowConditionBranch?)
  onConnect,
  required final void Function(_WorkflowLinkDrag, Offset) onLinkDragUpdate,
  required final VoidCallback onLinkDragEnd,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final handleExtent = switch (node.kind) {
      .outputs => 0.0,
      .condition when canEdit => 106.0,
      _ when canEdit => 42.0,
      _ => 0.0,
    };

    return FocusTraversalOrder(
      order: NumericFocusOrder(focusOrder),
      child: Focus(
        focusNode: focusNode,
        onFocusChange: (hasFocus) {
          if (hasFocus) onSelect();
        },
        onKeyEvent: (focusNode, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            onSelect();
            return KeyEventResult.handled;
          }

          return KeyEventResult.ignored;
        },
        child: DragTarget<_WorkflowLinkDrag>(
          onWillAcceptWithDetails: (details) =>
              canEdit &&
              WorkflowGraphValidation.connectionRejection(
                    workflow,
                    sourceNodeId: details.data.sourceNodeId,
                    targetNodeId: node.id,
                    branch: details.data.branch,
                  ) ==
                  null,
          onAcceptWithDetails: (details) {
            onConnect(details.data.sourceNodeId, node.id, details.data.branch);
            onSelect();
          },
          builder: (context, candidates, rejected) {
            final rejectedDrag = rejected
                .whereType<_WorkflowLinkDrag>()
                .firstOrNull;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  width: WorkflowCanvasMetrics.nodeWidth + handleExtent,
                  height: WorkflowCanvasMetrics.nodeHeight,
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  width: WorkflowCanvasMetrics.nodeWidth,
                  height: WorkflowCanvasMetrics.nodeHeight,
                  child: GestureDetector(
                    onTap: onSelect,
                    onPanStart: canEdit
                        ? (details) => onMoveStart(details.globalPosition)
                        : null,
                    onPanUpdate: canEdit
                        ? (details) => onMove(details.globalPosition)
                        : null,
                    onPanEnd: canEdit ? (_) => onMoveEnd() : null,
                    onPanCancel: canEdit ? onMoveEnd : null,
                    child: Semantics(
                      button: true,
                      selected: selected,
                      label: '${node.label}, ${node.canonicalName}',
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: selected || candidates.isNotEmpty
                                ? context.auraColors.primary
                                : rejectedDrag != null
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).dividerColor,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: _WorkflowCanvasNodeContents(node: node),
                      ),
                    ),
                  ),
                ),
                if (rejectedDrag != null)
                  Positioned(
                    left: 0,
                    top: -36,
                    child: _WorkflowConnectionRejectionNotice(
                      rejection: WorkflowGraphValidation.connectionRejection(
                        workflow,
                        sourceNodeId: rejectedDrag.sourceNodeId,
                        targetNodeId: node.id,
                        branch: rejectedDrag.branch,
                      ),
                    ),
                  ),
                if (canEdit && node.kind != .outputs)
                  if (node.kind == .condition)
                    Positioned(
                      right: 0,
                      top: 28,
                      child: Column(
                        children: [
                          ExcludeFocus(
                            child: _WorkflowNodeAddHandle(
                              node: node,
                              branch: .trueBranch,
                              labelKey: LocaleKeys.workflow_editor_true,
                              onTap: () => onAddNode(.trueBranch),
                              onDragUpdate: onLinkDragUpdate,
                              onDragEnd: onLinkDragEnd,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ExcludeFocus(
                            child: _WorkflowNodeAddHandle(
                              node: node,
                              branch: .falseBranch,
                              labelKey: LocaleKeys.workflow_editor_false,
                              onTap: () => onAddNode(.falseBranch),
                              onDragUpdate: onLinkDragUpdate,
                              onDragEnd: onLinkDragEnd,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Positioned(
                      right: 0,
                      top: (WorkflowCanvasMetrics.nodeHeight - 42) / 2,
                      child: ExcludeFocus(
                        child: _WorkflowNodeAddHandle(
                          node: node,
                          onTap: () => onAddNode(null),
                          onDragUpdate: onLinkDragUpdate,
                          onDragEnd: onLinkDragEnd,
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class const _WorkflowConnectionRejectionNotice({
  required final WorkflowConnectionRejection? rejection,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final key = _connectionRejectionKey(rejection);
    if (key == null) return const SizedBox.shrink();

    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: TextLocale(
          key,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onErrorContainer),
        ),
      ),
    );
  }
}

String? _connectionRejectionKey(WorkflowConnectionRejection? rejection) =>
    switch (rejection) {
      .missingSource =>
        LocaleKeys.workflow_editor_connection_rejected_missing_source,
      .missingTarget =>
        LocaleKeys.workflow_editor_connection_rejected_missing_target,
      .maximumConnections =>
        LocaleKeys.workflow_editor_connection_rejected_maximum,
      .selfConnection => LocaleKeys.workflow_editor_connection_rejected_self,
      .outputsSource => LocaleKeys.workflow_editor_connection_rejected_outputs,
      .inputsTarget => LocaleKeys.workflow_editor_connection_rejected_inputs,
      .missingConditionBranch =>
        LocaleKeys.workflow_editor_connection_rejected_branch_required,
      .unexpectedConditionBranch =>
        LocaleKeys.workflow_editor_connection_rejected_branch_unexpected,
      .duplicate => LocaleKeys.workflow_editor_connection_rejected_duplicate,
      .cycle => LocaleKeys.workflow_editor_connection_rejected_cycle,
      null => null,
    };

class const _WorkflowCanvasNodeContents({required final WorkflowNode node})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fields = node.inputFields.isNotEmpty
        ? node.inputFields
        : node.outputFields;
    final summary = fields.take(2).map((field) => field.name).join(', ');

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(WorkflowNodeIcon.forKind(node.kind), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            node.canonicalName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (summary.isNotEmpty) ...[
            const Spacer(),
            Text(
              summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class const _WorkflowNodeAddHandle({
  required final WorkflowNode node,
  required final VoidCallback onTap,
  required final void Function(_WorkflowLinkDrag, Offset) onDragUpdate,
  required final VoidCallback onDragEnd,
  final WorkflowConditionBranch? branch,
  final String? labelKey,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final content = labelKey == null
        ? const Icon(Icons.add, size: 20)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextLocale(labelKey!),
              const SizedBox(width: 4),
              const Icon(Icons.add, size: 16),
            ],
          );
    final handle = Material(
      color: context.auraColors.surface,
      shape: const StadiumBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: labelKey == null ? 10 : 8,
            vertical: 8,
          ),
          child: content,
        ),
      ),
    );
    final drag = (sourceNodeId: node.id, branch: branch);

    return Tooltip(
      message: LocaleKeys.workflow_editor_add_node.tr(),
      child: Draggable<_WorkflowLinkDrag>(
        data: drag,
        maxSimultaneousDrags: 1,
        onDragUpdate: (details) => onDragUpdate(drag, details.globalPosition),
        onDraggableCanceled: (_, _) {
          onDragEnd();
        },
        onDragEnd: (_) => onDragEnd(),
        feedback: Material(
          color: Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle, color: context.auraColors.primary),
              if (branch != null) ...[
                const SizedBox(width: 6),
                TextLocale(
                  branch == .trueBranch
                      ? LocaleKeys.workflow_editor_true
                      : LocaleKeys.workflow_editor_false,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: context.auraColors.primary),
                ),
              ],
            ],
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.4, child: handle),
        child: handle,
      ),
    );
  }
}

class const _WorkflowGridPainter({required final Color color})
    extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..strokeWidth = WorkflowCanvasMetrics.gridStrokeWidth;
    for (var x = 0.0; x < size.width; x += WorkflowCanvasMetrics.gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += WorkflowCanvasMetrics.gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_WorkflowGridPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _WorkflowConnectionPainter extends CustomPainter {
  _WorkflowConnectionPainter({
    required this.workflow,
    required this.color,
    required this.sceneOrigin,
    required this.draggedNodeId,
    required this.dragPosition,
    required this.linkPreview,
    required this.selectedConnectionKey,
  }) : super(repaint: Listenable.merge([dragPosition, linkPreview]));

  final WorkspaceWorkflow workflow;
  final Color color;
  final Offset sceneOrigin;
  final String? draggedNodeId;
  final ValueListenable<Offset?> dragPosition;
  final ValueListenable<_WorkflowLinkPreview?> linkPreview;
  final WorkflowConnectionKey? selectedConnectionKey;

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = {for (final node in workflow.nodes) node.id: node};
    final previewPosition = dragPosition.value;
    final activeNodeId = draggedNodeId;
    if (previewPosition != null && activeNodeId != null) {
      final activeNode = nodes[activeNodeId];
      if (activeNode != null) {
        nodes[activeNodeId] = activeNode.copyWith(
          x: previewPosition.dx,
          y: previewPosition.dy,
        );
      }
    }

    canvas.save();
    canvas.translate(-sceneOrigin.dx, -sceneOrigin.dy);
    for (final connection in workflow.connections) {
      final path = WorkflowConnectionGeometry.pathForConnection(
        connection,
        nodes,
      );
      final start = WorkflowConnectionGeometry.start(connection, nodes);
      if (path == null || start == null) continue;
      final selected = _connectionKey(connection) == selectedConnectionKey;
      final paint = Paint()
        ..color = selected ? color : color.withValues(alpha: 0.72)
        ..strokeWidth = selected
            ? WorkflowCanvasMetrics.connectionStrokeWidth + 1.5
            : WorkflowCanvasMetrics.connectionStrokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, paint);
      canvas.drawCircle(
        start,
        WorkflowCanvasMetrics.connectionEndpointRadius,
        Paint()..color = color,
      );
    }

    final preview = linkPreview.value;
    if (preview != null) {
      final source = WorkflowConnection(
        fromNodeId: preview.drag.sourceNodeId,
        toNodeId: preview.drag.sourceNodeId,
        conditionBranch: preview.drag.branch,
      );
      final start = WorkflowConnectionGeometry.start(source, nodes);
      final path = start == null
          ? null
          : WorkflowConnectionGeometry.pathBetween(start, preview.pointer);
      if (start != null && path != null) {
        canvas.drawPath(
          path,
          Paint()
            ..color = color.withValues(alpha: 0.82)
            ..strokeWidth = WorkflowCanvasMetrics.connectionStrokeWidth
            ..style = PaintingStyle.stroke,
        );
        canvas.drawCircle(
          preview.pointer,
          WorkflowCanvasMetrics.connectionEndpointRadius,
          Paint()..color = color,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WorkflowConnectionPainter oldDelegate) =>
      oldDelegate.workflow != workflow ||
      oldDelegate.color != color ||
      oldDelegate.sceneOrigin != sceneOrigin ||
      oldDelegate.draggedNodeId != draggedNodeId ||
      oldDelegate.dragPosition != dragPosition ||
      oldDelegate.linkPreview != linkPreview ||
      oldDelegate.selectedConnectionKey != selectedConnectionKey;
}

class const _SelectedConnectionDeleteButton({
  required final WorkflowConnection connection,
  required final WorkspaceWorkflow workflow,
  required final TransformationController transform,
  required final Size viewportSize,
  required final double traversalOrder,
  required final ValueChanged<WorkflowConnection> onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: transform,
    builder: (context, child) {
      final matrix = transform.value;
      final path = WorkflowConnectionGeometry.pathForConnection(connection, {
        for (final node in workflow.nodes) node.id: node,
      });
      final midpoint = path == null
          ? null
          : WorkflowConnectionGeometry.midpoint(path);
      if (midpoint == null) return const SizedBox.shrink();
      final position = MatrixUtils.transformPoint(matrix, midpoint);
      if (!position.dx.isFinite ||
          !position.dy.isFinite ||
          position.dx < 0 ||
          position.dy < 0 ||
          position.dx > viewportSize.width ||
          position.dy > viewportSize.height) {
        return const SizedBox.shrink();
      }

      return Positioned(
        left: position.dx - 24,
        top: position.dy - 24,
        child: FocusTraversalOrder(
          order: NumericFocusOrder(traversalOrder),
          child: Material(
            elevation: 3,
            shape: const CircleBorder(),
            color: Theme.of(context).colorScheme.surface,
            child: IconButton(
              tooltip: LocaleKeys.workflow_editor_confirm_delete_connection.tr(
                context: context,
              ),
              onPressed: () => onDelete(connection),
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _WorkflowFocusOrders {
  const _WorkflowFocusOrders({
    required this.nodeOrders,
    required this.connectionOrders,
    required this.nextOrder,
  });

  final Map<String, double> nodeOrders;
  final Map<WorkflowConnectionKey, double> connectionOrders;
  final double nextOrder;

  factory _WorkflowFocusOrders.forWorkflow(WorkspaceWorkflow workflow) {
    final nodeOrders = <String, double>{};
    final connectionOrders = <WorkflowConnectionKey, double>{};
    var nextOrder = 0.0;
    final inputs = workflow.nodes.where((node) => node.kind == .inputs).toList()
      ..sort(_compareNodes);
    final outputs =
        workflow.nodes.where((node) => node.kind == .outputs).toList()
          ..sort(_compareNodes);
    final remaining = workflow.nodes
        .where((node) => node.kind != .inputs && node.kind != .outputs)
        .toList();
    final incomingCount = {for (final node in workflow.nodes) node.id: 0};
    for (final connection in workflow.connections) {
      if (incomingCount.containsKey(connection.toNodeId) &&
          remaining.any((node) => node.id == connection.fromNodeId)) {
        incomingCount.update(connection.toNodeId, (count) => count + 1);
      }
    }
    final ready = remaining
        .where((node) => incomingCount[node.id] == 0)
        .toList();
    final orderedNodes = <WorkflowNode>[];
    final visited = <String>{};
    while (ready.isNotEmpty) {
      ready.sort(_compareNodes);
      final node = ready.removeAt(0);
      if (!visited.add(node.id)) continue;
      orderedNodes.add(node);
      for (final connection in workflow.connections.where(
        (connection) => connection.fromNodeId == node.id,
      )) {
        final target = remaining
            .where((item) => item.id == connection.toNodeId)
            .firstOrNull;
        if (target == null) continue;
        final count = incomingCount[target.id]! - 1;
        incomingCount[target.id] = count;
        if (count == 0) ready.add(target);
      }
    }
    orderedNodes.addAll(
      remaining.where((node) => !visited.contains(node.id)).toList()
        ..sort(_compareNodes),
    );

    void addNodeAndLinks(WorkflowNode node) {
      nodeOrders[node.id] = nextOrder++;
      final outgoing =
          workflow.connections
              .where((connection) => connection.fromNodeId == node.id)
              .toList()
            ..sort((left, right) {
              final branchOrder = _branchOrder(left.conditionBranch)
                  .compareTo(_branchOrder(right.conditionBranch));
              if (branchOrder != 0) return branchOrder;
              final leftNode = workflow.nodes
                  .where((item) => item.id == left.toNodeId)
                  .firstOrNull;
              final rightNode = workflow.nodes
                  .where((item) => item.id == right.toNodeId)
                  .firstOrNull;
              if (leftNode == null || rightNode == null) {
                return left.toNodeId.compareTo(right.toNodeId);
              }

              return _compareNodes(leftNode, rightNode);
            });
      for (final connection in outgoing) {
        connectionOrders[_connectionKey(connection)] = nextOrder++;
      }
    }

    for (final node in inputs) {
      addNodeAndLinks(node);
    }
    for (final node in orderedNodes) {
      addNodeAndLinks(node);
    }
    for (final node in outputs) {
      nodeOrders[node.id] = nextOrder++;
    }

    return _WorkflowFocusOrders(
      nodeOrders: nodeOrders,
      connectionOrders: connectionOrders,
      nextOrder: nextOrder,
    );
  }
}

int _compareNodes(WorkflowNode left, WorkflowNode right) {
  final y = left.y.compareTo(right.y);
  if (y != 0) return y;
  final x = left.x.compareTo(right.x);
  if (x != 0) return x;

  return left.id.compareTo(right.id);
}

int _branchOrder(WorkflowConditionBranch? branch) => switch (branch) {
  .trueBranch => 0,
  .falseBranch => 1,
  null => 0,
};

WorkflowConnectionKey _connectionKey(WorkflowConnection connection) => (
  fromNodeId: connection.fromNodeId,
  toNodeId: connection.toNodeId,
  conditionBranch: connection.conditionBranch,
);

abstract final class WorkflowNodeIcon {
  static IconData forKind(WorkflowNodeKind kind) => switch (kind) {
    .inputs => Icons.play_arrow_outlined,
    .connectorTool => Icons.extension_outlined,
    .condition => Icons.call_split_outlined,
    .transform => Icons.transform_outlined,
    .workflow => Icons.account_tree_outlined,
    .outputs => Icons.stop_outlined,
  };
}
