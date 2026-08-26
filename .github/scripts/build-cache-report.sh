#!/usr/bin/env bash
set -uo pipefail

system=${1:?usage: build-cache-report.sh <nix-system> <environment> <report-dir>}
environment=${2:?missing environment}
report_dir=${3:?missing report directory}
mkdir -p "$report_dir"
log="$report_dir/build.log"
summary="$report_dir/summary.md"
json="$report_dir/result.json"
started=$(date -u +%FT%TZ)
attr=".#packages.${system}.${environment}"

set +e
nix build "$attr" --no-link --print-build-logs --keep-going 2>&1 | tee "$log"
status=${PIPESTATUS[0]}
set -e
finished=$(date -u +%FT%TZ)

if [ "$status" -eq 0 ]; then result=success; else result=failure; fi
jq -n \
  --arg system "$system" --arg environment "$environment" \
  --arg attribute "$attr" --arg result "$result" \
  --arg started "$started" --arg finished "$finished" \
  --argjson exitCode "$status" \
  '{system:$system,environment:$environment,attribute:$attribute,result:$result,exitCode:$exitCode,started:$started,finished:$finished}' > "$json"

{
  echo "# RF Swift Nix cache build"
  echo
  echo "- Version: \`v1.0.0-dev\`"
  echo "- System: \`$system\`"
  echo "- Environment: \`$environment\`"
  echo "- Result: **$result**"
  echo "- Exit code: \`$status\`"
  echo "- Started: \`$started\`"
  echo "- Finished: \`$finished\`"
  if [ "$status" -ne 0 ]; then
    echo
    echo "## Relevant diagnostics"
    echo
    echo '```text'
    grep -E 'error:|failed|hash mismatch|unsupported|not available|no space|disk.*full|Cannot build' "$log" | tail -80 || tail -80 "$log"
    echo '```'
  fi
} > "$summary"

cat "$summary" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
exit "$status"
