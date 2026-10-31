import 'dart:math' as math;

import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_graph_validation.dart';
import 'package:flutter/painting.dart';

abstract final class WorkflowCanvasMetrics {
  static const canvasWidth = 1600.0;
  static const canvasHeight = 1000.0;
  static const nodeWidth = 280.0;
  static const nodeHeight = 132.0;
  static const canvasPadding = 100.0;
  static const minimumPosition = 0.0;
  static const minimumCurveOffset = 48.0;
  static const gridSpacing = 40.0;
  static const gridStrokeWidth = 1.0;
  static const connectionStrokeWidth = 2.5;
  static const connectionEndpointRadius = 4.0;
}

abstract final class WorkflowCanvasLayout {
  static Size sizeFor(WorkspaceWorkflow workflow) => Size(
    math.max(
      WorkflowCanvasMetrics.canvasWidth,
      _maxNodeRight(workflow.nodes) + WorkflowCanvasMetrics.canvasPadding,
    ),
    math.max(
      WorkflowCanvasMetrics.canvasHeight,
      _maxNodeBottom(workflow.nodes) + WorkflowCanvasMetrics.canvasPadding,
    ),
  );

  static double _maxNodeRight(List<WorkflowNode> nodes) => nodes.fold<double>(
    WorkflowCanvasMetrics.canvasPadding,
    (right, node) => math.max(
      right,
      WorkflowConnectionGeometry.boundedPosition(node.x) +
          WorkflowCanvasMetrics.nodeWidth,
    ),
  );

  static double _maxNodeBottom(List<WorkflowNode> nodes) => nodes.fold<double>(
    WorkflowCanvasMetrics.canvasPadding,
    (bottom, node) => math.max(
      bottom,
      WorkflowConnectionGeometry.boundedPosition(node.y) +
          WorkflowCanvasMetrics.nodeHeight,
    ),
  );
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
  ) {
    final node = nodes[connection.fromNodeId];
    if (node == null) return null;
    final branchOffset = switch (connection.conditionBranch) {
      .trueBranch => -WorkflowCanvasMetrics.nodeHeight / 4,
      .falseBranch => WorkflowCanvasMetrics.nodeHeight / 4,
      null => 0.0,
    };

    return Offset(
      boundedPosition(node.x) + WorkflowCanvasMetrics.nodeWidth,
      boundedPosition(node.y) +
          WorkflowCanvasMetrics.nodeHeight / 2 +
          branchOffset,
    );
  }

  static Offset? end(
    WorkflowConnection connection,
    Map<String, WorkflowNode> nodes,
  ) {
    final node = nodes[connection.toNodeId];
    if (node == null) return null;

    return Offset(
      boundedPosition(node.x),
      boundedPosition(node.y) + WorkflowCanvasMetrics.nodeHeight / 2,
    );
  }
}
