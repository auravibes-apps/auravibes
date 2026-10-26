# Workspace elements: legal documents and supporting product controls

Status: requirements brief for product-owner and qualified legal review; not publishable terms, legal advice, or a compliance certification.
Sources accessed: 2026-10-22. Research started at 2026-10-22T23:57:29Z.

Reconciled with accepted interview Q1–Q72. Existing dated legal/policy research is retained, not newly reverified in this documentation pass.

Read with the [product plan](workspace-elements-plan.md) and [excluded/conditional scope](workspace-elements-excluded.md). A privacy policy or disclaimer cannot authorize prohibited runtime behavior, unauthorized API access, or missing security controls.

## Facts to establish before drafting

Do not infer incorporation, jurisdiction, or legal applicability from the developer's timezone. Record:

- Legal entity, business address, privacy/support contacts, and distribution countries.
- Intended ages, actual audience, and whether children can access generated experiences.
- Actual implementation of the accepted independent local/cloud modes, team roles, and sharing controls. Public publishing is excluded.
- Hosting regions and actual storage, AI, analytics, moderation, and connector providers.
- For each provider: contractual role, data received, processing locations, retention, training use, and deletion behavior.
- Actual payments, credit expiry, renewal, cancellation, refund, and service-limit behavior.
- Treatment of uploads containing other people's personal information.

Unknown facts remain open decisions. Do not invent retention periods or promise encryption, no training, immediate erasure, or exclusive output ownership without evidence.

## Accepted product facts for future drafting

These are design commitments, not verified implementation facts. The product supports independent local and cloud workspaces. Local workspaces retain their own database/assets on the device, survive restarts, and initially have no team membership or remote access. Cloud workspaces require connectivity and do not persist records/assets as an offline cache; temporary working state is in memory. There is no automatic local/cloud synchronization.

Local workspaces may send selected content to online models and connectors when authorized. Do not describe local mode as inherently offline or private from every provider. Fully offline AI requires a configured local model. Verify actual SDK/network caching and telemetry before making storage or transmission promises.

Connections belong to the workspace. Local credentials use the platform secure credential store; cloud credentials stay in backend storage. Owners/admins manage connections and enable tools. Members receive role-based tool access, not credentials. Connections support reads and edits. User-scoped connections/chats are deferred.

Permission mode is selected per chat within workspace-owner limits. Default previews structural/destructive changes and external writes before asking. Allow-all skips those content/action approvals but preserves authorization, validation, recovery, and separately required consent. Saved views used outside chat default to asking for relevant actions unless another permitted mode is explicitly selected. Sharing, credential access, and new provider authorizations remain separate grants.

The app starts empty and remains domain-neutral; no bundled CRM. Relational tables, CSV import/export, attachments, record/schema/view history, and connector-backed forms are included. Executable HTML/JS, public publishing, child-directed experiences, and regulated decision systems are excluded from this implementation. Ordinary contact and expense records remain within scope.

## Document and control matrix

The entries below are proposed drafting topics. They are not assertions that every document or legal rule applies in every country.

| Document or disclosure | What it must address for this product | Required supporting behavior |
| --- | --- | --- |
| Privacy notice | Workspace items, table records, chat context, uploads, revisions, connector data, diagnostics; purposes, recipients, retention, rights, contact | Verified data inventory; accessible notice; rights and deletion process |
| AI data-use notice | What selected content reaches which AI provider, why, and under what retention/training arrangements | Contextual disclosure and permission before required transfers; record provider and accepted notice version |
| Terms of service / applicable EULA | Service scope, accounts, acceptable use, rights in uploads and outputs, limited hosting/rendering rights, suspension, export/deletion, consumer rights | Acceptance/version records; support and enforcement paths |
| Content and abuse policy | Prohibited content/code, impersonation, harassment, rights violations, reporting, enforcement, and appeals | Generation safeguards; in-app reports; maintained handling and removal process |
| Connector disclosure and authorization | Workspace-owned external account, enabled read/edit operations, AI transfers, revocation, service restrictions, irreversible actions | Admin-managed connections; role grants; separate required consent; disconnect; no hidden secondary use |
| Workspace/team terms | Admin powers, shared connection use, table/tool access, ownership of shared items, departure, CSV export, deletion | Enforced roles; clear sharing; membership changes and audit trail; no inherited view-creator privileges |
| Business DPA and vendor agreements, where applicable | Controller/processor roles, instructions, subprocessors, security, incidents, assistance, and deletion | Actual contracts and operating procedures; do not classify every provider as a processor automatically |
| International-transfer documentation, where applicable | Destinations, entities, and the appropriate legal transfer mechanism | Verified hosting and vendor arrangements; consent is not a universal substitute |
| Subscription/credit terms, if monetized | Price, included usage, limits, recurrence, cancellation, refunds, credit validity | Matching checkout and entitlement behavior; store/region-specific billing |
| Cookie/device-storage notice, if applicable | Essential storage versus analytics/advertising, embedded experiences, choices | Necessary consent/preference controls before applicable optional activity |
| Intellectual-property and license notices | Upload rights, generated source/media, dependency licenses, complaints, attribution | License inventory and notices; takedown handling where applicable |
| Creator/publisher terms, only if publishing is introduced | Rights to distribute, content responsibilities, data access, moderation, payments, removal | Publication review, access controls, reports, and applicable age/payment controls |

