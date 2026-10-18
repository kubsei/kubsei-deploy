#!/bin/sh
# Daily dump of the MongoDB databases (Atlas M0 has no backups). Runs on the server as deploy, from cron:
#   0 3 * * * /opt/kubsei-deploy/backup.sh >> /home/deploy/backups/backup.log 2>&1
# Restore one: docker run --rm -i mongo:8 mongorestore --uri="<uri>" --archive --gzip --drop < <file>
# shortcut: backups live on the same server as the app; also copy them off it (e.g. a Hetzner Storage Box)
# once losing the server would mean losing users' work
set -eu
cd "$(dirname "$0")"

dir="$HOME/backups"
mkdir -p "$dir"

for service in users editor; do
  var=MONGODB_URI_$(echo "$service" | tr a-z A-Z)
  uri=$(grep "^$var=" .env | cut -d= -f2-)
  [ -n "$uri" ] || { echo "$var is not set in .env" >&2; exit 1; }
  file="$dir/$service-$(date +%F).archive.gz"
  docker run --rm mongo:8 mongodump --uri="$uri" --archive --gzip --quiet > "$file.tmp"
  mv "$file.tmp" "$file"   # only complete dumps get the final name
  echo "$(date -Is) $file $(du -h "$file" | cut -f1)"
done

find "$dir" -name '*.archive.gz' -mtime +14 -delete
