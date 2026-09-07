# AuraVibes simplification goal

Paste the fenced prompt into Codex from the repository root. This starts work;
reading this file alone does not authorize execution. No extra plugin required.

```text
/goal Improve AuraVibes through repeated, verified simplifications and architecture improvements. Preserve business logic, supported features, externally supported contracts, and the Aura design system. Reduce maintained code and complexity; evolve architecture and UI components so later changes require fewer edits. Execute the loop below, committing each verified change, then continue automatically.

SUCCESS AND PRIORITIES

Priority order: behavior and safety > architectural boundaries > readability > fewer maintained lines.
Success requires evaluating at least N=5 distinct high-coupling business flows with dependency/call graphs and test-coverage evidence, completing eligible meaningful improvements and their equivalent occurrences, and producing the final architecture report below. A randomized sweep or a series of tiny commits alone cannot satisfy this goal. Report unresolved candidates separately; do not claim the codebase is perfect. Continue after each commit, not after asking for permission. Never invent work to keep the goal alive.

A useful change removes maintained production code, duplicate policy, unnecessary indirection, a bad pattern, or a concrete architectural violation. Architecture and UI improvements are eligible even without net line reduction when they demonstrably improve ownership, cohesion, reuse, or coupling. File moves count as architecture improvements only when they establish a clearer responsibility or dependency boundary; they do not count as code reduction. Formatting, renaming, and deleting tests do not count as code reduction.

MAINTENANCE BENEFIT GATE: Before implementing and before committing, name a concrete maintenance burden removed and its before/after evidence: duplicated business decisions consolidated, a dependency cycle or forbidden edge removed, independently maintained workflows unified, a live responsibility given one owner, or a genuinely unused subsystem retired. Other benefits need equally concrete evidence. Alias removal, terminal-await cleanup, cosmetic syntax, and isolated forwarding-method deletion fail this gate by themselves. Reject standalone commits below this bar; include small prerequisite changes only when they enable a named larger consolidation, explain that dependency, and finish that consolidation. Commit count, touched-file count, and raw deleted lines are not success metrics. Small fixes with substantial demonstrated benefit remain eligible.

Actively seek structural improvements, not only easy deletions. Substantial multi-file restructuring is encouraged when it removes a demonstrated source of complexity. You are authorized to reorganize entire affected features, consolidate modules, redistribute responsibilities, and migrate their consumers. There is no arbitrary file-count or diff-size limit. Choose the smallest COMPLETE solution to the problem, not the smallest patch that leaves its root cause intact. Size alone is never a reason to defer or request permission; uncertainty about behavior must be resolved with investigation and verification.

NON-NEGOTIABLES

- Preserve outputs, errors, side effects, ordering, defaults, persistence, serialization, async/stream behavior, cancellation, retries, approvals, permissions, localization, accessibility, and supported platforms.
- Never delete a working feature because it looks speculative or rarely used. “Unused” requires evidence. No grep matches alone is insufficient.
- Never remove validation, security checks, recovery paths, migrations, compatibility exports, or supported public APIs merely to reduce lines.
- Never replace Aura UI widgets with Material, Cupertino, or third-party widgets. Prefer the existing Aura equivalent when app code uses a non-Aura visual control. Preserve behavior, tokens, semantics, focus, keyboard handling, and layout. Flutter layout primitives and implementation primitives inside Aura components are legitimate; do not wrap everything just to add an Aura prefix. If no equivalent exists, record the gap; create a minimal reusable Aura component only when a current use requires it and parity can be verified.
- Aura UI's current widget inventory and file layout are NOT frozen. You may merge, combine, delete, update, enhance, create, or move UI package widgets when justified by current usage. Preserve supported UI behavior through the resulting Aura components. Migrate every in-repo consumer, public barrel, test, and Widgetbook story in the same coherent change; retain compatibility for externally supported consumers. Delete a used widget only after migrating its supported behavior to an appropriate Aura replacement. Avoid giant configurable widgets that merely hide duplication.
- Do not introduce generic frameworks, speculative extension points, or vendor-neutral interfaces for hypothetical needs. Preserve useful package, test, and external-system boundaries even when they have one implementation.
- No code golf, compressed formatting, blanket replacements, unrelated cleanup, weakened tests, analyzer suppressions, or new exclusions to make checks pass.
- No manual edits to generated files. Change their source, run the relevant generator, and inspect its output.
- Work locally. Local commits are authorized. Do not push, publish, open PRs, deploy, or write to remote services. No destructive Git operations. Preserve unrelated work.

START OR RESUME

1. Read root AGENTS.md, applicable nested instructions, and current git status. Record starting HEAD and pre-existing edits. Do not mix someone else's changes into your commits; skip overlapping files unless isolation is demonstrably safe.
2. Read applicable skills before touching code:
   - .agents/skills/app-architecture/SKILL.md for app code.
   - .agents/skills/package-architecture/SKILL.md for engine, UI, and Widgetbook.
   - Relevant Riverpod, usecase, localization, exception, Serverpod, or Dart skills only when the change needs them.
   - Use Ponytail's existing-code -> stdlib -> platform -> installed-dependency -> minimum-code ladder after understanding the flow. The Aura UI rule above takes precedence over replacing custom UI with platform controls.
3. Inspect pubspec.yaml, package manifests, lockfile, .fvmrc, relevant tests, and doc/architecture/ as needed. Verify installed versions and actual commands; do not assume a skill's version matches the repo.
4. Maintain one compact, uncommitted progress ledger outside tracked source, at a worktree-specific path resolved through git rev-parse --git-path. Record shuffled area order, candidates, searches, decisions, current patch, pending checks, completed commits, and deferred reasons. Never store secrets. On resume, reconcile ledger with Git and current files before acting. Do not restart completed work or repeat unchanged failed candidates.

LOOP: ONE COHERENT IMPROVEMENT, VERIFIED COMMITS

A. SELECT

- First inventory actual end-to-end business flows and rank coupling using observed cross-feature/package edges, dependency cycles, duplicated policy owners, and orchestration spread. Select and evaluate at least N=5 distinct high-coupling flows before making cleanup commits. A flow runs from a real trigger through state/orchestration to persistence or another effect; five helpers from one workflow do not count as five flows. If fewer than five flows exist, document the complete inventory and evaluate all of them rather than inventing targets.
- Enumerate app feature folders, shared app layers, engine modules, UI component groups, and repo-local skills for discovery. Randomize ties among similarly ranked flows/areas and persist the order; severity and maintenance benefit outrank randomness. Address the strongest actionable architectural target first. Do not repeatedly choose small candidates while a supported larger consolidation remains actionable.
- For each selected flow, complete the evidence record in section B. No candidate there? Record the inspected graph, coverage, and reason further restructuring would not help; a quick grep or passing analyzer does not establish architectural cleanliness.
- Use these categories:
  1. Proven dead code, unused flexibility, unreachable speculative scaffolding: replacement is nothing.
  2. Handwritten behavior already provided by Dart: name the exact library and function, and verify semantic equivalence.
  3. Code/dependency duplicating platform functionality: name the exact feature and supported-platform behavior. Respect Aura UI.
  4. One-implementation abstractions, unset configuration, forwarding layers: remove only when they carry no policy, lifecycle, injection, compatibility, or architectural responsibility.
  5. Duplicate business logic or needlessly complex expressions/control flow: show a short before/after and explain equivalent semantics. Similar text is not necessarily the same business rule.
  6. Architecture improvements and bad patterns: repair incorrect ownership, dependency cycles, mixed responsibilities, misplaced files, feature leakage, oversized coordinators, and duplicated orchestration. Improve the architecture itself when the current or proposed structure causes a demonstrated problem; do not limit discovery to enforcing today's folder layout.
  7. Stale or contradictory repo-local coding skills: correct evidence-backed guidance that would otherwise recreate the problem.
  8. Aura UI component evolution: consolidate overlapping widgets, improve composition and APIs, move misplaced components, replace app-side visual controls with Aura equivalents, or create a missing component for a demonstrated current need.

B. PROVE AND EXPAND

- Read each target file fully, its callers, dependencies, exports, and relevant tests. Trace the affected flow end to end. Search the whole repository with rg for callers and equivalent occurrences, including alternate names and implementations, not only exact text.
- For every architectural target, record a dependency graph (imports, injection, ownership, and package boundaries) and a runtime call graph (trigger, branches, state transitions, effects, error/cancel paths). Compact adjacency lists or Mermaid are sufficient; cite real file paths and symbols for edges. Resolve registrations and indirect dispatch where possible; label unknown edges explicitly instead of treating them as absent. Record cycles, duplicated decisions, and consumers affected by a change.
- Map each meaningful behavior/branch in that flow to actual test names, assertions, and execution results. Use existing coverage tooling for targeted line/branch coverage where available; distinguish measured coverage from an inspection-based behavior map and label unmeasured coverage. A test file's existence or a passing suite is not proof that the flow is covered. Identify gaps and close those needed to verify a planned consolidation. Do not declare an area clean while its relevant graph or behavior coverage is unknown; classify it as unresolved with the missing evidence.
- For deletion, check registrations, routing, code generation, conditional imports, native/platform hooks, configuration, public exports, examples, tests, and documented compatibility. Reachability from outside the repo can make locally unreferenced APIs live. If usage cannot be resolved, defer deletion.
- For shorter forms, compare null/empty behavior, exceptions, ordering, equality, mutability, laziness, side effects, asynchronous sequencing, and time/memory complexity as applicable. Example: a Set is not a safe list replacement if duplicates matter; Future.wait is not equivalent to sequential side effects.
- Make a compact candidate record before editing:
  Pattern and evidence; exact replacement; invariants; current/target owner; all matching locations; smallest verification commands; expected reduction or coupling improvement.
- For architecture changes, compare repairing the existing structure with the smallest better structure. Name the violated principle, concrete current cost, proposed dependency direction, files/consumers to migrate, and observable benefit. Choose based on evidence, not preference for a named architecture. Existing architecture docs are the baseline, not an immutable design; changing a rule requires this justification and synchronized docs/skills, not merely relocating the violation.
- Classify each match: equivalent and safe / different semantics / unresolved. Apply the principle to every proven-equivalent occurrence across the codebase. Fix the shared implementation once when callers already converge there.
- Keep one coherent improvement per migration, with separately verified commits where useful. Before a substantial restructure, record the target structure, complete affected-file/consumer inventory, behavior contracts, ordered migration steps, verification for each step, and how to recover your own changes. Each commit must build and pass its required checks. If the migration cannot be split without breaking the build or leaving invalid wiring, complete and verify the coherent multi-file change before committing it. Finish the migration and its equivalent occurrences before choosing another random pattern. Never turn a mechanical match into an unchecked global rewrite.
- Missing evidence means inspect more or defer that candidate. Do not ask about routine reversible choices. Ask only when missing information or an explicit decision actually prevents progress; keep working on independent candidates.

C. IMPLEMENT

- Establish passing focused baseline tests before changing behavior-bearing code. Add the smallest characterization test in the existing test framework if important behavior lacks coverage; verify it passes before refactoring. Preserve meaningful assertions when updating imports or test wiring.
- Make the simplest readable implementation that fully resolves the selected problem, across as many files as necessary. Reuse existing helpers and components. Extract shared logic only when current callers share the same policy; do not force distinct domains into one configurable helper. Remove temporary migration glue once consumers have moved; do not stop at a partial restructure because the remaining changes are numerous.
- Follow app ownership: UI renders and forwards intent; notifiers own mutable state; providers wire dependencies; usecases own business rules; repositories own persistence; services/adapters contain external effects and translation. Removing a pass-through must not make widgets call repositories or SDKs directly.
- Architecture cleanup and evolution are explicitly authorized, including moves of legacy files. Apply single responsibility, cohesion, encapsulation, and dependency inversion where they solve an observed problem; no mandatory extra layer per principle. Deliver one complete, verified boundary change at a time. Update paths, imports, exports, generated-source inputs/output, tests, and affected documentation together. Do not leave half-migrated owners or parallel architectures without a concrete temporary migration need. Preserve the responsibility and package-isolation safeguards above while evolving their implementation.
- Keep engine pure Dart and app-neutral, UI domain-neutral, and dependencies pointing from app to packages. Keep SDK-specific types and translations at existing boundaries where practical. Improve replaceability by removing actual leakage, not by promising effortless future migrations.
- Package/framework replacement is eligible only with a concrete reduction in total maintained complexity, verified version/platform compatibility, and a complete local behavior-preserving migration with focused checks. Count new adapters, configuration, dependency surface, and migration burden; fewer repository lines alone is insufficient. Use find-docs/Context7 for exact-version APIs and official sources where needed. Never guess APIs or migrate a whole framework as an incidental cleanup. Defer replacements requiring product choices, unverifiable platform behavior, breaking contracts, or production data migration; continue other work.
- Repo-local skills may be fixed, consolidated, or removed only after reading the entire skill and checking its references. Preserve unique valid guidance, update references, and validate examples/paths. Update architecture docs only when boundary or placement rules change. Never rewrite rules to excuse your patch or reduce verification. Do not edit global skills or installed plugin caches. Do not confuse coding-agent skills with the app's user-facing skills feature.

D. VERIFY

- Re-read the complete diff against the candidate's invariants. Inspect every changed call site and every remaining search match. Verify no stale imports or forbidden dependency edges were introduced.
- Every cross-feature change requires `fvm dart run melos run validate:quick` from the repository root on its final code state, in addition to behavior tests. Every workflow consolidation requires targeted integration tests exercising the real collaborating layers and their state/effect ordering, including relevant failure, cancellation, and retry cases. Reuse existing integration tests or add the smallest suitable test in the existing framework; mock external boundaries, not the internal orchestration being consolidated. Run these tests before and after migration. Isolated unit tests or interaction mocks alone do not satisfy this gate. Record the exact integration command and result; inability to run it blocks committing that consolidation.
- For architecture moves, verify old paths have no unintended references and the new dependency direction is respected by every affected consumer. Add or update the smallest existing-style boundary check when practical. For UI merges/deletions, verify all supported variants and interactions remain covered and all consumers use the intended Aura API. Treat reduced cycles, fewer policy owners, or fewer consumer-specific workarounds as concrete benefits; a new directory name is not evidence.
- Format only touched Dart source using repository conventions. Run fatal analysis for affected packages and focused tests for affected behavior and consumers. For this goal, behavior-bearing Dart refactors require BOTH analysis and focused tests, including provider cleanup; this explicitly supersedes the repo's analyzer-only shortcut for those changes. Pure analyzer-metadata edits without behavior changes may use its analyzer-only rule.
- Commands verified in this repo; replace test placeholders with discovered real paths:
  App analyzer, from root:
    fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine
  Other affected package analyzer, from package root:
    fvm dart analyze --fatal-infos --fatal-warnings
  App/UI focused tests, from the owning package:
    fvm flutter test test/path/to/file_test.dart --no-pub
  Engine focused tests, from packages/auravibes_engine:
    fvm dart test test/path/to/file_test.dart
  Shared logic or broad architecture moves, from root:
    fvm dart run melos run validate:quick
  Dependency changes, from root:
    fvm dart run dependency_validator
  Import changes, from the appropriate package scope supported by the tool:
    fvm dart run import_sorter:main --exit-if-changed
- Inspect current Melos definitions before using them. validate:quick currently runs analysis and formatting, NOT tests. It does not replace focused tests. Do not rerun analysis already covered by a completed broader check unless relevant files changed.
- Run full validate and PR gates only when required by scope/repo rules; do not run test:ci unless explicitly needed. For skills/docs-only edits, validate references, instructions, and diff; no unrelated Dart suites.
- For a substantial multi-feature or package-boundary restructure, run focused checks at stable intermediate steps, then full validate once on the completed migration, plus dependency/import gates when those change. Inspect the actual suite coverage and add targeted consumer/integration checks for affected contracts it does not exercise. Do not repeat suites already included in validate. A large diff needs broader evidence, not weaker checks or a claim that the analyzer proves behavior parity.
- For UI changes, capture and inspect before/after screenshots under matching conditions and run relevant widget tests. Verify focus/semantics and real native keyboard behavior when affected. Use dev Debug for native keyboard testing; Driver mode cannot prove it. If parity cannot be checked, defer the UI change.
- Announce long commands with expected duration. Record command, directory, exit status, duration, and relevant failures. Wait for running commands to finish; timeout or background execution is not a pass.
- Failed required check: diagnose and fix only your change, then rerun affected checks. Never commit a candidate whose required checks fail or cannot run. If a required baseline check already fails, defer that candidate rather than quietly calling it green. Report unrelated wider-gate diagnostics without expanding into unrelated repairs.
- If a candidate cannot be completed safely, undo only edits you made for that candidate, preserving pre-existing and concurrent changes. Record why; continue an independent candidate. If ownership is uncertain or the environment blocks all progress, report the concrete blocker and preserve recoverable state. Follow Codex's actual goal lifecycle rules; do not fake completion.

E. COMMIT AND CONTINUE

- Check git status before staging. Stage only this candidate's exact files/hunks. Inspect staged diff and ensure it contains no unrelated edits, generated churn, secrets, or progress ledger. Verify the code being committed matches the code checked.
- Reapply the maintenance benefit gate to the staged result. Record the target flow and before/after structural evidence, or the named consolidation this prerequisite enables. Reject cosmetic-only progress; do not relabel terminal awaits or aliases as architecture improvements. For completed consolidations, update their graphs and coverage maps to show the actual result.
- Commit with an accurate Conventional Commit title, normally refactor(scope): ..., or docs(skills): ... for guidance-only changes. Do not use git add ., bypass hooks, amend unrelated commits, or push. If hooks modify code, review and revalidate it before completing the commit.
- Verify commit succeeded and capture its real hash. Check status again. Record production-source added/deleted/net lines separately from tests, generated files, and docs, using Git rename detection. Do not count moves as deleted code or promise a percentage target.
- Emit a compact checkpoint: commit; pattern and actual benefit; occurrence counts and exceptions; checks/results; next area. Update the ledger, then immediately continue the same goal.

SWEEP COMPLETION

After finishing the ranked targets and queued occurrences, revisit areas affected by the changes. If the sweep produced improvements, reassess newly exposed structural opportunities. Finish only when the minimum architectural evaluations are complete, a complete evidence-backed sweep produces no further meaningful eligible change, no safe queued consolidation or prerequisite-only migration remains unfinished, and the final architecture report is written. Do not count tiny edits toward the minimum evaluations. Missing evidence requires further investigation or an explicit unresolved finding, never a clean verdict. User pause/stop always wins. If a budget interrupts work, checkpoint safely and do not mark unfinished work complete.

FINAL ARCHITECTURE REPORT (required completion artifact in the final response, with supporting detail in the ledger):
- Inventory and ranking of the evaluated flows; show that N=5 was met, or substantiate the smaller complete inventory.
- For each target: paths/symbols, dependency/call graphs before and after any change, coupling problem, coverage map and gaps, decision (resolved / no beneficial change found / deferred), evidence for that decision, and commit references where applicable.
- Rank the top five remaining complexity hotspots, or all if fewer remain. For each explain why it remains, why it was deferred, its impact, and the exact evidence, check, or decision needed to address it. Also identify which original top hotspots were resolved and how; never omit remaining hotspots because they are difficult.
- Commands, results, and relevant baseline failures, explicitly including cross-feature validate:quick and workflow integration results. Include measured production-line delta separately from tests/docs/generated files, and actual structural benefits rather than commit counts.
Never claim behavior preservation beyond what the checks and inspection support. A completed assessment may contain explicitly deferred findings; it must not claim those architectural problems were solved.
```

## Research basis

Reviewed 2026-09-05. The loop and repo-specific safeguards above are a synthesis,
not a quoted upstream prompt. No prompt guarantees a smaller model will avoid
mistakes; observable evidence and commit gates make failures easier to catch.

- [Ponytail upstream](https://github.com/DietrichGebert/ponytail): understand the
  code first, reuse existing capabilities, minimize implementation without
  deleting safety checks.
- [Martin Fowler: YAGNI](https://martinfowler.com/bliki/Yagni.html): remove
  speculative capabilities while retaining investment in code that is easier
  to change.
- [Martin Fowler: preparatory refactoring](https://martinfowler.com/articles/preparatory-refactoring-example.html):
  make structural changes incrementally and check preserved behavior.
- [OpenAI: Follow a goal](https://developers.openai.com/codex/use-cases/follow-goals):
  use a verifiable end condition, explicit scope, validation, and checkpoints
  for sustained work.
