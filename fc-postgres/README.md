# fc-postgres

Shared PostgreSQL image for friendscolony, built on `fc-os` (Ubuntu 26.04). pgAdmin 4 runs in the same
container. It holds no project schema: a project's database image builds `FROM fc-postgres:<version>`
in its own repo (e.g. `foresight/docker/database`).

| File | Purpose |
|---|---|
| `dockerfile` | fc-os + PostgreSQL + gosu + pgAdmin 4 |
| `fc-entrypoint.sh` | Creates the cluster on first start, runs `/docker-entrypoint-initdb.d`, starts pgAdmin, then postgres |
| `pgadmin/config_local.py` | pgAdmin settings: desktop mode, data in `/var/lib/pgadmin`, PostgreSQL tools from the container |
| `build.bat [PG_VERSION] [OS_VERSION]` | Builds `fc-postgres:<PG_VERSION>` (defaults `18`, `ubuntu26.04`) |
| `build18.bat` | PostgreSQL 18 |

PostgreSQL comes from Ubuntu's own packages when Ubuntu has that version (26.04 ships 18), otherwise from
the PostgreSQL project's apt repo.

## Environment variables (read by the entrypoint)

| Variable | Default | Notes |
|---|---|---|
| `POSTGRES_USER` | `postgres` | Superuser created at init. Project images set it with `ENV` |
| `POSTGRES_PASSWORD` | (required) | From the project's git-ignored `.env`; or `POSTGRES_PASSWORD_FILE` |
| `POSTGRES_DB` | `postgres` | Database created at init, owned by `POSTGRES_USER` |
| `POSTGRES_INITDB_ARGS` | `--encoding=UTF8 --locale=en_US.UTF-8` | Extra `initdb` flags |
| `PGADMIN_ENABLED` | `true` | `false` starts the container without pgAdmin |
| `PGADMIN_SERVER_NAME` | `$POSTGRES_DB` | Name of the registered server in pgAdmin |
| `PGADMIN_SERVER_GROUP` | `friendscolony` | Server group in pgAdmin |

User, password and init scripts only apply when the data volume is empty.

## pgAdmin

pgAdmin (`PGADMIN_VERSION` build arg, default 9.18; the 9.19 wheel lacks the built web UI) is served by
gunicorn on container port **5050**. On every start the entrypoint registers the container's database
over the local socket, which is trusted, so no password is stored or asked for.

- There is no pgAdmin login (desktop mode). **Publish 5050 on `127.0.0.1` only.**
- Its settings live in `/var/lib/pgadmin`; mount a volume there to keep them. Log:
  `/var/lib/pgadmin/gunicorn.log`.
