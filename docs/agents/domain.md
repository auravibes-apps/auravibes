# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`CONTEXT-MAP.md`** at the repo root. It points at one `CONTEXT.md` per context; read each one relevant to the topic.
- **`docs/adr/`**: read ADRs that touch the area you're about to work in.
- **`<context>/docs/adr/`**: in the relevant app, package, or Widgetbook context, read context-specific ADRs.

If any of these files don't exist, **proceed silently**. Don't flag their absence; don't suggest creating them upfront. The `/domain-modeling` skill creates them lazily when terms or decisions actually get resolved.

## File structure

This Dart workspace uses app and package directories as contexts:

```text
/
├── CONTEXT-MAP.md
├── docs/adr/                    ← system-wide decisions
├── apps/
│   └── <context>/
│       ├── CONTEXT.md
│       └── docs/adr/            ← context-specific decisions
├── packages/
│   └── <context>/
│       ├── CONTEXT.md
│       └── docs/adr/
└── widgetbook/
    ├── CONTEXT.md
    └── docs/adr/
```

`CONTEXT-MAP.md` is the source of truth for which contexts exist and where their documentation lives.

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in the relevant `CONTEXT.md`. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal: either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0007 (event-sourced orders), but worth reopening because…_
