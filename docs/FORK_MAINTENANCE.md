# HRMS fork: branch policy and upstream status

Last checked: 2026-11-07. This document describes the GitHub fork https://github.com/youssefdaoud23/hrms and the public source https://github.com/frappe/hrms.

## Branches

| Branch | Purpose |
| --- | --- |
| main | User-maintained working branch. Created from the previously tested fix/wsl-hrms-docker-persistence-20261107 branch, then given operational documentation. |
| develop | Fork's upstream-style tracking branch; not overwritten or rebased when main was created. |
| fix/wsl-hrms-docker-persistence-20261107 | Historical branch containing the 3 originally verified Docker repair commits. |
| Public frappe/hrms develop | Official upstream source of new HRMS changes and fixes. |

At the time main was created, GitHub still reported **develop as the fork's default branch**. Creating a branch does not automatically change the default GitHub branch. An owner can change it in GitHub repository Settings > General > Default branch. The original public repository also uses develop as its default branch.

## Exact upstream divergence measured on November 7, 2026

The comparison was made directly from freshly fetched Git refs, rather than estimated from file dates.

- Official upstream develop: 881610257 (2026-11-06, Merge pull request #5608 from asmitahase/appointment-letter-layout).
- Fork develop: 159548fa6 (2026-11-03, Merge pull request #5594 from barredterra/bump-po-review-3).
- Fork's original Docker fix branch: 11d28bc9b (2026-11-07), based on 159548fa6.
- Upstream develop compared with fork develop: **34 upstream-only commits, 0 fork-only**.
- Upstream develop compared with the original Docker fix branch: **34 upstream-only commits, 3 fork-only**.

The upstream-only count will change as upstream advances. Documentation commits added to main increase the fork-only count, but not the number of upstream commits that are missing. Therefore, re-measure before an actual merge or upgrade.

The latest upstream batch includes changes to appointment-letter behavior and related HRMS functionality. Do not assume a newer Git checkout is automatically compatible with an already running Frappe/ERPNext/HRMS installation. Frappe, ERPNext, HRMS, and the database migration state must be treated as a matched stack.

## Inspect current divergence safely

In a clone of **your fork**:

~~~bash
git remote -v
git remote add upstream https://github.com/frappe/hrms.git
git fetch upstream develop
git fetch origin develop main
git rev-list --left-right --count upstream/develop...origin/develop
git rev-list --left-right --count upstream/develop...origin/main
git log --oneline origin/main..upstream/develop
~~~

If a remote named upstream already exists, check its URL and skip git remote add upstream. The rev-list command prints two numbers: commits available only on the left reference, then commits available only on the right reference.

**These are read-only comparison commands, except for fetching remote-tracking metadata.** They do not update your working branch or running Docker installation.

## Recommended maintenance workflow

1. Use main for your tested, customized Docker setup. Develop remains a reference for public project changes.
2. Fetch upstream before planning an update. Inspect file changes, especially Docker files, migration scripts, and dependencies.
3. Create a new integration branch based on main rather than merging unreviewed changes straight into main.
4. Merge or cherry-pick upstream changes carefully in that integration branch, resolving conflicts without discarding your persistent-storage and safe-init protections.
5. Test on disposable or separately backed-up data: Frappe/ERPNext/HRMS compatibility, migrations, app registrations, authentication, scheduler/workers, user permissions, and HRMS workflows.
6. Only after passing verification, merge the tested integration branch into main. Keep a rollback commit/tag and verified backups of both the DB volume and site files.
7. Never make a live database upgrade solely to reduce the commit-behind count.

Avoid automatically hard-resetting main to upstream/develop, because that would discard fork-specific work. Avoid force-pushing main unless there is an exceptional and separately reviewed need.

## What has and has not been done

Completed:
- Created main from the verified Docker-fix branch.
- Preserved the existing fork develop and historical fix branch.
- Added instructions explaining the WSL2 failure, the fixes, existing-site restoration and remaining deployment limitations.
- Confirmed via the live WSL setup that the login page, API, and static assets returned HTTP 200, and the three app sources were registered.

Not yet done:
- Applied the 34 newer upstream commits to main.
- Converted the development-oriented Compose setup into a production deployment.
- Implemented safe fully automatic first-time site creation.
- Completed a new-machine end-to-end restore test, verified Windows browser login, or certified disaster recovery.
- Removed the hardcoded database root password, pinned versions, and hardened the deployment.
- Changed GitHub's default branch setting automatically (check the current repository settings before assuming main is the default).

See [Docker operations and migration guide](../docker/README.md).
