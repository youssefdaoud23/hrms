# Reproducible local Docker setup (Ubuntu, WSL2, Linux)

This stack is for **local development**, not production. It is designed for Docker Compose v2 and a new installation. Current defaults use Frappe, ERPNext, and HRMS from the **develop** branches of their respective repositories (HRMS comes from this fork). The application source changes over time; successful smoke tests apply to the commits checked out at the time of the run, not all future upstream changes. Image defaults are versioned (bench v5.31.1, MariaDB 11.8, Redis 7.4-alpine). You can pin further to exact digests/commits after a passing test.

## Fresh installation (new machine / new WSL2 distribution only)

Prerequisites: Ubuntu/Linux, Git, Docker Engine or Docker Desktop with Linux containers, Docker Compose v2, sufficient memory and free disk space for Frappe's dependency installation, and network access to GitHub/Docker Hub.

1. Clone this fork; check out the tested branch `fix/docker-initialization-safety-20261104` (until PR #1 is merged).
2. From the repository's `docker` directory, review the local development passwords in `docker-compose.yml`. By default, MariaDB root password is `123` and HRMS admin password is `admin`. For better security, create an untracked `.env` file and override `MARIADB_ROOT_PASSWORD` and `HRMS_ADMIN_PASSWORD` before starting. Do not put real HR data in this development stack.
3. Start from a **new empty Docker project and volumes** with `docker compose up -d`. Follow progress using `docker compose logs -f frappe`. Frappe downloads and installs the relevant apps. Database initialization can take substantial time.
4. From Windows or the Linux machine, open http://localhost:8000. Use username `Administrator` and the configured HRMS admin password.
5. Confirm apps using `docker compose exec frappe bash -lc 'cd /home/frappe/frappe-bench && bench --site hrms.localhost list-apps'`. The output must contain `frappe`, `erpnext`, and `hrms`.
6. To exercise initial boot and restart checks on a **disposable, clean installation**, run `bash docker/smoke-test.sh` from the repository root. This script starts the Compose stack, tests the HTTP endpoint, validates installed apps, restarts all containers, and tests again. It never deletes volumes. CI runs the same script in an ephemeral GitHub Actions runner.

One-line terminal commands to copy on a NEW Ubuntu/WSL2 system:

```bash
git clone --branch fix/docker-initialization-safety-20261104 https://github.com/youssefdaoud23/hrms.git
```
```bash
cd hrms/docker
```
```bash
docker compose config --quiet
```
```bash
docker compose up -d
```
```bash
docker compose logs --tail=100 frappe
```
```bash
docker compose exec -T frappe bash -lc 'cd /home/frappe/frappe-bench && bench --site hrms.localhost list-apps'
```
```bash
curl -I --max-time 10 http://localhost:8000
```

## Safeguards

- `init.sh` aborts on errors; it **never silently overwrites or repairs** an incomplete site. If startup fails, inspect logs and preserve existing data before manual recovery.
- The MariaDB CLI uses `ssl=0` for this local-only deployment to prevent the previously observed TLS/SSL import failure. It does not overwrite preexisting client config.
- MariaDB/Redis readiness checks and Compose health checks reduce startup races.
- Frappe binds to `0.0.0.0` **inside** Docker. Docker only publishes ports on the Linux/WSL2 host's `127.0.0.1` by default; do not make it internet-accessible using default credentials.
- The MariaDB and Frappe bench directories use independent **Compose-project-scoped** named volumes. Changing the Compose project name changes the volumes the app uses.
- The script checks all three installed apps before starting the server. A running container is not proof of a successful initialization.

## CRITICAL: existing installations need migration, not a direct Compose upgrade

The original `frappe/hrms` Compose file kept `/home/frappe/frappe-bench` **inside the Frappe container**. The updated Compose file mounts a **new persistent volume** there. If you simply recreate the original container, the volume will be empty and existing apps, site files, configs, and uploads can become inaccessible. The MariaDB image default also changes from `10.8` to `11.8`, which is a major DB version change and MUST NOT be applied automatically to existing MariaDB data.

**Do not run the updated Compose file against an existing installation until BOTH data migration and MariaDB upgrade planning are complete.**

1. Capture the current container name/ID, Compose project name, current Docker volume names, and versions. Preserve a backup of `/home/frappe/frappe-bench` from the OLD Frappe container, including all site config files, database credentials, encryption keys, file attachments and logs. Take a verified MariaDB database backup while writes are stopped.
2. Keep the existing MariaDB 10.8 image for the initial migration by setting `MARIADB_IMAGE=mariadb:10.8` in a local untracked `docker/.env` file. Do not change database major versions until a separately planned and verified MariaDB upgrade.
3. Populate the **new project-scoped Frappe bench volume** from the verified bench backup before allowing the updated Compose configuration to recreate the Frappe container. Preserve the non-root `frappe` user's ownership and permissions. Check the restored data and verify the existing MariaDB volume is still the one in use.
4. Only after these backups and checks should you recreate the application with the updated Compose file and test HTTP, app installation, and data continuity. Keep original backups until validation succeeds.

Never run `docker compose down -v`, `bench reinstall`, or `bench new-site --force` as a migration shortcut.

## Diagnostics

- Container status: `docker compose ps`
- Logs: `docker compose logs --tail=100 frappe`
- Check installed apps: `docker compose exec -T frappe bash -lc 'cd /home/frappe/frappe-bench && bench --site hrms.localhost list-apps'`
- HTTP check: `curl -I --max-time 10 http://localhost:8000`
- Fresh installation/restart smoke test (only on disposable environments): `bash docker/smoke-test.sh`

If Frappe reports a missing `tabDefaultValue` table, initial SQL import did not finish. The new script will refuse to silently reuse this incomplete site; verify the DB contents and repair/recover it explicitly.

Do not attempt WSL2 container migration from the old Compose file until these safeguards are completed.
