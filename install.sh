#!/usr/bin/env bash
# UE PCAS demo: install or upgrade on a Mac or a Linux server, with Docker.
#
#   curl -fsSLo install.sh https://raw.githubusercontent.com/beedev/ue-pcas-deploy/main/install.sh
#   bash install.sh                                          # this computer: http://localhost:8080
#   bash install.sh https://idea.example.com/ue-pcas         # a server, behind its HTTPS web proxy
#
# What it does, every run (running it again is how you upgrade; the demo data is kept):
#   1. Checks Docker and Docker Compose v2 are installed and running.
#   2. Downloads the configuration (this repository) into ~/ue-pcas, keeping your .env there.
#   3. Works out the address settings from the one address you give and writes them to .env.
#   4. Checks the five ports are free.
#   5. Pulls the images and starts the stack, then waits until every part reports healthy.
#   6. Prints the address and the demo sign-ins; for a server, the web proxy (nginx) lines to add.
#
# Settings (all optional, as environment variables):
#   PCAS_HOME=~/ue-pcas      where it installs
#   PCAS_PORT=8080  KEYCLOAK_PORT=8180  API_PORT=8000  MOCKS_PORT=8090  DB_PORT=5433
#   REPO=beedev/ue-pcas-deploy  BRANCH=main      where the configuration comes from
#   NO_DOWNLOAD=1            use the files already in PCAS_HOME (testing a local copy)
#   NO_OPEN=1                do not open the browser at the end (Mac)
set -euo pipefail

URL="${1:-${PCAS_URL:-http://localhost:8080}}"
URL="${URL%/}"
HOME_DIR="${PCAS_HOME:-$HOME/ue-pcas}"
REPO="${REPO:-beedev/ue-pcas-deploy}"
BRANCH="${BRANCH:-main}"
PCAS_PORT="${PCAS_PORT:-8080}"
KEYCLOAK_PORT="${KEYCLOAK_PORT:-8180}"
API_PORT="${API_PORT:-8000}"
MOCKS_PORT="${MOCKS_PORT:-8090}"
DB_PORT="${DB_PORT:-5433}"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then B=$'\033[1m'; G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; N=$'\033[0m'; else B=''; G=''; R=''; Y=''; N=''; fi
step() { printf '\n%s[%s]%s %s\n' "$B" "$1" "$N" "$2"; }
ok()   { printf '  %s✓%s %s\n' "$G" "$N" "$1"; }
warn() { printf '  %s!%s %s\n' "$Y" "$N" "$1"; }
die()  { printf '\n%s✗ %s%s\n' "$R" "$1" "$N" >&2; exit 1; }

# ---- 1. Docker -------------------------------------------------------------------------------------------------------------
step 1/6 "Docker"
os="$(uname -s)"
if ! command -v docker >/dev/null 2>&1; then
  if [ "$os" = Darwin ]; then die "Docker is not installed. Install Docker Desktop from https://www.docker.com/products/docker-desktop/, start it, then run this again."; fi
  die "Docker is not installed. Install Docker Engine and the Compose plugin (https://docs.docker.com/engine/install/), then run this again."
fi
docker info >/dev/null 2>&1 || die "Docker is installed but not running. Start Docker$([ "$os" = Darwin ] && echo ' Desktop'), wait until it is ready, then run this again."
docker compose version >/dev/null 2>&1 || die "Docker Compose v2 is missing (the 'docker compose' command). Install the Compose plugin, then run this again."
mem=$(docker info --format '{{.MemTotal}}' 2>/dev/null || echo 0)
if [ "$mem" -gt 0 ] && [ "$mem" -lt 3500000000 ]; then
  warn "Docker has $((mem / 1000000000)) GB of memory; the demo needs about 4 GB.$([ "$os" = Darwin ] && echo ' Raise it in Docker Desktop, Settings, Resources.')"
fi
ok "Docker $(docker version --format '{{.Server.Version}}' 2>/dev/null), $(docker compose version --short 2>/dev/null)"

# ---- 2. The configuration --------------------------------------------------------------------------------------------------
step 2/6 "Configuration in $HOME_DIR"
mkdir -p "$HOME_DIR"
if [ -z "${NO_DOWNLOAD:-}" ]; then
  command -v curl >/dev/null 2>&1 || die "curl is needed to download the configuration."
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/heads/$BRANCH" | tar -xz -C "$tmp" --strip-components=1 \
    || die "Could not download https://github.com/$REPO ($BRANCH)."
  # Everything is replaced except your .env.
  rm -rf "$HOME_DIR/config"
  for item in config docker-compose.yml .env.example README.md install.sh; do cp -R "$tmp/$item" "$HOME_DIR/"; done
fi
[ -f "$HOME_DIR/docker-compose.yml" ] || die "$HOME_DIR has no docker-compose.yml."
# The containers run as other users and must be able to read these files (a strict umask made Postgres skip its setup once).
chmod -R go+rX "$HOME_DIR/config"
ok "configuration from github.com/$REPO ($BRANCH)"

# ---- 3. The address --------------------------------------------------------------------------------------------------------
step 3/6 "Address $URL"
case "$URL" in http://*|https://*) ;; *) die "The address must start with http:// or https://, for example https://idea.example.com/ue-pcas" ;; esac
rest="${URL#*://}"
host="${rest%%/*}"
path=""; [ "$rest" != "$host" ] && path="/${rest#*/}"
origin="${URL%%://*}://$host"
local_run=false
case "$host" in localhost|localhost:*) local_run=true ;; esac
if $local_run; then
  [ -z "$path" ] || die "On this computer PCAS runs at the root of the address, for example http://localhost:8080, not under a path."
  [ "$host" = "localhost:$PCAS_PORT" ] || PCAS_PORT="${host#localhost:}"
  KEYCLOAK_URL="http://localhost:$KEYCLOAK_PORT"; KEYCLOAK_PATH=""
