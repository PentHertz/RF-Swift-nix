#!/usr/bin/env bash
set -euo pipefail
root=${1:?report root required}
output=${2:?output path required}
{
  echo "# RF Swift Nix v1.0.0-dev architecture report"
  echo
  echo "Generated: $(date -u +%FT%TZ)"
  echo
  echo '| Environment | System | Result | Exit |'
  echo '|---|---|---:|---:|'
  find "$root" -name result.json -type f -print0 | sort -z | while IFS= read -r -d '' result; do
    jq -r '"| `\(.environment)` | `\(.system)` | **\(.result)** | `\(.exitCode)` |"' "$result"
  done
} > "$output"
cat "$output" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
