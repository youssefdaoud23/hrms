# HRMS Docker: WSL2 recovery, operation, and migration

Last reviewed: 2026-11-07. Applies to the fork's main branch, which contains the WSL2 recovery changes from fix/wsl-hrms-docker-persistence-20261107.

> **Important:** This is a development-oriented Frappe Bench Compose setup, not a production-hardened deployment. The current startup script **requires an existing HRMS site configuration**. A fresh clone alone will NOT provision a new site. Never publish the site configuration, MariaDB data, backups, or runtime directory.

## What was found and fixed

On Ubuntu WSL2 (managed node LAPTOP-041MB6QK) the Frappe HRMS web page was initially unavailable because there were no running Docker containers and nothing listening on port 8000.

The WSL environment had Docker Engine 29.1.3 but did **not** recognize the Docker Compose v2 subcommand. It had the legacy standalone docker-compose 1.29.2, which worked. This is a CLI installation difference, not a reason to run Docker as root.

The original Compose file defined MariaDB, Redis, and Frappe, but mounted only the docker directory at /workspace. The Frappe Bench was created in the container's own writable filesystem and could disappear when the container was removed. The original init.sh also kept running bench init even after detecting an existing bench, and used bench new-site --force. That made it unsafe for an existing site.

The fix:
- Adds a persistent bind mount, ./runtime:/home/frappe/persist.
- Initializes the bench only if it does not already exist, and refuses to overwrite a partial bench.
- Installs ERPNext and HRMS source only if missing.
- Reuses the recovered site configuration instead of calling bench new-site --force.
- Creates missing site logs, public/files, and private/files directories before bench start.
- Makes the Bench listen on 0.0.0.0 so container port 8000 is reachable through the host mapping.
- Ignores docker/runtime/ in Git so local application files and site credentials are not committed.

During the repair, Frappe initially returned HTTP 500 because sites/hrms.localhost/logs/database.log could not be created: its parent directory was absent. Creating that directory immediately changed the login page response to HTTP 200.

## Observed result on the original WSL installation

On 2026-11-07:
- docker_mariadb_1, docker_redis_1, and docker_frappe_1 were all running.
- Frappe 17.x.x-develop, ERPNext 17.x.x-develop, and HRMS 17.0.0-dev were registered with the restored site.
- GET / returned HTTP 200 and rendered the login page.
- GET /api/method/frappe.ping returned HTTP 200.
- An application CSS asset also returned HTTP 200.
- The existing recovered site database had 953 tables.
- Successful user login from Windows was **not** independently verified; Windows PowerShell interoperability was unavailable inside that WSL session.

This proves local HTTP and basic application availability, not complete functional or production readiness.

## Files and persistence

| File or location | Role |
| --- | --- |
| docker/docker-compose.yml | MariaDB, Redis, and Frappe service definitions; publishes 8000 and 9000 |
| docker/init.sh | Safe idempotent-ish Bench startup for an existing site |
| docker/.gitignore | Excludes runtime/ from Git |
| docker/runtime/frappe-bench/ | Persistent Bench, apps, configuration, site files, and logs |
| docker/runtime/recovery/site_config.json | Private existing-site credentials used when the site's config is absent |
| Docker volume docker_mariadb-data | Persistent MariaDB contents under the original Compose project name |

The **Docker database volume and the Frappe runtime bind mount are separate**. Back up both. Do not use docker compose down -v or docker volume prune without a separately verified restore.

The original WSL recovery data was stored privately at /home/joe/hrms-backup/recovery-20261107/:
- existing-sites.sql.gz (gzip test passed), a dump of two site database schemas/data
- site_config.json containing private database credentials
- copies of the original Docker Compose file and init.sh

A separate folder /home/joe/hrms-backup/hrms.localhost-20261104-191221/ contained historical site public/private files, logs, and configuration. The database SQL dump does **not** include attachments; migrate the required public and private files separately. None of those backup files are part of this GitHub repository.

## Using an existing installation on the same machine

In the repository's docker directory, use the command supported by your installation:

~~~bash
cd ~/hrms/docker && docker-compose up -d
~~~

On an environment with Docker Compose v2, use:

~~~bash
cd ~/hrms/docker && docker compose up -d
~~~

Inspect containers and logs:

~~~bash
cd ~/hrms/docker && docker-compose ps
cd ~/hrms/docker && docker-compose logs --tail=100 frappe
~~~

Test local HTTP:

~~~bash
curl -I http://localhost:8000/
curl -I http://localhost:8000/api/method/frappe.ping
~~~

The expected host-side URL on WSL2 is http://localhost:8000, assuming WSL localhost forwarding works. On a separate server use its trusted-network address. The startup is a development server; do not expose port 8000 or 9000 directly to the public internet.

## Migrating an existing HRMS site to a new server

These steps describe an **existing-site restore**, not a fresh-install workflow. Use a private target server/WSL instance. Install Git, Docker Engine, and the Compose plugin (or standalone Compose), and make sure your Linux user has permission to use Docker.

