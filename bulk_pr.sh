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
  if git show-ref --verify --quiet "refs/heads/$branch"; then
    echo "⚠️ Branch $branch already exists locally, skipping creation."
  else
    git checkout -b "$branch" "$BASE_BRANCH"
    git push origin "$branch"
  fi
done

echo "🔹 Step 2: Creating PRs for all branches..."
for i in $(seq 1 $TOTAL_BRANCHES); do
  branch="test_branch_$i"
  git checkout "$branch"
  # Add a dummy file only if it doesn't already exist
  file="$branch.txt"
  if [ ! -f "$file" ]; then
    echo "Dummy content for $branch" > "$file"
    git add "$file"
    git commit -m "Add dummy file for $branch"
    git push origin "$branch"
  fi

  # Try to create PR only if one doesn’t already exist
  if ! gh pr list --head "$branch" --json number --jq '.[].number' | grep -q .; then
    gh pr create --base "$BASE_BRANCH" --head "$branch" \
      --title "PR for $branch" \
      --body "Auto-generated PR for $branch"
  else
    echo "⚠️ PR for $branch already exists, skipping."
  fi
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
