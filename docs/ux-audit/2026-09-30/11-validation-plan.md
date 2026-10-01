# Validation and completion plan

[Audit index](README.md) · [Finding register](10-prioritized-roadmap.md)

## Evidence still needed

The source review is complete for the inventoried app screens. Current screenshots, executed task traces, keyboard/screen-reader results, backend authentication results, and user research are still required to validate visual and interaction conclusions. The recommendations are reviewable proposals, not proven usability gains.

## Runtime setup

Use the repository-pinned Flutter/Dart toolchain and its documented isolated dev-app control path. Follow [Marionette instructions](../../../.agents/skills/marionette-mcp/SKILL.md) before launching or controlling the app. Use unique instance IDs and verify exact instance identity. Do not connect to an arbitrary running app or use real production customer data for fixtures.

On a configured macOS development machine, the documented smoke launch is:

```sh
fvm dart run tool/marionette_run.dart --instance-id ux-audit --device macos
```

The MCP bridge is repository-local `fvm dart run marionette_mcp`; its manifest/VM URI and identity checks are in the skill. Use the CLI wrapper only when MCP cannot be maintained. For browser/platform targets, follow the corresponding repository control path and renderer requirements rather than assuming a macOS smoke run verifies Web/iOS behavior.

This command was not run during the original source audit: FVM, Flutter, and Dart were absent. The implementation continuation has since installed the exact pinned SDK, bootstrapped dependencies and passed 70 focused baseline tests. Current execution evidence and remaining platform limits are recorded in [progress.md](progress.md). A macOS launch manifest and screenshots have not been produced in this Linux environment.

## Capture protocol

1. Record source revision, platform/renderer, app flavor, locale, viewport, theme, and fixture state.
2. Capture every original S01–S27 screen and every new implementation screen, or record its blocker. Include shared create/edit and built-in/read-only modes; do not infer them from one unrelated screenshot.
3. Before each action, inspect current controls and target stable keys/semantics. After the action, check the fresh state.
4. Save numbered screenshots and inspect each saved image. Reject loading, blank, wrong-state, or cropped captures as evidence of the intended completed state.
5. Add screenshot links beside the corresponding report's findings; keep source references as behavioral context.
6. Record actual navigation, focus, draft, validation, and backend results. Separate failure caused by missing test infrastructure from product failure.
7. For every recommendation, note confirmed, rejected, revised, or still unverified. Retain the reason and task result.

Use deterministic fixture data and redact secrets/identifying details. No fixture secret or ephemeral VM-service URI belongs in the Markdown report.

## Representative fixtures

| Fixture | States it should cover |
| --- | --- |
| Empty local app | No workspaces, accounts, providers, custom skills, or credential types |
| Local workspace ready for chat | Valid provider and models; model selected/unselected; optional agent |
| Local integration failure | Controlled authentication/network/protocol failure and safe recovery |
| Custom authoring workspace | Skill with resources/template tool; schema; named saved credential; two agents sharing a skill |
| Partial readiness | Disabled selected skill; missing/optional/unknown access; stale metadata; missing override target |
| Controlled cloud workspace | Connected/unconnected/connected-elsewhere; owner/admin/member roles; expired session |
| Large lists | Enough chats, agents, skills, connections, and workspaces to exercise search/filter/pagination |
| Busy conversation | Controlled queued drafts, tool approvals, retry timing, and delegated task states |

No successful external mutation should be exercised against production solely for the audit. Use local fixtures or an explicitly controlled test backend.

## Task scenarios

Targets are proposed acceptance conditions, not measured results. Participants should explain their reasoning without being taught the proposed navigation first.

