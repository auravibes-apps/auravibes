# Group 34: Strict tool sampling

## Goal

Make first-party tool contracts strict-compatible, keep dynamic skill calls closed when their declared inputs permit it, and persist one per-model sampling policy consistently for local and cloud workspaces.

## Scope

- Audit every first-party `ToolSpec` and `AppSkillToolDefinition` exactly once. Do not modify third-party MCP schemas.
- Close every supported object schema, require every property, and express optional values as nullable only where null and omission have equivalent execution behavior.
- Materialize `call_skill_tool.args` from the active skill-tool contracts. Preserve a typed strict-sampling fallback for contracts that cannot be represented safely.
- Add deterministic offline CI audit with stable schema paths and reasons; exceptions require a reason and linked issue.
- Persist `off`, `prefer`, or `require` per workspace model selection locally and in cloud workspaces. Legacy null policy resolves to current runtime behavior.
- Show effective policy, verified capability, and why `require` is unavailable in localized, keyboard-accessible controls.
- Include explicit policy in archive export/import, without credentials or secrets.
- Use one shared, versioned profile resolver for local and cloud requests. Add xAI strict mode only for the verified official xAI endpoint and exact model ID `grok-4.7`; all other custom endpoints remain unsupported.

## Design decisions

1. A missing persisted policy (`null`) means legacy automatic behavior: `prefer` for a verified profile, `off` otherwise. Explicit user values are preserved and passed unchanged to local and cloud request configuration.
2. `require` is selectable only when the selected model connection resolves to a verified profile and the model supports tool calls. Requests still enforce capability and schema preflight before transport.
3. Strict profiles carry stable profile ID/version, provider and model match, endpoint match, wire mode, schema limits, evidence URL, and verification date. The xAI profile uses OpenAI-compatible Chat Completions at the exact official origin, where xAI applies strict tool arguments implicitly; unknown models and custom URLs do not match.
4. Dynamic skill arguments use closed object schemas assembled from active contracts. Safe optional values become required nullable values and are normalized to omission before execution. Unsupported contracts retain a stable tool name and typed preflight path/reason.
5. Cloud policy uses a server-owned persistence row keyed by workspace, connection, and model; virtual selection IDs remain unchanged. Cloud writes require workspace-manager access.

## Compatibility evidence

Verified 2026-09-29 against the [OpenAI function-calling guide](https://developers.openai.com/api/docs/guides/function-calling) and [xAI structured-outputs guide](https://docs.x.ai/developers/model-capabilities/text/structured-outputs). The xAI profile is intentionally pinned to the documented `grok-4.7` example and official `https://api.x.ai/v1` endpoint; the profile record must retain the evidence URL and verification date.

## Acceptance criteria

- All audited first-party fixed schemas pass the shared strict preflight, or have one reviewed exception with a reason and issue link.
- Adding a first-party schema without an audit classification, or regressing a passing schema, fails offline CI.
- Local and cloud materialization and request configuration use the same dynamic schema and profile resolver.
- Unknown `args` keys are rejected by the existing execution validator. Explicit null follows the contract's declared omission semantics only.
- All three policies survive restart, workspace switching, conversation continuation, and archive round-trip. Legacy rows retain their former effective policy.
- Unsupported models never report verified strict capability; `require` is explained and blocked before the request.
- The xAI profile matches only `grok-4.7` at `https://api.x.ai/v1` using the OpenAI-compatible transport.
- No provider calls are made by schema-audit CI.

## Verification

Focused engine/app/server tests cover schema preflight, dynamic required/optional/null/unsupported fields, unknown fields, profile matching and wire request shape, local/cloud persistence and request configuration, policy UI, and archive round-trip. Run the audit from CI and the focused tests under FVM.
