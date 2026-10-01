# Contributing to AuraVibes

AuraVibes is a Flutter monorepo managed with Melos and FVM. The app lives in
`apps/auravibes_app/`, while shared functionality lives in `packages/`.

## Prerequisites and setup

Install:

- FVM version compatible with this repository
- Flutter version selected by [`.fvmrc`](.fvmrc)
- Dart SDK constraint in root [`pubspec.yaml`](pubspec.yaml), provided by the pinned Flutter SDK
- Melos version in root [`pubspec.yaml`](pubspec.yaml) dev dependencies

See [README.md](README.md) for platform-specific requirements and app setup.
Use FVM for every Dart and Flutter command so the repository SDK is used:

```bash
fvm flutter --version
fvm dart --version
```

## Development workflow

1. Fork and clone the repository.
2. Create a branch from `main`.
3. Select the Flutter SDK pinned in `.fvmrc` and resolve Dart dependencies:

   ```bash
   fvm use
   ```

   FVM selects the SDK pinned in `.fvmrc`, updates the local SDK link and VS
   Code setting, and runs `flutter pub get` by default when the SDK changes.
   This repository enables that behavior; use `--skip-pub-get` to skip
   resolution.

4. Run the repository's Melos workspace bootstrap:

   ```bash
   fvm dart run melos bootstrap
   ```

   The root Pub workspace declares package membership. Melos bootstrap
   resolves the workspace and generates ignored IntelliJ module files for its
   six packages. CI runs this command before checking for dependency artifact
   drift. Keep it in the fresh-checkout setup sequence even though Pub handles
   workspace package resolution; setup should leave no tracked or untracked
   dependency changes.

5. Make the smallest change that solves the problem. Follow the standards in
   [`AGENTS.md`](AGENTS.md) and the relevant package instructions.
6. Run focused checks while iterating:

   ```bash
   fvm dart run melos run validate:quick
   ```

   For the full pull request gate, see [Pull requests](#pull-requests) and
   [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

7. Commit with a Conventional Commits message.
8. Open a pull request against `main`, `dev`, or `stage`, as appropriate.

## Coding standards

- Keep Dart formatting at 80 columns. Use the root
  [`analysis_options.yaml`](analysis_options.yaml) and
  `very_good_analysis` rules as the source of truth.
- Use components from [`auravibes_ui`](packages/auravibes_ui/README.md) for
  app UI instead of creating duplicate controls.
- Add a reason when an analyzer `ignore` or `ignore_for_file` is necessary.
- Keep changes scoped. Remove declarations made unused by your change.
- Localize user-facing strings and use the project's typed error patterns.

Read [AGENTS.md](AGENTS.md) and the closest package `AGENTS.md` before
changing code.

## Commit messages

Use the form `<type>(<scope>): <description>`. Common types are:

- `feat`: add behavior
- `fix`: correct behavior
- `docs`: change documentation
- `refactor`: change structure without changing behavior
- `test`: add or change tests
- `chore`: maintenance

Examples: `feat(chats): add conversation search` and
`fix(ui): preserve keyboard focus`. Pull request titles must use the same
Conventional Commits format.

## Pre-commit hooks

Enable the repository hooks once per clone:

```bash
git config core.hooksPath .githooks
```

The hooks check import sorting, Dart formatting, and analysis before a commit.

## Pull requests

Before submitting, confirm that the change has:

- focused tests or analyzer coverage for non-trivial behavior;
- passing formatting, analysis, DCL, test, dependency, and import-sorting
  checks;
- no generated-file edits that should have been produced by a generator;
- a clear description of the problem, solution, and validation.

Use [`.github/workflows/ci.yml`](.github/workflows/ci.yml) for the authoritative
CI gates. Reviewers expect scoped changes, justified analyzer exceptions, and
consistent SDK and dependency versions.

## Larger features

For larger work, start with the relevant material in [`specs/`](specs/). Keep
the specification, implementation, and acceptance checks aligned. Use a
test-first approach where practical, and follow the project's Constitution
principles when a specification defines them.
