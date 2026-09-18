---
name: marionette-mcp
description: Load whenever an agent launches, connects to, inspects, or manipulates AuraVibes through Marionette MCP, including logs and multiple app instances.
---

# Marionette MCP app control

Use this skill for agent-controlled Flutter runs. Keep this path separate from
normal debugging and Flutter Driver.

## Setup and launch

- Work from the repository root.
- Run the project-local bridge from the repository root:
  `fvm dart run marionette_mcp`.
  The root `pubspec.yaml` and `pubspec.lock` pin `marionette_mcp` and
  `marionette_flutter` to the same exact compatible version. Do not activate
  or invoke a globally installed Marionette MCP executable.
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

## CLI fallback for shell-only agents

MCP remains the default for OpenCode, Pi, and Codex. Use the CLI only when the
agent cannot start or maintain an MCP server. The workspace pins
`marionette_cli` at `0.6.0` in `pubspec.yaml` and `pubspec.lock`; install it
with `fvm dart pub get` from the repository root.

Launch one isolated dev app, then use the repo wrapper for every CLI command:

```sh
fvm dart run tool/marionette_run.dart --instance-id agent-a --device macos
fvm dart run tool/marionette_cli.dart --instance-id agent-a get-interactive-elements
```

The wrapper reads `.dart_tool/marionette/instances/agent-a.json`, requires the
`dev` flavor and Marionette flag, verifies `auravibes.instanceIdentity`, and
passes that exact local `vmServiceUri` to `marionette_cli`. It rejects missing
instance IDs, URI or `--instance` overrides, production/remote endpoints, and
the CLI's global `register`, `unregister`, `list`, and `doctor` discovery
commands. Never call the upstream CLI directly with `--instance`.

`marionette_cli 0.6.0` has per-command connection lifecycle: the first command
connects, and the command disconnects in its cleanup path. There is no
persistent `connect` or `disconnect` command. Stop the app launcher with
Ctrl-C; the launcher removes its manifest on normal exit. The wrapper reports
the selected instance, a redacted manifest-URI label, and `connecting`,
`failed`, or `disconnected` state.

CLI command reference:

```sh
# inspect
fvm dart run tool/marionette_cli.dart --instance-id agent-a get-interactive-elements
# tap and enter text
fvm dart run tool/marionette_cli.dart --instance-id agent-a tap --key submit_button
fvm dart run tool/marionette_cli.dart --instance-id agent-a enter-text --key email_field --input 'test@example.com'
# scroll and screenshot
fvm dart run tool/marionette_cli.dart --instance-id agent-a scroll-to --text 'Bottom Item'
fvm dart run tool/marionette_cli.dart --instance-id agent-a take-screenshots --output .dart_tool/marionette/agent-a.png
# logs and lifecycle
fvm dart run tool/marionette_cli.dart --instance-id agent-a get-logs
fvm dart run tool/marionette_cli.dart --instance-id agent-a hot-reload
fvm dart run tool/marionette_cli.dart --instance-id agent-a hot-restart
```

The safe smoke path is local-only: launch the dev macOS app, run inspection,
screenshot, and logs, then stop the launcher. Do not add it to CI because it
requires a GUI app and a live VM service.

## Repeatable agent smoke runbook

Use this flow for an isolated macOS dev-app smoke run. It uses no production
server, credentials, or user data.

1. Give the run a unique ID and keep the launcher terminal/session open:

   ```sh
   fvm dart run tool/marionette_run.dart --instance-id agent-a --device macos
   ```

   Read `.dart_tool/marionette/instances/agent-a.json` and use its exact
   `vmServiceUri`. The URI is ephemeral and token-bearing: use it only for the
   connection, never paste it into a report. Confirm `appFlavor` is `dev` and
   `marionetteEnabled` is `true`.

2. Start or select the agent's own Marionette bridge. Call `connect` with the
   manifest URI, then immediately call `auravibes_instance_identity`. If the
   promoted tool is unavailable, use `call_custom_extension` with
   `extension: "auravibes.instanceIdentity"`. Continue only when the returned
   `instanceId` exactly matches `agent-a`.

