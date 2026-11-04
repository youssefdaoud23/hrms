# Local Docker development setup (Ubuntu / WSL2)

This stack is for **local development**, not production. Default admin and database passwords are insecure; do not use real employee data with the defaults.

## Fresh install

1. Install Docker Engine, Compose, and Git. Clone this fork and open the docker directory.
2. Optionally create a local .env file with MARIADB_ROOT_PASSWORD and HRMS_ADMIN_PASSWORD. Without it, development defaults are 123 and admin.
3. Run Docker Compose and inspect the Frappe logs. Initialization fetches Frappe, ERPNext and this HRMS fork.
4. Open http://localhost:8000 on Windows; sign in as Administrator using your configured HRMS_ADMIN_PASSWORD.
5. Verify installed apps using the bench site list-apps command; frappe, erpnext and hrms must appear.

## Reliability improvements

- Startup fails fast and refuses to overwrite an existing incomplete site.
- Local MariaDB client TLS is explicitly disabled by creating ~/.my.cnf with ssl=0 and 0600 permissions if no config already exists. This is development-only.
- MariaDB/Redis readiness is checked before initialization; their health checks are also visible via Compose.
- Frappe listens on 0.0.0.0 inside Docker; host ports 8000 and 9000 bind to 127.0.0.1 by default.
- MariaDB and the Frappe bench directory use named Docker volumes, providing persistence once correctly initialized.
- Image versions and application branches are configurable through .env. Defaults deliberately retain the upstream development-version choices; pin compatible, tested versions for reproducible deployments.

## CRITICAL: existing installations must migrate bench files before switching to this Compose file

The old Compose setup stored /home/frappe/frappe-bench inside the existing container, **not** in a persistent volume. Applying the new Compose file and recreating that container immediately would mount an empty volume over the old bench. This would make existing site files, app code, configuration, and uploads inaccessible.

**Do not directly execute a Compose up/recreate on an existing installation until completing this migration.**

1. Record the current Frappe container ID/name, Compose project name, and MariaDB volume with docker compose ps, docker compose config, and docker volume ls.
2. Stop Frappe writes before taking a consistent backup. Back up /home/frappe/frappe-bench from the **existing** Frappe container outside Docker, as well as the MariaDB data. Confirm the backup includes apps/, env/, Procfile and sites/hrms.localhost/site_config.json.
3. Create and populate the named volume hrms-frappe-bench from the verified bench backup. Preserve the frappe user's ownership and file permissions. Check its content before recreating the existing container.
4. Preserve and reuse the existing MariaDB volume (do not rename the Compose project accidentally). After confirming BOTH datasets are preserved, apply the updated Compose configuration.
5. Verify installed apps, uploaded files, database connectivity and http://localhost:8000. Keep backups until verified.

Do not run docker compose down -v, bench reinstall or bench new-site --force to perform this migration.

## Helpful one-line commands

- Container status: docker compose ps
- Application logs: docker compose logs --tail=100 frappe
- Installed apps: docker compose exec frappe bash -lc 'cd /home/frappe/frappe-bench && bench --site hrms.localhost list-apps'
- HTTP check: curl -I --max-time 10 http://localhost:8000

If the old installation reports that tabDefaultValue is missing, site bootstrap did not complete. Back up the files, inspect whether the database is empty, and repair it explicitly rather than resetting data on startup.

Changing HRMS_HOST_BIND from 127.0.0.1 to a public interface can expose an insecure development app. Never do so with default passwords, no TLS, or real HR records.