## Data flow disclosures

Document each boundary separately:

```text
User or connected service
  Local device database/assets OR cloud database/private asset storage
  Selected content sent to AI provider, when authorized
  Host-rendered view showing authorized data
  Enabled connector tool reading or editing an external service, when authorized
```

For each boundary, record data categories, source, purpose, recipient, location, retention, authorization, and deletion path. Include query results, derived summaries, temporary responses, embeddings if introduced, CSV exports, and logs. Connector writes may publish, transmit, or delete information externally; document the actual enabled operations. Merely opening a connected view does not authorize sending its data to AI.

Disclose whether the service scans content for abuse and whether authorized staff may review reports. Do not claim end-to-end encryption if servers or model providers can read content.

Do not conflate permissions:

- Accepting service terms is not blanket permission for every AI transfer.
- Connecting a service does not authorize unrelated uses or sharing with every generated app.
- A workspace administrator cannot necessarily consent for all people described in its records.
- Granting operating-system access does not automatically grant that access to embedded software.
- Allow-all for edits is not blanket legal consent or authorization for new services, broader sharing, or access beyond a member's role.

Shared workspace credentials require a clear statement of who can act through the external account and who may enable tools. Verify provider terms permit that use. Disclose that changing workspace membership affects access to workspace connections; never imply that a member personally owns the shared authorization.

External operations cannot promise universal undo or cross-service atomicity. Describe completed, failed, and uncertain outcomes, supported compensating actions, and how users resolve a disputed operation. Retain an appropriately minimized action history identifying the actor and AI involvement.

