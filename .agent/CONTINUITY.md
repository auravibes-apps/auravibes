# CONTINUITY.md

## [PLANS]
- Optimize build_runner code generation performance via `build.yaml` scoping

## [DECISIONS]
- 2026-04-05 [CODE] Scoped each generator (freezed, riverpod, json_serializable, drift_dev, go_router_builder) to only relevant source directories via `build.yaml`
- 2026-04-05 [CODE] Fixed builder name `drift_dev:not_connecting` → `drift_dev` (the `not_connecting` variant doesn't exist as a builder key)
- 2026-04-05 [CODE] Updated AGENTS.md with practical `--build-filter` examples matching real project paths

## [DISCOVERIES]
- 2026-04-05 [TOOL] **build.yaml scoping benchmark** (full build, after cache clear):
  - drift_dev inputs: 1064 → 116 (-89%)
  - source_gen inputs: 532 → 295 (-45%)
  - mockito inputs: 132 → 66 (-50%)
  - Total outputs written: 531 → 103 (-81%)
  - Wall time: 29.97s → 23.47s (-22%)
  - The biggest win was drift_dev scoping — it was previously scanning the entire `lib/` tree

## [PROGRESS]
- 2026-04-05 Created `apps/auravibes_app/build.yaml` with generator scoping
- 2026-04-05 Updated AGENTS.md with build.yaml docs and --build-filter examples

## [OUTCOMES]
- Build time reduced ~22% for full builds; incremental builds benefit even more from reduced input scanning
