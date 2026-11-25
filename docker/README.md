# HRMS Docker integration candidate

Development only. This is not a production deployment. Do not run this Compose stack over the November 7 installation. The historical recovery guide is in [RECOVERY_20261107.md](RECOVERY_20261107.md).

## Fresh installation

Clone the desired release branch into a new directory. Use a unique Compose project name and unused ports. Copy .env.example to .env (chmod 600), set unique passwords, and set HRMS_BRANCH to the branch being tested. Run docker compose -p hrms-test up -d. For a fresh site the database server must be empty. Existing config is verified rather than recreated. The web port defaults to loopback only. The runtime bind mount and database volume survive container recreation; do not delete either.

## Existing site

Do not attach a MariaDB 10.8 physical volume to the default 11.8 image. Use the same MariaDB version/image and compatible Frappe/ERPNext/HRMS revisions as the backup. Restore a copy of the full Bench (at runtime/frappe-bench), site config, public/private files and database into an independent project/volume. Set HRMS_MODE=restore, matching DB root password and image, and unused ports. Restore mode refuses to create a site. If the database dump excludes grants, restore grants separately before starting. A site with missing app sources, incomplete database or missing configuration requires manual recovery.

## Limitations and verification

The image versions are configurable; tags and develop branches are not immutable. Pin tested digests and app revisions before production. Local MariaDB client SSL compatibility is for this isolated development network only; do not disable TLS for remote production DBs. Compose environment variables are visible to Docker administrators. CI smoke-tests fresh provisioning, HTTP, registered apps and persistence across container recreation. Test an actual copy of the existing backup and application workflows before any migration. Do not use down -v on a real installation.
