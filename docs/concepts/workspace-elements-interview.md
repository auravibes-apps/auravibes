# Workspace elements: interview decision record

Status: accepted product decisions from Q1–Q72; synthesis, not a verbatim transcript.

Published implementation issue: [#1665 — relational workspace items and persistent interactive views](https://github.com/auravibes-apps/auravibes/issues/1665), labeled `ready-for-agent`. The published body was verified against the saved implementation spec.

This record preserves the interview, explicit corrections, and what remains unresolved. The [product plan](workspace-elements-plan.md) explains the accepted design. The [implementation spec](../specs/workspace-elements.md) translates it into user stories and testable behavior. [Excluded scope](workspace-elements-excluded.md) and [legal requirements](workspace-elements-legal.md) remain separate.

No application implementation, store approval, legal certification, or launch value was established by answering the questions.

## Explicit user corrections

- **Q5:** default permission mode previews/asks where required; allow-all does not ask for content-edit approval.
- **Q7:** support both local and cloud features. Cloud workspaces need no offline cache. Follow-up answers settled independent storage without automatic synchronization.
- **Q8:** the initially ambiguous answer was resolved by Q9: exclude HTML/JS execution from this implementation.
- **Q32:** Connections must support full reads and edits through available permitted tools, replacing the read-only proposal.
- **Q33:** Connections belong to workspaces now. User-scoped Connections and Conversations remain future scope.
- **Q53:** do not include a CRM example in the app. Users decide what to build; do not require a bundled workflow or CRM-first implementation target.

Later accepted answers refine earlier recommendations. They do not reinstate superseded recommendations.

## Accepted decisions

The statements below paraphrase the accepted outcome of each question, including follow-up clarifications.

| Question | Accepted decision |
| --- | --- |
| Q1 | Support related tables sufficient for connected business records, while keeping the product domain-neutral and deferring arbitrary formulas, scripts, and automation. |
| Q2 | Each table is a separate workspace item; folders group tables/views without another application container. |
| Q3 | Records belong to tables, have stable IDs and detail screens, and can be referenced directly without appearing in the workspace tree. |
| Q4 | Ordinary controls support creating and editing tables, columns, relationships, records, and views without requiring AI. |
| Q5 | Default mode previews structural/destructive changes; allow-all applies authorized changes without asking. |
| Q6 | Start with workspace membership and table-level access; defer row/column-level permissions. |
| Q7 | Support independent local and cloud workspaces; no persistent cloud offline cache. |
| Q8 | Executable projects are excluded, clarified by Q9 rather than treated as a second release track. |
| Q9 | Exclude HTML/JS execution entirely from this implementation; retain the idea separately. |
| Q10 | Local workspaces durably store their own database/assets on device; cloud workspaces store them remotely. |
| Q11 | No automatic synchronization between local and cloud workspaces. |
| Q12 | A reference column targets one specified table and selects one or multiple records. |
| Q13 | References stay inside one workspace and survive moves across folders. |
| Q14 | Basic types: text, number, checkbox, date, date/time, single/multiple select, URL, email, phone, attachment, reference. Money added by Q20. |
| Q15 | Allow-all preserves validation, access checks, revision history, and recoverable deletion. |
| Q16 | Search reference targets by a display field and secondary identifying details; store IDs and allow opening details. |
| Q17 | Reverse relationships are discoverable without a second independently editable copy of links. |
| Q18 | Trash preserves links to deleted records and offers authorized recovery; no cascading deletion of related data. |
| Q19 | Support optional required/default/unique constraints and resolve existing violations before enabling them. |
| Q20 | Money uses exact decimal values and explicit currency; defer currency conversion and mixed-currency totals. |
| Q21 | Selectors and reverse relationships reveal no unauthorized labels, counts, or fields; lost access does not delete links. |
| Q22 | Local workspaces can use authorized online models/Connectors with required disclosure; offline AI needs a configured local model. |
| Q23 | Cloud workspaces require connectivity, show unavailable states, and keep only temporary in-memory working content. |
| Q24 | Permanent deletion requires a separate explicit request; default asks, allow-all skips approval, and neither silently cascades. |
| Q25 | Type changes check conversions and reject silent data loss; offer correction or a replacement column. |
| Q26 | Multi-step changes within one workspace database are atomic. |
| Q27 | Conflict checks operate at record/schema/view revision boundaries, not an entire table lock; reread before retrying stale edits. |
| Q28 | Built-in search/filter/sort/column visibility/details, wide grid and narrow record list; defer Kanban/calendar layouts. |
| Q29 | A2UI views combine related data using bounded host lists, details, forms, charts, and simple aggregates; no executable expressions. |
| Q30 | Fetching a connected view does not automatically send data to AI. |
| Q31 | Allow-all concerns permitted content/actions; sharing, credential access, and new provider authorizations remain separate. |
| Q32 | Connectors support reads and edits through their available enabled tools; no read-only product restriction. |
| Q33 | Connections belong to workspaces; user-scoped Connections and Conversations are deferred. |
| Q34 | Local workspaces initially belong to one device user without team/remote collaboration; cloud supports teams. |
| Q35 | Create and select a referenced record inside its picker when the user can edit the target table. |
| Q36 | Reference filters can depend on another field, with consistency enforced through all write paths. |
| Q37 | Bound records, columns, assets, queries, and operations; paginate; choose numerical limits after local/cloud measurements. |
| Q38 | Retention periods remain unresolved launch requirements, with distinct trash/history/backup/log/provider treatment. |
| Q39 | Exclude child-directed experiences, public publishing, and regulated decision systems; ordinary personal/business records remain included. |
| Q40 | Workspace owners/admins manage Connections; members use permitted tools without receiving credentials. |
| Q41 | External writes follow default preview/approval or allow-all execution within granted access. |
| Q42 | Workspace roles control read-only/read-write tool access across manual, AI, and A2UI actions. |
| Q43 | External operations report completed/failed/uncertain steps; never promise cross-service atomic rollback or blindly retry unknown writes. |
| Q44 | External data stays in its source unless explicitly imported into an owned table; no implicit synchronized copies. |
| Q45 | Reference columns initially target owned tables, not arbitrary external records. |
| Q46 | Views execute with current-user permissions, never inherited creator privileges. |
| Q47 | Permission mode is selected per Conversation within workspace-owner limits. |
| Q48 | Admins explicitly enable tools; newly discovered tools start disabled. |
| Q49 | Record changes refresh views; column IDs survive renames; deleted/incompatible bindings show repair states. |
| Q50 | CSV import includes preview, mapping, and validation; resolve relations by IDs/unambiguous keys without guessing. |
| Q51 | CSV exports contain authorized owned data, stable relation IDs, and readable labels; defer full workspace migration packages. |
| Q52 | Attachment columns support multiple assets, host-controlled previews, and explicit type/size limits. |
| Q53 | No bundled CRM, seeded business workflow, or required CRM-first target. Users choose their use case. |
| Q54 | Start empty with clear creation actions; AI creates structures from user requests. |
| Q55 | A new table starts with an editable text display column separate from its internal record ID. |
| Q56 | Built-in table editors coexist with separately saved views over shared records. |
| Q57 | Parent-reference changes must resolve invalid dependent selections; reject inconsistent changes rather than silently clearing/retaining references. |
| Q58 | Duplicating a view preserves bindings; duplicating a table copies schema by default, with record copying explicit. |
| Q59 | Local Connections belong to the workspace and keep secrets in the platform credential store, never cells or definitions. |
| Q60 | Deleting nonempty folders trashes descendants together; default shows impact/asks and allow-all skips approval. |
| Q61 | Restore original IDs and valid links into the original available folder or workspace root; surface unresolved dependencies. |
| Q62 | Ordinary permanent deletion is blocked by retained record/view references until explicitly resolved; statutory erasure has a separate process. |
| Q63 | Use bounded structured queries and aggregates instead of arbitrary SQL in both local/cloud modes. |
| Q64 | Date-only differs from timestamps; missing differs from zero/false/empty text; timestamps represent instants shown in a selected timezone. |
| Q65 | Bulk actions operate on a defined selection and report partial results where atomic transactions are unavailable. |
| Q66 | Countries, minimum age, retention, providers, and numerical limits remain explicit release blockers. |
| Q67 | Record/schema/view restoration creates a new validated revision without rewinding unrelated records. |
| Q68 | External undo requires a supported compensating action and clear limits. |
| Q69 | Connector-backed A2UI forms call explicitly enabled tools with validated inputs, permissions, and approval handling. |
| Q70 | Saved-view actions outside chat start with default approvals unless the user explicitly selects another permitted mode. |
| Q71 | User-visible history identifies actor, AI involvement, affected item/revision, and Connector operation without credentials/unnecessary sensitive payloads. |
| Q72 | Reconcile plan, exclusions, and legal requirements, preserving corrections and unresolved release blockers. |

## Spec synthesis follow-up

The user explicitly requested the `to-spec` workflow after reconciliation. They confirmed the proposed testing boundaries: shared behavior through workspace use cases for local/cloud storage, authenticated server endpoint tests for cloud authorization, and focused UI tests for selectors, A2UI, and approval prompts.

The implementation spec must use Connector for a catalog integration, Connection for workspace-configured access, and Conversation for the workspace-owned chat transcript, following the existing domain documents and Connector/Skill ADR. Reuse host-owned tool approval/execution instead of introducing a Skill-owned tool runtime.

## Directory UX follow-up — 2026-10-23

The user requested the name **Directory**, ordinary folder/item navigation, a toolbar **+** with a type menu, support for future item types, and clean organization using menus and grouped controls. The transitional browser keeps folder/table creation forms permanently visible; the requested Directory removes those forms from the listing. The underlying workspace hierarchy and item identities are unchanged.

| Decision | Confirmed answer |
| --- | --- |
| Q73 | Content first throughout Directory and item editors. Put schema, permissions and settings in menus or separate panels. |
| Q74 | Show the current folder with a breadcrumb/path and Back navigation. Enter folders or open item editors; return to the same folder and scroll position. |
| Q75 | Toolbar + creates in the current folder. Choose an available item type, provide essential setup, then open the new item. Do not offer unimplemented types. |
| Q76 | Default to a simple list: folders first, then other items alphabetically. Show icon/name/minimal useful metadata; keep sort/filter controls in the toolbar. |
| Q77 | Use per-row menus for permitted Rename, Move, Duplicate and Trash actions. Group choices only where useful; show bulk actions after selection. |
| Q78 | Use a minimal creation sheet on narrow screens or dialog on wide screens. Ask for name and unavoidable required fields, then open the new item; defer advanced setup. |
| Q79 | Make + contextual: Directory creates item types; inside a table it adds a record. Put columns/schema in a separate menu. |
| Q80 | Enter selection mode by long-press on touch or Select in the toolbar menu. Show checkboxes and a contextual action bar only in selection mode. |

The [glossary](../../GLOSSARY.md) defines Directory, Folder and Item. Directory is a product/navigation concept, not a promise of an operating-system filesystem. Internal symbol renaming is not implied.

Q73–Q80 are confirmed. Q81, the final shared-understanding confirmation before applying the new UX, is pending. Do not implement the new UX from unanswered recommendations. Dates/money and constraints work continues independently; the integrated #1676 UI is a transitional baseline.

No ADR is added for reversible labels, menus or layout choices. Existing persistence, authorization, execution and release decisions remain in force.

## Unresolved release requirements

No answers selected launch countries, minimum age, retention durations, actual providers/initial Connector, numerical limits, legal entity details, or payment behavior. These need evidence and owner decisions before launch. Do not silently invent values or treat the `ready-for-agent` issue label as release authorization.

The published issue is the implementation tracking surface. These local documents remain the detailed product rationale; no code implementation or Git push is authorized by this synthesis alone.
