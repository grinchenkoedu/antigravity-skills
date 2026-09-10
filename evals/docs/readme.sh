#!/usr/bin/env bash
# The READMEs against the mechanics, in both languages:
#
#   bash evals/docs/readme.sh
#
# Checks that both README.md and README.uk.md describe the mechanics:
# - gku-guard
# - gku-survey
# - .gku/learned.md
# - Ruling:
# - Modify: path:lines
# - --auto
# - evals/run-all.sh
#
# Exits 0 when both READMEs mention every one, 1 otherwise.

set -u

root="$(cd "$(dirname "$0")/../.." && pwd)"

fails=0
note() { printf "FAIL  %s\n" "$1"; fails=$((fails + 1)); }

for doc in README.md README.uk.md; do
  f="$root/$doc"
  [ -f "$f" ] || { note "$doc: missing"; continue; }
  for token in \
    "gku-guard|PreToolUse|hooks.json" \
    "gku-survey" \
    "\.gku/learned\.md" \
    "Ruling:" \
    "Modify: path:lines" \
    "--auto" \
    "evals/run-all\.sh"
  do
    grep -qE -- "$token" "$f" || note "$doc: never mentions ${token%%|*}"
  done
done

if [ "$fails" -eq 0 ]; then
  printf "readme: both languages describe the mechanics the skills rely on\n"
else
  printf "readme: %s gap(s)\n" "$fails" >&2
fi
exit $((fails > 0))
