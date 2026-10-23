# Workspace elements: product and architecture proposal

Status: product scope accepted through interview Q1–Q72; not implemented or store-approved.
Policy research date: 2026-10-22. Research started at 2026-10-22T23:57:29Z.

## Decision

Build a database-backed workspace tree containing durable, typed items, relational tables, and bounded interactive views. Support independent local and cloud workspaces with the same item capabilities. Connections belong to workspaces and expose permitted read and edit tools. HTML/JS execution is excluded from this implementation, not a parallel release track.

The accepted decisions below supersede the original read-only connector proposal, mandatory approval for every destructive action, and cloud-only assumptions. Release blockers remain explicitly unresolved; accepted scope is not a release-readiness claim.

This is a product proposal, not a claim about existing capabilities. Follow [target users](../product/target-users.md) and the existing [app architecture](../../doc/architecture/target-architecture.md) when implementing it.

Companion documents:

- [Interview decision record](workspace-elements-interview.md): accepted Q1–Q72 outcomes, corrections, and unresolved launch decisions.
- [Implementation spec](../specs/workspace-elements.md): user stories, implementation boundaries, and user-confirmed testing decisions.
- [Published implementation tickets](../specs/workspace-elements-tickets.md): 26 approved vertical slices and their verified GitHub blocking dependencies.
- [Excluded, deferred, and platform-blocked scope](workspace-elements-excluded.md): ideas removed from the initial plan, reasons, and conditions for reconsideration.
- [Legal documents and operational requirements](workspace-elements-legal.md): disclosures, contracts, consent flows, and unresolved legal decisions.

## Users and outcomes

Primary users are everyday people who do not need coding knowledge. Solo entrepreneurs and teams are secondary users.

Users decide what to build. Start with an empty workspace and clear Folder, Table, View, and File creation controls. AI can create a structure from an explicit request. Do not seed a CRM, preload a business workflow, or make a CRM the required first implementation target. The system remains domain-neutral.

Users can create and edit tables, columns, relationships, records, and views through ordinary controls without prompting AI. Do not expose database internals, object keys, or runtime configuration in ordinary workflows.

## Workspace model

An initially empty workspace can contain folders, tables, views, and files. A folder groups related tables and views; there is no additional application container in this implementation.

Every item has a stable ID, workspace ID, parent folder ID, type, title, current revision, and lifecycle state. Names and locations can change without breaking references. Validate that moves remain within the authorized workspace and do not create folder cycles.

Use one parent per item initially. References from views and chats do not create additional ownership. Shortcuts, tags, and multiple-parent organization are unnecessary for the first version.

| Type | Durable content | Opening behavior |
| --- | --- | --- |
| Folder | Database metadata | List its children |
| Table | Database schema and records | Open a spreadsheet-style table editor |
| View | Validated A2UI definition, definition version, data bindings, action references | Render approved host components |
| File | Database metadata and asset ID; bytes in local asset storage or cloud object storage | Preview or download a supported format |

The table editor is not a promise of Excel compatibility, formulas, macros, or arbitrary SQL. A folder represents organization, not an operating-system directory. Each table is a separate item. Its rows are records with stable IDs and openable detail screens, not individual nodes in the workspace tree. Chats and views can reference records directly.

## Typed columns and relationships

A new table starts with one editable text column used as its display label. The label is separate from the internal record ID and can be renamed. IDs remain stable across label changes, moves, and restoration.

Supported column types:

- Text and number.
- Checkbox.
- Date-only and date/time.
- Single select and multiple select.
- URL, email, and phone.
- Money with an explicit currency and exact decimal values, not floating-point amounts.
- Attachment with multiple asset references.
- Reference to one or multiple records in one specified owned table.

Columns may have required-value constraints, defaults, and uniqueness where applicable. Manual, AI, import, and view writes follow the same validation. Resolve existing invalid values before enabling a constraint. Empty values are distinct from zero, false, and empty text. Timestamps represent instants displayed in the selected timezone; date-only values remain dates.

Check existing values before changing a column type. Reject silent data loss; offer correction or creation of a replacement column. Allow-all does not bypass this rule. Defer arbitrary formulas, computed lookups, custom scripts, automatic workflows, currency conversion, and mixed-currency totals.

Configure a reference column's target table and single/multiple selection. References stay within one workspace, across folders if needed. They target owned tables only; arbitrary external connector records need a separate identity/lifecycle design and are excluded for now.

Use searchable, paginated record pickers with a configured display field and secondary details to distinguish duplicate labels. Store record IDs rather than displayed names. Users can open record details or create and select a new target record if they can edit its table.

