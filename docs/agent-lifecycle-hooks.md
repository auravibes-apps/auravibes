# Trusted agent lifecycle hooks

Lifecycle hooks are optional local commands that run before and after tool
calls. They are available only for local workspaces on Linux, macOS, and
Windows. Cloud execution remains server authoritative; web and mobile do not
run local hook commands.

Hook configuration is never discovered or enabled automatically. In workspace
settings, choose a JSON configuration file, review and trust its fingerprint,
then separately enable hooks for that workspace. Trust covers the canonical
configuration path and its content, each configured executable, and files
listed in `sourceFiles`. The trust dialog shows executable paths, literal
arguments, source file paths, and the fingerprint. The current fingerprint is
checked again at each hook invocation. A path or content change requires
renewed trust. Imported workspace data does not carry hook opt-in or trust.
The app rereads workspace opt-in and trust after source inspection, including
the runtime's final inspection immediately before starting the command.
Revoking trust, disabling hooks, or selecting a different configuration during
inspection prevents launch.

Trusted commands run with the current user's operating-system permissions.
They can read or change files available to that account. Aura starts each
executable with an argument vector and no shell, an empty inherited
environment, and the configuration directory as its working directory.
Review the executable and every script or file it loads before trusting the
configuration.

## Configuration format

The configuration accepts one `beforeTool` hook and one `afterTool` hook:

```json
{
  "version": 1,
  "sourceFiles": ["hooks/shared-policy.json"],
  "hooks": [
    {
      "event": "beforeTool",
      "command": "./hooks/check-tool",
      "args": []
    },
    {
      "event": "afterTool",
      "command": "./hooks/add-context",
      "args": []
    }
  ]
}
```

Commands may be absolute paths or paths relative to the configuration file.
Arguments are passed literally; shell expansion and command substitution do
not occur. Use `sourceFiles` for scripts or data files loaded by a command that
may change independently of the configuration. Configuration files are
limited to 32 KiB, there may be at most two hooks and eight source files, and
each hook accepts at most 16 arguments. Executable and source-file contents
are fingerprinted with a combined 64 MiB inspection limit.

Each command receives one JSON object on standard input. It contains the hook
event, tool call ID, tool identifier, and argument names. Post-tool input also
contains whether the tool succeeded. Raw argument values, tool results,
credentials, and conversation content are not passed to hook commands. Hook
input is limited to 8 KiB; tool and call identifiers are capped at 128 bytes,
and at most 24 argument names of 24 bytes each are included.

The `beforeTool` command must print one JSON object to standard output:

```json
{"decision":"allow"}
```

or:

```json
{"decision":"block","reason":"Policy reason shown with the tool call."}
```

Aura resolves the existing tool approval before invoking a hook. A pending or
denied approval runs neither the hook nor the tool. After approval, an allow
permits dispatch without granting any additional permission. A block prevents
dispatch, and its bounded, redacted reason appears with the tool call. The
reason is capped at 1024 UTF-8 bytes without splitting a character. Approving
an old tool-call digest cannot run a changed call.

The `afterTool` command may print:

```json
{"context":"Additional bounded context for the next model turn."}
```

Post-tool output is redacted and capped at 4 KiB before it is added to model
context. It does not replace the tool arguments or result.
Recognized API-key, token, password, authorization, cookie, and URL credential
patterns are redacted in reasons and supplemental context. Hooks receive no raw
argument values, tool output, conversation text, or inherited credentials.
Redaction cannot identify arbitrary unlabeled or encoded secrets; trusted hook
authors must avoid printing them. Standard error is never exposed as context.

## Failure and resource bounds

Each command has a five-second runtime limit and an 8 KiB combined standard
output and error limit, enforced while streams are read. Cancellation and
output overflow terminate the direct child process. Standard error is drained
but never stored. Non-zero exit, malformed output, timeout, output overflow,
untrusted or changed source, and unsupported runtime states are reported with
distinct hook failure codes. If the process exits but output streams do not
close within 100 ms, the invocation fails instead of accepting partial output.
The first terminal failure remains the outcome when cancellation, timeout,
and output events race.

| Pre-tool condition | Persisted code | Behavior |
| --- | --- | --- |
| Explicit policy block | `hook_blocked` | No tool dispatch; show the bounded redacted reason. |
| Five-second timeout | `hook_timeout` | No tool dispatch. |
| Combined output exceeds 8 KiB | `hook_output_limit` | No tool dispatch; discard captured output. |
| Untrusted/changed source or unavailable workspace/runtime | `hook_unavailable` | No tool dispatch; review current sources or use a supported local desktop workspace. |
| Nonzero exit, invalid protocol/UTF-8, inspection failure, or incomplete streams | `hook_failed` | No tool dispatch; discard raw error output. |
| Conversation cancellation | No failure payload; `stoppedByUser` result | No tool dispatch or conversation resume. |

Pre-tool hooks fail closed: only a valid `allow` response permits dispatch.
Post-tool failures are recorded with `lifecycle_hook_post_timeout`,
`lifecycle_hook_post_output_limit`, `lifecycle_hook_post_unavailable`, or
`lifecycle_hook_post_failed`; they add no context and preserve the completed
tool result, media, and output digest. Cancellation also discards post-hook
context. Cancelled source conversations do not resume after batch approval.

Pre-tool failures block dispatch. Post-tool failures add no context and are
recorded separately; they do not erase or change the completed tool result.
Hooks are not a sandbox: trust only commands you are willing to run as your
user account.
Fingerprint verification cannot make filesystem inspection and OS execution
atomic. Review every executable and list independently loaded scripts/data in
`sourceFiles`; files a trusted command chooses to load implicitly are outside
that fingerprint. Descendant processes are the trusted command's cleanup
responsibility; Aura bounds and terminates its direct child.