The [Apple-specific consent findings](workspace-elements-excluded.md#apple-app-store) must be reflected in real flows, not only legal text.

## Privacy, deletion, and store declarations

Google Play requires a privacy policy, accurate Data safety disclosures, and contextual disclosures/consent where applicable. The policy must cover actual collection, use, sharing, retention, and deletion. Third-party AI integrations remain within the developer's responsibility. See [User Data](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en).

For in-app account creation, implement accessible deletion initiation both inside the app and through the required external resource; address associated data and justified retained exceptions. See [Google account-deletion guidance](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en). Apple and Microsoft requirements must also be checked for the actual account flow; see the policy register in the companion document.

Choose and document separate treatment for:

- Deleted items still in trash or revision history.
- Assets referenced by another retained item.
- Shared business records after one member leaves.
- Backups, security logs, fraud records, and legally required retention.
- Disconnected-service caches and AI-provider copies.
- CSV exports held by users or recipients, and external changes that cannot be recalled by deleting a workspace item.

For ordinary editing, trash preserves reference links and IDs; nonempty folders move their contents to trash. Permanent deletion requires a separate explicit request and is blocked while retained records/views reference the target. Allow-all skips the approval prompt, not these integrity checks. Restore operations create new validated revisions. Explain how the separate rights/account-erasure process satisfies applicable obligations even where ordinary deletion is blocked by references.

Disclose local versus cloud erasure accurately. Local assets are device-held; cloud retention includes service-side history, backups, and provider copies where applicable. Define both without selecting invented periods. Do not imply that deleting AuraVibes data reverses a completed connector write or removes a user's downloaded CSV.

### Current erasure behavior in this implementation slice

Keep these verified product facts separate from unresolved legal or provider policy:

- Local workspace deletion removes the local workspace database rows and queues its owned chat attachment paths, asset bytes, and Connection credential references before cascading those rows. Credential cleanup calls the platform secure store and legacy credential storage; file and credential cleanup failures remain queued durably for retry after the workspace is gone. Credential and attachment references still used by another workspace are preserved. The user sees a pending notice while local file or credential cleanup remains queued. Copies exported outside AuraVibes, device backups outside the app, and data already sent to online AI or Connector providers are not recalled by this operation.
- Ordinary cloud workspace deletion is a soft delete. **Erase workspace data** is a separate owner-only request. It revokes workspace membership and invitations, removes workspace credentials immediately, and queues all workspace-owned objects for deletion. While asset cleanup or background work remains, the workspace is inaccessible and the owner sees a durable pending status. After successful cleanup, AuraVibes removes workspace content, every remaining revision regardless of the configured history-retention policy, trash, Connections, Conversations, asset references, reports, and workspace-scoped audit/event rows. Object cleanup can require an owner retry after its automatic retry limit.
- An owner-scoped erasure status record remains after the workspace row is removed so the owner can see pending, failed, or completed cleanup and retry a failed cleanup. It stores the workspace ID/name, account ID, request ID, and status metadata. The erasure prompt and completion notice disclose this purpose and the unconfigured expiry; account deletion removes these status records.
- Cloud account deletion is blocked while the account owns any workspace data, including older soft-deleted workspaces. The owner must transfer those workspaces or explicitly erase them, and must wait for pending erasure to finish. Account deletion removes sign-in identity, workspace membership, personal message bookmarks, user-owned secrets, recent model selections, OAuth transactions, and the account's mutation receipts. Shared workspace content remains available to other members.
- Shared-workspace records may retain the deleted account's identifier: revision actor IDs; content-report reporter and reviewer IDs; conversation turn initiator, execution creator, tool-decision, conversation-event, and stream-event actor IDs; conversation-context actor IDs; workspace audit/event actor IDs; invite creator/acceptor IDs; and object-upload actor IDs. `WorkspaceInvite` records in any status (pending, accepted, expired, declined, or revoked) may also retain the invitee's `email` and `normalizedEmail` after account deletion; no expiry is configured for those addresses in this slice. These records remain with shared workspace content. Account deletion removes the member's access but does not anonymize these shared-workspace identities or invitation addresses. No treatment or retention policy is implemented in this slice; their allowed use, anonymization, and retention remain product-owner/counsel decisions for #1692 before release.
- Object-upload rows belong to the workspace upload lifecycle and are retained with their workspace objects; deleting those rows independently could orphan pending uploads or disrupt an outstanding signed upload. Their `expiresAt` bounds the signed upload request, not row retention, and this slice does not prune expired upload metadata. An outstanding signed upload request is not revoked by account deletion. Upload actor-ID treatment and row retention remain #1692 release blockers.
- During ordinary workspace use, revision history follows its configurable workspace policy. Explicit workspace erasure deletes every remaining workspace revision regardless of that policy. A trash-retention policy, cloud backup retention period, and AI-provider retention period are not configured here; these remain #1692 release-evidence blockers. Completed Connector actions and downloaded exports remain outside AuraVibes erasure. Do not describe the status record or completion response as proof that provider copies, backups, or exports were removed.

The status metadata exists to make asynchronous cloud cleanup owner-visible and retryable after the workspace disappears; this is its operational purpose, not a selected legal retention period. Confirm an appropriate retention rule before launch.

Reference counting must not accidentally defeat a valid deletion request. Conversely, deleting one person's account must not silently destroy another customer's legitimately retained shared data. Resolve ownership, rights, and retention with counsel and implement the result.

Keep App Privacy details, Play Data safety, Partner Center disclosures, permission prompts, privacy notices, and vendor configurations consistent. A website notice alone does not update store declarations.

## Provider and connector contracts

Before enabling a connector, verify that its terms permit workspace-shared authorization, intended reads/edits, display, any retention, AI processing, and onward sharing. User consent cannot grant rights that the provider's contract withholds. Automatic synchronization is excluded; imports into owned tables are explicit copies and need their own source/retention disclosures.

For Google APIs, publish accurate disclosures, request minimal scopes, and assess scope-specific verification and Limited Use requirements. Identify any required security assessment before committing to launch. See [Google API Services User Data Policy](https://developers.google.com/terms/api-services-user-data-policy), last updated 2024-02-15.

Do not assume that a service connection permits foundation-model training or unrestricted human access. Verify each API's specific policy and the model provider's terms/settings. Separate inference needed for the user's requested task from any optional improvement or training purpose.

For AI vendors, confirm commercial and redistribution rights, prohibited uses, retention, subprocessors, incident terms, and support for deletion. Preserve required third-party notices. Do not promise that AI output is unique, noninfringing, or copyright-protected everywhere.

## Jurisdiction-dependent review

| Trigger | Required assessment before launch | Official starting point |
| --- | --- | --- |
| GDPR applies to the processing | Map lawful bases by purpose; assess transparency, rights, processor terms, special-category conditions, transfers, and any risk assessment | [European Commission: legal grounds](https://commission.europa.eu/law/law-topic/data-protection/information-business-and-organisations/legal-grounds-processing-data_en); [GDPR legal text](https://eur-lex.europa.eu/eli/reg/2016/679/oj/eng) |
| Colombian personal-data law applies | Assess authorization/exceptions, notices, data-subject rights, processor arrangements, transfers, and any registration duty | [Official Law 1581 of 2012](https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php/norma.php?i=49981) |
| US child-directed service or actual knowledge of under-13 users | Assess COPPA applicability and current notice/parental-consent obligations and exceptions | [FTC COPPA rule and materials](https://www.ftc.gov/legal-library/browse/rules/childrens-online-privacy-protection-rule-coppa) |
| EU AI Act applies | Determine provider/deployer roles and applicable interaction/content transparency duties, exceptions, and transition dates | [Commission Article 50 FAQ](https://digital-strategy.ec.europa.eu/en/faqs/transparency-obligations-under-article-50-ai-act) and [official Article 50 text](https://ai-act-service-desk.ec.europa.eu/en/ai-act/article-50) |
| Other US states/countries, public hosting, or regulated use cases | Determine actual territorial/threshold applicability and current requirements before drafting promises | Counsel to identify relevant official regulator/statute sources for selected launch markets |

Consent is one GDPR lawful basis, not the universal answer. A store can separately require a permission flow even where another legal basis supports the processing. The EUR-Lex GDPR page was access-challenged during this research; detailed jurisdiction-specific conclusions remain unverified.

The Commission states that Article 50 applies from 2026-08-02, with specific obligations, exceptions, and transitional treatment. Do not treat every generated view or source file as requiring an identical visible watermark. Assess actual outputs and the provider's role. Clearly identify AI interactions in the product; burying a notice in terms is insufficient where an interaction notice is required.

No minimum age or retention period is selected in this proposal. A statement that children are not intended users does not replace audience assessment or required controls.

## Payment and generated-experience boundaries

Use [Google Play Payments](https://support.google.com/googleplay/android-developer/answer/9858738?hl=en) and the Apple/Microsoft policy sources in the companion document for the exact transaction. Mobile digital purchases commonly require store billing subject to applicable exceptions and regional programs. Windows PC treatment depends on product classification.

Document whether a subscription buys AI usage, workspace storage, or connected tools. Do not add a generic external-checkout clause and assume it makes every flow permitted. Generated games and catalogs are outside this implementation; a future proposal must reassess classification and payment rules before enabling them.

An AI disclaimer cannot transfer all responsibility to users or waive mandatory consumer rights. Do not offer regulated decisions as an ordinary dashboard feature without separate review.

## Release evidence checklist

- [ ] Product owner confirms legal entity, countries, minimum age, providers, retention, and any payments. These remain unresolved release blockers alongside numerical capacity limits.
- [ ] Engineering verifies the data map, deletion paths, sharing defaults, grants, and revocation.
- [ ] Product and counsel approve document scope and unresolved legal determinations.
- [ ] Required notices and affirmative choices appear before the relevant data use.
- [ ] Applicable provider contracts, API permissions, and verification are complete.
- [ ] Required content rules are accepted before upload/sharing; reports reach a maintained process.
- [ ] Public legal URLs work and match store declarations and app behavior.
- [ ] Reviewers receive working access and representative demos without production personal data.
- [ ] No HTML/JS runtime, public publishing, child-directed experience, or regulated decision system is included in this implementation; metadata accurately reflects those boundaries.
- [ ] Local/cloud data-location claims, lack of cloud offline caching, and authorized online processing match actual behavior.
- [ ] Workspace-shared connections, enabled tools, default/allow-all modes, external effects, and limited undo are accurately disclosed and enforced.

These documents are planning inputs. No existing legal policy, backend contract, consent implementation, or store-console declaration was audited or changed.
