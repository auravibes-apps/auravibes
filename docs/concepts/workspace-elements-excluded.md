# Workspace elements: excluded, deferred, and platform-blocked scope

Status: scope decisions and policy research, not a store approval or a shipped-app audit.
Verified on: 2026-10-22. Research started at 2026-10-22T23:57:29Z.

Scope reconciled with accepted interview Q1–Q72. The dated policy findings below are retained from the earlier research, not newly reverified during reconciliation.

The [main plan](workspace-elements-plan.md) contains the proposed initial scope. This file preserves removed ideas without falsely classifying every deferred feature as impossible. The [legal companion](workspace-elements-legal.md) covers documentation and consent work.

## Classification

- **Excluded design:** do not implement this behavior; it conflicts with the proposed security model or a cited platform restriction.
- **Excluded scope:** intentionally omitted from this implementation; not necessarily impossible or prohibited.
- **Conditional:** technically possible, but outside the initial release until named platform, implementation, and legal gates are met.
- **Deferred:** possible; omitted for product scope rather than a demonstrated prohibition.
- **Unverified:** available evidence does not establish the exact policy treatment. Do not promise approval or invent a ban.

Storing code in a database instead of files does not change the store's assessment of what executes. Consent language cannot override a platform prohibition.

## Accepted scope that must not be marked excluded

- Independent local and cloud workspaces with the same item/table/view capabilities; local has no team/remote collaboration initially.
- Typed relational tables, single/multiple references, reverse relationships, filtered selectors, constraints, exact-decimal money, and CSV import/export.
- Workspace-owned connections with explicitly enabled read and edit tools, including connector-backed A2UI forms.
- Default/allow-all modes: allow-all skips content/action approval but not access checks, validation, or separate provider/sharing grants.
- Empty, domain-neutral workspaces. No bundled CRM or required business template.

These decisions replace the original read-only connector limitation and cloud-only assumptions. Not having a cloud offline cache does not exclude durable local workspaces.

## Platform findings

These are paraphrases and architecture implications. All sources below were accessed on 2026-10-22. A permission in policy is not an approval of AuraVibes' implementation.

### Apple App Store

[App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), last updated 2026-10-16:

- 2.5.2 restricts code that changes app functionality; its educational exception is narrow.
- 4.7 permits specified software, including HTML5/JavaScript mini apps and games, subject to 4.7.1–4.7.5: privacy, moderation, payments, native-API restrictions, per-instance data consent, software index/universal links, and age controls.
- 2.5.6 establishes the WebKit baseline, with specified entitlement exceptions.
- 1.2 covers user/AI-created content safeguards.
- 5.1.2(i) requires disclosure and explicit permission before personal data goes to third-party AI.
- 5.2.2 requires authorization under connected services' terms.

**Implication for a future proposal:** execution would remain conditional on these requirements; it is excluded from the accepted implementation. Do not assume private, AI-authored apps are exempt from 4.7. Resolve classification, index/deep-link handling, and permissions with App Review. Do not claim a general-purpose creator is an educational exception.

### Google Play

