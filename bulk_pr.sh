#!/usr/bin/env bash
set -euo pipefail

# CONFIG
BASE_BRANCH="main"
TOTAL_BRANCHES=100
CLOSE_RELEASED=40
CLOSE_PREVIOUS=20

echo "🔹 Step 1: Creating and pushing $TOTAL_BRANCHES branches..."
for i in $(seq 1 $TOTAL_BRANCHES); do
  branch="test_branch_$i"
  git checkout -b "$branch" "$BASE_BRANCH"
  git push origin "$branch"
done

echo "🔹 Step 2: Creating PRs for all branches..."
for i in $(seq 1 $TOTAL_BRANCHES); do
  branch="test_branch_$i"
  gh pr create --base "$BASE_BRANCH" --head "$branch" \
    --title "PR for $branch" \
    --body "Auto-generated PR for $branch"
done

echo "🔹 Step 3: Closing $CLOSE_RELEASED random PRs with label 'released'..."
prs=$(gh pr list --state open --json number --jq '.[].number')
to_close=$(echo "$prs" | shuf | head -n $CLOSE_RELEASED)
for pr in $to_close; do
  gh pr close "$pr"
  gh pr edit "$pr" --add-label "released"
done

echo "🔹 Step 4: Closing $CLOSE_PREVIOUS random PRs with label 'previous_release'..."
prs=$(gh pr list --state open --json number --jq '.[].number')
to_close=$(echo "$prs" | shuf | head -n $CLOSE_PREVIOUS)
for pr in $to_close; do
  gh pr close "$pr"
  gh pr edit "$pr" --add-label "previous_release"
done

echo "✅ All tasks completed!"
