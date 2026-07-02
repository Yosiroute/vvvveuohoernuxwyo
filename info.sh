#!/usr/bin/env bash
set -u
API="https://api.vercel.com"
TEAM="$VERCEL_ORG_ID"
TOKEN="$VERCEL_ARTIFACTS_TOKEN"
HASH="deadbeefdeadbeef"

echo "----DRY----"
turbo run build --dry-run=json > /tmp/dry.json 2>/dev/null
cat /tmp/dry.json

echo "----PUT----"
printf 'inert-marker-%s' "$(date +%s)" > /tmp/marker.bin
curl -sS -X PUT \
  "$API/v8/artifacts/$HASH?teamId=$TEAM" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/octet-stream" \
  -H "x-artifact-duration: 0" \
  --data-binary @/tmp/marker.bin \
  -w 'PUT HTTP %{http_code}\n'

echo "----EXISTS (HEAD)----"
curl -sS -I \
  "$API/v8/artifacts/$HASH?teamId=$TEAM" \
  -H "Authorization: Bearer $TOKEN" \
  -w 'HEAD HTTP %{http_code}\n'

echo "----GET----"
curl -sS \
  "$API/v8/artifacts/$HASH?teamId=$TEAM" \
  -H "Authorization: Bearer $TOKEN" \
  -w '\nGET HTTP %{http_code}\n'

mkdir -p public && echo done > public/index.html