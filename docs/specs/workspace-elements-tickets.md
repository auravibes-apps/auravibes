# Workspace elements: published implementation tickets

Status: approved breakdown published and verified on 2026-10-23.

Parent: [#1665](https://github.com/auravibes-apps/auravibes/issues/1665). All 26 tickets are open, labeled `ready-for-agent`, and linked as native sub-issues with 47 native blocking edges. Parent title, body, and state were preserved.

See the [spec](workspace-elements.md) and [interview record](../concepts/workspace-elements-interview.md) for scope and rationale. Ticket completion and release readiness are distinct.

## Dependency order

| Slice | Ticket | Blocked by |
| --- | --- | --- |
| 01 | [#1667 — Create and browse folders](https://github.com/auravibes-apps/auravibes/issues/1667) | None |
| 02 | [#1668 — Create tables and edit text records](https://github.com/auravibes-apps/auravibes/issues/1668) | [#1667](https://github.com/auravibes-apps/auravibes/issues/1667) |
| 03 | [#1669 — Grant table access to workspace members](https://github.com/auravibes-apps/auravibes/issues/1669) | [#1668](https://github.com/auravibes-apps/auravibes/issues/1668) |
| 04 | [#1670 — Add basic typed columns](https://github.com/auravibes-apps/auravibes/issues/1670) | [#1668](https://github.com/auravibes-apps/auravibes/issues/1668) |
| 05 | [#1671 — Add dates and exact money](https://github.com/auravibes-apps/auravibes/issues/1671) | [#1670](https://github.com/auravibes-apps/auravibes/issues/1670) |
| 06 | [#1672 — Enforce constraints and safe schema changes](https://github.com/auravibes-apps/auravibes/issues/1672) | [#1670](https://github.com/auravibes-apps/auravibes/issues/1670) |
| 07 | [#1673 — Link records across tables](https://github.com/auravibes-apps/auravibes/issues/1673) | [#1669](https://github.com/auravibes-apps/auravibes/issues/1669) |
| 08 | [#1674 — Enforce dependent relationship filters](https://github.com/auravibes-apps/auravibes/issues/1674) | [#1673](https://github.com/auravibes-apps/auravibes/issues/1673) |
| 09 | [#1675 — Browse tables across screen sizes](https://github.com/auravibes-apps/auravibes/issues/1675) | [#1670](https://github.com/auravibes-apps/auravibes/issues/1670) |
| 10 | [#1676 — Move and rename workspace items](https://github.com/auravibes-apps/auravibes/issues/1676) | [#1668](https://github.com/auravibes-apps/auravibes/issues/1668) |
| 11 | [#1677 — Trash and restore items and records](https://github.com/auravibes-apps/auravibes/issues/1677) | [#1673](https://github.com/auravibes-apps/auravibes/issues/1673), [#1676](https://github.com/auravibes-apps/auravibes/issues/1676) |
| 12 | [#1678 — Restore revisions and permanently delete safely](https://github.com/auravibes-apps/auravibes/issues/1678) | [#1672](https://github.com/auravibes-apps/auravibes/issues/1672), [#1677](https://github.com/auravibes-apps/auravibes/issues/1677) |
| 13 | [#1679 — Perform atomic and bulk record edits](https://github.com/auravibes-apps/auravibes/issues/1679) | [#1672](https://github.com/auravibes-apps/auravibes/issues/1672), [#1674](https://github.com/auravibes-apps/auravibes/issues/1674) |
| 14 | [#1680 — Import and export CSV](https://github.com/auravibes-apps/auravibes/issues/1680) | [#1671](https://github.com/auravibes-apps/auravibes/issues/1671), [#1672](https://github.com/auravibes-apps/auravibes/issues/1672), [#1673](https://github.com/auravibes-apps/auravibes/issues/1673) |
| 15 | [#1681 — Attach and preview shared assets](https://github.com/auravibes-apps/auravibes/issues/1681) | [#1669](https://github.com/auravibes-apps/auravibes/issues/1669), [#1677](https://github.com/auravibes-apps/auravibes/issues/1677) |
| 16 | [#1682 — Save and open persistent A2UI views](https://github.com/auravibes-apps/auravibes/issues/1682) | [#1669](https://github.com/auravibes-apps/auravibes/issues/1669) |
| 17 | [#1683 — Add relational views, charts, and aggregates](https://github.com/auravibes-apps/auravibes/issues/1683) | [#1673](https://github.com/auravibes-apps/auravibes/issues/1673), [#1675](https://github.com/auravibes-apps/auravibes/issues/1675), [#1682](https://github.com/auravibes-apps/auravibes/issues/1682) |
| 18 | [#1684 — Duplicate tables and views explicitly](https://github.com/auravibes-apps/auravibes/issues/1684) | [#1673](https://github.com/auravibes-apps/auravibes/issues/1673), [#1682](https://github.com/auravibes-apps/auravibes/issues/1682) |
| 19 | [#1685 — Manage workspace Connections and enabled tools](https://github.com/auravibes-apps/auravibes/issues/1685) | None |
| 20 | [#1686 — Read connected data in saved views](https://github.com/auravibes-apps/auravibes/issues/1686) | [#1682](https://github.com/auravibes-apps/auravibes/issues/1682), [#1685](https://github.com/auravibes-apps/auravibes/issues/1685) |
| 21 | [#1687 — Edit workspace items across Conversations](https://github.com/auravibes-apps/auravibes/issues/1687) | [#1672](https://github.com/auravibes-apps/auravibes/issues/1672), [#1673](https://github.com/auravibes-apps/auravibes/issues/1673), [#1682](https://github.com/auravibes-apps/auravibes/issues/1682) |
| 22 | [#1688 — Execute Connector writes with clear outcomes](https://github.com/auravibes-apps/auravibes/issues/1688) | [#1685](https://github.com/auravibes-apps/auravibes/issues/1685) |
| 23 | [#1689 — Submit forms through approved host actions](https://github.com/auravibes-apps/auravibes/issues/1689) | [#1679](https://github.com/auravibes-apps/auravibes/issues/1679), [#1686](https://github.com/auravibes-apps/auravibes/issues/1686), [#1687](https://github.com/auravibes-apps/auravibes/issues/1687), [#1688](https://github.com/auravibes-apps/auravibes/issues/1688) |
| 24 | [#1690 — Show change history and handle harmful-content reports](https://github.com/auravibes-apps/auravibes/issues/1690) | [#1687](https://github.com/auravibes-apps/auravibes/issues/1687), [#1688](https://github.com/auravibes-apps/auravibes/issues/1688) |
| 25 | [#1691 — Erase workspace/account data across retained references](https://github.com/auravibes-apps/auravibes/issues/1691) | [#1678](https://github.com/auravibes-apps/auravibes/issues/1678), [#1681](https://github.com/auravibes-apps/auravibes/issues/1681), [#1685](https://github.com/auravibes-apps/auravibes/issues/1685), [#1690](https://github.com/auravibes-apps/auravibes/issues/1690) |
| 26 | [#1692 — Measure limits and assemble release evidence](https://github.com/auravibes-apps/auravibes/issues/1692) | [#1680](https://github.com/auravibes-apps/auravibes/issues/1680), [#1683](https://github.com/auravibes-apps/auravibes/issues/1683), [#1684](https://github.com/auravibes-apps/auravibes/issues/1684), [#1689](https://github.com/auravibes-apps/auravibes/issues/1689), [#1691](https://github.com/auravibes-apps/auravibes/issues/1691) |

## Initial frontier

- [#1667 — Create and browse folders](https://github.com/auravibes-apps/auravibes/issues/1667).
- [#1685 — Manage workspace Connections and enabled tools](https://github.com/auravibes-apps/auravibes/issues/1685).

Each slice includes needed persistence/API/UI behavior and focused tests. Follow native GitHub dependencies as work completes; the frontier above is the publication snapshot.

Existing #1427 and #1521 remain coordination points rather than added blocking edges. Launch countries, age, retention, providers, numerical limits, and any payments remain owner decisions; the release-evidence ticket must expose unresolved requirements rather than invent values.

Local publication bodies and the resumable batch manifest are retained under the task scratch directory. No application implementation or production operation was performed.

## Approved Directory UX follow-up

Q73–Q81 extend #1675 to include Directory naming, current-folder navigation with return context, toolbar type creation, minimal responsive forms, contextual row menus and selection mode. Tables keep content primary, contextual record creation and separate schema/access controls. Original bounded responsive table-query acceptance remains required. Other item types adopt the same shell conventions when implemented. The native dependency remains #1670; no additional child or blocking edge is introduced.
