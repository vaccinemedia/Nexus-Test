#!/usr/bin/env sh
# Open the built TAP in FuseX (or fall back to default handler).
set -e
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
SNA="$ROOT/out/nexus.sna"
if [ ! -f "$SNA" ]; then
  echo "Missing $SNA — run: make" >&2
  exit 1
fi
for app in FuseX "Fuse for Mac" Fuse; do
  if [ -d "/Applications/$app.app" ]; then
    exec open -na "/Applications/$app.app" -- "$SNA"
  fi
done
exec open "$SNA"