Expose reverse relationships as queries over the same links, not a second independently editable copy. Pickers and reverse views must not disclose unauthorized labels, counts, or fields. Losing permission does not delete the relationship.

Allow selector filters based on another field. For example, a dependent reference can be restricted by a selected parent record. Enforce consistency through every write path. Reject a parent change that leaves incompatible references; do not silently clear or retain them. Submit a consistent combined change instead.

## Table editor, imports, and duplication

Every table has a built-in editor with search, filters, sorting, visible-column controls, and record details. Use a grid on wide screens and a record list on narrow screens. Saved interactive views are separate items; several can use the same records. Kanban and calendar layouts are deferred.

Include CSV import with preview, explicit column mapping, and validation. Resolve references through explicit IDs or unambiguous keys; never guess between duplicate names. Export authorized owned-table data as CSV with stable relationship IDs and readable labels. Full workspace migration packages are deferred.

Duplicating a view preserves its data references. Duplicating a table copies its schema by default; copying records requires an explicit choice. Do not silently duplicate a connected system.

Queries use structured filters, sorting, pagination, and approved aggregates, never arbitrary SQL. Bound records, columns, attachments, query results, and operation sizes. Numerical limits require local/cloud measurements and remain release blockers.

## Chats and shared editing

Items belong to the workspace, independently of the chat that created them. A chat stores references to item IDs. Opening an item changes navigation state, not ownership.

Example:

1. Chat A creates an Expenses table and Spending overview view.
2. The view opens beside the chat on a wide screen.
3. On a narrow screen, the view opens full-screen with a return-to-chat control.
4. Chat B selects the same item and requests a category filter.
5. The host checks permissions and saves a new view revision.

Any chat acting for an authorized user can request edits. A chat does not automatically receive every workspace item's contents. Supply only the selected or otherwise authorized context needed for the task.

Apply edits against an expected record, schema, or view revision rather than locking the entire table. Reject a stale write with a recoverable conflict. Competing edits need a fresh read before retrying; unrelated record edits do not conflict solely because they share a table. Real-time collaborative editing is deferred.

Multi-step changes within one workspace database are atomic: succeed entirely or leave no partial records. Bulk operations target a defined selection, not a search result that changes during execution. Present scope under default approval mode and report partial results where a single transaction is unavailable.

## Bounded interactive views

