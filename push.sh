#!/bin/bash
set -e
REPO="eheimbuch/own_your_stats"
BRANCH="main"
TOKEN=$(gh auth token)
AUTH="Authorization: token $TOKEN"

api() {
  local method=$1 path=$2 data=$3
  if [ -n "$data" ]; then
    curl -s -H "$AUTH" -H "Content-Type: application/json" -X "$method" -d "$data" "https://api.github.com$path"
  else
    curl -s -H "$AUTH" -X "$method" "https://api.github.com$path"
  fi
}

# Get current HEAD
echo "=== Getting current ref ==="
REF=$(api GET "/repos/$REPO/git/refs/heads/$BRANCH")
CURRENT_SHA=$(echo "$REF" | python3 -c "import sys,json; print(json.load(sys.stdin)['object']['sha'])")
echo "HEAD: ${CURRENT_SHA:0:7}"

# Get base tree
COMMIT=$(api GET "/repos/$REPO/git/commits/$CURRENT_SHA")
BASE_TREE=$(echo "$COMMIT" | python3 -c "import sys,json; print(json.load(sys.stdin)['tree']['sha'])")
echo "Base tree: ${BASE_TREE:0:7}"

# Collect files
FILES=$(cd /root/own_your_stats && find . -not -path './.git/*' -not -path './node_modules/*' -not -path './dist/*' -type f | sed 's|^\./||' | sort)
echo "Files to upload:"
echo "$FILES"

# Create blobs and tree entries
TREE_ENTRIES="["
FIRST=true
while IFS= read -r fp; do
  [ -z "$fp" ] && continue
  CONTENT=$(base64 -w0 < "/root/own_your_stats/$fp")
  BLOB=$(api POST "/repos/$REPO/git/blobs" "{\"content\":\"$CONTENT\",\"encoding\":\"base64\"}")
  SHA=$(echo "$BLOB" | python3 -c "import sys,json; print(json.load(sys.stdin)['sha'])")
  if [ "$FIRST" = true ]; then FIRST=false; else TREE_ENTRIES+=","; fi
  TREE_ENTRIES+="{\"path\":\"$fp\",\"mode\":\"100644\",\"type\":\"blob\",\"sha\":\"$SHA\"}"
  echo "  $fp ($SHA)"
done <<< "$FILES"
TREE_ENTRIES+="]"

# Create tree
echo "=== Creating tree ==="
TREE=$(api POST "/repos/$REPO/git/trees" "{\"base_tree\":\"$BASE_TREE\",\"tree\":$TREE_ENTRIES}")
NEW_TREE=$(echo "$TREE" | python3 -c "import sys,json; print(json.load(sys.stdin)['sha'])")
echo "New tree: ${NEW_TREE:0:7}"

# Create commit
echo "=== Creating commit ==="
NEW_COMMIT=$(api POST "/repos/$REPO/git/commits" "{\"message\":\"Initial release: offline-first Skill-Datenbank\",\"tree\":\"$NEW_TREE\",\"parents\":[\"$CURRENT_SHA\"]}")
COMMIT_SHA=$(echo "$NEW_COMMIT" | python3 -c "import sys,json; print(json.load(sys.stdin)['sha'])")
echo "Commit: ${COMMIT_SHA:0:7}"

# Update ref
echo "=== Updating ref ==="
api PATCH "/repos/$REPO/git/refs/heads/$BRANCH" "{\"sha\":\"$COMMIT_SHA\",\"force\":true}"
echo "✅ Success! https://github.com/$REPO"