# Agent Skills Cleanup Design

## Goal

Make repo-local agent skills consistent, discoverable, low-duplication, and mechanically validated without introducing a shared runtime library.

## Scope

This change covers `.agents/skills`, the repo-local skill routing contract in `AGENTS.md`, and CI validation for those files. It does not convert project-local skills into a distributable Agent Plugin repository, change application Dart code, or remove existing skill names.

## Design

### Canonical ownership

One skill owns each recurring rule set:

- `app-architecture`: app feature placement, app layer boundaries, app-specific Riverpod placement, and app verification.
- `package-architecture`: engine/UI package boundaries, public API exports, and package verification.
- `flutter-riverpod-expert`: Riverpod 3 behavior, hooks/consumer imports, provider selection, lifecycle, mutations, and provider testing.
- `localization`: easy_localization behavior and translation workflows.
- `melos-7`: Melos 7/8 workspace configuration and command behavior.
- `serverpod`: AuraVibes Serverpod workflow and safety rules.
- `error-handling-exceptions`: exception policy.
- `dart-shorthand`: Dart dot-shorthand policy.
- `dart-coverage-audit`: coverage workflow and its parser.
- `code-review`: CodeRabbit CLI review workflow.
- `review-pr`: collecting and applying GitHub PR feedback.

Specialized overlays reference canonical owners instead of repeating their rules:

- `flutter-expert` becomes general Flutter workflow and routing guidance. Riverpod details route to `flutter-riverpod-expert`; app/package placement routes to the architecture skills.
- `flutter-controller-pattern` becomes controller orchestration guidance and points to `app-architecture`, `flutter-riverpod-expert`, and `usecase-pattern` for boundaries.
- `flutter-notifier-pattern` becomes notifier naming/lifecycle and runtime-adapter guidance and points to `flutter-riverpod-expert` and `usecase-pattern`.
- `usecase-pattern` remains the focused use-case workflow and points to `error-handling-exceptions` for exception policy and `app-architecture` for placement.

### Reference splitting

Keep `SKILL.md` as control-plane content: trigger, scope, canonical decisions, reference map, and verification. Move long reference material into direct, one-hop files named by topic:

- `localization`: split translation structures/reuse, runtime usage, and advanced/audit details into direct references.
- `melos-7`: split configuration, scripts/filters, commands, and CI/release details into direct references.

Every new reference is named directly from its owning `SKILL.md`; no reference index or multi-hop hub is introduced.

### Routing and metadata

- Narrow overlapping descriptions so generic Flutter requests select `flutter-expert`, Riverpod requests select `flutter-riverpod-expert`, and architecture requests select the matching app/package skill.
- Remove or replace `related-skills` values that are not present in the repo-local skill catalog.
- Keep metadata optional and factual; do not add aliases for skills that are not shipped locally.
- Update `AGENTS.md` only if routing rules or validation commands change.

### Rule consistency

Use AuraVibes rules as the authority for local Flutter code:

- New Riverpod UI uses Dart switch patterns instead of `.when()`.
- Legacy providers remain maintenance-only and use `hooks_riverpod/legacy.dart`.
- Generated providers and app placement follow the local Riverpod and app-architecture skills.

Generic examples that contradict those rules are rewritten or labeled as legacy/external examples.

### Mechanical audit

Add `scripts/audit-agent-skills.sh` with no external dependencies beyond POSIX shell utilities and Git. It must fail on:

- missing or mismatched `SKILL.md` frontmatter `name`;
- descriptions that do not begin with `Use when` or exceed 1,536 characters;
- `SKILL.md` bodies over 500 lines;
- references named by a skill but missing on disk;
- files under a skill `references/` directory not discoverable from its `SKILL.md`;
- `related-skills` names absent from the repo-local catalog;
- known forbidden contradictory Riverpod guidance (`StateProvider`/`.when()` in AuraVibes guidance unless explicitly marked legacy).

It prints file-specific errors and exits non-zero on failures. It does not attempt to parse arbitrary Markdown or evaluate model behavior.

Add `.github/workflows/skills-verify.yml` to run the audit on pull requests and pushes affecting `.agents/skills`, `AGENTS.md`, or the audit script.

## Acceptance criteria

1. All repo-local skill directories contain valid, matching frontmatter names.
2. No `SKILL.md` exceeds 500 lines; long guidance lives in directly linked references.
3. No repo-local `related-skills` entry points to an absent skill.
4. Riverpod guidance has one local answer for `.when()`, legacy providers, generated providers, and scoped providers.
5. Generic Flutter skill routes specialized topics instead of duplicating them.
6. Audit script passes locally and CI invokes it for relevant changes.
7. No Dart application/package source changes are required for this cleanup.

## Verification

Run from repo root:

```sh
bash scripts/audit-agent-skills.sh
bash /Users/davidlondono/.agents/skills/agent-harness/scripts/verify-harness.sh
bash -n scripts/audit-agent-skills.sh
```

Review `git diff --check` and inspect the generated skill diff. No Dart test suite is required because this changes agent documentation and shell validation only.

## Risks and mitigations

- **Routing still overlaps:** descriptions use explicit topic ownership and local cross-references; audit checks stale related names but not model selection quality.
- **Reference becomes undiscoverable:** audit checks every reference file is named from its owning `SKILL.md`.
- **Generic docs drift again:** canonical-owner table and CI audit make ownership visible; future rule changes update the owner first.
- **Validator overreach:** checks remain structural and narrow; it does not reject valid prose or require standalone plugin packaging.
