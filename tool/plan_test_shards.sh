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
timing_source="not needed (no app tests)"
lookup_duration_ms=0
main_runs_examined=0
artifact_list_requests=0
artifact_download_requests=0

if jq -e '
  if .mode == "full" then
    true
  else
    (.packages // {}) | has("apps/auravibes_app")
  end
' "$manifest" > /dev/null; then
  timing_source="fixed shard fallback"
  download_dir="$(mktemp -d)"
  trap 'rm -rf "$download_dir"' EXIT
  timings="$download_dir/test_timings.json"
  lookup_started_ms="$(date +%s%3N)"

  # Only successful full test runs on main upload this artifact. One repository
  # listing avoids per-run metadata requests; validate at most 20 unique runs.
  artifact_candidates=""
  artifact_list_requests=$((artifact_list_requests + 1))
  if ! artifact_candidates="$(gh api \
    "repos/${GITHUB_REPOSITORY}/actions/artifacts?name=test-timings&per_page=100" \
    --jq '[.artifacts[]
      | select(.expired == false and .workflow_run.head_branch == "main")
      | {run_id: .workflow_run.id, artifact_id: .id, created_at: .created_at}]
      | group_by(.run_id)
      | map(max_by(.created_at))
      | sort_by(.created_at)
      | reverse
      | .[:20][]
      | "\(.run_id)\t\(.artifact_id)"')"; then
    log 'Could not list main timing artifacts; historical timings unavailable.'
    artifact_candidates=""
  fi

  while IFS=$'\t' read -r run_id artifact_id; do
    [ -n "$artifact_id" ] || continue
    main_runs_examined=$((main_runs_examined + 1))
    artifact_download_requests=$((artifact_download_requests + 1))
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
  done <<< "$artifact_candidates"

  lookup_duration_ms=$(( $(date +%s%3N) - lookup_started_ms ))
  if [ "$timing_source" = 'fixed shard fallback' ]; then
    log '::warning::No usable historical test timing artifact found; using fixed shards. See test-plan/timing-lookup.txt.'
    matrix="$(dart tool/changed_test_selector.dart "${matrix_args[@]}")"
  fi
else
  log 'No app tests selected; historical timing lookup skipped.'
  matrix="$(dart tool/changed_test_selector.dart "${matrix_args[@]}")"
fi

log "Lookup metrics: duration_ms=$lookup_duration_ms main_runs_examined=$main_runs_examined artifact_list_requests=$artifact_list_requests artifact_download_requests=$artifact_download_requests"
printf '%s\n' "$matrix" > "$plan_dir/matrix.json"
printf '%s\n' "$timing_source" > "$plan_dir/timing-source.txt"
