# Domain Docs

Use this guide to route work to context documents and architecture sources.

## Route work

1. Read `CONTEXT-MAP.md` when ownership is unclear or work crosses workspace areas.
2. Read the likely owner's `CONTEXT.md`. Use its responsibility and data flow to confirm scope.
3. Follow its `Relationships and evidence` links only when work crosses owners. Read each cited source that affects the change.
4. Read an ADR only when the change touches a recorded decision. Find ADR locations in `CONTEXT-MAP.md`. If no relevant ADR exists, proceed.
5. For package boundaries, read [`package-boundaries.md`](../../doc/architecture/package-boundaries.md). For app layer placement, read [`target-architecture.md`](../../doc/architecture/target-architecture.md).

## Check

Finish routing when each affected owner has a matching `CONTEXT.md` and each cross-context claim cites code or an architecture document. If ownership or evidence remains unclear, ask the coordinator.

## Terms

Use a term from the `Domain terms` section when one exists. Otherwise, use the name in source code. Ask the coordinator before you add or change a domain term without evidence.

## ADR criteria

Record a resolved decision as an ADR only when all three tests pass:
- The decision is hard to reverse.
- A future reader needs context to understand the decision.
- The decision resolves a real trade-off.

If an ADR conflicts with code or context documents, cite both paths and ask the coordinator before changing the decision.
