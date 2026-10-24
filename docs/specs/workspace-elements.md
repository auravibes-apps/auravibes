# Workspace elements with relational tables and persistent interactive views

## Problem Statement

People need durable, organized information and useful interactive tools that AI can create and edit across Conversations. A chat-only result is difficult to reuse, and a filesystem cannot naturally represent related records, typed tables, and live connected data. Users should not have to learn coding or database administration to maintain what they create.

Users need these capabilities in both local and cloud workspaces. Team members must not gain unintended access through shared views, relationships, or Connections. AI edits need predictable approval, validation, conflict handling, and recovery.

## Solution

Provide an initially empty, domain-neutral workspace tree containing Folder, Table, View, and File items. Tables contain typed records and relationships. Views persist bounded A2UI definitions and reference owned tables or enabled Connector tools. Items outlive their creation Conversation and can be opened and edited from other authorized Conversations or ordinary controls.

Support independent local and cloud storage with the same item capabilities. Local workspaces persist on device; cloud workspaces support teams and require connectivity without a persistent offline content cache. Connections belong to the workspace and support enabled read/edit tools. Default and allow-all modes govern action approval without overriding access, integrity, or required separate grants.

Do not ship a CRM template, seeded business workflow, or HTML/JS execution. Users choose what to build.

## User Stories