| ID | Task | Conditions and observable success | Findings |
| --- | --- | --- | --- |
| T01 | Start the first local chat | Create workspace, connect AI, choose model, send through controlled fixture; clear return/next step | UX-01, UX-07, UX-08 |
| T02 | Start directly in cloud | Zero local workspaces/accounts; authenticate and create/connect intended cloud workspace; no hidden local prerequisite | UX-06, UX-14, UX-15 |
| T03 | Find an older chat | Locate full history from shell; open intended conversation; correct selected state | UX-01, UX-05 |
| T04 | Switch workspace with a draft | Cancel preserves content/focus; confirmed switch shows correct identity; failed switch offers retry | UX-02, UX-09, UX-25 |
| T05 | Repair a service behind a tool | Identify source, diagnose safely, reconnect, return to tool view; no wrong connection edited | UX-04, UX-17, UX-20, UX-32 |
| T06 | Configure skill access with no types | Create the schema from blocked setup, return to credential draft, save, resume skill readiness | UX-03, UX-18, UX-19 |
| T07 | Create an agent with a shared skill | Correct instructions/skill objects; selected skill reused by second agent; readiness and visibility understood | UX-21, UX-22, UX-24 |
| T08 | Create a skill with a tool and resource | Staged identity save is explained; continue child authoring; resource/tool persistence explicit | UX-23, UX-25, UX-27, UX-28 |
| T09 | Apply Markdown then leave parent | Person predicts draft/persistence boundary; no silent loss; undo/preview/focus remain usable | UX-25, UX-26 |
| T10 | Change a shared credential type | Dependencies visible; conflicts preserve existing usages; recovery returns to unfinished type | UX-03, UX-29 |
| T11 | Recover expired cloud access | Accounts and Workspaces agree on status; auth returns to intended workspace | UX-15, UX-16 |
| T12 | Remove local/cloud items | Person predicts device/cloud/membership effect; cancel changes nothing; partial failures identified | UX-12, UX-13 |
| T13 | Resolve a tool approval | Operation and once/chat/skip/stop scope explained; targeted result visible | UX-10, UX-24 |
| T14 | Inspect delegated work | Child role, parent, and input policy understood; parent return works | UX-11, UX-31 |
| T15 | Change appearance and context policy | Predict global appearance versus workspace-specific context effect before switching | UX-02 |
| T16 | Use unsupported cloud control | Reason appears at entry; alternative accurate; restriction still enforced | UX-30 |
| T17 | Recover route/list failures | Loading/auth/missing/network states identifiable; relevant retry/parent action works | UX-31, UX-32 |

## Screen coverage and variants

| Screens | Required modes/states |
| --- | --- |
| S01 | Each internal slide; no accounts; existing workspace; invalid name; failed creation; local/cloud intent |
| S02–S04 | No provider; no model; unavailable model; sending; history empty/populated; parent/child; approval/queue/retry |
| S05–S06 | All navigation tiles; selected shell state; app versus workspace setting; valid/invalid context budgets |
| S07–S09 | Local/connected/available; search/selection/rename; creation/auth detour; owner/admin/member; connect/remove/leave/delete |
| S10–S14 | No server/account; stored/expired identity; login failure; registration email/code; reset email/code; return context |
| S15–S18 | Mixed types/health; zero types; contextual/general create; each edit form; catalog/manual/native setup; local/cloud restrictions |
| S19–S22 | Empty/large lists; create/edit; disabled/visibility states; built-in/custom; missing/optional access; child authoring |
| S23–S27 | Create/edit/read-only; dirty/clean/reverted; schema conflicts; request preview; nested Markdown draft and keyboard exits |

## Navigation and persistence regression matrix

For each dirty editable mode, exercise: screen Back, native/system Back, browser Back/Forward where supported, explicit Cancel/Close, drawer destination change, return/reset of a shell branch, workspace switch, direct route replacement, parent setup detour, and external auth cancellation. Record which exits are supported on the platform and which require a persistent draft rather than navigation interception.

For each old route, check workspace/object identity, query context, redirect destination, selected shell entry, direct entry, parent relationship, and task return. Preserve the Models alias and all create/edit routes while migration is staged.

Inspect resulting data, not just snackbars: correct object changed, no unintended duplicate, unchanged secret retained, explicit clear/replacement honored, shared schema users unaffected when blocked, and local/cloud removal consequences correct.

## Accessibility and responsive matrix

Cover desktop/mobile layouts, the 959/960 shell boundary, narrow supported widths, text scaling, Spanish expansion, light/dark themes, and representative accent choices. Test real native keyboard behavior in an ordinary dev-debug run; automation's emulated input does not establish iOS keyboard correctness.

