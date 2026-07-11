import 'package:auravibes_server/src/features/workspaces/domain/workspace_roles.dart';
import 'package:auravibes_server/src/features/workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:test/test.dart';

void main() {
  test('workspace roles define role and roster permissions', () {
    expect(WorkspaceRoles.isValid(WorkspaceRoles.owner), isTrue);
    expect(WorkspaceRoles.isValid(WorkspaceRoles.admin), isTrue);
    expect(WorkspaceRoles.isValid(WorkspaceRoles.member), isTrue);
    expect(WorkspaceRoles.isValid('viewer'), isFalse);

    expect(WorkspaceRoles.canViewRoster(WorkspaceRoles.owner), isTrue);
    expect(WorkspaceRoles.canViewRoster(WorkspaceRoles.admin), isTrue);
    expect(WorkspaceRoles.canViewRoster(WorkspaceRoles.member), isFalse);
  });

  test('owner and admin invitation policy differs', () {
    expect(
      WorkspaceRoles.canInvite(WorkspaceRoles.owner, WorkspaceRoles.admin),
      isTrue,
    );
    expect(
      WorkspaceRoles.canInvite(WorkspaceRoles.admin, WorkspaceRoles.member),
      isTrue,
    );
    expect(
      WorkspaceRoles.canInvite(WorkspaceRoles.admin, WorkspaceRoles.admin),
      isFalse,
    );
    expect(
      WorkspaceRoles.canInvite(WorkspaceRoles.owner, WorkspaceRoles.owner),
      isFalse,
    );
  });

  test('owner and admin member management policy differs', () {
    expect(
      WorkspaceRoles.canAssignRole(
        WorkspaceRoles.owner,
        WorkspaceRoles.member,
        WorkspaceRoles.admin,
      ),
      isTrue,
    );
    expect(
      WorkspaceRoles.canAssignRole(
        WorkspaceRoles.admin,
        WorkspaceRoles.member,
        WorkspaceRoles.admin,
      ),
      isFalse,
    );
    expect(
      WorkspaceRoles.canManageTarget(
        WorkspaceRoles.admin,
        WorkspaceRoles.admin,
      ),
      isFalse,
    );
    expect(
      WorkspaceRoles.canManageTarget(
        WorkspaceRoles.owner,
        WorkspaceRoles.owner,
      ),
      isFalse,
    );
  });

  test('capabilities follow owner admin and member policy', () {
    final owner = CloudWorkspaceUseCases.capabilitiesForRole(
      WorkspaceRoles.owner,
    );
    final admin = CloudWorkspaceUseCases.capabilitiesForRole(
      WorkspaceRoles.admin,
    );
    final member = CloudWorkspaceUseCases.capabilitiesForRole(
      WorkspaceRoles.member,
    );

    expect(owner.canInviteAdmins, isTrue);
    expect(owner.canManageAdmins, isTrue);
    expect(owner.canRename, isTrue);
    expect(owner.canTransferOwnership, isTrue);
    expect(owner.canLeave, isFalse);
    expect(owner.canDelete, isTrue);

    expect(admin.canViewMembers, isTrue);
    expect(admin.canInviteMembers, isTrue);
    expect(admin.canInviteAdmins, isFalse);
    expect(admin.canManageMembers, isTrue);
    expect(admin.canManageAdmins, isFalse);
    expect(admin.canRename, isFalse);
    expect(admin.canLeave, isTrue);

    expect(member.canViewMembers, isFalse);
    expect(member.canInviteMembers, isFalse);
    expect(member.canManageMembers, isFalse);
    expect(member.canLeave, isTrue);
  });
}