1. As a user, I want an empty workspace with clear creation controls, so that I decide what to organize.
2. As a user, I want folders containing tables, views, and files, so that related information stays together.
3. As a user, I want to rename and move items without breaking references, so that organization can evolve safely.
4. As a user, I want AI to create structures from my request, so that I can start without database knowledge.
5. As a user, I want manual editing controls, so that I can maintain my system without prompting AI.
6. As a user, I want each table to be a workspace item, so that I can organize and open it independently.
7. As a user, I want records with stable IDs and detail screens, so that I can address them without cluttering the workspace tree.
8. As a user, I want a new table to start with an editable text label column, so that records have readable names.
9. As a user, I want text, number, checkbox, date, date/time, selection, URL, email, phone, attachment, money, and reference columns, so that values have useful types.
10. As a user, I want required values, defaults, and uniqueness constraints, so that records remain valid.
11. As a user, I want existing violations surfaced before constraints are enabled, so that schema edits do not silently invalidate my data.
12. As a user, I want column conversions checked for data loss, so that changing a type does not destroy information.
13. As a user, I want exact decimal money with explicit currency, so that amounts do not acquire floating-point errors.
14. As a user, I want dates, timestamps, and missing values distinguished, so that time and empty-state meanings remain accurate.
15. As a user, I want single-record and multiple-record references to another owned table, so that my data can express relationships.
16. As a user, I want references across folders in the same workspace, so that organization does not constrain relationships.
17. As a user, I want searchable, paginated record pickers with identifying details, so that duplicate names do not cause incorrect links.
18. As a user, I want to open a selected record's details, so that I can inspect the linked information.
19. As an authorized editor, I want to create a target record inside its picker, so that I can complete a relationship without losing my task.
20. As a user, I want reverse relationships derived from existing links, so that I can discover related records without duplicate relationship data.
21. As a user, I want selectors filtered by another field, so that related selections remain consistent.
22. As a user, I want incompatible parent/dependent changes rejected clearly, so that neither silent clearing nor invalid links occur.
23. As a workspace member, I want relationship displays to honor my access, so that restricted records do not leak labels, fields, or counts.
24. As a user, I want search, filters, sorting, and visible-column controls, so that I can work with tables without generated UI.
25. As a mobile user, I want record lists and detail screens on narrow displays, so that table work remains practical.
26. As a desktop user, I want a wide table grid, so that I can scan and edit records efficiently.
27. As a user, I want CSV import preview, column mapping, and validation, so that imported data has predictable types and relationships.
28. As a user, I want ambiguous imported references reported instead of guessed, so that records are linked correctly.
29. As a user, I want authorized CSV exports with readable relation labels and stable IDs, so that data remains useful outside the app.
30. As a user, I want view duplication to preserve bindings and table duplication to copy schema by default, so that copying does not silently duplicate a whole system.
31. As a user, I want separately saved views over shared tables, so that different presentations use the same authoritative records.
32. As a user, I want lists, details, forms, charts, and simple aggregates in views, so that my information becomes useful interactive tools.
33. As a user, I want views refreshed when records change, so that displayed information stays current.
34. As a user, I want schema changes to preserve renamed bindings or show a repair state, so that views do not guess which field to use.
35. As a user, I want loading, empty, stale, disconnected, denied, and failure states, so that I understand what happened and can recover.
36. As a user, I want to open an item beside a Conversation on a wide screen or full-screen on mobile, so that I can discuss and inspect it together.
37. As a user, I want another authorized Conversation to edit the same item, so that useful work is independent of its creation chat.
38. As a user, I want only necessary authorized data supplied as AI context, so that discussing one item does not expose the whole workspace.
39. As a user, I want stale record/schema/view edits detected, so that concurrent work does not silently overwrite changes.
40. As a user, I want unrelated record edits to proceed independently, so that a table is not unnecessarily locked.
41. As a user, I want multi-step owned-data changes committed atomically, so that failed edits leave no partial records.
42. As a user, I want bulk actions to target a defined selection, so that a changing search does not alter the action's scope.
43. As a user, I want restorable record, schema, and view revisions, so that I can recover from mistakes.
44. As a user, I want restoration to create a validated new revision, so that recovery does not rewind unrelated work or violate current constraints.
45. As a user, I want folder deletion to move descendants to trash, so that a mistaken deletion remains recoverable.
46. As a user, I want trashed records to preserve their links, so that related data is not deleted or silently unlinked.
47. As a user, I want restored items returned to their available original folder or workspace root, so that recovery has a predictable location.
48. As a user, I want ordinary permanent deletion blocked by retained references, so that dependent records and views are not silently broken.
49. As a user, I want a separate rights/account-erasure process, so that reference integrity does not prevent required data deletion.
50. As a user, I want multiple attachment assets with host-controlled previews, so that media belongs naturally in my records.
51. As a user, I want shared asset references across Conversations and items, so that deleting one reference does not destroy another retained use.
52. As a local-workspace user, I want my database/assets retained on device across restarts, so that local content does not depend on cloud storage.
53. As a cloud-workspace user, I want shared authorized access without a persistent offline cache, so that the cloud remains the authoritative content store.
54. As a user, I want independent local/cloud workspaces without automatic synchronization, so that storage ownership is understandable.
55. As a local-workspace user, I want authorized online AI and Connector use disclosed, so that local storage is not mistaken for zero network transmission.
56. As a workspace owner, I want workspace-owned Connections managed by owners/admins, so that shared external-account access is controlled.
57. As an admin, I want to enable Connector tools explicitly, so that newly discovered capabilities do not become available silently.
58. As an admin, I want role-based read/read-write tool access, so that members can perform only permitted operations.
59. As a member, I want to use permitted Connections without receiving credentials, so that access does not expose secrets.
60. As a user, I want enabled Connector reads and edits available through chat and bound A2UI forms, so that my tools can act on connected services.
61. As a user, I want a connected view to fetch data without automatically sending it to AI, so that display access and model processing remain separate.
62. As a user, I want external data retained in its source unless explicitly imported, so that viewing it does not create an accidental synchronized copy.
63. As a user, I want external operations to report completed, failed, and uncertain steps, so that partial outcomes are understandable.
64. As a user, I want unknown external writes reconciled before retry, so that actions are not accidentally duplicated.
65. As a user, I want external undo offered only when a supported compensating action exists, so that irreversible actions are not misrepresented.
66. As a user, I want default approval for structural/destructive edits and external writes, so that I can review their impact.
67. As a user, I want allow-all to skip approval for authorized edits/actions, so that I can choose uninterrupted execution.
68. As an owner, I want Conversation approval modes bounded by workspace permissions, so that allow-all never expands a member's access.
69. As a user, I want sharing, credentials, and new provider authorizations handled separately, so that editing permission does not silently authorize new disclosures.
70. As a user, I want saved-view actions outside chat to default to the appropriate approvals, so that a view does not inherit its creator's allow-all setting.
71. As a member, I want views to execute with my permissions, so that sharing a view does not grant the creator's privileges.
72. As a user, I want useful actor/AI/operation history without secrets, so that changes are accountable without unnecessary sensitive logging.
73. As a user, I want bounded query, attachment, and operation sizes with clear errors, so that the system remains usable and dependable.
74. As a user, I want in-app reporting and maintained handling of harmful AI content, so that unsafe output can be addressed.
75. As a user, I want accurate legal and store disclosures matching actual storage, transfers, retention, and deletion, so that I can make informed choices.