1. Clone the tested main branch:

~~~bash
git clone --branch main --single-branch https://github.com/youssefdaoud23/hrms.git
cd hrms/docker
~~~

2. Privately transfer the backup and matching site_config.json to the destination user, for example under ~/hrms-transfer. Do not commit these files, paste their contents into a ticket, or expose them in shell history. Restore private/public attachment files separately if needed. Confirm that backup data and application versions match the target before any restore.

3. Copy only the site configuration into the ignored runtime recovery folder:

~~~bash
mkdir -p runtime/recovery && chmod 700 runtime/recovery
install -m 600 ~/hrms-transfer/site_config.json runtime/recovery/site_config.json
~~~

4. Start MariaDB and Redis without starting the web service yet:

~~~bash
docker compose up -d mariadb redis
~~~

For standalone Compose, replace every occurrence of docker compose with docker-compose.

5. Restore the SQL dump to a **new or explicitly chosen empty** target database volume. Do not restore onto an existing populated site without a separate migration plan:

~~~bash
set -o pipefail; gzip -dc ~/hrms-transfer/existing-sites.sql.gz | docker compose exec -T mariadb sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mariadb -u root'
~~~

6. The historical dump included the site databases but **not MariaDB's mysql system-user database**. Recreate the application's user and database permissions using the values from the private site_config.json. The following local script does not print or embed the actual password in the command line; its generated SQL is piped to the database:

~~~bash
python3 - <<'PY' | docker compose exec -T mariadb sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mariadb -u root'
import json, re
from pathlib import Path
c = json.loads(Path("runtime/recovery/site_config.json").read_text())
db = c["db_name"]
user = c.get("db_user") or db
password = c["db_password"]
assert re.fullmatch(r"[A-Za-z0-9_]+", db), "Unexpected database name"
def quoted(value):
    return "'" + str(value).replace("\\", "\\\\").replace("'", "\\'") + "'"
identity = quoted(user) + "@'%'"
print("CREATE USER IF NOT EXISTS " + identity + " IDENTIFIED BY " + quoted(password) + ";")
print("ALTER USER " + identity + " IDENTIFIED BY " + quoted(password) + ";")
print("GRANT ALL PRIVILEGES ON " + chr(96) + db + chr(96) + ".* TO " + identity + ";")
PY
~~~

Run this only against a dedicated destination database server. Before using it in a shared MariaDB server, review existing grants/users and avoid changing another application's user. Remove transferred copies of private configuration only after confirming their safe storage and restore requirements.

7. Start the application, and check status:

~~~bash
docker compose up -d
docker compose ps
docker compose logs --tail=100 frappe
curl -I http://localhost:8000/
~~~

The Frappe startup process downloads/builds the latest develop versions if the persistent bench is missing; its initial build may perform extensive installation. Inspect logs and verify version compatibility rather than assuming an immediate login page.

8. Validate: login, HRMS modules, employee records, permissions, background jobs, Redis, attachments, and any customizations. HTTP 200 alone is not enough. Save a fresh verified backup before upgrading or migrating data.

## Fresh installations are **not** supported yet

The current safe script refuses to start if neither sites/hrms.localhost/site_config.json nor runtime/recovery/site_config.json exists. This is intentional: the repaired stack must not quietly create or overwrite site data.

For a *brand-new* site, a separately tested first-run provisioning flow needs to be implemented: generate secrets outside Git, create the site, install the requested apps, configure DB grants, set default site, and verify migrations and background jobs. Do **not** re-enable the old bench new-site --force startup behavior.

## Remaining risks and recommended follow-up

1. **Hard-coded MariaDB root password** remains in docker/docker-compose.yml, inherited from the original setup. Replace it with a protected environment/secret configuration and rotate affected credentials before any shared or production deployment. Do not blindly change the env value for an existing volume: the database already has a persisted root password.
2. **Unpinned components:** frappe/bench:latest and Frappe/ERPNext/HRMS develop are moving targets. Pin compatible versions/digests and test upgrades in isolation.
3. **Development service:** bench start/Werkzeug is not a production web server, and Redis has no application-level authentication in this sample stack. Prefer the official [Frappe Docker](https://github.com/frappe/frappe_docker) deployment for production.
4. **Backups:** the SQL dump's gzip stream passed validation, and the restored site worked locally, but a full disaster-recovery drill including attachments, users/grants, background jobs, and upgrades has not been certified.
5. **Deployment automation:** introduce a tested fresh-install option, healthchecks, restart policies, secure secret management, and separate existing-site restoration tooling before promising two-command deployments.
6. **GitHub scope:** this documentation and the Docker fixes live on this fork's main branch; the original public frappe/hrms project is unchanged.

See [Fork maintenance and upstream status](../docs/FORK_MAINTENANCE.md) for branch strategy and update commands.
