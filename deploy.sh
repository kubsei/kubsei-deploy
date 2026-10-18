#!/bin/sh
# Runs on the server. Pins the given image tags in .env, then pulls and restarts what changed.
#   ./deploy.sh                          re-pull the tags already in .env (e.g. latest)
#   ./deploy.sh users=3f9c2e1 editor=latest
set -eu
cd "$(dirname "$0")"

# Pull first, then run the version just pulled: a shell keeps reading the old file while git replaces it
if [ -z "${CADDYFILE_BEFORE:-}" ]; then
  CADDYFILE_BEFORE=$(git rev-parse HEAD:Caddyfile)
  export CADDYFILE_BEFORE
  git pull --ff-only
  exec "$0" "$@"
fi

for arg in "$@"; do
  service=${arg%%=*}
  tag=${arg#*=}
  case "$service" in
    gateway|users|editor) ;;
    *) echo "Unknown service: $service" >&2; exit 1 ;;
  esac
  if ! echo "$tag" | grep -Eq '^[A-Za-z0-9._-]+$'; then
    echo "Invalid tag: $tag" >&2; exit 1
  fi
  var=$(echo "$service" | tr a-z A-Z)_TAG
  sed -i "s/^$var=.*/$var=$tag/" .env
done

docker compose pull
docker compose up -d --remove-orphans
# The Caddyfile is bind-mounted: after git replaces it, Caddy keeps the old one until restarted
[ "$CADDYFILE_BEFORE" = "$(git rev-parse HEAD:Caddyfile)" ] || docker compose restart caddy
docker image prune -f
docker compose ps
