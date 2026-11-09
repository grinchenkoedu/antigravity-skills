#!/usr/bin/env bash
# The developer's language, asserted: run it from anywhere.
#
#   bash evals/skills/language.sh
#
# A run speaks the language the developer wrote in, from the plan to the pull
# request, and Ukrainian wins when Ukrainian and Russian are mixed. That rule
# lives once, in gku-reference/language.md, and every skill points at it — the old
# state was nine copies of "English or Ukrainian" in nine wordings, two skills
# with none, and an English-only rule on commits and titles that contradicted
# the rest.
#
# The choice crosses sessions through one header line, `**Language:**`, in every
# task file: /gku-implement and /gku-pr usually start with a bare path and no
# prose to judge by. And the structure other skills grep for stays English, or
# a translated `Modify:` breaks file-lists.sh and the review that reads it.
#
# Exits 0 when it holds, 1 otherwise.

set -u

root="$(cd "$(dirname "$0")/../.." && pwd)"
skills="$root/skills"
lang_md="$root/gku-reference/language.md"
[ -d "$skills" ] || { printf 'no skills under %s\n' "$skills" >&2; exit 1; }

fails=0
note() { printf 'FAIL  %s\n' "$1"; fails=$((fails + 1)); }
# Prose wraps at the file's width and the phrases wear backticks and bold —
# flatten and undress before matching, as manual.sh does.
flat() { tr '\n' ' ' < "$1" | tr -d '`*' | tr -s ' '; }
has() { printf '%s' "$1" | grep -qF -e "$2"; }

# --- the rule itself ---------------------------------------------------------

if [ -f "$lang_md" ]; then
  langf="$(flat "$lang_md")"
  lines="$(wc -l < "$lang_md" | tr -d ' ')"
  [ "$lines" -le 40 ] || note "language.md is $lines lines; every skill points at it, so keep it under 40"
  has "$langf" 'Ukrainian over Russian' || note 'language.md: mixed Ukrainian and Russian no longer resolves to Ukrainian'
  has "$langf" 'і ї є ґ' || note 'language.md: no telltale Ukrainian letters, so the mix cannot be told apart'
  has "$langf" 'ы э ё ъ' || note 'language.md: no telltale Russian letters, so the mix cannot be told apart'
  has "$langf" 'Structure stays English' || note 'language.md: nothing keeps the structure other skills grep in English'
  for token in 'Modify:' 'Ruling:' 'Mode: manual' '[answered]' 'BLOCKER' 'Ready'; do
    has "$langf" "$token" || note "language.md: $token is not listed as structure that stays English"
  done
  has "$langf" 'tools and evals read that word' \
    || note 'language.md: does not say why the verdict label stays English'
  has "$langf" 'commit subjects and bodies' || note 'language.md: commits are not said to follow the language'
  has "$langf" 'pull request titles' || note 'language.md: pull request titles are not said to follow the language'
  has "$langf" 'keeps its form, not its language' \
    || note "language.md: a repository's English titles would override the developer's language"
  has "$langf" 'Language: <ISO 639-1 code>' || note 'language.md: no header line carries the choice to a later session'
else
  note 'no gku-reference/language.md'
fi

# --- every skill points at it, and none keeps an old rule --------------------

for f in "$skills"/gku-*/SKILL.md; do
  s="$(basename "$(dirname "$f")")"
  sf="$(flat "$f")"
  has "$sf" 'gku-reference/language.md' || note "$s: never points at gku-reference/language.md"
  # Inline as well: nothing tells a skill to open language.md, so the one
  # exception the rule exists for has to be in the pointer itself.
  has "$sf" 'Ukrainian over Russian' || note "$s: the pointer drops Ukrainian over Russian"
  for old in 'English or Ukrainian' 'commit messages in English' 'messages and titles in English'; do
    printf '%s' "$sf" | grep -qiF -e "$old" && note "$s: still says \"$old\""
  done
done

# --- the header that carries it across sessions ------------------------------

# Step 6 and --manual each have a template, in SKILL.md and manual.md; check
# both, or one could lose its line while the other keeps the check green.
for f in SKILL.md manual.md; do
  grep -q '^\*\*Language:\*\*' "$skills/gku-plan/$f" || note "plan: the task-file template in $f has no **Language:** line"
done
for s in research audit; do
  grep -q '^\*\*Language:\*\*' "$skills/gku-$s/SKILL.md" || note "gku-$s: its task-file template has no **Language:** line"
done
for s in implement pr; do
  has "$(flat "$skills/gku-$s/SKILL.md")" 'Language: line' \
    || note "gku-$s: never reads the task file's **Language:** line, so a bare path runs in English"
done
has "$(flat "$skills/gku-pr/SKILL.md")" 'their format, not their language' \
  || note 'pr: copies the language of recent titles along with their format'

# --- the one word tools and evals read ---------------------------------------

revf="$(flat "$skills/gku-review/SKILL.md")"
has "$revf" 'Its label stays English in every language' \
  || note 'review: step 6 lets a translated verdict hide its English label'
has "$revf" '2 BLOCKERS — спочатку' \
  || note 'review: step 6 shows no verdict in another language with the English label'

if [ "$fails" -eq 0 ]; then
  printf "language: one rule, every skill points at it, and the task file carries it\n"
else
  printf 'language: %s problem(s)\n' "$fails" >&2
fi
exit $((fails > 0))
