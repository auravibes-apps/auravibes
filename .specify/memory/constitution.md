<!--
Sync Impact Report:
- Version change: NONE → 1.0.0
- Modified principles: N/A (initial constitution)
- Added sections: All sections (initial constitution)
- Removed sections: N/A
- Templates requiring updates:
  ✅ .specify/templates/plan-template.md - Constitution Check section aligned
  ✅ .specify/templates/spec-template.md - User needs and data requirements aligned
  ✅ .specify/templates/tasks-template.md - Task categorization aligned with principles
- Follow-up TODOs: None
-->

# AuraVibes Flutter Monorepo Constitution

## Core Principles

### I. Start with User Needs

**Why here**: User-centered design prevents feature creep and ensures real value delivery in AI assistant applications.

Required:

- Every feature MUST begin with explicit user scenarios and pain points
- Features without clear user benefit MUST be rejected or deferred
- User stories MUST be prioritized by value and independently testable
- UI/UX decisions MUST be validated against user journey maps
- Accessibility MUST be considered from the start, not as an afterthought

**Rationale**: In AI-powered applications, it's easy to build technically impressive features that don't solve real problems. Starting with user needs ensures we build what matters.

### II. Design with Data

**Why here**: Data-driven decisions reduce assumptions and improve AI assistant effectiveness.

Required:

- Database schema MUST be designed before UI implementation
- Data flow diagrams MUST exist for features involving state persistence
- API contracts MUST be defined before provider implementations
- Analytics and telemetry MUST be planned for user behavior understanding
- Data models MUST use immutable patterns (Freezed/Equatable) for predictability

**Rationale**: Flutter's reactive paradigm and Riverpod's state management work best with well-designed data models. Changing database schema later has high blast radius across the monorepo.

### III. Package-First Architecture

**Why here**: Monorepo structure enables code reuse and maintains clean boundaries between concerns.

Required:

- Every feature MUST consider: Does this belong in an existing package, a new package, or the main app?
- Shared functionality MUST be extracted to packages (`packages/*/`)
- Platform-specific code MUST be isolated in appropriate packages or app layers
- UI components MUST use the `auravibes_ui` package design system (atoms/molecules/organisms/templates)
- Package dependencies MUST flow inward: concrete implementations depend on abstractions, not vice versa

**Rationale**: Flutter monorepos with Melos work best when packages have clear, single responsibilities. Cross-package coupling creates maintenance burden and breaks independent testing.

### IV. UI Kit Mandate

**Why here**: Consistent UI reduces cognitive load and accelerates development across the monorepo.

Required:

- ALL UI components MUST use design tokens from `auravibes_ui` package (colors, typography, spacing)
- Custom widgets MUST follow atomic design hierarchy (atoms → molecules → organisms → templates)
- New components MUST be added to `auravibes_ui` if reusable across features
- Material Design 3 theming MUST be applied via the design system, not hardcoded
- Responsive design MUST use defined breakpoints from design tokens

**Rationale**: Hardcoded styles and ad-hoc components create visual inconsistency and make theme changes expensive. The atomic design system ensures scalability and maintainability.

### V. Test-Driven Development (NON-NEGOTIABLE)

**Why here**: Flutter's hot reload enables rapid iteration, but tests ensure stability across the monorepo.

Required:

- TDD mandatory: Tests written → User approved → Tests fail → Then implement
- Red-Green-Refactor cycle strictly enforced
- Widget tests MUST exist for all UI components in `auravibes_ui`
- Integration tests MUST cover critical user journeys (chat, workspace management, agent interactions)
- Unit tests MUST cover business logic in providers, repositories, and use cases
- 80%+ code coverage required for new features

**Rationale**: Flutter's widget tree and Riverpod's provider dependencies create complex state interactions that are difficult to debug without tests. Tests document intent and prevent regressions.

### VI. Fail Fast + Explicit Errors

**Why here**: Silent failures in AI assistant applications can lead to data loss or incorrect responses.

Required:

- Prefer explicit error types over dynamic exceptions
- Use `Result<T, E>` pattern for fallible operations (via Freezed sealed classes)
- Never catch exceptions and return null silently
- Log all errors with structured context (user action, feature, error type)
- UI MUST display meaningful error messages to users, not technical stack traces
- Critical operations MUST have rollback/recovery mechanisms

**Rationale**: AI interactions involve external APIs (Anthropic, OpenAI) and local state (Drift database). Silent failures corrupt user data and erode trust. Explicit errors enable debugging and recovery.

