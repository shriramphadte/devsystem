#!/usr/bin/env bash
# fc-postgres entrypoint: initialises the cluster on first start, runs /docker-entrypoint-initdb.d,
# then runs postgres as the postgres user. Project images set POSTGRES_USER / POSTGRES_DB defaults
# with ENV and add their init scripts to /docker-entrypoint-initdb.d.
set -euo pipefail

: "${PGDATA:=/var/lib/postgresql/data}"
: "${POSTGRES_USER:=postgres}"
: "${POSTGRES_DB:=postgres}"
: "${POSTGRES_INITDB_ARGS:=--encoding=UTF8 --locale=en_US.UTF-8}"

# Allow the password to come from a Docker secret file
if [[ -n "${POSTGRES_PASSWORD_FILE:-}" && -f "${POSTGRES_PASSWORD_FILE}" ]]; then
  POSTGRES_PASSWORD="$(< "${POSTGRES_PASSWORD_FILE}")"
fi

if [[ "${1:-}" == "postgres" && "$(id -u)" == "0" ]]; then
  mkdir -p "$PGDATA" /var/run/postgresql /var/lib/pgadmin
  chown -R postgres:postgres "$PGDATA" /var/run/postgresql /var/lib/pgadmin
  chmod 700 "$PGDATA"
  exec gosu postgres "$BASH_SOURCE" "$@"
fi

if [[ "${1:-}" == "postgres" && ! -s "$PGDATA/PG_VERSION" ]]; then
  if [[ -z "${POSTGRES_PASSWORD:-}" ]]; then
    echo "fc-postgres: POSTGRES_PASSWORD (or POSTGRES_PASSWORD_FILE) must be set for first-time init." >&2
    exit 1
  fi

  echo "fc-postgres: initialising new cluster in $PGDATA (PostgreSQL $(cat /etc/fc-pg-major))"
  pwfile="$(mktemp)"
  printf '%s' "$POSTGRES_PASSWORD" > "$pwfile"
  # shellcheck disable=SC2086
  initdb -D "$PGDATA" -U "$POSTGRES_USER" --pwfile="$pwfile" --auth-local=trust --auth-host=scram-sha-256 $POSTGRES_INITDB_ARGS
  rm -f "$pwfile"

  {
    echo "listen_addresses = '*'"
    echo "password_encryption = scram-sha-256"
  } >> "$PGDATA/postgresql.conf"
  {
    echo "host all all 0.0.0.0/0 scram-sha-256"
    echo "host all all ::/0 scram-sha-256"
  } >> "$PGDATA/pg_hba.conf"

  # Temporary local-only server for setup
  pg_ctl -D "$PGDATA" -o "-c listen_addresses=''" -w start

  if [[ "$POSTGRES_DB" != "postgres" ]]; then
    psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres \
      -c "CREATE DATABASE \"${POSTGRES_DB}\" OWNER \"${POSTGRES_USER}\";"
  fi

  for f in /docker-entrypoint-initdb.d/*; do
    [[ -e "$f" ]] || continue
    case "$f" in
      *.sh)     echo "fc-postgres: running $f"; bash "$f" ;;
      *.sql)    echo "fc-postgres: running $f"; psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$f" ;;
      *.sql.gz) echo "fc-postgres: running $f"; gunzip -c "$f" | psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" ;;
      *)        echo "fc-postgres: ignoring $f" ;;
    esac
  done

  pg_ctl -D "$PGDATA" -m fast -w stop
  echo "fc-postgres: init complete."
fi

# pgAdmin: registers this database (over the local socket, which is trusted, so no password is
# stored) and serves the web UI on port 5050 in the background. PGADMIN_ENABLED=false turns it off.
# pgAdmin asks for a password unless one is saved, so the server gets a passfile with a placeholder:
# socket connections use trust auth and never check it.
if [[ "${1:-}" == "postgres" && "${PGADMIN_ENABLED:-true}" != "false" ]]; then
  servers="/var/lib/pgadmin/servers.json"
  passfile="/var/lib/pgadmin/pgpass"
  printf '*:*:*:*:local-socket-trust\n' > "$passfile"
  chmod 600 "$passfile"
  cat > "$servers" <<EOF
{"Servers": {"1": {
  "Name": "${PGADMIN_SERVER_NAME:-$POSTGRES_DB}",
  "Group": "${PGADMIN_SERVER_GROUP:-friendscolony}",
  "Host": "/var/run/postgresql",
  "Port": 5432,
  "MaintenanceDB": "${POSTGRES_DB}",
  "Username": "${POSTGRES_USER}",
  "PassFile": "${passfile}",
  "SSLMode": "prefer"
}}}
EOF
  (
    cd /opt/pgadmin/app
    /opt/pgadmin/bin/python setup.py setup-db >/dev/null 2>&1 || true
    /opt/pgadmin/bin/python setup.py load-servers "$servers" --replace >/dev/null 2>&1 \
      || echo "fc-postgres: pgAdmin could not register the server; add it by hand." >&2
    exec /opt/pgadmin/bin/gunicorn --chdir /opt/pgadmin/app --bind 0.0.0.0:5050 \
      --workers 1 --threads 25 --timeout 86400 --access-logfile - pgAdmin4:app
  ) > /var/lib/pgadmin/gunicorn.log 2>&1 &
  echo "fc-postgres: pgAdmin starting on port 5050 (log /var/lib/pgadmin/gunicorn.log)"
fi

exec "$@"