## Implementation Decisions

### Existing ownership and vocabulary

- Reuse Workspace, Local workspace, Cloud workspace, Membership, Conversation, Mutation receipt, Connector, Connection, and Tool approval consistently with existing domain guidance. Item, Table, Record, Column, Reference, and View are proposed concepts for this feature, not claims about existing entities.
- Preserve the accepted Connector/Skill boundary: a Connector is an integration catalog entry; a Connection is a workspace's configured access. Skills provide instructions and reference Connector tool IDs; they do not own tool definitions or credentials.
- Extend workspace-owned app workflows and server workspace behavior. The Flutter host owns presentation, local persistence, authorization decisions, and adapters. Serverpod owns authenticated cloud state, authorization, and durable operations. The engine stays app-neutral and does not acquire Flutter, Drift, or host-owned persistence.
- Use existing use-case/repository/service boundaries and the common Connector executor. Resolve workspace, enabled Connection, permissions, tool revision, and input schema at execution time. Do not introduce an alternative executor just for views.
- Existing cloud mirrors identify remote workspaces; they do not justify caching the new cloud records/assets locally. Scope the no-offline-cache requirement to this feature rather than silently rewriting unrelated metadata storage.
- Existing MCP Apps hosting is a distinct current capability. Excluding newly authored HTML/JS projects does not authorize removing that host or imply it has been audited for this feature.

### Item and persistence contract

- Persist a database-backed hierarchy with stable item IDs, workspace IDs, one parent folder, type, title, revision, and lifecycle state. Validate workspace ownership and folder cycles on moves. Do not tie object keys to visible paths.
- Tables are items; rows are records with stable IDs and detail screens. Views and Conversations reference IDs. A folder groups a system without a new application container.
- Local storage is a durable device database plus device assets. Cloud storage is remote database plus private object assets. Cloud workers may use disposable temporary disk, never authoritative worker-local state.
- Maintain equivalent item/table/view/Connector behavior in local and cloud workspaces. Local initially has one device user without team/remote collaboration. Cloud has membership and table-level access.
- Cloud content requires connectivity; keep only temporary in-memory working data. Verify storage adapters, SDKs, and preview/network behavior do not create a persistent offline content cache. Explicit exports are user artifacts rather than an offline cache.
- Local workspaces may use authorized online AI and Connectors. Disclose those transfers. Fully offline AI requires a configured local model; do not promise it without one.
- Add the necessary persistent item, column/schema, record/reference, view/binding, revision, asset-reference, and access representations. Choose physical modeling within existing persistence conventions; the product contract does not prescribe an EAV schema or SQL table per user table. Include migration/generation work without hand-editing generated output.

### Tables and integrity

- Support the column types in the user stories. A new table has one editable text display column, separate from the stable record ID. Money uses exact decimals and explicit currency; missing differs from zero/false/empty text. Date-only differs from timestamp instants rendered in a selected timezone.
- Optional required/default/unique constraints apply through every writer. Resolve existing invalid values before enabling a constraint. Type conversions must not silently discard values.
- Reference columns select one or multiple records from one specified owned table in the same workspace. Display paginated searchable labels with secondary details; preserve IDs through renames and folder moves. Permit authorized target creation inside the picker.
- Reverse relationships derive from existing links. Field-dependent filters are integrity rules, not picker-only filtering. Reject inconsistent parent/dependent updates unless submitted together consistently.
- Queries use bounded structured filters, sorting, pagination, and approved simple aggregates, not arbitrary SQL. Determine numerical capacity and attachment limits through local/cloud measurements before release.
- CSV import previews mapping and validates values. Resolve references by IDs or unambiguous keys. Export authorized owned records with relationship IDs and labels. View duplication retains bindings; table duplication copies schema unless record copying is explicitly requested.

### Changes, lifecycle, and recovery

