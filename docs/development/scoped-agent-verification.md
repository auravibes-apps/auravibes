# Scoped agent verification

Scoped verification checks files reported by a configured editing tool after its
successful response. It is disabled by default and requires an owner-supplied
MCP runner implementing `auravibes.scoped-verification/1` on the editing tool's
server. AuraVibes does not ship that runner. An ordinary shell MCP tool does not
meet this contract.

Only local AuraVibes workspaces are eligible. A local workspace is a logical app
container; its root identifier names a checkout owned by the runner. The app does
not open a host checkout or execute a host shell. Cloud workspaces are unsupported.
Missing runners, unsupported capabilities, uncertain receipts, and interrupted
connections cannot produce a passing result.

## Configuration and authority

The owner selects one runner, edit tools on that same server, a runner-owned root
identifier, and explicit checks. Each check contains an ID, executable, argument
array, and optional case-sensitive path suffixes. An empty suffix list matches
every reported path. Commands come only from saved configuration. Model text,
private MCP app data, and command suggestions in tool output grant no authority.

The app checks the workspace, saved revision, tool bindings, and permissions before
connection and execution. Each verification owns a separate MCP connection and
runner instance. The connection advertises no elicitation support; unexpected
elicitation is rejected and makes verification incomplete. Ordinary interactive
MCP calls keep their own connection and handler.

| Setting | Default | Maximum |
| --- | --- | --- |
| Enabled | No | Owner opt-in |
| Runtime, including connection setup | 30 seconds | 120 seconds |
| Retained output | 16 KiB UTF-8 | 64 KiB UTF-8 |
| Repair attempts per originating user turn | 1 | 2 |
| Checks | None | 8 |
| Reported paths | None | 128 |
| Bytes per reported path | — | 4,096 UTF-8 |
| Serialized configuration | — | 32 KiB UTF-8 |

Successful edits do not consume repair attempts. A failed check arms the next
verification as a repair. Spent attempts persist across tool IDs, settings changes,
and provider reconstruction. Verification does not replay an edit or approve a
corrective edit; existing tool permissions and approval flow still apply.

## Editing-tool report

The successful MCP editing response must include this SDK `structuredContent`:

```json
{
  "auravibesChangedPaths": {
    "version": 1,
    "workspaceRoot": "checkout-42",
    "paths": ["lib/example.dart"]
  }
}
```

The root must exactly equal saved configuration. Paths are relative and supplied
as separate data. The app normalizes repeated separators and `.` segments and
deduplicates paths. It rejects the entire report for traversal, absolute paths,
URLs, drive prefixes, backslashes, control characters, empty/root-only paths, or
components beginning with `-`. It never executes a valid subset of a bad report.
Unknown report fields cannot introduce command authority.

Normalization alone cannot prove filesystem containment. The runner must resolve
paths against the bound root, reject symlink escapes, and prevent time-of-check
races. It must sandbox execution and permit only the configured executable/argv
and selected paths. Treat the configured runner as a trusted integration boundary.

## Runner protocol

All four operations call the configured MCP tool. Requests include
`"protocol":"auravibes.scoped-verification/1"` and an `operation` of
`capabilities`, `start`, `poll`, or `cancel`. Replies must be SDK
`structuredContent`, with `isError` false or absent. JSON embedded in text is not a
receipt. Unknown protocol fields are rejected by the strict parsers.

Capabilities must return every flag below as `true`:

```json
{
  "protocol": "auravibes.scoped-verification/1",
  "capabilities": {
    "scopedPaths": true,
    "canonicalContainment": true,
    "sandboxedCommands": true,
    "boundedOutput": true,
    "deadline": true,
    "cancellation": true,
    "idempotentStart": true,
    "cancellationTombstones": true,
    "nonInteractive": true
  }
}
```

A start request looks like this (the actual deadline is computed by the app):

```json
{
  "protocol": "auravibes.scoped-verification/1",
  "operation": "start",
  "operationId": "app-generated-operation-id",
  "workspaceRoot": "checkout-42",
  "deadlineMs": 1793635230000,
  "maxOutputBytes": 16384,
  "checks": [{
    "id": "analyze",
    "executable": "dart",
    "arguments": ["analyze"],
    "paths": ["lib/example.dart"]
  }]
}
```

