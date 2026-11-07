#!/usr/bin/env bash
set -Eeuo pipefail

# Preserve the bench and site data in the docker/runtime bind mount.
export FRAPPE_BIND_ADDR=0.0.0.0
if [[ -n "${NVM_DIR:-}" && -n "${NODE_VERSION_DEVELOP:-}" ]]; then
  export PATH="${NVM_DIR}/versions/node/v${NODE_VERSION_DEVELOP}/bin:${PATH}"
fi
BENCH=/home/frappe/persist/frappe-bench
cd /home/frappe/persist
if [[ ! -d "$BENCH/apps/frappe" ]]; then
  if [[ -e "$BENCH" ]]; then
    echo "ERROR: partial bench exists; refusing to overwrite it" >&2
    exit 3
  fi
  bench init --skip-redis-config-generation --frappe-branch develop frappe-bench
fi
cd "$BENCH"
bench set-mariadb-host mariadb
bench set-redis-cache-host redis://redis:6379
bench set-redis-queue-host redis://redis:6379
bench set-redis-socketio-host redis://redis:6379
sed -i '/^redis_/d; /^watch:/d' Procfile

if [[ ! -d apps/erpnext ]]; then
  bench get-app --branch develop erpnext
fi
if [[ ! -d apps/hrms ]]; then
  bench get-app --branch develop hrms
fi

SITE=sites/hrms.localhost/site_config.json
RECOVERY=/home/frappe/persist/recovery/site_config.json
if [[ ! -f "$SITE" && -f "$RECOVERY" ]]; then
  mkdir -p sites/hrms.localhost
  install -m 600 "$RECOVERY" "$SITE"
fi
if [[ ! -f "$SITE" ]]; then
  echo "ERROR: no hrms.localhost site config. Refusing automatic site creation." >&2
  exit 4
fi
mkdir -p sites/hrms.localhost/logs sites/hrms.localhost/public/files sites/hrms.localhost/private/files
bench use hrms.localhost
exec bench start