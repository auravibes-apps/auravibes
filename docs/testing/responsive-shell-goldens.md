# Responsive shell and UI goldens

Run fixture-backed UI goldens on Linux x64. CI and the manual `Update Linux UI
goldens` workflow use `ubuntu-26.04`; FVM reads the pinned Flutter version from
`.fvmrc` (`3.47.7` at this revision).

The manual workflow updates only tests tagged `golden` and uploads PNGs as an
artifact. It has read-only repository permissions and never commits or pushes.
Download and review the artifact before copying baselines into the repository.

On Linux x64, run these commands from each package root to update and verify its
goldens. Wrap local checks with the validation lease:

```sh
python3 "$(git rev-parse --show-toplevel)/tool/validation_lease.py" -- fvm flutter test --no-pub --tags=golden --update-goldens
python3 "$(git rev-parse --show-toplevel)/tool/validation_lease.py" -- fvm flutter test --no-pub --tags=golden
```
