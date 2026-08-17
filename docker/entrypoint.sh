#!/bin/sh

set -eu

cd /app/server

create_secret() {
  secret_file="$1"
  configured_value="$2"

  if [ ! -s "$secret_file" ]; then
    if [ -n "$configured_value" ]; then
      printf '%s' "$configured_value" > "$secret_file"
    else
      head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$secret_file"
    fi
  fi

  chmod 0444 "$secret_file"
}

initialize_secrets() {
  if [ "$(id -u)" -ne 0 ]; then
    printf '%s\n' 'Secret initialization must run as root.' >&2
    exit 1
  fi

  umask 077
  create_secret /secrets/mysql-root/password "${MYSQL_ROOT_PASSWORD:-}"
  create_secret /secrets/database/password "${DB_PASSWORD:-}"
  create_secret /secrets/redis/password "${REDIS_PASSWORD:-}"
  create_secret /secrets/rabbitmq/password "${RABBITMQ_PASSWORD:-}"

  redis_password="$(cat /secrets/redis/password)"
  cat > /secrets/redis/redis.conf <<EOF
bind 0.0.0.0
protected-mode yes
port 6379
dir /data
appendonly yes
requirepass ${redis_password}
EOF

  rabbitmq_password="$(cat /secrets/rabbitmq/password)"
  cat > /secrets/rabbitmq/rabbitmq.conf <<EOF
default_user = ${RABBITMQ_USERNAME:-helpsupport}
default_pass = ${rabbitmq_password}
default_vhost = /
EOF

  chmod 0444 /secrets/redis/redis.conf /secrets/rabbitmq/rabbitmq.conf
  printf '%s\n' 'Internal service secrets and configuration files are ready.'
}

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

load_application_secrets() {
  load_secret DB_PASSWORD /run/secrets/helpsupport-database/password
  load_secret REDIS_PASSWORD /run/secrets/helpsupport-redis/password
  load_secret RABBITMQ_PASSWORD /run/secrets/helpsupport-rabbitmq/password
  load_secret RABBITMQ_MANAGEMENT_PASSWORD /run/secrets/helpsupport-rabbitmq/password
}

run_as_app() {
  if [ "$(id -u)" -eq 0 ]; then
    su-exec app "$@"
  else
    "$@"
  fi
}

exec_as_app() {
  if [ "$(id -u)" -eq 0 ]; then
    exec su-exec app "$@"
  else
    exec "$@"
  fi
}

run_migrations() {
  printf '%s\n' 'Checking database migration status...'
  run_as_app php webman b8:migrate:status

  printf '%s\n' 'Applying database migrations...'
  run_as_app php webman b8:migrate
}

case "${1:-serve}" in
  init-secrets)
    initialize_secrets
    ;;
  serve)
    load_application_secrets
    if [ "${B8_RUN_MIGRATIONS:-1}" = "1" ]; then
      run_migrations
    else
      printf '%s\n' 'Database migrations are disabled (B8_RUN_MIGRATIONS=0).'
    fi
    exec_as_app php start.php start
    ;;
  migrate)
    load_application_secrets
    run_migrations
    ;;
  *)
    load_application_secrets
    exec_as_app "$@"
    ;;
esac
