#!/usr/bin/env bash
# Sets the "Lead approval" commit status for one PR.  Usage: lead-approval.sh <pr-number>
#   REPO             review repo; gh needs a token with statuses: write (GH_TOKEN in CI)
#   TEAMS_FILE       teams.yml from the base branch (default .github/teams.yml)
#   DRY_RUN=1        print the decision without writing a status
#
# The PR's team is its fork's org (head repo owner), looked up in TEAMS_FILE. Green when a lead of
# that team has approved (latest non-comment review), red with instructions otherwise.
# Same-repo PRs, bot PRs, reviewers' PRs and the `lead-verified` label pass. A lead's own PR needs another lead;
# a team's only lead is waived (Zedu review still applies). Only writes the status when it changes,
# since GitHub caps statuses per commit and context.
set -euo pipefail

pr=$1
[[ "$pr" =~ ^[0-9]+$ ]] || { echo "Invalid PR number: $pr" >&2; exit 1; }
: "${REPO:?}"
TEAMS_FILE=${TEAMS_FILE:-.github/teams.yml}
CONTEXT="Lead approval"
here=$(cd "$(dirname "$0")" && pwd)

info=$(gh api "repos/$REPO/pulls/$pr")
sha=$(jq -r .head.sha <<< "$info")
author=$(jq -r .user.login <<< "$info")
head_repo=$(jq -r '.head.repo.full_name // ""' <<< "$info")
org=${head_repo%%/*}
verified=$(jq -r '[.labels[].name] | index("lead-verified") != null' <<< "$info")

decide() {
  if [ "$head_repo" = "$REPO" ]; then
    echo "success|Same-repo PR; lead approval not required"; return
  fi
  case "$author" in
    *"[bot]") echo "success|Bot PR; lead approval not required"; return ;;
  esac
  # Reviewers (write access to the review repo) open setup PRs from personal forks.
  case "$(gh api "repos/$REPO/collaborators/$author/permission" --jq .permission 2>/dev/null || echo none)" in
    admin|maintain|write) echo "success|Reviewer PR; lead approval not required"; return ;;
  esac
  if [ "$verified" = true ]; then
    echo "success|Lead approval verified by a reviewer (lead-verified label)"; return
  fi
  if [ -z "$head_repo" ]; then
    echo "failure|Fork was deleted; reopen this PR from your team's org fork"; return
  fi

  local team leads
  team=$(ruby "$here/team-of.rb" "$TEAMS_FILE" "$org")
  if [ "$(jq -r '.team // ""' <<< "$team")" = "" ]; then
    if [ "${org,,}" = "${author,,}" ]; then
      echo "failure|Personal fork. Open this PR from your team's org fork, not $org/"; return
    fi
    echo "failure|Fork org $org isn't registered. Ask a reviewer to add it to .github/teams.yml"; return
  fi

  # Leads other than the author; a team's only lead opening their own PR is waived.
  leads=$(jq -r --arg a "${author,,}" '.leads[] | select(ascii_downcase != $a)' <<< "$team")
  if [ -z "$leads" ]; then
    if jq -e --arg a "${author,,}" '.leads | map(ascii_downcase) | index($a) != null' <<< "$team" >/dev/null; then
      echo "success|Team's only lead opened this PR; Zedu review applies"; return
    fi
    echo "failure|Team $(jq -r .team <<< "$team") has no leads in .github/teams.yml"; return
  fi

  local approved hit
  # gh can't combine --slurp with --jq, so pipe the pages into jq.
  approved=$(gh api --paginate --slurp "repos/$REPO/pulls/$pr/reviews?per_page=100" | jq -r \
    'flatten | map(select(.state != "COMMENTED" and .state != "PENDING")) | group_by(.user.login | ascii_downcase)
          | map(last) | map(select(.state == "APPROVED")) | .[].user.login | ascii_downcase')
  hit=$(grep -Fxi -f <(printf '%s\n' "$leads") <<< "$approved" | head -1 || true)
  if [ -n "$hit" ]; then
    echo "success|Approved by team lead @$hit"
  else
    echo "failure|Waiting for a team lead to approve: @${leads//$'\n'/ @}"
  fi
}

result=$(decide)
state=${result%%|*}
description=${result#*|}
description=${description:0:140}

if [ -n "${DRY_RUN:-}" ]; then
  echo "PR #$pr: would set $state: $description"
  exit 0
fi

current=$(gh api "repos/$REPO/commits/$sha/status" 2>/dev/null \
  | jq -r --arg c "$CONTEXT" '[.statuses[] | select(.context == $c)][0] // empty | "\(.state)|\(.description)"' || true)
if [ "$current" = "$state|$description" ]; then
  echo "PR #$pr: unchanged ($state: $description)"
  exit 0
fi
gh api "repos/$REPO/statuses/$sha" -f state="$state" -f context="$CONTEXT" -f description="$description" >/dev/null
echo "PR #$pr: $state: $description"
