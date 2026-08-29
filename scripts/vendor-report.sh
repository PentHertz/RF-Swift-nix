#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"
check_urls=0; [[ ${1:-} == --check-urls ]] && check_urls=1
failed=0
printf '%-24s %-15s %-15s %-8s %s\n' TOOL PINNED UPSTREAM STATUS ARCHITECTURES
while IFS=$'\t' read -r name version url platforms; do
  state="-"; upstream="-"
  if (( check_urls )); then
    urls=()
    while IFS= read -r artifact_url; do urls+=("$artifact_url"); done < <(
      jq -r --arg n "$name" '.[$n].artifacts // {default: {url: .[$n].url}} | .[].url' \
        pkgs/vendor/sources.json
    )
    state=ok
    for artifact_url in "${urls[@]}"; do
      code=$(curl -I -L --retry 2 --connect-timeout 10 --max-time 30 -sS -o /dev/null -w '%{http_code}' \
        "$artifact_url" || true)
      if [[ ! "$code" =~ ^2 ]]; then state="HTTP-$code"; failed=1; break; fi
    done
    probe_url=$(jq -r --arg n "$name" '.[$n].versionProbe.url // empty' pkgs/vendor/sources.json)
    if [[ -n "$probe_url" ]]; then
      pattern=$(jq -r --arg n "$name" '.[$n].versionProbe.pattern' pkgs/vendor/sources.json)
      prefix=$(jq -r --arg n "$name" '.[$n].versionProbe.prefix' pkgs/vendor/sources.json)
      suffix=$(jq -r --arg n "$name" '.[$n].versionProbe.suffix' pkgs/vendor/sources.json)
      probe_type=$(jq -r --arg n "$name" '.[$n].versionProbe.type // "regex"' pkgs/vendor/sources.json)
      if [[ "$probe_type" == githubRelease ]]; then
        match=$(curl -L --retry 2 --connect-timeout 10 --max-time 30 -fsS "$probe_url" 2>/dev/null \
          | jq -r '.tag_name // empty' || true)
      else
        match=$(curl -L --retry 2 --connect-timeout 10 --max-time 30 -fsS "$probe_url" 2>/dev/null \
          | grep -oE "$pattern" | sort -Vu | tail -1 || true)
      fi
      if [[ -n "$match" ]]; then
        upstream=${match#"$prefix"}; upstream=${upstream%"$suffix"}
      else
        upstream="unknown"
      fi
    fi
  fi
  printf '%-24s %-15s %-15s %-8s %s\n' "$name" "$version" "$upstream" "$state" "$platforms"
done < <(jq -r 'to_entries[] | [.key,.value.version,.value.url,(.value.platformPaths|keys|join(","))] | @tsv' \
  pkgs/vendor/sources.json)

(( failed == 0 ))
