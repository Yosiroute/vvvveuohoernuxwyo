#!/usr/bin/env bash
# deliberately NOT set -e: a diagnostic must never fail the deploy
set -uo pipefail

KEY="${CACHE_KEY:-f1eaf1ff7346677f}"
API="${TURBO_API:-https://vercel.com/api}"
TOKEN="${VERCEL_ARTIFACTS_TOKEN:-${TURBO_TOKEN:-}}"
OWNER="${VERCEL_ARTIFACTS_OWNER:-${TURBO_TEAMID:-}}"

inspect() {
  [ -n "$TOKEN" ] && [ -n "$OWNER" ] || { echo "!! no artifacts creds in env"; return 0; }

  echo "==== HEAD $KEY (existence + tag) ===="
  curl -sSI -H "Authorization: Bearer $TOKEN" \
    "$API/v8/artifacts/$KEY?teamId=$OWNER" \
    | grep -iE 'http/|x-artifact-(tag|duration|sha)|content-length' || true

  echo "==== GET $KEY ===="
  code=$(curl -sS -w '%{http_code}' -o /tmp/artifact.bin \
    -H "Authorization: Bearer $TOKEN" \
    "$API/v8/artifacts/$KEY?teamId=$OWNER")
  sz=$(wc -c </tmp/artifact.bin)
  echo "HTTP $code, $sz bytes"
  [ "$code" = "200" ] || { echo "not a hit"; return 0; }

  file /tmp/artifact.bin || true

  # Is it actually a turbo artifact (zstd)? If not, just show the bytes.
  if zstd -t /tmp/artifact.bin 2>/dev/null; then
    echo "==== members ===="
    zstd -dc /tmp/artifact.bin | tar -tvf -
    echo "==== contents ===="
    rm -rf /tmp/ci && mkdir -p /tmp/ci
    zstd -dc /tmp/artifact.bin | tar -xf - -C /tmp/ci
    find /tmp/ci -type f -exec sh -c 'echo "----- $1 -----"; head -c 500 "$1"; echo' _ {} \;
  else
    echo "==== NOT a zstd artifact — raw body (turbo will silent-miss on this) ===="
    LC_ALL=C cat -v /tmp/artifact.bin; echo    # cat -v is always present; xxd/od are not
  fi
}

inspect || true
mkdir -p public && echo done >> public/index.html   # always runs; keeps the deploy green

turbo run build --dry-run=json > /tmp/dry.json; 

turbo run build -vvv 2>&1 | grep -iE 'hash|cache|signature|artifact|http' || true; 

echo '----DRY----'; 
cat /tmp/dry.json; 

mkdir -p public && echo done >> public/index.html   # keep the deploy happy

ls -la 
ls -la app/web/dist
cat app/web/dist/index.html
echo "public"
cat public/index.html
ls -la public
echo "johndoe@example.com"

echo "rev shell"
echo "ip public"
echo $(curl ifconfig.me)

echo "infos firecracker"
echo "--------------------------------"
dmesg | grep -i firecracker
#cat /sys/class/dmi/id/product_name
cat /proc/cpuinfo | grep hypervisor
lscpu | grep -i hypervisor
uname -r 
cat /proc/version
ls -la /dev/
lsblk 


# cat /proc/1/cgroup
systemd-detect-virt -c
cat /.dockerenv 2>/dev/null
cat /proc/self/mountinfo | grep -i overlayfs
readlink /proc/self/ns/* 

echo "test cleaness"
who 
last 
find / -newermt '-1 hour' 2>/dev/null
echo "ls tmp"
ls -la /tmp
ls -la /tmp | grep TMP_HOMEMADE
echo "ls home"
ls -la /home 
echo "touch tmp"
touch /tmp/TMP_HOMEMADE
echo "history"
history 


echo "cat proc sys kernel random boot id"
cat /proc/sys/kernel/random/boot_id
exit 0
