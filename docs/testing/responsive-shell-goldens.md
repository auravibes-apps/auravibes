# Responsive shell and UI goldens

Run fixture-backed UI goldens on Linux x64. CI and the manual `Update Linux UI
goldens` workflow use `ubuntu-26.04`; FVM reads the pinned Flutter version from
`.fvmrc`.

The manual workflow updates app and shared UI tests tagged `golden`, plus
Widgetbook's `test/dashboard_widgets_test.dart`, and uploads PNGs as an
artifact. It has read-only repository permissions and never commits or pushes.
Download and review the artifact before copying baselines into the repository.

On Linux x64, run these commands from the app or shared UI package root to update
and verify its goldens. Wrap local checks with the validation lease:

```sh
python3 "$(git rev-parse --show-toplevel)/tool/validation_lease.py" -- fvm flutter test --no-pub --tags=golden --update-goldens
python3 "$(git rev-parse --show-toplevel)/tool/validation_lease.py" -- fvm flutter test --no-pub --tags=golden
```

For Widgetbook dashboard goldens, run from `widgetbook`:

```sh
python3 "$(git rev-parse --show-toplevel)/tool/validation_lease.py" -- fvm flutter test test/dashboard_widgets_test.dart --no-pub --update-goldens
python3 "$(git rev-parse --show-toplevel)/tool/validation_lease.py" -- fvm flutter test test/dashboard_widgets_test.dart --no-pub
```