else
  [ "${URL%%://*}" = https ] || die "A server address must be https:// (the sign-in cookie is sent only over HTTPS)."
  # The sign-in service sits next to PCAS on the same host, under <path>-keycloak (or /keycloak at the root).
  KEYCLOAK_PATH="${path:-}-keycloak"; [ -n "$path" ] || KEYCLOAK_PATH="/keycloak"
  KEYCLOAK_URL="$origin$KEYCLOAK_PATH"
fi

# One line per setting in .env; anything else you put there is kept.
envf="$HOME_DIR/.env"
touch "$envf"
before="$(grep -E '^PCAS_URL=' "$envf" 2>/dev/null | cut -d= -f2- || true)"
set_env() {
  local key="$1" value="$2"
  grep -v -E "^$key=" "$envf" > "$envf.tmp" || true
  printf '%s=%s\n' "$key" "$value" >> "$envf.tmp"
  mv "$envf.tmp" "$envf"
}
set_env PCAS_URL "$URL"
set_env PCAS_ORIGIN "$origin"
set_env PCAS_BASE_PATH "$path"
set_env KEYCLOAK_URL "$KEYCLOAK_URL"
set_env KEYCLOAK_PATH "$KEYCLOAK_PATH"
set_env PCAS_PORT "$PCAS_PORT"
set_env KEYCLOAK_PORT "$KEYCLOAK_PORT"
set_env API_PORT "$API_PORT"
set_env MOCKS_PORT "$MOCKS_PORT"
set_env DB_PORT "$DB_PORT"
ok "PCAS at $URL, sign-in at $KEYCLOAK_URL"

cd "$HOME_DIR"
running="$(docker compose ps -q 2>/dev/null | wc -l | tr -d ' ')"
fresh=false
if [ -n "$before" ] && [ "$before" != "$URL" ]; then
  # The sign-in service reads its allowed addresses only on a fresh start, so a new address needs a fresh volume (the demo data starts over).
  warn "The address changed from $before; the stack starts fresh and the demo data is reset."
  fresh=true
fi

# ---- 4. Ports --------------------------------------------------------------------------------------------------------------
step 4/6 "Ports"
in_use() { (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null; }
if [ "$running" = 0 ] || $fresh; then
  $fresh && docker compose down -v --remove-orphans >/dev/null 2>&1 || true
  for p in "PCAS_PORT=$PCAS_PORT" "KEYCLOAK_PORT=$KEYCLOAK_PORT" "API_PORT=$API_PORT" "MOCKS_PORT=$MOCKS_PORT" "DB_PORT=$DB_PORT"; do
    if in_use "${p#*=}"; then die "Port ${p#*=} is in use by another program. Stop it, or choose another port, for example: ${p%%=*}=$(( ${p#*=} + 1000 )) bash install.sh $URL"; fi
  done
  ok "$PCAS_PORT, $KEYCLOAK_PORT, $API_PORT, $MOCKS_PORT and $DB_PORT are free"
else
  ok "the stack is already running on its ports; it is upgraded in place"
fi

# ---- 5. Start --------------------------------------------------------------------------------------------------------------
step 5/6 "Images and start (the first time takes a few minutes)"
docker compose pull --quiet || die "Could not pull the images from ghcr.io."
docker compose up -d --wait --wait-timeout 300 || {
  docker compose ps
  die "Not every part became healthy. See which with 'docker compose ps' and why with 'docker compose logs <name>' (in $HOME_DIR)."
}
ok "all parts healthy"

# ---- 6. Done ---------------------------------------------------------------------------------------------------------------
step 6/6 "Ready"
printf '\n  Open %s%s%s\n  Sign in as demo.all (every role), or r.alvarez, r.chen, k.osei and the others; the password is Pcas!2026.\n' "$B" "$URL" "$N"
printf '  Press Flow in the top bar for the guided story. The Workbench stand-in is at %s/workbench.\n' "$URL"
printf '  Stop: cd %s && docker compose down    (add -v to wipe the demo data)\n' "$HOME_DIR"
if ! $local_run; then
  # Under a path, the proxy removes the path before the stack sees it, and puts it back on the stack's own redirects (D-234).
  prefix_lines=""
  if [ -n "$path" ]; then
    hostre="$(printf '%s' "$host" | sed 's/\./\\./g')"
    prefix_lines="        proxy_set_header X-Forwarded-Prefix $path;
        proxy_redirect ~^(?:https?://$hostre(?::\\d+)?)?/(?!${path#/}|${KEYCLOAK_PATH#/})(.*)\$ $path/\$1;"
  fi
  cat <<NGINX

  This server's HTTPS web proxy (nginx) must pass two paths to the stack. Inside the server block for $host:

    location ^~ $KEYCLOAK_PATH/ {
        proxy_pass http://127.0.0.1:$KEYCLOAK_PORT;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host \$http_host;
    }
    location ^~ ${path}/ {
        proxy_pass http://127.0.0.1:$PCAS_PORT/;
        proxy_http_version 1.1;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host \$http_host;
        proxy_set_header Connection "";
        proxy_read_timeout 300s;
$prefix_lines
    }

  Then: sudo nginx -t && sudo systemctl reload nginx
NGINX
elif [ "$os" = Darwin ] && [ -z "${NO_OPEN:-}" ]; then
  open "$URL" 2>/dev/null || true
fi
