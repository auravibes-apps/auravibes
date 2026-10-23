typedef WorkspaceAccess = ({String role});

extension WorkspaceAccessCapabilities on WorkspaceAccess {
  bool get isOwner => hasRole('owner');
  bool get canManage => isOwner || hasRole('admin');
  bool hasRole(String expected) => role == expected;
}