### VII. Simplicity + YAGNI

**Why here**: Premature complexity increases attack surface and maintenance burden in cross-platform apps.

Required:

- Do not add new config keys, provider methods, feature flags, or routing branches without a concrete accepted use case
- Do not introduce speculative "future-proof" abstractions without at least one current caller
- Keep unsupported platforms or features explicit (error out) rather than adding partial fake support
- Prefer straightforward widget composition over clever meta-programming
- Duplicate small, local logic when it preserves clarity (DRY applies only after rule-of-three)

**Rationale**: Flutter's declarative UI and Riverpod's reactive state already provide powerful abstractions. Adding layers of indirection without clear benefit makes the codebase harder to navigate and test.

### VIII. Observability + Performance

**Why here**: AI assistant performance directly impacts user experience across six platforms.

Required:

- Structured logging required for all provider operations, API calls, and state changes
- Performance profiling MUST be done for features involving:
  - Chat message rendering (large conversation threads)
  - Database queries (workspace/chat history)
  - AI provider API calls (latency and token usage)
  - Image/media handling
- Memory usage MUST be monitored for long-running sessions
- Startup time MUST stay under 3 seconds on target devices
- Animation frame rates MUST maintain 60 fps during UI interactions

**Rationale**: Flutter apps on multiple platforms have different performance characteristics. AI responses can be slow, and UI jank during message streaming degrades perceived quality.

### IX. Security + Privacy

**Why here**: AI assistants handle sensitive user data (API keys, conversations, workspaces).

Required:

- API keys MUST be stored using secure storage (flutter_secure_storage or platform keychain)
- User conversations MUST be encrypted at rest (Drift encryption or platform-level encryption)
- Never log or persist sensitive data (API keys, auth tokens) in plain text
- Use neutral, project-scoped placeholders in tests/examples (e.g., `test_user`, `auravibes_workspace`)
- Never commit personal data, real names, emails, or API keys in code, docs, or tests
- Validate all user inputs before processing (guard clauses, schema validation)

**Rationale**: Cross-platform Flutter apps access platform-specific secure storage. Losing API keys or exposing conversations damages user trust and violates privacy expectations.

### X. Code Quality Standards

**Why here**: Monorepo consistency enables parallel development across packages.

Required:

- Use `very_good_analysis` linting rules strictly (no warnings allowed in CI)
- Format all code with `dart format` before commits
- Follow Dart naming conventions: `lowerCamelCase` for variables/functions, `PascalCase` for types, `snake_case` for files
- Keep files under 400 lines; extract large widgets/providers into smaller units
- Use meaningful names: `ChatMessageList` over `MessageWidget`, `WorkspaceRepository` over `Repo`
- Document public APIs with dartdoc comments for package consumers

**Rationale**: Flutter's hot reload and IDE support work best with consistent, well-formatted code. Large files slow down analysis and make navigation difficult.

## Architecture Constraints

### Monorepo Structure

**Why here**: Melos manages dependencies and linking across packages.

Required:

- Main app lives in `apps/auravibes_app/`
- Reusable packages live in `packages/*/`
- Shared UI components live in `packages/auravibes_ui/`
- Each package MUST have clear, single responsibility (e.g., `auravibes_ui` for UI, `auravibes_core` for domain logic)
- Use `melos bootstrap` for dependency installation, never manual `pub get`
- All Dart commands MUST prefix with `fvm ` to ensure correct SDK version

**Rationale**: Manual dependency management in monorepos creates version conflicts and linking issues. Melos ensures consistency and enables local package linking.

### State Management Contract

**Why here**: Riverpod provides powerful state management, but misuse creates complex dependencies.

Required:

- Use code generation for providers (`riverpod_generator`)
- Providers MUST have clear ownership: app-level (singleton), scoped (feature-level), or autoDispose (ephemeral)
- Never mutate state directly; always create new instances (immutable updates)
- Use `AsyncValue` for async operations, never raw Futures in UI
- Keep business logic in providers/repositories, not in widgets
- Controllers orchestrate use cases; widgets only handle presentation

**Rationale**: Riverpod's reactive model works best with immutability. Mutable state creates race conditions and makes testing difficult.

### Navigation Contract

**Why here**: GoRouter enables declarative routing, but deep links require careful planning.

Required:

