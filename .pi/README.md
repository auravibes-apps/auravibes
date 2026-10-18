# Pi project baseline

## Setup

Project packages live in `settings.json`. Guardrails is pinned to 0.19.0.
If missing, install from the repository root:

```sh
pi install --local npm:@aliou/pi-guardrails@0.19.0
```

Restart Pi after package or MCP changes. Review loaded servers with `pi mcp list`
and Guardrails configuration with `/guardrails:settings`.

## Guardrails scope

`extensions/guardrails.json` enables built-in policies, outside-workspace approval,
and risky-shell-command confirmation. It adds protection for `.env` variants,
Serverpod passwords and Firebase service-account keys, Android signing settings,
and signing/key file extensions. Protection applies even before files exist.
`.env.example`, `.env.sample`, `.env.test`, and `passwords.example.yaml` remain
readable. PEM protection is conservative: public PEM certificates also match.
Built-in Git push, hard reset, and clean commands need confirmation.

**Coverage gap:** Guardrails 0.19.0 recognizes built-in `read`, `write`, `edit`,
`bash`, `grep`, `find`, and `ls` tool names. Hypa, ReadSeek, MCP, and other custom
tools are not covered by these hooks. They remain enabled by explicit choice.
Policies and prompts prevent accidents. They are not a sandbox or secret boundary.
Even built-in shell parsing cannot contain arbitrary programs. Do not use custom
tools to bypass protected-file or remote-write rules.

## Local prerequisites

- Dart LSP already uses `fvm dart language-server`. No extra LSP baseline needed.
- Existing worker subagent settings remain unchanged. No extra baseline needed.
- SonarQube MCP is removed from repository MCP configurations.
- ReadSeek macOS ARM64 binary needs Homebrew libraries. This machine needed
  `brew install ftxui xxhash`. Repeat a ReadSeek read to verify dependency repair.
- Native MCP definitions live in `mcp.json`. Shared `../.mcp.json` remains separate.
