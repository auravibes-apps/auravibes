import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';

ToolPermissionMode mapPermissionAccess(PermissionAccess access) =>
    switch (access) {
      .ask => .alwaysAsk,
      .granted => .alwaysAllow,
      .denied => .alwaysDeny,
    };

PermissionAccess mapPermissionMode(ToolPermissionMode mode) => switch (mode) {
  .alwaysAsk => .ask,
  .alwaysAllow => .granted,
  .alwaysDeny => .denied,
};