Keyboard-only and screen-reader tests must include navigation, list filters, modals, nested credential setup, Markdown editor escape, invalid-field focus, tool approvals, and destructive confirmation. Check live-state announcements, repeated streaming noise, focus return, effective names, and reading order. Measure contrast and hit targets from the actual rendered UI.

## Evidence template

```md
### Txx / Sxx — task and state

- Revision/platform/locale/viewport/theme:
- Fixture and entry route:
- Numbered actions and observed transitions:
- Screenshot file(s), inspected:
- Result: passed / failed / blocked / recommendation rejected
- Draft/data/focus/permission consequence:
- Finding IDs confirmed or revised:
- First relevant redacted failure and recovery:
- Remaining limit:
```

## What was checked for this documentation task

The repository's documentation-only rule requires relevant documentation checks and diff review, without Dart suites. Handoff checks cover local Markdown links/anchors, source line references, complete screen and route inventory, unique finding IDs, matching severity totals, document structure, and whitespace. These checks validate the report's integrity; they do not execute the app or validate recommended behavior.

### Documentation verification record — 2026-09-30

| Command/check | Result | Duration |
| --- | --- | --- |
| `python3 -` — inline documentation integrity check | Passed: 13 documents; 236 local links; 108 source line anchors within file bounds; complete S01–S27 assessments; 34 current route classes; 32 unique findings; matching severity totals; 27 evidence entries; balanced fences and consistent tables | Under 1 second |
| `git diff --no-index --check /dev/null <audit-file>` for each new Markdown file | Passed: no whitespace errors across all 13 new files | Under 1 second total |
| `git diff --check` and `git status --short` | Passed: no tracked-file whitespace errors; changes confined to the new audit directory | Under 1 second |

The initial route-check pattern assumed conventional Dart class declarations. It was corrected to recognize primary constructors, and the focused coverage check passed for all 34 classes. This was a checker limitation, not an app failure. No Flutter tests, screenshots, or live accessibility checks ran; the runtime/toolchain blocker is recorded above.

### Implementation continuation boundary

The verification record above belongs to the initial source audit. The pinned toolchain and baseline are now available. Task 1 has passing focused tests, a zero-diagnostic strict app scan and approved repair review. [Execution evidence](14-execution-evidence.md) records the exact commands and limits; [progress.md](progress.md) tracks the remaining implementation and validation work.

Original evidence links are now pinned to `c0527f8c`. The documentation checker verifies all 122 source references against that Git revision, so later source edits cannot move the original evidence. Current implementation references are recorded separately.

Rendered widget tests may establish deterministic layout, semantics and controlled persistence behavior. Real native keyboard and assistive technology, production email delivery and participant task comprehension keep their separate prerequisites. Record each untested variant as unfinished instead of inferring it from a different passing fixture.

[The coverage map](15-validation-coverage.md) distinguishes executed rendered fixtures, production/custom routes, structural checks and source-only candidates at its stated cutoff. Refresh it after later implementation tasks; it is not a substitute for final runtime or native/participant evidence.


### Readable capture preparation

The repository already loads actual Inter, JetBrains Mono and MaterialIcons assets in its marketing capture fixture. Root verified those three source font files and recorded their asset names, sizes and SHA-256 values in `/tmp/aura-ux-capture-fonts.json`. Final audit capture fixtures can reuse that font loading without replacing existing Ahem regression baselines. This verifies available font inputs only; no current screen capture, Spanish copy result or typography acceptance follows from it. Final images must render actual production screens and localization, identify the final working-tree fingerprint and be inspected individually.

## Task 7 validation checkpoint

The contract now has executed production-route rendering for all 29 current implementations and 35 typed endpoints, all 17 task dispositions and eight fixture definitions. Final-source capture acceptance, aggregate validation, the Linux virtual-display journey, the whole-change review and documentation checks pass. Representative reflow and named contrast/target/semantics checks retain their stated limits. The pre-repair Web route run is preserved under its old source identity. Production email/catalog access, macOS/iOS assistive technology and participant sessions retain their prerequisites. See [current coverage](15-validation-coverage.md#final-current-source-validation-2026-10-01), [progress](progress.md) and [execution evidence](14-execution-evidence.md#task-7-final-source-linux-smoke-and-capture).
