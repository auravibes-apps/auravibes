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

An allow continues through Aura's existing tool approval decision. It never
grants tool permission. A block prevents dispatch, and its bounded, redacted
reason appears with the tool call.

The `afterTool` command may print:

```json
{"context":"Additional bounded context for the next model turn."}
```

Post-tool output is redacted and capped at 4 KiB before it is added to model
context. It does not replace the tool arguments or result.

## Failure and resource bounds

Each command has a five-second runtime limit and an 8 KiB combined standard
output and error limit, enforced while streams are read. Cancellation and
output overflow terminate the direct child process. Standard error is drained
but never stored. Non-zero exit, malformed output, timeout, output overflow,
untrusted or changed source, and unsupported runtime states are reported with
distinct hook failure codes.

Pre-tool failures block dispatch. Post-tool failures add no context and are
recorded separately; they do not erase or change the completed tool result.
Hooks are not a sandbox: trust only commands you are willing to run as your
user account.
