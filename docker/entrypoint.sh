#!/bin/sh

set -eu

cd /app/server

load_secret() {
  variable_name="$1"
  secret_file="$2"
  current_value="$(printenv "$variable_name" 2>/dev/null || true)"

  if [ -z "$current_value" ]; then
    if [ ! -r "$secret_file" ]; then
      printf 'Required secret file is not readable: %s\n' "$secret_file" >&2
      exit 1
    fi

    secret_value="$(cat "$secret_file")"
    if [ -z "$secret_value" ]; then
      printf 'Required secret file is empty: %s\n' "$secret_file" >&2
      exit 1
    fi

    export "$variable_name=$secret_value"
  fi
}

load_secret DB_PASSWORD /run/secrets/helpsupport-database/password
load_secret REDIS_PASSWORD /run/secrets/helpsupport-redis/password
load_secret RABBITMQ_PASSWORD /run/secrets/helpsupport-rabbitmq/password
load_secret RABBITMQ_MANAGEMENT_PASSWORD /run/secrets/helpsupport-rabbitmq/password

run_migrations() {
  printf '%s\n' 'Checking database migration status...'
  php webman b8:migrate:status

  printf '%s\n' 'Previewing database migrations...'
  php webman b8:migrate --dry-run

  printf '%s\n' 'Applying database migrations...'
  php webman b8:migrate
}

case "${1:-serve}" in
  serve)
    if [ "${B8_RUN_MIGRATIONS:-0}" = "1" ]; then
      run_migrations
    else
      printf '%s\n' 'Database migrations are disabled (B8_RUN_MIGRATIONS=0).'
    fi
    exec php start.php start
    ;;
  migrate)
    run_migrations
    ;;
  *)
    exec "$@"
    ;;
esac