Use A2UI as a declarative view format rendered by an approved component catalog. Persist a validated definition and bindings rather than depending on conversation history to reconstruct the view. A2UI is a presentation protocol; persistence, authorization, and connector execution remain AuraVibes responsibilities. See the [official A2UI overview](https://a2ui.org/), accessed 2026-10-22.

The host owns navigation, permission prompts, data queries, action execution, and error handling. Definitions cannot inject JavaScript, choose arbitrary network destinations, add native capabilities, or supply unrestricted executable expressions. New component capabilities ship through the normal application release process.

A view can combine related owned tables and enabled connector tools through bounded host operations. Support lists, details, forms, charts, and simple aggregates. It must not contain an accidental second authoritative copy of its source data.

| Binding | Behavior | Initial scope |
| --- | --- | --- |
| Owned table | Read records and perform validated updates | Included |
| Live connector | Read and edit through enabled tools; show freshness and errors | Included, subject to tool and provider access |
| Explicit import | Copy source data into an owned table with source/capture context | User-requested copy; no automatic synchronization |
| Bidirectional synchronization | Maintain copies with conflict and deletion rules | Excluded from initial scope |

Connector credentials stay in the host/backend credential store. Bindings reference enabled tools and connection IDs, never secrets or raw SQL. A2UI forms submit validated inputs through those tools. Recheck authorization and approval mode when executing an operation. Treat imported records as untrusted data, including instructions embedded in them.

Refresh views when referenced records change. Stable column IDs preserve bindings across renames. Deleted or incompatible columns produce a visible repair state rather than guessed replacements.

Opening a connected view can fetch data without sending it to a model. Only send the selected data needed for an AI task when the applicable permission exists.

Show loading, empty, stale, disconnected, access-denied, and failure states. A connector's OAuth grant does not automatically authorize sending its contents to an AI provider. Resolve those flows under the legal companion document before release.

## Storage and stateless services

Local and cloud workspaces are independent; there is no automatic synchronization. Both support the same table, relationship, view, asset, and connector capabilities. Local workspaces initially belong to one device user without team membership or remote access. Cloud workspaces support team membership and table-level access.

| Information | Proposed storage |
| --- | --- |
| Tree, metadata, permissions, definitions, revisions, schemas, records, bindings | Device database for local workspaces; remote database for cloud workspaces |
| Photos, videos, uploaded binaries | Durable device asset storage locally; private S3/R2 objects in cloud; both use asset IDs |
| Open panel, active selection, temporary render state | Client/session state |
| Cloud working data | Temporary in-memory state only; no persistent offline cache of cloud records or assets |

Cloud workspaces require connectivity and show an unavailable state when disconnected. Local workspaces persist independently across app restarts. Platform implementation must verify that SDK/WebView/network caching does not silently persist cloud content for offline use. Explicit user exports are separate from an offline cache.

Local describes storage ownership, not a promise that every task works without a network. Local workspaces may use online AI and connectors, with required disclosures before transmitting local data. Fully offline AI requires a configured local model; online connectors require connectivity. Workspace migration/import/export packages and offline synchronization remain deferred.

Keep object keys independent of visible folder paths. Moving an item changes metadata rather than copying media. S3 represents hierarchy through keys and prefixes rather than a native directory tree; see [AWS object-key documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html), accessed 2026-10-22.

Stateless cloud workers may use temporary disk. Durable state must survive their replacement. No worker-local directory is authoritative. A future build worker can materialize a project temporarily without making cloud storage stateful.

Do not choose a new database engine, generic plugin framework, or additional storage layer until implementation requirements justify one.

## Shared asset lifecycle

Use one asset system for chat attachments, visible files, table attachments, and view media. References resolve through authorization checks. Generate temporary download URLs when needed; do not persist them as the asset's identity.

Deleting a chat must not delete an asset still referenced by another retained item. Workspace/account deletion must remove applicable references and schedule eligible objects for deletion. Revisions, backups, legal holds, and shared ownership require documented retention rules; no retention period is chosen here.

Attachment columns allow multiple assets using the same asset system. Validate uploads, sizes, MIME types, and supported host-controlled previews. Do not execute an uploaded HTML file as trusted AuraVibes content. Keep untrusted previews isolated from authenticated application pages.

## Trash, deletion, and recovery

Deleting a nonempty folder moves its descendants to trash together. Default mode shows the impact and asks; allow-all skips approval. Neither mode cascades deletion through table relationships.

Trashing a referenced record preserves its links. Show a deleted-record state and permitted restore action without disclosing restricted metadata. Restore the original ID and valid relationships, returning items to their original folder if available, otherwise the workspace root. Show unresolved dependencies.

Ordinary permanent deletion requires a separate explicit request. Default mode presents affected links and asks; allow-all skips approval. Both modes block permanent deletion while retained records or views still reference the target. Require explicit unlinking, replacement, or deletion of those references first. Statutory account/data erasure uses a separate process and is not defeated by this ordinary editing rule.

Retain restorable record, schema, and view revisions under the eventual retention policy. Restoration creates a new revision and validates current constraints and permissions; it does not rewind unrelated records. Local deletion follows local storage rules; cloud deletion follows disclosed service rules. Retention periods for trash, history, backups, logs, and provider copies remain unresolved release blockers.

## Workspace connections and external edits

Connections belong to the workspace in both local and cloud modes. Local credentials use the platform secure credential store; cloud credentials stay in the backend credential store. User-scoped connections and chats are future scope.

Only workspace owners/admins add, replace, or disconnect connections. Members use permitted tools without receiving credentials. Admins explicitly enable tools; newly discovered tools start disabled. Support read-only and read/write tool access by workspace role, enforced for manual, AI, and A2UI operations.

Views use the current user's workspace permissions, never the creator's inherited privileges. Sharing a view does not share otherwise unavailable data or tool access. Explicit workspace membership/tool grants govern use of the shared external account.

External writes use the same default/allow-all behavior described below, within granted access. Connected data stays in its source unless explicitly imported into an owned table. Reading or editing it does not create a synchronized copy.

Multi-service operations are not atomic. Report completed, failed, and uncertain steps. Never blindly retry an external write with an unknown outcome; reconcile it using supported provider mechanisms. Undo is available only through a supported compensating action, with clear limits for irreversible actions.

## Access and safety requirements

- Enforce cloud workspace membership and table/item access server-side for every read and write; enforce corresponding access rules in local operations.
- Start with workspace membership and table-level access. Defer row/column-level permissions and arbitrary ACL inheritance complexity.
- Separate permission to edit a view from permission to read or change its underlying data.
- Use the accepted permission modes below; allow-all skips approval prompts without skipping validation, access checks, or recovery requirements.
- Record the initiating user, chat, operation, affected item, and revision without logging credentials or unnecessary content.
- Add generation safeguards, an in-app report action, and an operational response process. Private workspaces do not eliminate AI-content safety duties.
- Exclude public publishing, child-directed experiences, regulated decision systems, executable HTML/JS, a mini-app marketplace, advertising, and creator payments from this implementation. Ordinary personal/business records remain in scope.
- Implement and accurately describe account deletion, retention, and data-provider consent before launch.

These are proposed controls, not evidence that controls already exist. Platform-specific policy findings and source dates live in the excluded-scope document.

### Approval modes and auditability

- Select default or allow-all per chat, within workspace-owner limits. Members cannot exceed their access through either mode.
- Default mode permits ordinary owned-record edits after an explicit request, but previews structural/destructive changes and asks before applying them. External writes preview the action and ask.
- Allow-all applies authorized content/schema changes and external actions without approval prompts. Validation, relationship integrity, permission checks, and revision history still apply.
- Sharing, credential access, and new provider authorizations remain separate grants. Allow-all does not silently authorize them or override required consent.
- A saved-view action outside chat starts in default mode unless the user explicitly selects another permitted mode. Never inherit allow-all from the creation chat accidentally.
- Record the initiating user, AI involvement, chat/action context, affected item/revision, and connector operation. Show useful history to users without storing credentials or unnecessary sensitive payloads.

## Delivery sequence

1. Tree and lifecycle in independent local/cloud storage: empty workspaces, folders, stable IDs, authorization, trash/restore, and asset references.
2. Owned relational data: typed columns, selectors, constraints, built-in editing, CSV import/export, atomic changes, revisions, and recovery.
3. Persistent views: approved A2UI catalog, relational bindings, forms/aggregates, cross-chat selection, adaptive navigation, and schema repair states.
4. Workspace connections: enabled read/edit tools, role grants, approval modes, data-use choices, revocation, and external failure/undo handling.
5. Release preparation: moderation operations, deletion checks, disclosures, store declarations, and reviewer access.

Each increment needs focused checks before proceeding. This proposal creates no commitment to ship all increments together.

## Acceptance criteria

- Moving or renaming an item preserves chat and view references.
- Two chats can address the same authorized item; stale writes produce a visible conflict.
- A user cannot obtain data by guessing another workspace's item or asset ID.
- A view cannot read a table or connection solely because its author can edit the view.
- Generated content cannot access credentials, unrestricted queries, or undocumented native capabilities.
- A photo survives deletion of one reference and becomes eligible for cleanup after its last retained reference is removed.
- Replacing a cloud worker loses no committed content.
- Connector revocation stops further access and invalidates applicable transient results; explicitly imported owned records follow their separate lifecycle.
- Deleting an account follows the disclosed treatment of owned items, shared items, revisions, and assets.
- Reports can be submitted inside the app and reach a maintained response process.
- Store metadata and legal documents describe the tested behavior without promising unsupported runtimes or universal store approval.
- All supported column types, constraints, and reference filters behave consistently across manual, AI, import, and view writes.
- Reference selectors show authorized records only, distinguish duplicate labels, and preserve links across renames and folder moves.
- Local workspaces survive restart without cloud storage; cloud workspaces do not persist an offline data cache.
- Local and cloud workspaces do not automatically synchronize, and the app does not preload a CRM or another workflow.
- Default and allow-all modes follow their distinct approval rules; neither bypasses role access, validation, or required separate grants.
- Connector reads and edits work through explicitly enabled tools; newly discovered tools do not gain access automatically.
- Unknown external outcomes do not trigger blind duplicate writes, and unsupported undo is not advertised.
- Record/schema/view restores create validated new revisions; ordinary permanent deletion respects retained references.
- CSV import resolves relationships without guessing; export and view queries expose only authorized data.
- Bound query/attachment/operation limits are measured for local/cloud behavior and chosen before release.

## Unresolved release blockers

The interview settled product scope, not launch-specific values. Before release, choose launch countries, minimum age, retention periods, actual AI/hosting/connector providers and their permitted tools, numerical capacity limits, and any paid flows. Complete the corresponding legal disclosures, consent behavior, moderation operations, and store declarations. These are explicit blockers, not silent defaults.

Do not reopen accepted local/cloud parity, workspace-owned connections, connector edit support, or empty/domain-neutral workspaces as unanswered questions. Implementation details must satisfy this contract; issues discovered during implementation should be surfaced rather than silently narrowing it.