- Use expected record/schema/view revisions for conflict detection rather than table-wide locks. A stale writer must reread before retry. Owned multi-step mutations within one workspace database are atomic.
- Reuse existing mutation identity/idempotency conventions at cloud boundaries. Do not infer that database idempotency makes arbitrary external writes safe to replay.
- Bulk operations use a defined selection. Return meaningful partial results where a single transaction is unavailable.
- Trash a folder and descendants together without cascading through table references. Trashed records keep links and show an authorized deleted/restore state. Restore stable IDs into the available original folder or root and surface unresolved dependencies.
- Ordinary permanent deletion requires a separate explicit request and is blocked by retained record/view references until explicitly resolved. Default asks; allow-all skips approval but not integrity checks. Account/statutory erasure remains a separate process.
- Record/schema/view restoration creates a new validated revision without rewinding unrelated work. Retention durations remain release decisions.
- Assets are identified independently of paths/temporary URLs and shared across attachments/items/views. Retain an asset while authorized retained references require it; coordinate cleanup with revisions, deletion rights, and disclosed retention. Validate multiple attachments and isolate untrusted previews.

### Views, context, and actions

- Persist versioned validated A2UI definitions and bindings. Render the approved host catalog; do not inject JavaScript, executable expressions, unrestricted destinations, raw SQL, or native privileges.
- Views support lists, details, forms, charts, and simple aggregates over related records and enabled Connector tools. Record changes refresh views. Stable column IDs survive renames; incompatible/deleted bindings show a repair state.
- Built-in table editors support wide grids, narrow lists/details, search/filter/sort/column visibility. Saved views are separate items. Open items beside Conversations on wide screens and full-screen with return navigation on narrow screens.
- Different authorized Conversations can edit one durable item. Supply only necessary authorized model context. Fetching a view does not automatically send its data to AI.
- Views execute with current-user access, never creator privileges. Editing a view does not grant underlying data or tool access. Selectors and reverse views must not leak restricted labels/counts/fields.

### Connections, approval, and external effects

- Connections belong to workspaces. Owners/admins manage them; roles grant enabled read/read-write tool access. Newly discovered tools start disabled. Local secrets use platform credential storage; cloud secrets remain backend-held. Members never receive raw credentials through data or views.
- Preserve Connector/Connection resolution rules when multiple matching Connections exist rather than guessing which account to use.
- Default mode applies ordinary owned-record edits after an explicit request, and previews/asks for structural/destructive changes and external writes. Allow-all skips content/action approval within granted access; it never bypasses validation, denied permissions, or required separate consent.
- Select mode per Conversation within owner limits. Saved-view actions outside a Conversation start in default mode unless the user explicitly selects another permitted mode. Sharing, credential access, and new provider authorization remain separate grants.
- A2UI forms bind enabled tools and validated inputs through the same authorization/approval/execution path as other callers.
- External reads/edits do not create synchronized owned copies. Imports are explicit. External operations report completed/failed/uncertain outcomes, reconcile unknown writes before retry, and offer undo only through supported compensating actions.
- Expose useful actor/AI/operation/revision history without credentials or unnecessary sensitive content. Provide generation safeguards, in-app reporting, and maintained response operations.

## Testing Decisions

The user confirmed these boundaries during spec synthesis: shared behavior through workspace use cases for local/cloud storage, authenticated server endpoint tests for cloud authorization, and focused UI tests for selectors, A2UI, and approval prompts.

- Prefer one reusable behavioral scenario suite at the workspace use-case boundary, exercised against local persistence and cloud-backed adapters. This is a proposed extension of existing seams, not a new generic testing framework. Assert externally visible results, persisted state, errors, and access boundaries; do not mirror implementation internals.
- Use existing Workspace use-case tests and CloudWorkspaceEndpoint integration tests as prior art. Exercise real local persistence for restart, migrations, transactions, reference integrity, and history. Exercise authenticated cloud endpoints for membership/table/tool access, resource guessing, stale writes, and mutation replay behavior.
- Reuse CloudLocalProductionComposition test patterns to prove cloud item reads/writes do not fall back to local content storage, while local content survives a storage reopen. Verify local/cloud parity through the same observable scenarios.
- Reuse ResolveToolApprovalDecisionUsecase's existing mode/permission matrix. Extend it for new item and Connector actions: allow-all changes only the final approval decision, never denied/unconfigured access. Add separate-grant and outside-Conversation default-mode cases.
- Reuse ChatA2uiRuntime and existing host tool-result separation patterns for validated definitions, schema repair, host actions, lifecycle, and model-context separation. Add focused widget tests for wide/narrow navigation, record pickers, duplicate labels, constraints, and visible approvals/errors. Keep these tests at the highest boundary that exposes the behavior.
- Cover rename/move reference stability; filtered relationship integrity through all writers; unauthorized metadata/count leakage; exact money/date/missing values; destructive conversions; ambiguous CSV references; atomic owned changes; stale revisions; trash/restore and deletion blockers; shared-asset retention and cleanup; limits and pagination.
- Use deterministic Connector fakes at the existing execution boundary for read/edit requests, role/tool gates, revocation, partial/unknown outcomes, duplicate-write prevention, and unsupported undo. Do not require live credentials, paid external operations, or production personal data.
- Treat legal/store declaration checks, provider terms, actual cache behavior, and moderation operations as release verification beyond unit tests. Existing tests are prior art, not evidence that this feature already passes.
- Run focused tests, analyzers, migrations/generation checks, and applicable CI-parity gates through the pinned FVM and repository validation lease during implementation. This documentation task does not claim those gates ran.

