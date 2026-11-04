#!/usr/bin/env bash
# Local Docker development bootstrap. Never overwrite an existing site automatically.
set -Eeuo pipefail
trap 'echo "HRMS startup failed at line $LINENO: $BASH_COMMAND" >&2' ERR

SITE_NAME="${HRMS_SITE_NAME:-hrms.localhost}"
BENCH_DIR="/home/frappe/frappe-bench"
MARIADB_ROOT_PASSWORD="${MARIADB_ROOT_PASSWORD:?MARIADB_ROOT_PASSWORD must be set}"
HRMS_ADMIN_PASSWORD="${HRMS_ADMIN_PASSWORD:?HRMS_ADMIN_PASSWORD must be set}"
FRAPPE_BRANCH="${FRAPPE_BRANCH:-develop}"
ERPNEXT_BRANCH="${ERPNEXT_BRANCH:-develop}"
HRMS_BRANCH="${HRMS_BRANCH:-develop}"
HRMS_APP_REPO="${HRMS_APP_REPO:-https://github.com/youssefdaoud23/hrms.git}"

if [[ -n "${NVM_DIR:-}" && -n "${NODE_VERSION_DEVELOP:-}" ]]; then
    export PATH="$NVM_DIR/versions/node/v$NODE_VERSION_DEVELOP/bin:$PATH"
fi

# The MariaDB 11.8 CLI in frappe/bench:latest otherwise requires TLS from a
# local MariaDB 10.8 server that does not have TLS enabled.
# This is for an isolated DEVELOPMENT stack only, not remote/production DBs.
client_config="$HOME/.my.cnf"
if [[ -e "$client_config" ]]; then
    if ! grep -Eq '^[[:space:]]*ssl[[:space:]]*=[[:space:]]*(0|false)[[:space:]]*$' "$client_config"; then
        echo "Existing $client_config does not specify ssl=0. Review it manually; not overwriting it." >&2
        exit 1
    fi
else
    (umask 077; printf '[client]\nssl=0\n' > "$client_config")
fi

# Compose v1 can start services before the databases are ready.
echo "Waiting for MariaDB and Redis..."
ready=0
for ((attempt=1; attempt<=60; attempt++)); do
    if MYSQL_PWD="$MARIADB_ROOT_PASSWORD" mariadb --host=mariadb --protocol=TCP --user=root --execute='SELECT 1' >/dev/null 2>&1 && (echo >/dev/tcp/redis/6379) >/dev/null 2>&1; then
        ready=1
        break
    fi
    sleep 2
done
if [[ "$ready" -ne 1 ]]; then
    echo "MariaDB/Redis not ready after 120 seconds; refusing to initialize site." >&2
    exit 1
fi

if [[ ! -d "$BENCH_DIR/apps/frappe" ]]; then
    if [[ -d "$BENCH_DIR" && -n "$(ls -A "$BENCH_DIR")" ]]; then
        echo "Existing bench directory is incomplete. Inspect $BENCH_DIR before retrying." >&2
        exit 1
    fi
    echo "Creating a new bench..."
    # --ignore-exist is necessary for an empty Docker named volume mount.
    bench init --ignore-exist --skip-redis-config-generation --frappe-branch "$FRAPPE_BRANCH" "$BENCH_DIR"
else
    echo "Existing bench found."
fi

cd "$BENCH_DIR"
bench set-mariadb-host mariadb
bench set-redis-cache-host redis://redis:6379
bench set-redis-queue-host redis://redis:6379
bench set-redis-socketio-host redis://redis:6379

# Use external Redis and bind the web server to the Docker interface.
sed -i '/^redis_/d; /^watch:/d' Procfile
sed -i -E 's|^web:[[:space:]]+(FRAPPE_BIND_ADDR=[^[:space:]]+[[:space:]]+)?bench serve|web: FRAPPE_BIND_ADDR=0.0.0.0 bench serve|' Procfile
if ! grep -q '^web: FRAPPE_BIND_ADDR=0.0.0.0 bench serve' Procfile; then
    echo "Could not configure the Frappe web bind address in Procfile." >&2
    exit 1
fi

if [[ ! -f "sites/$SITE_NAME/site_config.json" ]]; then
    # Never silently replace an incomplete site directory or existing database.
    if [[ -e "sites/$SITE_NAME" ]]; then
        echo "Site directory exists without site_config.json: manual recovery required." >&2
        exit 1
    fi
    echo "Creating site $SITE_NAME..."
    [[ -d apps/erpnext ]] || bench get-app --branch "$ERPNEXT_BRANCH" erpnext
    [[ -d apps/hrms ]] || bench get-app --branch "$HRMS_BRANCH" "$HRMS_APP_REPO"
    bench new-site "$SITE_NAME" --mariadb-root-password "$MARIADB_ROOT_PASSWORD" --admin-password "$HRMS_ADMIN_PASSWORD" --mariadb-user-host-login-scope='%'
    bench --site "$SITE_NAME" install-app hrms
    bench --site "$SITE_NAME" set-config developer_mode 1
    bench --site "$SITE_NAME" enable-scheduler
    bench --site "$SITE_NAME" clear-cache
else
    echo "Existing site found; verifying installation rather than reinstalling..."
fi

if ! installed_apps="$(bench --site "$SITE_NAME" list-apps)"; then
    echo "The site exists but its database is incomplete. Stop: restore or repair it manually." >&2
    exit 1
fi
for app in frappe erpnext hrms; do
    if ! grep -Eq "^$app([[:space:]]|$)" <<< "$installed_apps"; then
        echo "Missing installed app $app on $SITE_NAME. Manual recovery required; no database changes made." >&2
        exit 1
    fi
done

bench use "$SITE_NAME"
echo "HRMS site verified; starting Frappe."
exec bench start
