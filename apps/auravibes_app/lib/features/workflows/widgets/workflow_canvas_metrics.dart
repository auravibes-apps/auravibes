import 'dart:math' as math;

import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_graph_validation.dart';
import 'package:flutter/painting.dart';

abstract final class WorkflowCanvasMetrics {
  static const canvasWidth = 2500.0;
  static const canvasHeight = 1500.0;
  static const boundaryWidth = 260.0;
  static const nodeWidth = 260.0;
  static const portHeight = 28.0;
  static const nodeHeaderHeight = 40.0;
  static const boundaryHeaderHeight = 38.0;
  static const inputBoundaryLeft = 40.0;
  static const outputBoundaryLeft = 2200.0;
  static const boundaryTop = 60.0;
  static const canvasPadding = 80.0;
  static const minimumPosition = 0.0;
  static const minimumPortRows = 1;
  static const headerDividerHeight = 1.0;
  static const boundaryPortCenterOffset = 14.0;
  static const nodePortCenterOffset = 15.0;
  static const minimumCurveOffset = 48.0;
  static const gridSpacing = 40.0;
  static const gridStrokeWidth = 1.0;
  static const connectionStrokeWidth = 2.5;
  static const connectionEndpointRadius = 4.0;
  static const int maximumPortRows =
      WorkflowGraphValidation.maximumWorkflowCollectionSize;
}

abstract final class WorkflowCanvasLayout {
  static Size sizeFor(WorkspaceWorkflow workflow) {
    final double width = math.max(
      WorkflowCanvasMetrics.canvasWidth,
      _maxNodeRight(workflow.nodes) + WorkflowCanvasMetrics.canvasPadding,
    );
    final double height = math.max(
      WorkflowCanvasMetrics.canvasHeight,
      _maxContentBottom(workflow) + WorkflowCanvasMetrics.canvasPadding,
    );

    return Size(width, height);
  }

  static double _maxNodeRight(List<WorkflowNode> nodes) => nodes.fold<double>(
    WorkflowCanvasMetrics.outputBoundaryLeft +
        WorkflowCanvasMetrics.boundaryWidth,
    (right, node) => math.max(
      right,
      WorkflowConnectionGeometry.boundedPosition(node.x) +
          WorkflowCanvasMetrics.nodeWidth,
    ),
  );

  static double _maxContentBottom(WorkspaceWorkflow workflow) => math.max(
    _maxNodeBottom(workflow.nodes),
    _boundaryBottom(workflow.inputs, workflow.outputs),
  );

  static double _maxNodeBottom(List<WorkflowNode> nodes) => nodes.fold<double>(
    WorkflowCanvasMetrics.minimumPosition,
    (bottom, node) => math.max(bottom, _nodeBottom(node)),
  );

  static double _nodeBottom(WorkflowNode node) =>
      WorkflowConnectionGeometry.boundedPosition(node.y) +
      WorkflowCanvasMetrics.nodeHeaderHeight +
      WorkflowCanvasMetrics.headerDividerHeight +
      _portRows(node.inputs.length, node.outputs.length) *
          WorkflowCanvasMetrics.portHeight;

  static double _boundaryBottom(
    List<WorkflowPort> inputs,
    List<WorkflowPort> outputs,
  ) =>
      WorkflowCanvasMetrics.boundaryTop +
      WorkflowCanvasMetrics.boundaryHeaderHeight +
      WorkflowCanvasMetrics.headerDividerHeight +
      _portRows(inputs.length, outputs.length) *
          WorkflowCanvasMetrics.portHeight;

  static double _portRows(int first, int second) => math
      .max(first, second)
      .clamp(
        WorkflowCanvasMetrics.minimumPortRows,
        WorkflowCanvasMetrics.maximumPortRows,
      )
      .toDouble();
}

abstract final class WorkflowConnectionGeometry {
  static double boundedPosition(double value) => value.isFinite
      ? value.clamp(
          WorkflowCanvasMetrics.minimumPosition,
          WorkflowGraphValidation.maxWorkflowNodePosition,
        )
      : WorkflowCanvasMetrics.minimumPosition;

  static Offset? start(
    WorkflowConnection connection,
    Map<String, WorkflowNode> nodes,
    List<WorkflowPort> workflowInputs,
  ) => connection.fromNodeId == null
      ? _boundaryStart(connection.fromPortId, workflowInputs)
      : _nodeStart(connection, nodes);

  static Offset? end(
    WorkflowConnection connection,
    Map<String, WorkflowNode> nodes,
    List<WorkflowPort> workflowOutputs,
  ) => connection.toNodeId == null
      ? _boundaryEnd(connection.toPortId, workflowOutputs)
      : _nodeEnd(connection, nodes);

  static Offset? _boundaryStart(String portId, List<WorkflowPort> ports) {
    final index = _portIndex(ports, portId);
    if (index < WorkflowCanvasMetrics.minimumPosition) return null;

    return Offset(
      WorkflowCanvasMetrics.inputBoundaryLeft +
          WorkflowCanvasMetrics.boundaryWidth,
      WorkflowCanvasMetrics.boundaryTop +
          WorkflowCanvasMetrics.boundaryHeaderHeight +
          WorkflowCanvasMetrics.boundaryPortCenterOffset +
          WorkflowCanvasMetrics.portHeight * index,
    );
  }

  static Offset? _boundaryEnd(String portId, List<WorkflowPort> ports) {
    final index = _portIndex(ports, portId);
    if (index < WorkflowCanvasMetrics.minimumPosition) return null;

    return Offset(
      WorkflowCanvasMetrics.outputBoundaryLeft,
      WorkflowCanvasMetrics.boundaryTop +
          WorkflowCanvasMetrics.boundaryHeaderHeight +
          WorkflowCanvasMetrics.boundaryPortCenterOffset +
          WorkflowCanvasMetrics.portHeight * index,
    );
  }

  static Offset? _nodeStart(
    WorkflowConnection connection,
    Map<String, WorkflowNode> nodes,
  ) {
    final node = nodes[connection.fromNodeId];
    if (node == null) return null;
    final index = _portIndex(node.outputs, connection.fromPortId);
    if (index < WorkflowCanvasMetrics.minimumPosition) return null;

    return Offset(
      boundedPosition(node.x) + WorkflowCanvasMetrics.nodeWidth,
      _nodePortCenterY(node.y, index),
    );
  }

  static Offset? _nodeEnd(
    WorkflowConnection connection,
    Map<String, WorkflowNode> nodes,
  ) {
    final node = nodes[connection.toNodeId];
    if (node == null) return null;
    final index = _portIndex(node.inputs, connection.toPortId);
    if (index < WorkflowCanvasMetrics.minimumPosition) return null;

    return Offset(boundedPosition(node.x), _nodePortCenterY(node.y, index));
  }

  static int _portIndex(List<WorkflowPort> ports, String portId) =>
      ports.indexWhere((port) => port.id == portId);

  static double _nodePortCenterY(double nodeY, int index) =>
      boundedPosition(nodeY) +
      WorkflowCanvasMetrics.nodeHeaderHeight +
      WorkflowCanvasMetrics.nodePortCenterOffset +
      WorkflowCanvasMetrics.portHeight * index;
}
