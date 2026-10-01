# Workspaces, cloud accounts, and access recovery

[Audit index](README.md) · Screens S07–S14 · Findings UX-12–UX-16

## Goals

Open the correct workspace, know whether its data and execution are local or cloud, connect an accessible cloud workspace, and manage access without confusing device removal with permanent cloud deletion. Account identity is shared app context; workspace content and role are separate concepts.

## Current journeys

| Step | Create a local workspace | Create/connect a cloud workspace | Recovery/alternative |
| --- | --- | --- | --- |
| 1 | More → Workspaces | More → Cloud accounts, or account action from Create Workspace | First-run cloud gap: UX-06 |
| 2 | Create Workspace | Add account chooser → Login or Register | Login supports password reset |
| 3 | Name + Local workspace | Authenticate; registration includes code verification | ReturnPath preserved when supplied |
| 4 | Create → New Chat in new workspace | Return to initiating create flow or Accounts | Draft restoration needs live verification |
| 5 | Connect AI if needed | Create cloud workspace using account, or find an available workspace in manager | Expired session has Sign in again |
| 6 | Use workspace | Connect to this app, then open workspace | Connected elsewhere is a distinct state |
| 7 | Rename/duplicate/archive/delete | Members/invites/ownership, remove shortcut, leave, delete | Capability and role checks apply |

Evidence: E10–E13 and E23. Successful server transactions are unverified.

## S07 — Workspace management

**Current purpose:** manage Local workspaces, Connected cloud workspaces, and Available cloud workspaces. It also owns search, sorting, selection, bulk actions, local archive operations, switching, and inline name editing.

**Strengths:** separate source sections; active marker; search and sort; cloud authentication recovery; distinctions between attached and available workspaces; delete/remove confirmations; inline rename guard; archive feedback.

**Recommendation:** keep one manager reached from the workspace header. Default to workspaces the person can open now. Put cloud discovery and pending access in a clear Connect workspace subview or expansion. Avoid introducing a second ordinary workspace list elsewhere.

### UX-12 — Workspace opening and cloud discovery share a busy lifecycle surface

- **Task step/view:** S07 when a person simply wants to open another workspace.
- **Evidence:** E10; `_WorkspaceSourceSections` renders local, connected, and available cloud sections after shared search/management actions. The same screen offers import/export, bulk deletion, edit, switch, attach, and detach.
- **User problem and impact:** opening an existing workspace competes with discovery and administration. Multiple representations of a cloud workspace may need an explanation of attached versus available.
- **Severity:** medium. **Confidence:** medium.
- **Change:** a primary Open workspace list with Local/Cloud/status badges; a secondary Connect cloud workspace view with account identity and connection state. Retain filters for larger collections.
- **Preserve:** mirror identity, connected-through account, active workspace, all archive actions, and connected-elsewhere checks.
- **Verification:** with local, attached cloud, unconnected cloud, and duplicate-access examples, ask the participant to open one and connect another. They should distinguish opening from connecting without creating duplicates.

### UX-13 — Bulk deletion combines different consequences behind one action

- **Task step/view:** select local and connected cloud entries in S07 and invoke bulk delete.
- **Evidence:** E10; bulk confirmation explains that local workspaces are deleted from the device while cloud workspaces are removed from the app. Individual cloud remove copy additionally states local chats/files are deleted and cloud data remains.
- **User problem and impact:** the common action name “Delete selected” can imply either permanent cloud deletion or harmless shortcut removal. Existing confirmation helps, but mixed selection still asks the person to reconcile different outcomes.
- **Severity:** medium. **Confidence:** medium.
- **Change:** an itemized confirmation grouped by consequence, with counts and names: local deletion versus cloud removal with local-data cleanup. Use “Remove selected” only when the selected objects share that consequence; otherwise use an explicit mixed-action label.
- **Preserve:** cancellation, partial-failure reporting, safe navigation to the next workspace or Intro after active workspace removal, and the distinction between removing, leaving, and deleting cloud content. Implementation planning confirmed that the existing usecase permits active and last workspace removal; no new prohibition is proposed.
- **Verification:** before confirmation, ask what happens on this device and in the cloud. Cancel must change nothing. Partial failures must identify the unchanged objects and offer targeted recovery.

## S08 — Workspace creation

**Current purpose:** name a workspace and choose local or an account-backed target. **Strengths:** same form as onboarding, name validation, explicit target label, add-account returnPath in later creation, creating/error states, dirty-pop protection.

**Recommendation:** make location legible as Local on this device / Cloud through [account], and show the relevant tradeoff alongside that choice. Preserve the typed name across any account flow. Successful creation opens the new workspace, so say that before the action.