3. Call `get_interactive_elements` before interacting. Use stable keys, never
   coordinates. The new-chat smoke controls are:

   - `workspace_selector`
   - `chat_composer`
   - `chat_agent_selector`
   - `chat_model_selector`
   - `chat_attachment_options_button`
   - `chat_send_button`

   If a required control has no stable key, stop and report the missing
   selector. Visible text is a fallback, not a coordinate substitute.

4. Seed deterministic local state through the app custom extensions. Use the
   promoted MCP tools when present, or `call_custom_extension` with these
   names and arguments:

   ```text
   auravibes.seedDemoData {}
   auravibes.selectWorkspace {"workspaceId":"marionette-demo-workspace"}
   auravibes.selectModel {
     "workspaceId":"marionette-demo-workspace",
     "modelSelectionId":"marionette-demo-model-selection"
   }
   ```

   After each extension call, call `get_logs`. Then inspect until the UI shows
   `Marionette Demo` and `marionette-demo-model`. These fixed IDs are local
   development fixtures, not production records.

5. Exercise the deterministic composer path with stable keys:

   ```text
   tap {"key":"chat_composer"}
   enter_text {"key":"chat_composer","input":"Marionette smoke message"}
   get_interactive_elements {}
   ```

   Call `get_logs` after every tap or text-entry action. Verify the entered
   text from the inspected `EditableText`; do not send unless a controlled
   local backend or fixture makes the send result deterministic.

6. Exercise optional controls only when their state is present:

   - Tap `chat_attachment_options_button`, inspect the surfaced menu keys, and
     use only a checked-in fixture if a file picker is available. Never attach
     a real user file or browse arbitrary paths.
   - Tap `chat_model_selector` or `workspace_selector`, inspect the resulting
     options, and select by surfaced key/text. The custom extensions above are
     the deterministic selection path when the menu is not populated.
   - If a pending tool-approval card appears, use only its stable keys:
     `tool_approval_allow_once`, `tool_approval_allow_conversation`,
     `tool_approval_skip`, and `tool_approval_stop_all`. If no request exists,
     record approval as not applicable; do not manufacture a production tool
     request.

   Call `get_logs` after every optional action. Logs are already redacted by
   `AppLogging`. A local `service:model_sync` failure is expected when the
   configured `http://localhost:8080/` server is not running; report it as an
   environment limitation, not as proof that chat sending passed.

7. On any failed action, immediately call `get_logs` and
   `take_screenshots`. With the CLI fallback, save the image under
   `.dart_tool/marionette/` with the instance ID. Record the failed stable key,
   current route/state, first relevant redacted log, and screenshot path.
   Stop only the launcher session for the manifest's PID with Ctrl-C. Never use
   `pkill`, a broad Flutter kill, or another agent's manifest. On clean exit,
   disconnect the bridge and confirm the manifest was removed.

8. If the process crashed and the manifest remains, verify that its exact PID
   is no longer the matching runner before removing the stale manifest or
   choosing another ID. A stale manifest is not permission to connect by
   scanning for another VM service.

The CLI fallback can run the keyed inspection, input, screenshot, and log
steps shown above. It has no custom-extension command, so use MCP for the full
seeded workspace/model flow or document that extension-only steps were skipped.

### Marionette, Flutter Driver, and native keyboard boundaries

- Marionette uses `ENABLE_MARIONETTE=true`, stable-key interaction, VM-service
  custom extensions, and redacted app logs.
- Flutter Driver uses the `dev Driver` launch profile and
  `ENABLE_FLUTTER_DRIVER=true`; its text entry is test-input emulation, not a
  native keyboard.
- Native keyboard behavior uses `dev Debug` with neither automation define.
  Do not combine Marionette and Flutter Driver flags. Relaunch after changing
  any `--dart-define`.

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
