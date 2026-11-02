import 'dart:math' as math;

import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:collection/collection.dart';
import 'package:flutter/painting.dart';

abstract final class WorkflowCanvasMetrics {
  static const nodeWidth = 280.0;
  static const nodeHeight = 132.0;
  static const minimumCurveOffset = 48.0;
  static const gridSpacing = 40.0;
  static const gridStrokeWidth = 1.0;
  static const connectionStrokeWidth = 2.5;
  static const connectionHitTargetWidth = 24.0;
  static const connectionEndpointRadius = 4.0;
}

typedef WorkflowConnectionKey = ({
  String fromNodeId,
  String toNodeId,
  WorkflowConditionBranch? conditionBranch,
});

abstract final class WorkflowConnectionGeometry {
  static Offset? start(
    WorkflowConnection connection,
    Map<String, WorkflowNode> nodes,
  ) {
    final node = nodes[connection.fromNodeId];
    if (node == null || !node.x.isFinite || !node.y.isFinite) return null;
    final branchOffset = switch (connection.conditionBranch) {
      .trueBranch => -WorkflowCanvasMetrics.nodeHeight / 4,
      .falseBranch => WorkflowCanvasMetrics.nodeHeight / 4,
      null => 0.0,
    };
    final point = Offset(
      node.x + WorkflowCanvasMetrics.nodeWidth,
      node.y + WorkflowCanvasMetrics.nodeHeight / 2 + branchOffset,
    );

    return _isFinite(point) ? point : null;
  }

  static Offset? end(
    WorkflowConnection connection,
    Map<String, WorkflowNode> nodes,
  ) {
    final node = nodes[connection.toNodeId];
    if (node == null || !node.x.isFinite || !node.y.isFinite) return null;
    final point = Offset(node.x, node.y + WorkflowCanvasMetrics.nodeHeight / 2);

    return _isFinite(point) ? point : null;
  }

  static Path? pathForConnection(
    WorkflowConnection connection,
    Map<String, WorkflowNode> nodes,
  ) {
    final startPoint = start(connection, nodes);
    final endPoint = end(connection, nodes);
    if (startPoint == null || endPoint == null) return null;

    return pathBetween(startPoint, endPoint);
  }

  static Path? pathBetween(Offset startPoint, Offset endPoint) {
    final horizontalDistance = endPoint.dx - startPoint.dx;
    if (!horizontalDistance.isFinite) return null;
    final controlOffset = math.max(
      WorkflowCanvasMetrics.minimumCurveOffset,
      horizontalDistance.abs() / 2,
    );
    final firstControl = Offset(startPoint.dx + controlOffset, startPoint.dy);
    final secondControl = Offset(endPoint.dx - controlOffset, endPoint.dy);
    if (!_isFinite(firstControl) || !_isFinite(secondControl)) return null;

    return Path()
      ..moveTo(startPoint.dx, startPoint.dy)
      ..cubicTo(
        firstControl.dx,
        firstControl.dy,
        secondControl.dx,
        secondControl.dy,
        endPoint.dx,
        endPoint.dy,
      );
  }

  static Offset? midpoint(Path path) {
    final metric = path.computeMetrics().firstOrNull;
    if (metric == null || !metric.length.isFinite) return null;

    final point = metric.getTangentForOffset(metric.length / 2)?.position;
    return point != null && _isFinite(point) ? point : null;
  }

  static double distanceToPath(Offset point, Path path) {
    final bounds = path.getBounds();
    if (!_isFinite(point) || !_isFiniteRect(bounds)) {
      return double.infinity;
    }
    if (!bounds
        .inflate(WorkflowCanvasMetrics.connectionHitTargetWidth / 2)
        .contains(point)) {
      return double.infinity;
    }

    for (final metric in path.computeMetrics()) {
      final samples = (metric.length / 24).clamp(1.0, 96.0).round();
      var previous = metric.getTangentForOffset(0)?.position;
      for (var index = 1; index <= samples; index++) {
        final current = metric
            .getTangentForOffset(metric.length * index / samples)
            ?.position;
        if (previous != null && current != null) {
          final distance = _distanceToSegment(point, previous, current);
          if (distance < WorkflowCanvasMetrics.connectionHitTargetWidth / 2) {
            return distance;
          }
        }
        previous = current;
      }
    }

    return double.infinity;
  }

  static double _distanceToSegment(Offset point, Offset start, Offset end) {
    final delta = end - start;
    final lengthSquared = delta.distanceSquared;
    if (!lengthSquared.isFinite) return double.infinity;
    if (lengthSquared == 0) return (point - start).distance;

    final ratio =
        (((point - start).dx * delta.dx + (point - start).dy * delta.dy) /
                lengthSquared)
            .clamp(0.0, 1.0);

    return (point - (start + delta * ratio)).distance;
  }

  static bool _isFinite(Offset point) => point.dx.isFinite && point.dy.isFinite;

  static bool _isFiniteRect(Rect rect) =>
      rect.left.isFinite &&
      rect.top.isFinite &&
      rect.right.isFinite &&
      rect.bottom.isFinite;
}
