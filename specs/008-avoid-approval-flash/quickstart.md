# Quickstart: Avoid Approval Flash

## Preconditions

- Use FVM for all Dart/Flutter commands.
- Work in `apps/auravibes_app` for targeted tests.
- Keep implementation scoped to the app package unless a reusable package need appears.

## TDD Checklist

1. Add/adjust tests proving a pending tool with effective `granted` permission is not emitted to approval UI input.
2. Add/adjust tests proving a pending tool with effective `needsConfirmation` remains visible and waits for approval.
3. Add/adjust tests proving `RunAllowedToolsUsecase` still executes granted tools and returns `waitForToolApproval` for confirmation-required tools.
4. Run the new targeted tests and confirm they fail before implementation.
5. Implement the shared permission decision path.
6. Run targeted tests until green.

## Verification Commands

From `apps/auravibes_app`:

```bash
fvm flutter test test/features/tools/usecases/run_allowed_tools_usecase_test.dart --no-pub
```

If provider/widget tests are added for approval visibility, run them with the relevant paths:

```bash
fvm flutter test test/features/chats/providers/[approval_visibility_test].dart --no-pub
```

From repository root, run quick validation when implementation is complete:

```bash
fvm dart run melos run validate:quick
```

## Manual Scenario

1. Configure a tool to ask for approval.
2. Trigger the tool and approve it for the conversation.
3. Trigger the same tool again in that conversation.
4. Verify the approval card never appears and the tool progresses directly to running/resolved.
5. Trigger a different unapproved tool.
6. Verify the approval card appears and execution waits for user action.
