#!/usr/bin/env bash
set -euo pipefail

KEY="${CACHE_KEY:-6d88db4a54854863}"        # override via env, or edit here
API="${TURBO_API:-https://vercel.com/api}"
TOKEN="${VERCEL_ARTIFACTS_TOKEN:-${TURBO_TOKEN:-}}"
OWNER="${VERCEL_ARTIFACTS_OWNER:-${TURBO_TEAMID:-}}"

if [ -z "$TOKEN" ] || [ -z "$OWNER" ]; then
  echo "!! no artifacts token/owner in env — remote cache creds not injected"; exit 0
fi

echo "==== fetching artifact for key: $KEY ===="
code=$(curl -sS -w '%{http_code}' -o /tmp/artifact.bin \
  -H "Authorization: Bearer $TOKEN" \
  "$API/v8/artifacts/$KEY?teamId=$OWNER")
echo "HTTP $code, $(wc -c </tmp/artifact.bin) bytes"
[ "$code" = "200" ] || { echo "not a hit; body:"; cat /tmp/artifact.bin; echo; exit 0; }

echo "==== file type ===="
file /tmp/artifact.bin || true

echo "==== members ===="
# turbo artifacts are zstd-compressed tar
if zstd -dc /tmp/artifact.bin 2>/dev/null | tar -tvf - ; then :; 
else
  echo "(zstd decode failed — dumping first bytes as-is)"
  head -c 200 /tmp/artifact.bin | xxd | head
fi

echo "==== extract + show contents ===="
rm -rf /tmp/cache_inspect && mkdir -p /tmp/cache_inspect
zstd -dc /tmp/artifact.bin 2>/dev/null | tar -xf - -C /tmp/cache_inspect 2>/dev/null || true
find /tmp/cache_inspect -type f | while read -r f; do
  echo "----- $f -----"
  head -c 500 "$f"; echo
done

turbo run build --dry-run=json > /tmp/dry.json; 

turbo run build -vvv 2>&1 | grep -iE 'hash|cache|signature|artifact|http' || true; 

echo '----DRY----'; 
cat /tmp/dry.json; 

mkdir -p public && echo done > public/index.html   # keep the deploy happy