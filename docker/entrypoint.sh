#!/bin/sh

set -eu

cd /app/server

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
