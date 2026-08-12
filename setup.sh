#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

for repo in bet-api bet-client; do
  if [ -d "$repo/.git" ]; then
    echo "skip $repo (already cloned)"
  else
    git clone "https://github.com/myungjaeyu/$repo.git"
  fi
done
