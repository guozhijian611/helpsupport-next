#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$ROOT_DIR/saiadmin-artd"
SERVER_DIR="$ROOT_DIR/server"
PACKAGES_DIR="$ROOT_DIR/packages"

REMOTE="${REMOTE:-b8org}"
REMOTE_ENV="${REMOTE_ENV:-LC_ALL=C LANG=C}"
REMOTE_OTEL_DISABLED_INSTRUMENTATIONS="${REMOTE_OTEL_DISABLED_INSTRUMENTATIONS:-pdo}"
SSH_OPTS=(-o SendEnv=NONE -o SetEnv=LC_ALL=C -o SetEnv=LANG=C)
RSYNC_SSH="${RSYNC_SSH:-ssh -o SendEnv=NONE -o SetEnv=LC_ALL=C -o SetEnv=LANG=C}"
REMOTE_ROOT="${REMOTE_ROOT:-/www/wwwroot/helpsupport-next}"
REMOTE_ROOT="${REMOTE_ROOT%/}"
REMOTE_SERVER_DIR="$REMOTE_ROOT/server"
REMOTE_PACKAGES_DIR="$REMOTE_ROOT/packages"
REMOTE_PUBLIC_DIR="$REMOTE_SERVER_DIR/public"
REMOTE_ADMIN_DIR="$REMOTE_PUBLIC_DIR/admin"
REMOTE_STORAGE_DIR="$REMOTE_PUBLIC_DIR/storage"
REMOTE_BACKUP_DIR="$REMOTE_ROOT/backups"

LOCAL_DB_HOST="${LOCAL_DB_HOST:-127.0.0.1}"
LOCAL_DB_PORT="${LOCAL_DB_PORT:-3306}"
LOCAL_DB_NAME="${LOCAL_DB_NAME:-b8aiadmin}"
LOCAL_DB_USER="${LOCAL_DB_USER:-root}"
LOCAL_DB_PASS="${LOCAL_DB_PASS:-root}"

REMOTE_DB_HOST="${REMOTE_DB_HOST:-127.0.0.1}"
REMOTE_DB_PORT="${REMOTE_DB_PORT:-3306}"
REMOTE_DB_NAME="${REMOTE_DB_NAME:-b8aiadmin}"
REMOTE_DB_USER="${REMOTE_DB_USER:-b8aiadmin}"
REMOTE_DB_PASS="${REMOTE_DB_PASS:-b8aiadmin}"

BUILD_ADMIN="${BUILD_ADMIN:-}"
SYNC_DB="${SYNC_DB:-}"
ADMIN_PUBLIC_BASE="${ADMIN_PUBLIC_BASE:-/admin/}"
DRY_RUN="${DRY_RUN:-}"
FIX_PERMS="${FIX_PERMS:-1}"
RESTART_WEBMAN="${RESTART_WEBMAN:-1}"
CHECK_WEBMAN_DISABLED_FUNCTIONS="${CHECK_WEBMAN_DISABLED_FUNCTIONS:-1}"
if [[ -t 0 ]]; then
  INTERACTIVE="${INTERACTIVE:-1}"
else
  INTERACTIVE="${INTERACTIVE:-0}"
fi

ADMIN_EXCLUDES=(
  --exclude='storage/'
  --exclude='.user.ini'
)
SERVER_EXCLUDES=(
  --exclude='.env'
  --exclude='runtime/'
  --exclude='public/admin/'
  --exclude='public/h5/'
  --exclude='public/storage/'
  --exclude='public/.user.ini'
)

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "缺少命令：$1" >&2
    exit 1
  fi
}

log() {
  printf '\n==> %s\n' "$1"
}

