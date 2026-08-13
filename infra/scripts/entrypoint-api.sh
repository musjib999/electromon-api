#!/bin/sh
set -e

# shellcheck disable=SC1091
. /compose-database-url.sh
electromon_export_database_url

echo "==> Starting Electromon API (NODE_ENV=${NODE_ENV})"
cd /app
exec node dist/main.js