**Source caveat:** the add-account action navigates with go, and the form's dirty protection uses PopScope. This does not establish that route replacement preserves or guards the draft. The proposed test in UX-25 covers it.

**Merge boundary:** reuse creation across onboarding and later management; do not stack unrelated member/ownership administration into this form.

## S09 — Cloud workspace detail

**Current purpose:** connect/remove locally, rename, see/manage members, invite, renew/revoke invites, transfer ownership, leave, and delete cloud workspace. Actions depend on capabilities and role.

**Strengths:** role-dependent visibility; separate local removal and cloud deletion copy; named confirmation for permanent deletion; member-role and ownership controls; server revision information passed to invite actions.

**Recommendation:** title the page with the actual workspace name and show account, role, connected-to-device state, and execution/storage context. Group Connect to this app, Members & invitations, and consequential lifecycle actions. Local removal, leaving a team, and permanent cloud deletion must remain separate.

**Recovery limits:** the source uses generic cloud action feedback in several places. Confirm whether failures can distinguish stale role/revision, expired authentication, no network, and ownership prerequisites. Link people to the relevant recovery; do not merely duplicate raw backend errors.

**Do not merge:** a workspace detail page with all account identities. Account deletion affects multiple workspaces and has different ownership prerequisites.

## S10 — Cloud accounts

**Current purpose:** list stored cloud identities and remove them from the app or permanently delete them. **Strengths:** no-server state, empty state, separate remove/delete actions, local mirror warnings, ownership-transfer error, and cleanup failure feedback.

**Recommendation:** reach this from account/workspace context rather than treating it as a workspace-only capability. Show server or service identity when multiple identities could be ambiguous. Keep permanent account deletion away from ordinary connection repair without removing access to it.

### UX-16 — Account health is expressed differently across screens

- **Task step/view:** S10 account list versus S07 expired cloud access.
- **Evidence:** E13; each listed account renders a static “Signed in” label. E10 has a distinct Needs sign in/session-expired block in workspace discovery.
- **User problem and impact:** a stored account and a currently verified session can be mistaken for the same thing. A person recovering access can receive conflicting guidance depending on the destination.
- **Severity:** medium. **Confidence:** medium; session-expiry behavior has not been run.
- **Change:** distinguish account stored, session verified, session expired, and health unknown. Reuse consistent reconnect actions and avoid asserting Signed in solely because a stored record exists.
- **Preserve:** multiple accounts, server identity, removal versus deletion, and ownership restrictions.
- **Verification:** expire/revoke one test session, then inspect Accounts and Workspaces. Both should agree on what is known, offer reauthentication, and preserve the intended workspace return.

## S11 — Add cloud account

**Current purpose:** explain cloud value and route to Login or Register. It already explains that people return to their cloud flow.

### UX-14 — The account chooser repeats a decision that can sit on the login screen

- **Task step/view:** Cloud accounts → Add cloud account → Log in or Create account.
- **Evidence:** E13; S11 has explanation and two navigation buttons. S12/S13 already link between login and registration and preserve returnPath.
- **User problem and impact:** an extra view exists primarily to choose between two neighboring auth states.
- **Severity:** low. **Confidence:** medium.
- **Change:** open Log in by default with a clear Create account alternative in one auth shell. Place the cloud explanation and return hint there.
- **Preserve:** explicit consent to choose login versus registration, return context, and password recovery. Do not automatically register or submit credentials.
- **Verification:** compare the current chooser and proposed entry on existing-account and new-account tasks. Keep the chooser if testing shows its explanation materially improves choice clarity.

## S12 — Cloud login

**Current purpose:** authenticate, with registration and reset links. **Strengths:** dedicated form, localized loading/errors, password masking, keyboard actions, and returnPath completion.

**Recommendation:** label the cloud service and destination being unlocked. Use one clear Log in action; keep Create account and Forgot password secondary. Cancellation should return to the initiating workspace task with safe draft restoration.

**State checks:** valid/invalid credentials; no configured server; unreachable service; expired account; multiple identities; OAuth/browser state if applicable to the specific provider; canceled recovery; keyboard submission; secret disclosure prevention.

## S13 — Cloud registration

**Current purpose:** email/password submission followed by a verification code. **Strengths:** password policy help, code invalid/expired error distinctions, Resend code, Edit email, loading protection, and returnPath.

### UX-15 — Authentication headers and recovery copy expose implementation steps

