# pgAdmin settings for fc-postgres. pgAdmin runs inside the database container in desktop mode
# (no pgAdmin login, no master password): publish its port on 127.0.0.1 only.
SERVER_MODE = False
MASTER_PASSWORD_REQUIRED = False
UPGRADE_CHECK_ENABLED = False

DATA_DIR = "/var/lib/pgadmin"
SQLITE_PATH = "/var/lib/pgadmin/pgadmin4.db"
SESSION_DB_PATH = "/var/lib/pgadmin/sessions"
STORAGE_DIR = "/var/lib/pgadmin/storage"
LOG_FILE = "/var/lib/pgadmin/pgadmin4.log"

# pg_dump / pg_restore / psql for backup and restore come from the container's PostgreSQL.
DEFAULT_BINARY_PATHS = {"pg": "/usr/local/pgbin"}
