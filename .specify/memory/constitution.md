<!--
Sync Impact Report:
- Version change: 1.0.0 -> 2.0.0
- Modified principles:
  - Start with User Needs -> User Value First
  - Design with Data -> Layered, Package-Aware Architecture
  - Package-First Architecture -> Layered, Package-Aware Architecture
  - UI Kit Mandate -> UI System First
  - Test-Driven Development (NON-NEGOTIABLE) -> Risk-Based Quality Gates
  - Fail Fast + Explicit Errors -> Explicit Failures
  - Simplicity + YAGNI -> Simplicity
  - Observability + Performance -> Observable Where It Matters
  - Security + Privacy -> Security and Privacy
  - Code Quality Standards -> Dart and Flutter Standards
- Added sections: Online references reviewed
- Removed sections: Hard coverage/startup/FPS mandates without project baselines
- Templates requiring updates:
  ✅ .specify/templates/plan-template.md - no change needed
  ✅ .specify/templates/spec-template.md - no change needed
  ✅ .specify/templates/tasks-template.md - testing note aligned with risk-based gates
  ✅ .specify/templates/commands/*.md - no files present
- Follow-up TODOs: None
-->

# AuraVibes Flutter Monorepo Constitution

## Core Principles

### I. User Value First

Every feature MUST start from a named user scenario, pain point, and measurable
success outcome. Features without a clear user benefit MUST be deferred. Specs
MUST keep user stories independently testable so each delivered slice can be
validated without shipping unrelated scope.

**Rationale**: AI assistant work can drift into impressive but unused capability.
User-centered slices keep implementation small and reviewable.

### II. Layered, Package-Aware Architecture

Flutter code MUST keep presentation, state/orchestration, domain decisions, and
data access separated. Widgets MUST not contain business logic. Repositories and
services MUST own external APIs, database access, and platform integration.
Reusable code MUST live in `packages/*`; app-specific composition MUST remain in
`apps/auravibes_app/`.

**Rationale**: Flutter architecture guidance emphasizes clear layer boundaries
with views, view models/controllers, repositories, and services. In this monorepo,
package boundaries are the enforcement mechanism for those responsibilities.

### III. UI System First

Production UI MUST use `auravibes_ui` tokens and components before adding custom
styling. Reusable widgets MUST be added to `packages/auravibes_ui/` only when
there is a current second use or a clear design-system need. UI changes MUST
account for responsive layout and accessibility semantics relevant to the change.

**Rationale**: Shared UI keeps visual behavior consistent. Requiring reuse too
early creates unnecessary abstractions, so extraction needs a current reason.

### IV. Data and State Correctness

Persistent data changes MUST define the model, ownership, and migration path
before implementation. Riverpod providers MUST have clear ownership and lifecycle
(`autoDispose`, scoped, or app-level). Async UI state MUST use `AsyncValue` or an
equivalent explicit loading/error/data representation. State updates MUST be
immutable.

**Rationale**: Drift schemas, Riverpod lifecycles, and generated immutable models
are high-blast-radius choices. Making ownership explicit prevents hidden coupling.

### V. Risk-Based Quality Gates

Tests are REQUIRED for new behavior, bug fixes, public package APIs, database
migrations, provider logic, and critical user journeys. Tests MUST be written
before or with the implementation when practical, and bug fixes SHOULD include a
regression test that fails before the fix. Documentation-only changes may use
review-only validation.

**Rationale**: Mandatory TDD for every edit creates process noise. Risk-based
testing keeps the non-negotiable part: changed behavior must be verifiable.

### VI. Explicit Failures

Fallible operations MUST expose explicit error states or typed exceptions. Code
MUST NOT catch errors and return `null` or generic fallback values silently. User
facing errors MUST explain the recovery path without exposing stack traces or
secrets.

**Rationale**: AI providers, local databases, and platform APIs fail often.
Silent failures cause data loss and make support/debugging harder.

### VII. Security and Privacy

Secrets, API keys, tokens, personal data, and conversation content MUST NOT be
logged or committed. Credentials MUST be stored with platform secure storage or
another approved secret-storage mechanism. User input and external data MUST be
validated at trust boundaries.

**Rationale**: AuraVibes handles provider credentials and private conversations.
The minimum safe rule is to prevent accidental disclosure by default.

### VIII. Observable Where It Matters

Provider operations, API calls, database writes, and long-running tasks MUST log
structured context sufficient to debug failures without logging sensitive data.
Performance-sensitive features MUST define the relevant metric before optimizing
and verify the result after changes.

**Rationale**: Observability is useful when it answers a support or performance
question. Blanket telemetry requirements create noise and privacy risk.

### IX. Simplicity

Every new abstraction, package, provider method, configuration key, route branch,
or feature flag MUST have a current accepted use case. Prefer straightforward
widget composition and small local duplication over speculative reuse. Unsupported
platforms or states MUST fail explicitly instead of pretending to work.

**Rationale**: The easiest code to maintain is code that does only what is needed
now. Premature flexibility is a recurring source of bugs in Flutter apps.

### X. Dart and Flutter Standards

Dart code MUST pass configured analysis with no warnings. Code MUST be formatted
with `dart format`. Public package APIs MUST use dartdoc when consumed outside
their package. Naming, imports, and API design MUST follow Effective Dart unless
the local codebase has a stronger convention.

**Rationale**: Consistency is the main value of Dart style rules. The analyzer,
formatter, and package docs keep monorepo work reviewable.

## Architecture Constraints

### Monorepo Structure

- Main app code lives in `apps/auravibes_app/`.
- Reusable packages live in `packages/*/`.
- Shared UI components live in `packages/auravibes_ui/`.
- Each package MUST have one clear responsibility.
- Dependency installation and workspace operations MUST use Melos from the repo root.
- Dart and Flutter commands MUST use the repository-pinned FVM SDK.

### State Management Contract

- Generated Riverpod providers are preferred because this project already uses code generation.
- Providers MUST declare lifecycle intentionally rather than relying on accidental defaults.
- Controllers/notifiers orchestrate use cases; widgets render state and forward user intent.
- Mutable shared state is prohibited unless isolated behind a repository/service boundary.

### Database Contract

- Drift schema changes MUST include migration tests or a documented verification path.
- Multi-step writes MUST use transactions.
- Providers MUST NOT contain raw SQL or schema migration logic.
- Persisted metadata MUST be versioned when the shape can change over time.

### Dependency Contract

- Runtime and development dependencies MUST be added with `fvm flutter pub add` or the
  project-approved Melos command, not by hand-editing `pubspec.yaml`.
- New dependencies MUST justify current use, maintenance health, and package-boundary impact.
- Do not import another package's `lib/src` internals.

## Development Workflow

1. **Read before write**
   - Inspect existing packages, widgets, providers, and data models before editing.
   - Check `packages/auravibes_ui/STYLE_GUIDE.md` before changing UI components.

2. **Define scope boundary**
   - Keep one concern per PR or task.
   - Identify affected app/package paths before implementation.
   - Document any intentional constitution exception before review.

3. **Implement minimal patch**
   - Change only lines needed for the accepted behavior.
   - Prefer deleting or simplifying code over adding framework.
   - Add abstractions only after a current caller requires them.

4. **Validate by risk**
   - Docs-only: review rendered content or links where relevant.
   - UI: widget tests and visual/manual check for affected states.
   - Provider/domain/data: unit tests for logic and error states.
   - Database: migration/data-shape verification.
   - Critical user journey: integration or end-to-end coverage when feasible.

5. **Document impact**
   - PRs MUST call out behavior changes, migration risk, and validation performed.
   - Breaking changes MUST include migration notes.

### Validation Commands

Default checks for code changes:

```bash
fvm dart run melos analyze
fvm dart run melos format
fvm dart run melos run test
fvm dart run melos run validate:quick
```

Run narrower package checks when the change is isolated and full validation is not
reasonable for the current task.

## Online References Reviewed

- GitHub Spec Kit constitution template and constitution command workflow, reviewed 2026-04-26.
- Flutter app architecture guide, reviewed 2026-04-26.
- Dart Effective Dart guide, reviewed 2026-04-26.
- Riverpod code-generation documentation, reviewed 2026-04-26.
- Melos getting-started documentation, reviewed 2026-04-26.

## Governance

### Amendment Procedure

- This constitution supersedes conflicting local conventions.
- Amendments MUST document the proposed change, impact, migration needs, and version bump.
- Maintainer approval is REQUIRED before merging constitution changes.
- Dependent templates under `.specify/templates/` MUST be checked with each amendment.

### Versioning Policy

- **MAJOR**: Removes or redefines a principle in a way that changes required behavior.
- **MINOR**: Adds a principle or materially expands required behavior.
- **PATCH**: Clarifies wording without changing required behavior.

### Compliance Review

- PRs MUST satisfy the principles relevant to touched files and changed behavior.
- Reviewers MUST block changes that violate security/privacy or data-migration rules.
- Complexity beyond the Simplicity principle MUST be justified in the PR description.
- `AGENTS.md` remains the runtime command and agent-behavior reference.

### Conflict Resolution

- If external best practices conflict with this constitution, follow this constitution
  and propose an amendment if the external guidance is better for this project.
- If a platform requirement conflicts with this constitution, document the exception
  and keep the workaround as narrow as possible.

**Version**: 2.0.0 | **Ratified**: 2026-03-09 | **Last Amended**: 2026-04-26
