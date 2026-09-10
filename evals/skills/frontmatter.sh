#!/usr/bin/env bash
# Frontmatter invariants for the gku skills in Antigravity:
#
#   bash evals/skills/frontmatter.sh
#
# Asserts that every skill carries:
# - name: gku-<name> matching directory
# - model: pro or model: flash matching its complexity profile
# - non-empty description without leaked /gku: or .claude/ or CLAUDE.md
# - no Claude-specific directives (user-invocable, disallowed-tools, hooks)
#
# Exits 0 when every skill matches, 1 otherwise.

set -u

root="$(cd "$(dirname "$0")/../.." && pwd)"
skills="$root/skills"

[ -d "$skills" ] || { printf "no skills at %s\n" "$skills" >&2; exit 1; }

PRO_SKILLS="plan audit research review pr-review"
FLASH_SKILLS="implement fix init pr pr-resolve verify"

fails=0
checked=0
note() { printf "FAIL  %s\n" "$1"; fails=$((fails + 1)); }
head_of() { sed -n "2,/^---$/p" "$skills/$1/SKILL.md"; }
has() { head_of "$1" | grep -q "^$2"; }
in_list() { case " $2 " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

for dir in "$skills"/gku-*/; do
  dir_name="$(basename "$dir")"
  s="${dir_name#gku-}"
  [ -f "$dir/SKILL.md" ] || continue
  checked=$((checked + 1))

  has "$dir_name" "name: $dir_name" || note "$dir_name: name must be $dir_name"
  has "$dir_name" "description:"   || note "$dir_name: missing description"

  # Forbidden Claude-only directives
  has "$dir_name" "user-invocable"            && note "$dir_name: contains Claude-only user-invocable"
  has "$dir_name" "disable-model-invocation"  && note "$dir_name: contains Claude-only disable-model-invocation"
  has "$dir_name" "disallowed-tools"          && note "$dir_name: contains Claude-only disallowed-tools"
  has "$dir_name" "hooks:"                    && note "$dir_name: contains Claude-only hooks block"

  # Description cleanliness
  head_of "$dir_name" | grep -q "/gku:" && note "$dir_name: description leaks /gku: syntax"
  head_of "$dir_name" | grep -q "\.claude/" && note "$dir_name: description leaks .claude/ path"
  head_of "$dir_name" | grep -q "CLAUDE\.md" && note "$dir_name: description leaks CLAUDE.md"

  # Model assignment
  if in_list "$s" "$PRO_SKILLS"; then
    has "$dir_name" "model: pro" || note "$dir_name: must have model: pro"
  elif in_list "$s" "$FLASH_SKILLS"; then
    has "$dir_name" "model: flash" || note "$dir_name: must have model: flash"
  else
    note "$dir_name: unrecognized skill $s not in pro or flash list"
  fi
done

if [ "$checked" -eq 0 ]; then
  printf "no SKILL.md found under %s\n" "$skills" >&2
  exit 1
elif [ "$fails" -eq 0 ]; then
  printf "skills: frontmatter invariants hold across %s skills\n" "$checked"
else
  printf "skills: %s frontmatter problem(s)\n" "$fails" >&2
fi
exit $((fails > 0))