## Out of Scope

- Executable HTML/JS projects, arbitrary native modules, a mobile shell/Node.js runtime, remote build workers, and a developer IDE.
- Bundled CRM examples, seeded business workflows, or a required CRM-first implementation target.
- Public publishing, mini-app marketplaces, advertising, creator payments, child-directed experiences, and regulated decision systems.
- Automatic local/cloud synchronization, persistent cloud offline content caching, and local team/remote collaboration.
- User-scoped Connections/Conversations, cross-workspace record links, arbitrary external-record reference columns, row/column permissions, and complex ACL inheritance.
- Full spreadsheet compatibility, formulas, computed lookups, custom scripts, automatic workflows, currency conversion, and mixed-currency totals.
- Kanban/calendar layouts, real-time collaborative editing, and full workspace migration packages.
- Bidirectional Connector synchronization, universal external undo, cross-service atomic rollback, and blind retries of uncertain external writes.
- Arbitrary SQL, credential exposure, inherited view-creator access, hidden post-review features, and bypassing validation or authorization under allow-all.
- Selecting launch countries, age, retention periods, actual providers, numerical limits, payment behavior, or publishable legal text without the required owner decisions and evidence.

## Further Notes

This spec synthesizes the accepted 72-question interview, including explicit corrections concerning approval modes, local/cloud parity, workspace-owned Connections, Connector edit support, excluded HTML/JS execution, and no bundled CRM.

Treat it as one coherent feature specification that can be delivered in ordered increments: item/storage lifecycle; typed relational data; persistent views; workspace read/edit Connections and approvals; release verification. Do not interpret an issue label as authorization to release or to narrow accepted scope silently.

Launch countries, minimum age, retention durations, actual AI/hosting/Connector providers and permitted tools, numerical capacity limits, and any payments remain explicit release blockers. Resolve matching disclosures, separate consent, contracts, moderation, deletion, and store declarations before launch. The existing policy research is dated and does not certify compliance.

No prototype established a physical schema or new runtime. No production behavior, migration, live provider integration, or test execution is claimed by this specification. Related existing issues concerning tool modes, workspace policies, local-network disclosure, and shared-Conversation visibility should be coordinated during implementation rather than overwritten or silently closed.

## Directory UX amendment — interview in progress

Confirmed requirements from the 2026-10-23 follow-up supersede transitional creation-heavy layouts:

- Name the workspace navigation destination **Directory**.
- Browse one folder at a time, with folder entry, item opening, breadcrumbs/path and Back navigation that restores location and scroll context.
- Create through a toolbar + type menu in the current folder. Include only available types and accommodate future types without redesigning the browser.
- Default to a simple folders-first list, then alphabetically ordered items, with an icon, name and minimal useful metadata.
- Keep content primary in Directory and every item editor. Put schema, permissions and settings in menus or separate panels.
- Put permitted item actions in contextual row menus. Reveal bulk controls after selection; use submenus for meaningful groups rather than hiding ordinary actions behind unnecessary levels.

Creation-form presentation, contextual + behavior inside tables and selection-mode entry are awaiting Q78–Q80. Final interview confirmation and ticket reconciliation remain pending. Existing database hierarchy, stable IDs, current-user permissions and local/cloud boundaries remain required; this amendment does not authorize executable file types or change release gates.
