#!/usr/bin/env bash
# Reuse the newest usable main timing artifact without weakening test selection.
set -euo pipefail

manifest="$1"
plan_dir="$2"
mkdir -p "$plan_dir"
lookup_log="$plan_dir/timing-lookup.txt"
: > "$lookup_log"

log() {
  printf '%s\n' "$*" | tee -a "$lookup_log"
}

matrix_args=(
  matrix --manifest "$manifest"
  --shard-package apps/auravibes_app --shard-count 3
)
matrix="$(dart tool/changed_test_selector.dart "${matrix_args[@]}")"
timing_source="not needed (no app tests)"

if jq -e '.include | any(.package == "apps/auravibes_app")' <<< "$matrix" > /dev/null; then
  timing_source="fixed shard fallback"
  download_dir="$(mktemp -d)"
  trap 'rm -rf "$download_dir"' EXIT
  timings="$download_dir/test_timings.json"

  # The timing upload already requires successful tests; unrelated jobs need
  # not finish or pass before their timing artifact becomes useful.
  if ! run_ids="$(gh run list --repo "$GITHUB_REPOSITORY" \
    --workflow ci.yml --branch main --limit 20 \
    --json databaseId --jq '.[].databaseId')"; then
    log 'Could not list main runs; historical timings unavailable.'
    run_ids=""
  fi

  while IFS= read -r run_id; do
    [ -n "$run_id" ] || continue
    if ! artifact_id="$(gh api \
      "repos/${GITHUB_REPOSITORY}/actions/runs/${run_id}/artifacts?name=test-timings" \
      --jq '[.artifacts[] | select(.expired == false) | .id][0] // empty')"; then
      log "Main run $run_id: artifact lookup failed."
      continue
    fi
    if [ -z "$artifact_id" ]; then
      log "Main run $run_id: no unexpired test-timings artifact."
      continue
    fi
    if ! gh api "repos/${GITHUB_REPOSITORY}/actions/artifacts/${artifact_id}/zip" \
      > "$download_dir/timings.zip"; then
      log "Main run $run_id, artifact $artifact_id: download failed."
      continue
    fi
    if ! unzip -p "$download_dir/timings.zip" test_timings.json > "$timings" \
      || [ ! -s "$timings" ]; then
      log "Main run $run_id, artifact $artifact_id: missing or unreadable test_timings.json."
      continue
    fi
    planner_status=0
    candidate="$(dart tool/changed_test_selector.dart "${matrix_args[@]}" --timings "$timings" \
      2> "$download_dir/planner.log")" || planner_status=$?
    tee -a "$lookup_log" < "$download_dir/planner.log" >&2
    if [ "$planner_status" -ne 0 ]; then
      log "Main run $run_id, artifact $artifact_id: shard planner failed."
      continue
    fi
    if ! jq -e '.include | any(.package == "apps/auravibes_app" and .shardMode == "timed")' \
      <<< "$candidate" > /dev/null; then
      log "Main run $run_id, artifact $artifact_id: planner rejected timings (invalid, stale, or missing app samples)."
      continue
    fi
    matrix="$candidate"
    timing_source="main run $run_id"
    log "Using test timings from main run $run_id, artifact $artifact_id."
    break
  done <<< "$run_ids"

  if [ "$timing_source" = 'fixed shard fallback' ]; then
    log '::warning::No usable historical test timing artifact found; using fixed shards. See test-plan/timing-lookup.txt.'
  fi
else
  log 'No app tests selected; historical timing lookup skipped.'
fi

printf '%s\n' "$matrix" > "$plan_dir/matrix.json"
printf '%s\n' "$timing_source" > "$plan_dir/timing-source.txt"
