# Bootstrap Guidance and Smoke Cases

## Goal

Make the README and contributor setup instructions reproduce the repository's
pinned Flutter workspace setup, correct stale toolchain and platform claims,
and add repeatable agent scenarios for the decisions that caused setup advice
to drift.

## Verified repository facts

- `.fvmrc` pins Flutter and sets `runPubGetOnSdkChanges` to `true`.
- Root `pubspec.yaml` declares the Dart SDK constraint, a Dart Pub workspace,
  and the Melos dependency.
- FVM `4.3.1` exposes `--skip-pub-get`; its current documentation says `fvm use`
  runs `flutter pub get` unless skipped.
- A local `fvm dart run melos bootstrap` run bootstrapped six workspace
  packages and generated ignored IntelliJ `.iml` files.
- CI's `setup-workspace` action runs Melos bootstrap. The integrity job then
  checks for tracked or untracked dependency artifact drift.
- The app has Android, iOS, macOS, Web, Windows, and Linux targets. Chat
  attachment controls are disabled on Web, and the Web attachment service
  reports unsupported file operations. Open issue [#1063](https://github.com/auravibes-apps/auravibes/issues/1063)
  tracks that support.
- README references missing screenshot files, a `#` demo target, and a missing
  architecture guide. Existing architecture docs live under `doc/architecture/`.

## Design

Use FVM-pinned commands throughout setup docs. Explain that `fvm use` selects
the SDK from `.fvmrc` and performs Pub resolution by default when the SDK
changes; `fvm dart run melos bootstrap` remains the explicit workspace step
used by CI. Describe available platform targets while naming the Web chat
attachment limitation and its follow-up issue. Remove README references whose
targets do not exist; do not create screenshot assets.

Update root agent guidance and the Melos skill to match the root package's
current Melos constraint and repository CI behavior. Add three semantic
scenarios using the existing skill `evals.json` convention: formatter usage,
FVM Pub-get behavior, and the role of Melos bootstrap. Expected outcomes
describe behavior rather than fixed phrases.

## Boundaries

- Do not change app behavior, CI workflows, or dependency configuration.
- Do not generate screenshots or implement Web attachments.
- Keep #1063 open and do not touch #868 or #947.
- Use root `pubspec.yaml`, `.fvmrc`, and CI as sources of truth.

## Acceptance

- README toolchain claims match `.fvmrc` and root `pubspec.yaml`.
- README feature/platform claims include the Web attachment limitation and
  link to #1063; invalid local or placeholder targets are removed or fixed.
- README and CONTRIBUTING document the same pinned fresh-checkout commands
  and distinguish FVM SDK/Pub setup from Melos bootstrap.
- Root agent guidance, Melos specialist guidance, and smoke cases agree with
  current configuration and CI.
- Smoke cases document expected behavior for all three decisions without
  brittle exact-phrase checks.
