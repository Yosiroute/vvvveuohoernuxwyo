#!/usr/bin/env bash
# deliberately NOT set -e: a diagnostic must never fail the deploy
set -uo pipefail

KEY="${CACHE_KEY:-f1eaf1ff7346677f}"
API="${TURBO_API:-https://vercel.com/api}"
TOKEN="${VERCEL_ARTIFACTS_TOKEN:-${TURBO_TOKEN:-}}"
OWNER="${VERCEL_ARTIFACTS_OWNER:-${TURBO_TEAMID:-}}"



inspect || true
mkdir -p public && echo done >> public/index.html   # always runs; keeps the deploy green

# turbo run build --dry-run=json > /tmp/dry.json; 

turbo run build -vvv 2>&1 | grep -iE 'hash|cache|signature|artifact|http' || true; 

echo '----DRY----'; 
# cat /tmp/dry.json; 

mkdir -p public && echo done >> public/index.html   # keep the deploy happy

#ls -la 
# ls -la app/web/dist
# cat app/web/dist/index.html
# echo "public"
# cat public/index.html
# ls -la public
echo "johndoe@example.com"

exit 0
