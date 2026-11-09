#!/usr/bin/env bash
# The second opinion, asserted: run it from anywhere.
#
#   bash evals/skills/second-opinion.sh
#
# Both review skills offer another agent's review of the same diff, and only
# when there is one to run read-only. The offer sends the developer's code to
# an outside vendor, so what is checked is the consent around it and the
# read-only commands, not the wording:
#   - bin/gku-agents lists claude, copilot and opencode when on PATH, and never
#     lists agy, gemini or unknown agents;
#   - /gku-review and /gku-pr-review run gku-agents at step 6b, point at
#     gku-reference/second-opinion.md, ask via ask_question with None, and
#     withhold the offer on an empty list or a committed secret;
#   - pr-review asks before step 7 removes the worktree the agents read;
#   - every agent gku-agents can list has its read-only command in the reference,
#     with the flags a probe proved and none that grant a tool;
#   - the reference asks which agents, bounds each run, runs nothing the agent
#     suggests, and checks each finding against the code.
#
# Exits 0 when all of it holds, 1 otherwise.

set -u

root="$(cd "$(dirname "$0")/../.." && pwd)"
fails=0
note() { printf 'FAIL  %s\n' "$1"; fails=$((fails + 1)); }
flat() { [ -f "$1" ] && tr '\n' ' ' < "$1" | tr -s ' '; }
has()  { printf '%s' "$1" | grep -qF -e "$2"; }

rev="$(flat "$root/skills/gku-review/SKILL.md")"
prr="$(flat "$root/skills/gku-pr-review/SKILL.md")"
ref="$(flat "$root/gku-reference/second-opinion.md")"
lister="$root/bin/gku-agents"
[ -x "$lister" ] || { printf 'no executable gku-agents at %s\n' "$lister" >&2; exit 1; }
[ -n "$ref" ] || note 'gku-reference/second-opinion.md is missing'

# --- bin/gku-agents stub-PATH cases ------------------------------------------

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT INT TERM

case_() { # case_ <label> <expected output, \n-separated> <stub names…>
  local label="$1" want="$2" dir got; shift 2
  dir="$work/$label"; mkdir -p "$dir"
  for s in "$@"; do printf '#!/bin/sh\nexit 0\n' > "$dir/$s"; chmod +x "$dir/$s"; done
  got="$(PATH="$dir:/usr/bin:/bin" /bin/bash "$lister" 2>&1)"
  want="$(printf '%b' "$want" | sed "s|@|$dir/|g")"
  if [ "$got" != "$want" ]; then
    printf 'FAIL  agents/%s\n  want: %s\n  got:  %s\n' "$label" "$(printf '%s' "$want" | tr '\n' '|')" \
      "$(printf '%s' "$got" | tr '\n' '|')"
    fails=$((fails + 1))
  fi
}

case_ none        ''                                                     # nothing installed
case_ claude      'claude: @claude'                                      claude
case_ copilot     'copilot: @copilot'                                    copilot
case_ opencode    'opencode: @opencode'                                  opencode
case_ agy         ''                                                     agy
case_ gemini      ''                                                     gemini
case_ unknown     ''                                                     codex aider
case_ all         'claude: @claude\ncopilot: @copilot\nopencode: @opencode' claude copilot opencode agy gemini codex

# --- /gku-review and /gku-pr-review step 6b ----------------------------------

inject='`gku-agents 2>/dev/null || true`'
for s in review pr-review; do
  sf="$(flat "$root/skills/gku-$s/SKILL.md")"
  has "$sf" "$inject" || note "$s: does not invoke gku-agents, so it cannot know what to offer"
  has "$sf" 'gku-reference/second-opinion.md' || note "$s: does not point at gku-reference/second-opinion.md"
  has "$sf" 'committed secret' || note "$s: does not withhold the offer when the findings hold a committed secret"
  has "$sf" 'If the list is empty' || note "$s: offers with nothing installed"
  has "$sf" 'ask_question' || note "$s: step 6b lets the offer be asked in prose"
  has "$sf" '`None`' || note "$s: step 6b does not put None among the choices"