The runner must execute argv without interpolating paths into shell source. It
must define the configured executable's path-selection semantics, reject any
unsupported command safely, and check containment before dispatch. Every selected
check must actually finish before it reports a completed receipt. Reusing an
operation ID with different input must never launch replacement work.

Poll contains the protocol, `operation:"poll"`, and `operationId`. The app polls
at 250 ms intervals. Start and poll return the same receipt shape:

```json
{
  "protocol": "auravibes.scoped-verification/1",
  "operationId": "app-generated-operation-id",
  "workspaceRoot": "checkout-42",
  "state": "completed",
  "scopeValidated": true,
  "checks": [{"id": "analyze", "exitCode": 1}],
  "output": "A diagnostic from the configured check.\n",
  "outputTruncated": false,
  "originalOutputBytes": 40,
  "cancellationRecorded": false
}
```

`state` is `running`, `completed`, or `cancelled`. The original byte count must
equal the UTF-8 bytes retained when untruncated, or exceed them when truncated.
Output cannot exceed the request limit. Completed receipts must identify every
requested check exactly once and cannot contain an unknown check. The app accepts
pass only when all completed exit codes are zero and the root, operation, and
containment acknowledgement match.

### Cancellation and deadlines

Cancel carries the protocol, `operation:"cancel"`, operation ID, bound root, and
original `deadlineMs`. The runner must stop active work and durably record an
idempotent cancellation tombstone, including when cancel arrives before start has
registered the operation. Keep the tombstone through the original deadline and
reject expired or tombstoned starts. Return a matching receipt with
`state:"cancelled"`, `scopeValidated:true`, and `cancellationRecorded:true`.

This is necessary because start and cancel can overlap. The app waits at most two
seconds for cancellation confirmation, then closes its connection. The runner must
enforce deadlines independently of client connectivity and stop its process tree.
Closing the connection alone is not evidence that execution stopped.

Execution permission is checked before capabilities, start, and poll. Revoking
permission cannot block cleanup: cancel retains narrowly bound authority only for
that invocation's already-created start intent. Cancelling one tool stops its
verification; stopping the conversation fans out to every active verification.

## Result states and repair example

| State | Meaning |
| --- | --- |
| `pass` | All selected checks completed with exit code zero. |
| `fail` | Completed checks include a nonzero exit code. |
| `skipped` | No eligible report/check or disabled/unsupported workspace. No passing claim. |
| `cancelled` | Stop occurred before dispatch, or the runner confirmed cancellation. |
| `incomplete` | Timeout, invalid/unsupported receipt, unavailable runner, permission/connection error, or unconfirmed cancellation. |

An illustrative fake-runner sequence for a single user turn is:

1. Approved edit `edit-1` reports `lib/example.dart`. Start `operation-1` receives
   a completed receipt with check `analyze`, exit code `1`, bounded diagnostics,
   and validated scope. The stored result is `fail`, with one repair remaining.
2. The agent requests a corrective edit through the ordinary approval flow.
   Approved `edit-2` reports the path again. A fresh connection starts
   `operation-2`; this reservation spends the one repair attempt.
3. Its completed matching receipt reports `analyze`, exit code `0`, and validated
   scope. The stored result is `pass`, with zero repair attempts remaining.
4. A third repair reservation in that turn cannot launch a command. Replaying
   either tool-call ID returns the durable result instead of starting it again.

The model receives bounded edit feedback plus explicit verification state and
repair authority. A failed verification does not turn an already completed edit
into a mutation error. Late zero-exit receipts cannot overwrite the stored winner.

## Integration evidence

Engine tests cover strict reports, path selection, limits, result states, deadlines,
and cancellation. App tests cover durable reservations, permission changes, fresh
sessions, concurrent cancellation isolation, structured metadata, and real local
MCP HTTP transport. These use test runners; they do not certify an external
runner's sandbox, canonical containment, process cleanup, or deployment. A runner
owner must validate those obligations in its own environment before enabling it.
