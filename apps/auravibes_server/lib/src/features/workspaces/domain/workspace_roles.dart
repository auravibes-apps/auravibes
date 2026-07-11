abstract final class WorkspaceRoles {
  static const owner = 'owner';
  static const admin = 'admin';
  static const member = 'member';

  static const values = {owner, admin, member};

  static bool isValid(String role) => values.contains(role);

  static bool canViewRoster(String role) => role == owner || role == admin;

  static bool canInvite(String actorRole, String invitedRole) =>
      actorRole == owner && invitedRole != owner ||
      actorRole == admin && invitedRole == member;

  static bool canManageTarget(String actorRole, String targetRole) =>
      actorRole == owner && targetRole != owner ||
      actorRole == admin && targetRole == member;

  static bool canAssignRole(String actorRole, String targetRole, String role) =>
      role != owner &&
      canManageTarget(actorRole, targetRole) &&
      (actorRole == owner || role == member);
}
