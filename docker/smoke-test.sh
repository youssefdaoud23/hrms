#!/usr/bin/env bash
# Smoke test for a NEW, disposable development environment.
# This script never removes volumes. Do not run on an existing installation
# before migrating bench data as documented in docker/README.md.
set -Eeuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
site="${HRMS_SITE_NAME:-hrms.localhost}"
http_port="${HRMS_HTTP_PORT:-8000}"
timeout_seconds="${HRMS_SMOKE_TIMEOUT_SECONDS:-2700}"

print_logs() {
    docker compose ps || true
    docker compose logs --tail=100 frappe mariadb redis || true
}
trap 'echo "Smoke test failed at line $LINENO" >&2; print_logs >&2' ERR

wait_for_http() {
    local deadline=$((SECONDS + timeout_seconds))
    local status
    while ((SECONDS < deadline)); do
        status="$(curl --max-time 10 --silent --output /dev/null --write-out '%{http_code}' "http://127.0.0.1:${http_port}/" || true)"
        if [[ "$status" =~ ^(200|301|302|303|307|308)$ ]]; then
            echo "HRMS HTTP check passed ($status)"
            return 0
        fi
        sleep 15
    done
    echo "HRMS did not return a successful HTTP response in time." >&2
    return 1
}

check_apps() {
    local apps
    apps="$(docker compose exec -T frappe bash -lc "cd /home/frappe/frappe-bench && bench --site '$site' list-apps")"
    printf '%s\n' "$apps"
    local app
    for app in frappe erpnext hrms; do
        if ! grep -Eq "^${app}([[:space:]]|$)" <<< "$apps"; then
            echo "Missing installed app: $app" >&2
            return 1
        fi
    done
}

echo "Starting development stack for smoke test..."
docker compose up -d
wait_for_http
check_apps
echo "Restarting services to verify site persistence..."
docker compose restart
wait_for_http
check_apps
echo "PASS: first boot, HTTP response, required apps, and restart persistence."
