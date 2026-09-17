---
name: marionette-mcp
description: Load whenever an agent launches, connects to, inspects, or manipulates AuraVibes through Marionette MCP, including logs and multiple app instances.
---

# Marionette MCP app control

Use this skill for agent-controlled Flutter runs. Keep this path separate from
normal debugging and Flutter Driver.

## Setup and launch

- Work from the repository root.
- Install the bridge once per machine:
  `dart pub global activate marionette_mcp`.
- Project configuration registers the bridge for shared MCP (`.mcp.json`), Pi
  (`.pi/mcp.json` and `pi-mcp-adapter`), OpenCode (`opencode.json`), and Codex
  (`.codex/config.toml`). Each agent runtime must start its own bridge process.
- Start the isolated app path with:
  `fvm dart run melos run start:marionette`.
- Direct form:
  `fvm dart run tool/marionette_run.dart --instance-id agent-a --device macos`.

The wrapper runs the dev flavor with `ENABLE_MARIONETTE=true`, passes
`AURAVIBES_MARIONETTE_INSTANCE_ID`, captures the Flutter runner PID and VM
service URI, and writes a temporary manifest to
`.dart_tool/marionette/instances/<instance-id>.json`. It also prints
`AURAVIBES_MARIONETTE_INSTANCE_ID`, `AURAVIBES_MARIONETTE_MANIFEST`, and
`AURAVIBES_MARIONETTE_VM_SERVICE_URI` machine-readable lines. When no ID is
provided, the wrapper generates one. A duplicate ID is rejected.

## Multi-agent routing

Marionette’s bridge has one active VM connection. Route each agent explicitly:

1. Launch one app wrapper and one bridge process for the agent.
2. Read that agent’s manifest and take its exact `vmServiceUri`.
3. Call Marionette `connect` with that URI.
4. Immediately call the promoted `auravibes_instance_identity` tool.
5. Continue only when its `instanceId` equals the manifest’s `instanceId`.

Never share a Marionette bridge between agents. The bridge does not choose an
app from an instance ID; explicit URI selection plus the identity check prevents
an agent from acting on another agent’s app. If identity does not match,
disconnect and connect to the correct manifest URI before doing anything else.

The app registers `auravibes.instanceIdentity` only on the Marionette debug
path. Marionette promotes it to the `auravibes_instance_identity` MCP tool.

## App interaction

Use `get_interactive_elements` first. Prefer stable `ValueKey<String>` keys;
visible text is the fallback. Available interaction tools include:

- `tap`, `secondary_tap`, `double_tap`, `long_press`
- `swipe`, `pinch_zoom`, `scroll_to`
- `enter_text`, `press_key`, `press_back_button`
- `take_screenshots`, `hot_reload`, `hot_restart`

## Logs

Call `get_logs` after reproducing an action. The app forwards redacted
`AppLogging` output to Marionette’s `PrintLogCollector`. Do not subscribe the
collector directly to `Logger.root`; that would bypass app log redaction.

## Separate control paths

- Use `dev Debug` for normal debugging and native keyboard behavior.
- Use `dev Driver` only for Flutter Driver/MCP input emulation.
- Do not pass `ENABLE_MARIONETTE` and `ENABLE_FLUTTER_DRIVER` together.
- Do not use Driver mode to validate real iOS keyboard behavior.

On normal exit the wrapper removes the temporary manifest. If a manifest is
left after a crash, verify no matching runner is alive before removing the
stale file or choosing another instance ID.