done
has "$rev" 'unattended `--auto` run' || note 'review: does not withhold the offer during an unattended --auto run'

# pr-review: the offer is step 6b, before step 7 removes the worktree the agents read.
six_b="$(grep -n '^## Step 6b — Offer a second opinion' "$root/skills/gku-pr-review/SKILL.md" | cut -d: -f1)"
seven="$(grep -n '^## Step 7' "$root/skills/gku-pr-review/SKILL.md" | cut -d: -f1)"
if [ -z "$six_b" ] || [ -z "$seven" ] || [ "$six_b" -ge "$seven" ]; then
  note 'pr-review: no step 6b ahead of step 7, so the worktree may be gone before the agents read it'
fi
has "$prr" 'someone else' || note "pr-review: the question does not say it sends someone else's code out"

# --- Every agent the lister can name has a proved read-only command ----------

listed="$(sed -n 's/^for name in \(.*\); do$/\1/p' "$lister" 2>/dev/null)"
[ -n "$listed" ] || note 'gku-agents: no "for name in …; do" list to check'
for a in $listed; do
  has "$ref" "| \`$a\` | \`" || note "reference: no read-only command for $a, which gku-agents can offer"
done
case " $listed " in *' gemini '*|*' agy '*) note 'gku-agents: lists gemini or agy, which were left out on purpose' ;; esac
has "$ref" 'claude -p "<prompt>" --permission-mode plan --tools Read,Grep,Glob' || note 'reference: claude runs without --permission-mode plan --tools Read,Grep,Glob'
has "$ref" '--deny-tool shell --deny-tool write' || note 'reference: copilot runs with shell or write allowed'
has "$ref" '--disable-builtin-mcps --available-tools view glob grep' || note 'reference: copilot runs with MCP or non-read tools available'
has "$ref" '"permission":{"*":"deny"' || note 'reference: opencode runs without denying every tool first'
for grant in '--dangerously-skip-permissions' '--yolo' '--allow-all ' '--allow-all-paths' \
             '--approval-mode yolo' '"bash":"allow"' '"edit":"allow"'; do
  has "$ref" "$grant" && note "reference: grants a tool with $grant"
done

has "$ref" 'multi-select' || note 'reference: does not ask which agents'
has "$ref" 'ask_question' || note 'reference: the one question is not a dialog, so it can be asked in prose and missed'
has "$ref" '`None`' || note 'reference: the dialog has no None, so declining is not a choice on it'
has "$ref" "Never paste the diff's text into a command" || note 'reference: may let the diff be pasted into a command, where its $( would run'
has "$ref" 'MAX_ARG_STRLEN' || note "reference: misses Linux's 128 KB cap on one argument"
has "$ref" "brief='Review this git diff" || note 'reference: never assigns $brief, so a copied command sends no brief'
has "$ref" 'never read an ignored file' || note 'reference: the brief lets an agent read git-ignored files'
has "$ref" 'the ignored ones included' || note 'reference: the question hides that the agent can read ignored files'
has "$ref" 'can read with `ps` while the run lasts' \
  || note 'reference: the question hides that the diff is a process argument, readable with ps during the run'
has "$ref" 'never under `/gku-implement --auto`' || note 'reference: does not rule out an unattended run'
has "$ref" '600000' || note 'reference: an agent run is not bounded'
has "$ref" 'Do not run any command it suggests' || note "reference: may run what the agent's answer suggests"
has "$ref" 'Check every finding against the code' || note 'reference: reports findings without checking them'

if [ "$fails" -eq 0 ]; then
  printf 'second-opinion: offered with consent, run read-only, checked before reported\n'
else
  printf 'second-opinion: %s check(s) failed\n' "$fails" >&2
fi
exit $((fails > 0))