prompt_yes_no() {
  local question="$1"
  local default_answer="$2"
  local answer=""
  local suffix="[y/N]"

  if [[ "$default_answer" == "y" ]]; then
    suffix="[Y/n]"
  fi

  read -r -p "$question $suffix " answer
  answer="${answer:-$default_answer}"

  case "$answer" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

if [[ "$INTERACTIVE" == "1" ]]; then
  if [[ -z "$BUILD_ADMIN" ]]; then
    if prompt_yes_no "是否先编译 admin 前端？" "n"; then
      BUILD_ADMIN=1
    else
      BUILD_ADMIN=0
    fi
  fi

  if [[ -z "$SYNC_DB" ]]; then
    if prompt_yes_no "是否同步本地数据库到服务器？这会覆盖服务器 ${REMOTE_DB_NAME} 库" "n"; then
      SYNC_DB=1
    else
      SYNC_DB=0
    fi
  fi

  if [[ -z "$DRY_RUN" ]]; then
    if prompt_yes_no "是否只预览，不实际同步？" "n"; then
      DRY_RUN=1
    else
      DRY_RUN=0
    fi
  fi
else
  BUILD_ADMIN="${BUILD_ADMIN:-0}"
  SYNC_DB="${SYNC_DB:-0}"
  DRY_RUN="${DRY_RUN:-0}"
fi

RSYNC_FLAGS=(-azh --delete -e "$RSYNC_SSH")
ADMIN_RSYNC_FLAGS=(-azh --delete -e "$RSYNC_SSH")
STORAGE_RSYNC_FLAGS=(-azh --progress -e "$RSYNC_SSH")
if [[ "$DRY_RUN" == "1" ]]; then
  RSYNC_FLAGS+=(-n)
  ADMIN_RSYNC_FLAGS+=(-n)
  STORAGE_RSYNC_FLAGS+=(-n)
fi

log "部署配置"
echo "服务器：${REMOTE}"
echo "远程命令环境：${REMOTE_ENV}"
echo "rsync SSH：${RSYNC_SSH}"
echo "目标目录：${REMOTE_ROOT}"
echo "server 目标：${REMOTE_SERVER_DIR}"
echo "packages 目标：${REMOTE_PACKAGES_DIR}"
echo "admin 目标：${REMOTE_ADMIN_DIR}"
echo "编译 admin：${BUILD_ADMIN}"
echo "同步数据库：${SYNC_DB}"
echo "admin 基础路径：${ADMIN_PUBLIC_BASE}"
echo "预览模式：${DRY_RUN}"
echo "修复权限：${FIX_PERMS}"
echo "重启 Webman：${RESTART_WEBMAN}"
echo "检查 Webman 禁用函数：${CHECK_WEBMAN_DISABLED_FUNCTIONS}"
echo "远程禁用 OpenTelemetry 自动埋点：${REMOTE_OTEL_DISABLED_INSTRUMENTATIONS}"
echo "OpenTelemetry 提醒：服务端 PHP 如需上报链路或指标，需要安装并启用 opentelemetry 扩展。"
echo "同步 storage：增量同步 ${SERVER_DIR}/public/storage -> ${REMOTE_STORAGE_DIR}（不删除远程已有文件）"
if [[ "$SYNC_DB" == "1" ]]; then
  echo "数据库同步：将覆盖远程 ${REMOTE_DB_USER}@${REMOTE_DB_HOST}:${REMOTE_DB_PORT}/${REMOTE_DB_NAME}"
  echo "数据库备份：覆盖前备份到 ${REMOTE}:${REMOTE_BACKUP_DIR}"
else
  echo "数据库同步：关闭。本次不会覆盖远程数据库。"
fi

if [[ "$INTERACTIVE" == "1" ]]; then
  if ! prompt_yes_no "确认开始执行？" "y"; then
    echo "已取消"
    exit 0
  fi
fi

require_command ssh
require_command rsync

if [[ "$SYNC_DB" == "1" && "$DRY_RUN" != "1" ]]; then
  require_command mysqldump
fi

if [[ "$CHECK_WEBMAN_DISABLED_FUNCTIONS" == "1" ]]; then
  if [[ "$DRY_RUN" == "1" ]]; then
    log "预览模式：跳过远程 Webman 禁用函数检查"
    echo "将执行：ssh ${REMOTE} \"${REMOTE_ENV} curl -Ss https://www.workerman.net/webman/check | php\""
  else
    log "检查远程 PHP 禁用函数"
    echo "参考：https://www.workerman.net/doc/webman/others/disable-function-check.html"
    if ! ssh "${SSH_OPTS[@]}" "$REMOTE" "${REMOTE_ENV} curl -Ss https://www.workerman.net/webman/check | php"; then
      echo "远程 PHP 禁用函数检查失败。请按 Webman 文档解除禁用后再部署：" >&2
      echo "https://www.workerman.net/doc/webman/others/disable-function-check.html" >&2
      exit 1
    fi
  fi
else
  log "跳过 Webman 禁用函数检查"
fi

if [[ "$BUILD_ADMIN" == "1" ]]; then
  require_command pnpm

  log "编译 admin 前端"
  (
    cd "$FRONTEND_DIR"
    VITE_BASE_URL="$ADMIN_PUBLIC_BASE" pnpm build
  )
else
  log "跳过 admin 前端编译"
  echo "如需编译后再部署，执行：BUILD_ADMIN=1 ./deploy.sh"
fi

ADMIN_DIST_READY=1
if [[ ! -d "$FRONTEND_DIR/dist" ]]; then
  ADMIN_DIST_READY=0
  echo "前端构建目录不存在：$FRONTEND_DIR/dist" >&2
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "预览模式下继续执行；实际部署前请生成 dist，或使用 BUILD_ADMIN=1 ./deploy.sh" >&2
  else
    echo "请先在 $FRONTEND_DIR 生成 dist，或使用 BUILD_ADMIN=1 ./deploy.sh" >&2
    exit 1
  fi
fi

if [[ "$DRY_RUN" == "1" ]]; then
  log "预览模式：跳过创建服务器目录"
  echo "将执行：ssh ${REMOTE} \"${REMOTE_ENV} mkdir -p '${REMOTE_SERVER_DIR}' '${REMOTE_PACKAGES_DIR}' '${REMOTE_PUBLIC_DIR}' '${REMOTE_ADMIN_DIR}' '${REMOTE_STORAGE_DIR}'\""
else
  log "创建服务器目录"
  ssh "${SSH_OPTS[@]}" "$REMOTE" "${REMOTE_ENV} mkdir -p '$REMOTE_SERVER_DIR' '$REMOTE_PACKAGES_DIR' '$REMOTE_PUBLIC_DIR' '$REMOTE_ADMIN_DIR' '$REMOTE_STORAGE_DIR'"
fi

if [[ -d "$PACKAGES_DIR" ]]; then
  log "同步 packages 到 ${REMOTE}:${REMOTE_PACKAGES_DIR}"
  rsync "${RSYNC_FLAGS[@]}" "$PACKAGES_DIR/" "$REMOTE:$REMOTE_PACKAGES_DIR/"
else
  log "跳过 packages 同步"
  echo "本地目录不存在：$PACKAGES_DIR"
fi

log "同步 server 到 ${REMOTE}:${REMOTE_SERVER_DIR}"
rsync "${RSYNC_FLAGS[@]}" "${SERVER_EXCLUDES[@]}" "$SERVER_DIR/" "$REMOTE:$REMOTE_SERVER_DIR/"

if [[ -d "$SERVER_DIR/public/storage" ]]; then
  log "增量同步 storage 到 ${REMOTE}:${REMOTE_STORAGE_DIR}"
  rsync "${STORAGE_RSYNC_FLAGS[@]}" "$SERVER_DIR/public/storage/" "$REMOTE:$REMOTE_STORAGE_DIR/"
else
  log "跳过 storage 同步"
  echo "本地目录不存在：$SERVER_DIR/public/storage"
fi

if [[ "$ADMIN_DIST_READY" == "1" ]]; then
  log "同步 admin 到 ${REMOTE}:${REMOTE_ADMIN_DIR}"
  rsync "${ADMIN_RSYNC_FLAGS[@]}" "${ADMIN_EXCLUDES[@]}" "$FRONTEND_DIR/dist/" "$REMOTE:$REMOTE_ADMIN_DIR/"
else
  log "预览模式：跳过 admin 同步"
  echo "本地目录不存在：$FRONTEND_DIR/dist"
fi

if [[ "$DRY_RUN" == "1" ]]; then
  log "预览模式：跳过权限修复和前端检查"
  echo "将执行：ssh ${REMOTE} \"${REMOTE_ENV} find '${REMOTE_SERVER_DIR}' '${REMOTE_PACKAGES_DIR}' -path '${REMOTE_PUBLIC_DIR}/.user.ini' -prune -o -exec chown -h www:www {} +\""
  echo "将检查：${REMOTE_ADMIN_DIR}/index.html、${REMOTE_ADMIN_DIR}/assets"
else
  if [[ "$FIX_PERMS" == "1" ]]; then
    log "修复 server 和 packages 文件归属"
    ssh "${SSH_OPTS[@]}" "$REMOTE" "${REMOTE_ENV} find '$REMOTE_SERVER_DIR' '$REMOTE_PACKAGES_DIR' -path '$REMOTE_PUBLIC_DIR/.user.ini' -prune -o -exec chown -h www:www {} +"
  fi

  log "检查 admin 同步结果"
  ssh "${SSH_OPTS[@]}" "$REMOTE" "${REMOTE_ENV} bash -s" <<EOF
    set -e
    test -f '$REMOTE_ADMIN_DIR/index.html'
    test -d '$REMOTE_ADMIN_DIR/assets'
    ls -ld '$REMOTE_ADMIN_DIR' '$REMOTE_ADMIN_DIR/index.html' '$REMOTE_ADMIN_DIR/assets'
EOF
fi

if [[ "$SYNC_DB" == "1" ]]; then
  if [[ "$DRY_RUN" == "1" ]]; then
    log "预览模式：跳过数据库同步"
    echo "本地数据库：${LOCAL_DB_USER}@${LOCAL_DB_HOST}:${LOCAL_DB_PORT}/${LOCAL_DB_NAME}"
    echo "服务器数据库：${REMOTE_DB_USER}@${REMOTE_DB_HOST}:${REMOTE_DB_PORT}/${REMOTE_DB_NAME}"
    echo "将先备份服务器数据库到：${REMOTE}:${REMOTE_BACKUP_DIR}/${REMOTE_DB_NAME}_YYYYmmdd_HHMMSS.sql.gz"
    echo "随后使用本地 mysqldump --add-drop-table 覆盖导入服务器数据库。"
  else
    BACKUP_FILE="$REMOTE_BACKUP_DIR/${REMOTE_DB_NAME}_$(date +%Y%m%d_%H%M%S).sql.gz"

    log "备份服务器数据库到 ${REMOTE}:${BACKUP_FILE}"
    ssh "${SSH_OPTS[@]}" "$REMOTE" "${REMOTE_ENV} bash -s" <<EOF
      set -e
      mkdir -p '$REMOTE_BACKUP_DIR'
      MYSQL_PWD='$REMOTE_DB_PASS' mysqldump \
        -h '$REMOTE_DB_HOST' \
        -P '$REMOTE_DB_PORT' \
        -u '$REMOTE_DB_USER' \
        --single-transaction \
        --no-tablespaces \
        --routines \
        --triggers \
        '$REMOTE_DB_NAME' | gzip > '$BACKUP_FILE'
EOF

    log "同步本地数据库 ${LOCAL_DB_NAME} 到服务器数据库 ${REMOTE_DB_NAME}"
    if ! MYSQL_PWD="$LOCAL_DB_PASS" mysqldump \
      -h "$LOCAL_DB_HOST" \
      -P "$LOCAL_DB_PORT" \
      -u "$LOCAL_DB_USER" \
      --single-transaction \
      --no-tablespaces \
      --routines \
      --triggers \
      --add-drop-table \
      "$LOCAL_DB_NAME" | ssh "${SSH_OPTS[@]}" "$REMOTE" "${REMOTE_ENV} MYSQL_PWD='$REMOTE_DB_PASS' mysql -h '$REMOTE_DB_HOST' -P '$REMOTE_DB_PORT' -u '$REMOTE_DB_USER' '$REMOTE_DB_NAME'"
    then
      echo "数据库同步失败，请检查上方 mysqldump/mysql 错误。远程备份文件：${BACKUP_FILE}" >&2
      exit 1
    fi
  fi
fi

if [[ "$RESTART_WEBMAN" == "1" ]]; then
  if [[ "$DRY_RUN" == "1" ]]; then
    log "预览模式：跳过远程重启"
    echo "将执行：ssh ${REMOTE} \"${REMOTE_ENV} OTEL_PHP_DISABLED_INSTRUMENTATIONS='${REMOTE_OTEL_DISABLED_INSTRUMENTATIONS}' bash -lc 'cd '${REMOTE_SERVER_DIR}' && php webman restart -d'\""
  else
    log "重启服务器 Webman"
    ssh "${SSH_OPTS[@]}" "$REMOTE" "${REMOTE_ENV} OTEL_PHP_DISABLED_INSTRUMENTATIONS='$REMOTE_OTEL_DISABLED_INSTRUMENTATIONS' bash -lc 'cd '$REMOTE_SERVER_DIR' && php webman restart -d'"
  fi
else
  log "跳过 Webman 重启"
fi

if [[ "$DRY_RUN" == "1" ]]; then
  log "预览完成，未实际同步。确认无误后执行：./deploy.sh"
else
  log "部署完成"
fi
