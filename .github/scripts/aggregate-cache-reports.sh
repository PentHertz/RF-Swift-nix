#!/usr/bin/env bash
# Aggregate the per-environment result.json files the cache build jobs upload
# into one Markdown report (and the job summary). The report job runs with
# `if: always()` so a failed matrix still gets a table; when NO report was
# uploaded at all (every build job died before its reporting step, or the run
# was cancelled) the download step leaves no directory behind - say so in the
# report instead of failing on `find`, since the build jobs already carry the
# failure status.
set -euo pipefail
root=${1:?report root required}
output=${2:?output path required}
mkdir -p "$root"
mapfile -d '' results < <(find "$root" -name result.json -type f -print0 | sort -z)
{
  echo "# RF Swift Nix v1.0.0-dev architecture report"
  echo
  echo "Generated: $(date -u +%FT%TZ)"
  echo
  if [[ ${#results[@]} -eq 0 ]]; then
    echo "**No per-environment report was uploaded.** Every build job ended before its"
    echo "reporting step (a failure at checkout, Nix installation or cache login, or a"
    echo "cancelled run): see the build jobs' logs."
  else
    ok=0; failed=0
    echo '| Environment | System | Result | Exit |'
    echo '|---|---|---:|---:|'
    for result in "${results[@]}"; do
      jq -r '"| `\(.environment)` | `\(.system)` | **\(.result)** | `\(.exitCode)` |"' "$result"
      if [[ "$(jq -r '.result' "$result")" == "success" ]]; then ok=$((ok+1)); else failed=$((failed+1)); fi
    done
    echo
    echo "${#results[@]} environment(s): $ok succeeded, $failed failed."
  fi
} > "$output"
cat "$output" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