- **Task step/view:** registration entry and verification; reset-code verification.
- **Evidence:** E13; the registration screen title uses `workspace_management.cloud_register`, translated as “Send code.” The registration and reset forms unconditionally render the local-development server-log hint in their code states. Resend success copy also references local development.
- **User problem and impact:** a screen titled Send code does not explain that the task is creating an account. A person outside development cannot recover by reading server logs and may infer that no usable email route exists.
- **Severity:** medium. **Confidence:** medium.
- **Change:** titles “Create cloud account,” then “Verify your email”; show the destination email, resend/edit actions, and truthful delivery guidance. Restrict development instructions to the development experience or an intentional diagnostic disclosure.
- **Preserve:** verification security, invalid/expired code distinctions, rate-limiting behavior, and returnPath.
- **Verification:** review both configured production email delivery and local development. Production should give a person a reachable next action; development instructions should not obscure the regular verification task.

## S14 — Password recovery

**Current purpose:** request reset code, then submit code and a new password, and return to Login. **Strengths:** clear reset introduction, password policy, resend/edit email, keyboard actions, and preserved returnPath into login.

**Recommendation:** retain this as a separate task state. Show the account email during verification and explain successful password change before login. Keep reset errors recoverable without losing unrelated workspace context. Apply UX-15 to delivery instructions.

**Do not merge:** code entry into the ordinary login form as a collection of additional always-visible fields. A shared shell can preserve progress and reduce route duplication while keeping the active task clear.

## Shared consequence language

| Action | Target | Required explanation |
| --- | --- | --- |
| Switch workspace | Active app context | Where the person goes and whether unsaved work is preserved |
| Connect to this app | Cloud workspace shortcut/mirror | Access becomes available on this device; cloud identity remains |
| Remove from this app | Shortcut and local workspace data | Local chats/files removed; cloud content remains |
| Leave workspace | Membership | Access ends; explain local cleanup |
| Delete cloud workspace | Cloud content and local data | Permanent scope; name confirmation and affected members |
| Remove account from app | Stored identity/session and mirrors | Cloud data remains; linked local shortcuts removed |
| Delete account | Cloud identity | Ownership prerequisites and end of access; unrelated shared content remains |

These distinctions are partly already present in current confirmations. The recommendation is to carry them into entry labels, groupings, and completion feedback consistently.
## Implementation checkpoint

The shared header and guarded workspace switching are verified in Tasks 1 and 2. It exposes Manage, Create, Connect cloud and Workspace settings on the existing routes. App/account scope is explicit in navigation; Task 3b1 verifies account/auth reachability behind a failed workspace session while keeping data routes gated.

Task 3a is verified for canonical server/account identity, shared checked health, connected/discovery views, itemized consequences and cloud detail orientation. Its reviewed repair prevents a second mirror through another account, updates targeted health after invitation authentication errors and keeps recovery in the initiating manager workspace. The affected/shared-opener suites pass 172 cases; focused/full fatal scans have zero diagnostics. Device removal remains distinct from remote leaving/deletion; preexisting mirrors are neither merged nor rebound. These consequences and role boundaries passed controlled fixtures, while participant understanding remains unmeasured. [Evidence](14-execution-evidence.md#task-3a-verified-handoff) separates these fixtures from pending current captures and live/native results.

Task 3b1 is verified for shared authentication, exact-account recovery, failed-session reachability and safe task return. Its reviewed repair prevents delayed login, registration or reset from navigating away after a branch switch; verified account persistence remains valid. All 33 affected cases pass, final full analysis has zero diagnostics and scoped review has zero open/new findings. [Auth handoff](14-execution-evidence.md#task-3b1-verified-handoff) records the full checks. Task 3b2 is verified for zero-workspace cloud entry, canonical account selection, shared discovery and retained creation intent. Its reviewed pending-create repair prevents intent/auth transitions from losing a successful handoff and restores controls after failure; [first-use evidence](14-execution-evidence.md#task-3b2-verified-handoff) records the checks. Production registration/reset email delivery has a named external blocker. [Progress](progress.md) keeps that requirement separate from controlled form evidence.

## Task 7 validation checkpoint

Controlled zero-account authentication/create and expired-session attachment preserve the intended cloud identity. Origin, connected/discovery, role and itemized consequence fixtures retain their reviewed results. Cloud native-tool restrictions are shown together with accurate alternatives. These tests do not prove live account/email delivery, cloud availability or participant consequence prediction. See [current coverage](15-validation-coverage.md#current-implementation-evidence--task-7) and [execution evidence](14-execution-evidence.md#task-7-final-attempt-2-results-and-bounded-correction).
