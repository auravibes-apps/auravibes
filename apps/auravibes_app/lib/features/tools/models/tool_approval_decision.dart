import 'package:auravibes_app/domain/enums/tool_permission_result.dart';

class const ToolApprovalDecision({
  required final String toolCallId,
  required final ToolPermissionResult permissionResult,
  final String? permissionTableId,
}) {
  bool get needsConfirmation =>
      permissionResult == ToolPermissionResult.needsConfirmation;
}