[Device and Network Abuse](https://support.google.com/googleplay/android-developer/answer/16559646?hl=en) restricts external executable downloads and self-updates, while allowing an interpreter/VM exception that includes browser/WebView JavaScript. Runtime-loaded code must still respect Play policies; unsafe JavaScript bridges are specifically risky.

**Implication:** browser-compatible code is conditional, not categorically banned. External DEX/JAR/native-module delivery is excluded from this design.

[AI-generated content policy](https://support.google.com/googleplay/android-developer/answer/13985936?hl=en) requires generation safeguards and in-app reporting. The [official explanatory guidance](https://support.google.com/googleplay/android-developer/answer/14094294?hl=en-GB) identifies malicious-code generation as violative content.

[UGC policy](https://support.google.com/googleplay/android-developer/answer/9876937?hl=en) requires accepted content rules and ongoing moderation with reporting/blocking appropriate to the sharing experience. Team sharing needs assessment too; it is not automatically outside UGC rules.

### Microsoft Store on Windows PC

[Microsoft Store Policies](https://learn.microsoft.com/en-us/windows/apps/publish/store-policies), page labeled version 7.20:

- 10.2.2 restricts dynamically included code that fundamentally changes described functionality or violates policy.
- 10.2 and 10.3 require security and testability.
- 10.5 covers personal-data disclosures, consent, and protection, including specific requirements concerning noncustomers' data.
- 10.8 distinguishes payment treatment by product type; do not transplant mobile billing assumptions to Windows PC.

**Implication:** a clearly described web-project feature may be feasible. Confirm package type, runtime, catalog/game classification, and data flows before shipping it. This review does not cover Xbox or certify any Windows package.

## Removed ideas and reconsideration gates

| Idea or behavior | Status | Reason / gate |
| --- | --- | --- |
| Treat executable code as harmless because its source is DB text | Excluded design | Storage format does not establish execution safety or policy eligibility. |
| Download native modules, DEX/JAR, or replacement app binaries through project content | Excluded design | Use the appropriate reviewed application-update mechanism. Google restriction is cited above; do not generalize it into a ban on all Windows extensions. |
| Give generated apps arbitrary native APIs, shell commands, or host privileges | Excluded design | Breaks the proposed trust boundary; Apple 4.7.2 imposes a separate permission gate. |
| Give views/code raw SQL, unrestricted connector access, tokens, or host session cookies | Excluded design | User data and credentials would cross an uncontrolled trust boundary. |
| Hide runtime capabilities until after review | Excluded design | Disclose and make the actual feature reviewable; no review-only behavior switches. |
| Permit malware, credential theft, abusive content, or unauthorized service access | Excluded design | Implement prevention, reports, and response; terms alone are insufficient. |
| Run HTML/CSS/JS projects | Excluded scope | User excluded execution from this implementation. A future proposal would need isolated execution, limits, platform classification, and review evidence. This is not a universal store ban. |
| Connect a generated web app to internal tables or connectors | Excluded scope | Depends on the excluded runtime. A future proposal needs narrow data contracts, grants, and platform review. Bounded host-rendered A2UI forms remain included. |
| Share a user's existing permissions automatically with each generated app | Excluded design | Require a scoped, inspectable grant. Apple-specific consent rule is in the policy findings. |
| Publish a community mini-app catalog or marketplace | Conditional | Requires moderation operations, abuse controls, age handling, reviewable catalog/deep links, and applicable billing. |
| Use one global external checkout flow for all stores and regions | Excluded design | Payment rules vary. Validate each product, storefront, region, entitlement, and agreement. |
| Guarantee Node.js, Bash, native executables, background services, or npm builds on mobile | Excluded promise | Browser JavaScript is a different runtime. A separate approved runtime or remote build/execution service needs its own plan. |
| Remote build and execution workers | Deferred | Feasible with isolation, quotas, dependency controls, and cleanup; remote execution is not a store-policy escape hatch. |
| Full spreadsheet formulas, macros, or Excel fidelity | Deferred | Separate scope from structured tables and a spreadsheet-style editor. |
| Bidirectional connector sync and full offline collaboration | Deferred | Need conflict, deletion, retention, and authorization semantics. |
| Automatic local/cloud synchronization and persistent cloud offline cache | Excluded scope | Workspaces are independent. Cloud requires connectivity; local stores its own durable database/assets. |
| User-scoped connections and chats | Deferred | Connections belong to workspaces for now. |
| Cross-workspace relations and references to arbitrary external records | Deferred | References target owned tables in the same workspace. External identities and deletion rules need a separate plan. |
| Row-level or column-level permissions | Deferred | Start with workspace membership, table access, and role-based connector tool grants. |
| Formulas, computed lookups, custom scripts, automatic workflows, currency conversion, and mixed-currency totals | Deferred | Typed records, bounded aggregates, exact money, and related-table views are included. |
| Kanban/calendar layouts and complete workspace migration packages | Deferred | Built-in grid/list editing and CSV import/export are included. |
| Bundled CRM, seeded business workflow, or required CRM implementation target | Excluded scope | Users decide what to build; start empty and domain-neutral. |
| Universal undo or atomic transactions across external services | Excluded promise | Report completed/failed/uncertain steps. Compensate only through supported actions; never blindly retry unknown writes. |
| Mix permanent physical folders and virtual folders in the main workspace | Deferred alternative | Unnecessary complexity; virtual paths can satisfy project imports. This is not a store prohibition. |
| Child-directed experiences, public publishing, or regulated decision systems | Excluded scope | User excluded these from this implementation. A separate proposal needs audience/domain review and actual safeguards. Ordinary personal/business data remains in scope. |

## Historical web-project idea retained outside this implementation

This is background for a possible future proposal, not an accepted delivery phase. The user excluded HTML/JS execution from the implementation. If a future proposal reopens it, a web project could be a workspace item containing virtual files:

```text
Pricing calculator [Web app]
├── index.html
├── styles.css
├── main.js
└── assets/logo.png [asset reference]
```

Store small source files and a versioned path manifest in the database. Keep media and large binaries in object storage. Serve one coherent project revision with correct relative paths and MIME types. Validate paths to prevent traversal. Build workers may materialize temporary directories and discard them afterward.

Keep source revisions separate from user data. Preview a selected revision; preserve a last working revision and stop/reload controls. Do not auto-run a new AI edit in a context holding sensitive data. Present source/export controls as advanced options without making an IDE the core experience.

For web, isolate untrusted content from the authenticated application origin. For mobile/Windows, evaluate the actual WebView and messaging implementation. Restrict network access and host messages; validate caller identity, operation, inputs, and granted resources. Avoid third-party remote scripts in the first executable version.

Browser sandbox configuration is only one layer. See [MDN embedding guidance](https://developer.mozilla.org/en-US/docs/Learn_web_development/Core/Structuring_content/General_embedding_technologies), accessed 2026-10-22. In particular, same-origin script execution can undermine an iframe sandbox when permissions are combined incorrectly. Browser controls do not prove that a mobile WebView is isolated.

## Evidence required to reopen executable scope

Reopening scope requires an explicit new product decision first. The following technical/policy gates do not automatically add execution back to the accepted plan.

1. A precise feature description and classification for each distribution channel.
2. A working isolated runtime with tests for host/session access, data exfiltration, unauthorized messages, and resource exhaustion.
3. A platform-specific capability map. No universal native bridge.
4. Reviewable demos, all relevant project/index links, and representative safe/error cases.
5. Generation safeguards and staffed report/removal operations.
6. Data-sharing grants, revocation, age handling, and relevant legal documents.
7. A billing decision for each paid flow, including credits, subscriptions, and paid content.
8. Store review outcome for the submitted implementation. Support guidance can reduce uncertainty but cannot guarantee approval.

Where a feature is unavailable on a platform, show a clear limitation. Any external-browser alternative requires its own review of link/payment rules; do not use it to conceal an otherwise forbidden flow.

## Evidence limits

This is prospective design research. No installed build, entitlements, runtime bridge, SDK inventory, store declarations, paid flows, moderation tooling, or published legal documents were audited. No feature above has been certified compliant. Recheck policies and regional programs before submission.