- Define all routes in a single router configuration
- Use typed route parameters (not dynamic maps)
- Deep links MUST be validated before navigation
- Navigation state MUST persist across app lifecycle (backgrounding/foregrounding)
- Handle navigation errors gracefully (fallback routes, error screens)

**Rationale**: Complex navigation in AI assistants (chat → settings → workspace → chat) requires predictable routing. Ad-hoc navigation creates hard-to-debug state issues.

### Database Contract

**Why here**: Drift provides type-safe SQLite, but schema changes have high blast radius.

Required:

- Schema changes MUST include migration scripts
- Database version MUST be tracked explicitly
- Use DAOs (Data Access Objects) for complex queries, not raw SQL in providers
- Transactions MUST be used for multi-step operations
- Database files MUST be platform-appropriate (Application Documents on iOS/macOS, AppData on Windows)

**Rationale**: Database schema changes in production apps require careful migrations. Direct SQL in providers makes schema evolution difficult.

## Development Workflow

### Feature Development Process

1. **Read before write**
   - Inspect existing packages, widgets, and providers before editing
   - Check `auravibes_ui` for existing components before creating new ones
   - Review database schema for related entities

2. **Define scope boundary**
   - One concern per PR; avoid mixed feature+refactor+infra patches
   - Declare which packages are affected (app, UI, core, etc.)
   - Identify if UI kit needs updates

3. **Implement minimal patch**
   - Apply Simplicity/YAGNI/DRY rule-of-three explicitly
   - Use `auravibes_ui` design tokens for all UI changes
   - Write tests first, ensure they fail, then implement

4. **Validate by risk tier**
   - Docs-only: lightweight checks
   - UI changes: widget tests + visual regression
   - State/DB changes: integration tests + migration tests
   - Provider/API changes: unit tests + contract tests

5. **Document impact**
   - Update docs/PR notes for behavior, risk, side effects, and rollback
   - If UI changes: update `auravibes_ui` README and component catalog
   - If DB changes: document migration path and rollback strategy
   - If routing changes: update navigation documentation

6. **Respect queue hygiene**
   - If stacked PR: declare `Depends on #...`
   - If replacing old PR: declare `Supersedes #...`

### Branch / Commit / PR Flow

All contributors (human or agent) must follow the same collaboration flow:

- Create and work from a non-`main` branch
- Commit changes with clear, scoped commit messages (conventional commits)
- Open a PR to `main`; do not push directly to `main`
- Wait for required checks (analyze, format, test) and review outcomes before merging
- Merge via PR controls (squash/rebase/merge as repository policy allows)

### Validation Commands

Default local checks for code changes:

```bash
# Formatting
fvm dart format --set-exit-if-changed .

# Analysis
fvm dart analyze --fatal-infos

# Tests (run in specific package or app directory)
fvm flutter test

# Melos validation (run from monorepo root)
fvm dart run melos run validate:quick  # Quick check
fvm dart run melos run validate        # Full CI validation
```

### Platform-Specific Considerations

- **iOS/macOS**: Test on physical devices for performance; verify keychain access
- **Android**: Test across API levels (21+); verify secure storage behavior
- **Web**: Test with different browsers; verify responsive design at breakpoints
- **Windows/Linux**: Test installation paths and local storage

## Governance

### Amendment Procedure

- Constitution supersedes all other practices and conventions
- Amendments require:
  1. Documentation of proposed change
  2. Impact analysis on existing packages and features
  3. Migration plan for breaking changes
  4. Approval from project maintainers
  5. Update to constitution version following semantic versioning

### Versioning Policy

- **MAJOR**: Backward incompatible principle removals or redefinitions (e.g., removing TDD requirement)
- **MINOR**: New principle/section added or materially expanded guidance (e.g., adding accessibility principle)
- **PATCH**: Clarifications, wording improvements, typo fixes, non-semantic refinements

### Compliance Review

- All PRs/reviews MUST verify compliance with relevant constitution principles
- Complexity beyond simplicity guidelines MUST be justified in PR description
- Use `AGENTS.md` for runtime development guidance and command reference
- Constitution violations block PR merge until resolved

### Conflict Resolution

- In case of conflict between constitution and external best practices, constitution takes precedence
- If constitution principle conflicts with platform requirement, document exception and seek amendment
- When in doubt, err on the side of simplicity and user value

**Version**: 1.0.0 | **Ratified**: 2026-03-09 | **Last Amended**: 2026-03-09
