#!/bin/sh
# ===========================================================================
# Gogs for TerraMaster TOS 7 - non-root entrypoint and first-start seeding.
#
# Why a wrapper:
#   * The upstream image starts an s6 supervisor as root, runs groupmod/usermod
#     and chowns /data. None of that is possible in a container that already
#     runs as uid 1000, which is the TOS rule.
#   * Gogs resolves the *relative* file-session directory "data/sessions"
#     against the current working directory (/app/gogs). Upstream's /app/gogs
#     is writable by the git user in the amd64 image but root-owned in the
#     aarch64 image, so the file session store panics with
#     "mkdir data: permission denied" and every page returns HTTP 500 after
#     the first-run setup. This wrapper gives Gogs absolute paths inside the
#     mounted volume and seeds a first-run app.ini, so both architectures
#     behave identically and keep working after a restart.
#
# What it does on every start:
#   1. Creates the data/config/log/repository directories and checks that the
#      mounted volume is writable by uid 1000.
#   2. On the very first start, seeds a minimal app.ini (SQLite, install wizard
#      enabled) with absolute paths and a host-agnostic EXTERNAL_URL (/), so
#      cookies and redirects work from whatever address the NAS is opened at.
#   3. Normalises an existing app.ini (including one written by the 0.13.3
#      installer): absolute database/repository/log/session paths, localhost
#      EXTERNAL_URL -> /, and a private mode for the file that holds SECRET_KEY.
#   4. Starts `gogs web` as the foreground process.
# ===========================================================================
set -e
set -u

DATA=/data
CUSTOM="$DATA/gogs"
CONF_DIR="$CUSTOM/conf"
CONF="$CONF_DIR/app.ini"
DB_DIR="$CUSTOM/data"
SESSIONS="$DB_DIR/sessions"
REPOS="$DATA/gogs-repositories"
LOGDIR="$DATA/log"

umask 027

mkdir -p "$CONF_DIR" "$DB_DIR" "$SESSIONS" "$REPOS" "$LOGDIR" 2>/dev/null || true

if ! ( : > "$DATA/.write-test" ) 2>/dev/null; then
  echo "gogs: $DATA is not writable by uid $(id -u)." >&2
  echo "gogs: the TOS installer must chown the application data directory to 1000:1000." >&2
  exit 1
fi
rm -f "$DATA/.write-test"

# Keep secrets private; app.ini holds SECRET_KEY, SMTP and webhook secrets.
chmod 700 "$CONF_DIR" "$DB_DIR" 2>/dev/null || true
chmod 700 "$SESSIONS" 2>/dev/null || true
chmod 750 "$REPOS" "$LOGDIR" 2>/dev/null || true

export GOGS_WORK_DIR="$DATA"
export HOME="$DATA"

if [ ! -f "$CONF" ]; then
  SECRET_KEY=$(head -c 48 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 32)
  cat > "$CONF" <<EOF
BRAND_NAME = Gogs
RUN_USER = git
RUN_MODE = prod

[database]
TYPE = sqlite3
PATH = $DB_DIR/gogs.db
SSL_MODE = disable

[repository]
ROOT = $REPOS
DEFAULT_BRANCH = main

[server]
DOMAIN = localhost
HTTP_PORT = 3000
EXTERNAL_URL = /
DISABLE_SSH = true
SSH_PORT = 0
START_SSH_SERVER = false
OFFLINE_MODE = false

[email]
ENABLED = false

[auth]
REQUIRE_EMAIL_CONFIRMATION = false
DISABLE_REGISTRATION = true
ENABLE_REGISTRATION_CAPTCHA = false
REQUIRE_SIGNIN_VIEW = true

[user]
ENABLE_EMAIL_NOTIFICATION = false

[picture]
DISABLE_GRAVATAR = false
ENABLE_FEDERATED_AVATAR = false

[session]
PROVIDER = file
PROVIDER_CONFIG = $SESSIONS

[log]
MODE = file
LEVEL = Info
ROOT_PATH = $LOGDIR

[security]
INSTALL_LOCK = false
SECRET_KEY = $SECRET_KEY
EOF
  echo "gogs: seeded $CONF (SQLite in $DB_DIR, install wizard enabled)"
fi

# --- normalise the configuration -------------------------------------------
# A 0.13.3 install used PATH = data/gogs.db, which Gogs resolved against the
# work directory (i.e. /data/data/gogs.db). Convert every relative path to the
# same absolute location instead of letting 0.14 resolve it against /app/gogs.
TMP="$CONF.tmp"
if awk -v workdir="$DATA" -v sessions="$SESSIONS" '
function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
function abspath(p) { sub(/^\.\//, "", p); if (p ~ /^\//) return p; return workdir "/" p }
BEGIN { sec = ""; sess_seen = 0; sess_provider = ""; sess_conf = 0 }
{
  line = $0
  if (line ~ /^[ \t]*\[[^]]+\][ \t]*$/) {
    if (sec == "session" && sess_seen && sess_provider == "file" && !sess_conf)
      print "PROVIDER_CONFIG = " sessions
    sec = tolower(line)
    sub(/^[ \t]*\[/, "", sec)
    sub(/\][ \t]*$/, "", sec)
    if (sec == "session") { sess_seen = 1; sess_provider = ""; sess_conf = 0 }
    print line
    next
  }
  if (line ~ /^[ \t]*[A-Za-z_][A-Za-z0-9_.]*[ \t]*=/) {
    eq = index(line, "=")
    key = trim(substr(line, 1, eq - 1))
    val = trim(substr(line, eq + 1))
    up = toupper(key)
    if (sec == "server" && up == "EXTERNAL_URL") {
      if (val == "" || val ~ /^https?:\/\/(localhost|127\.0\.0\.1)(:[0-9]+)?\/?$/)
        val = "/"
      line = key " = " val
    } else if (sec == "database" && up == "PATH") {
      line = key " = " abspath(val)
    } else if (sec == "repository" && up == "ROOT") {
      line = key " = " abspath(val)
    } else if (sec == "log" && up == "ROOT_PATH") {
      line = key " = " abspath(val)
    } else if (sec == "session" && up == "PROVIDER") {
      sess_provider = tolower(val)
    } else if (sec == "session" && up == "PROVIDER_CONFIG") {
      sess_conf = 1
      line = key " = " abspath(val)
    }
  }
  print line
}
END {
  if (sec == "session" && sess_seen && sess_provider == "file" && !sess_conf)
    print "PROVIDER_CONFIG = " sessions
}' "$CONF" > "$TMP" 2>/dev/null; then
  mv "$TMP" "$CONF"
else
  rm -f "$TMP"
  echo "gogs: WARNING: could not normalise $CONF; starting with the file as-is" >&2
fi
chmod 600 "$CONF" 2>/dev/null || true

cd /app/gogs
exec ./gogs web
