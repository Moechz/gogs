#!/bin/sh
# ===========================================================================
# Gogs entrypoint for a non-root container (TOS 7 requirement).
#
# The image runs its own s6 supervisor as root and drops to the git user, which
# cannot happen inside a container that already runs as uid 1000. This wrapper
# starts the gogs binary directly with its work directory on the data volume.
# ===========================================================================
set -e
set -u

DATA=/data
mkdir -p "$DATA/gogs/conf" "$DATA/gogs/log" 2>/dev/null || true

if ! ( : > "$DATA/.write-test" ) 2>/dev/null; then
  echo "gogs: $DATA is not writable by uid $(id -u)" >&2
  exit 1
fi
rm -f "$DATA/.write-test"

export GOGS_WORK_DIR="$DATA"
export HOME="$DATA"

cd /app/gogs
exec ./gogs web
