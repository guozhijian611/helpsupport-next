#!/usr/bin/env bash
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

set -euo pipefail

# 未显式覆盖时使用 Flutter 中国社区镜像，加速 pub get 与引擎下载。
export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"
export FLUTTER_STORAGE_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.flutter-io.cn}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_APP_DIR="${ROOT_DIR}/flutter_app"
API_CONFIG_FILE="${FLUTTER_APP_DIR}/lib/core/api/api_client.dart"
ANDROID_SDK_DIR="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-${HOME}/Library/Android/sdk}}"
ANDROID_EMULATOR_ID="${ANDROID_EMULATOR_ID:-HelpSupport_API36}"
AUTO_LAUNCH_ANDROID_EMULATOR="${AUTO_LAUNCH_ANDROID_EMULATOR:-1}"
ANDROID_EMULATOR_BOOT_TIMEOUT_SECONDS="${ANDROID_EMULATOR_BOOT_TIMEOUT_SECONDS:-180}"

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "$1 not found"
}

add_path_dir() {
  local dir="$1"
  [[ -d "${dir}" ]] || return 0
  case ":${PATH}:" in
    *":${dir}:"*) ;;
    *) PATH="${dir}:${PATH}" ;;
  esac
}

setup_android_sdk_path() {
  [[ -d "${ANDROID_SDK_DIR}" ]] || return

  export ANDROID_HOME="${ANDROID_SDK_DIR}"
  export ANDROID_SDK_ROOT="${ANDROID_SDK_DIR}"
  add_path_dir "${ANDROID_SDK_DIR}/emulator"
  add_path_dir "${ANDROID_SDK_DIR}/platform-tools"
  add_path_dir "${ANDROID_SDK_DIR}/cmdline-tools/latest/bin"
  export PATH
}

print_flutter_run_help() {
  cat <<'HELP'

Flutter 运行快捷键（应用启动成功后直接输入）：
  r  热重载，只刷新 Dart 代码
  R  热重启，重建 Dart 运行状态
  h  查看所有交互命令
  d  断开 flutter run，App 继续留在设备上运行
  c  清屏
  q  退出并结束设备上的 App
HELP
}

print_script_usage() {
  cat <<'HELP'
用法：
  ./run_app.sh [设备序号] [flutter run 参数...]
  ./run_app.sh -d <设备序号> [flutter run 参数...]
  ./run_app.sh --device <设备序号> [flutter run 参数...]
  ./run_app.sh --device-index <设备序号> [flutter run 参数...]

示例：
  ./run_app.sh 1
  ./run_app.sh -d 1
  ./run_app.sh 2 --flavor dev
HELP
}

parse_args() {
  SELECTED_DEVICE_INDEX=""
  FLUTTER_RUN_ARGS=()

  while (($# > 0)); do
    case "$1" in
      -h | --help)
        print_script_usage
        exit 0
        ;;
      -d | --device | --device-index)
        local option="$1"
        shift
        [[ $# -gt 0 ]] || fail "${option} 需要传入设备序号"
        [[ "$1" =~ ^[0-9]+$ ]] || fail "设备序号必须是数字"
        SELECTED_DEVICE_INDEX="$1"
        ;;
      --device=*)
        SELECTED_DEVICE_INDEX="${1#--device=}"
        [[ "${SELECTED_DEVICE_INDEX}" =~ ^[0-9]+$ ]] || fail "设备序号必须是数字"
        ;;
      --device-index=*)
        SELECTED_DEVICE_INDEX="${1#--device-index=}"
        [[ "${SELECTED_DEVICE_INDEX}" =~ ^[0-9]+$ ]] || fail "设备序号必须是数字"
        ;;
      *)
        if [[ -z "${SELECTED_DEVICE_INDEX}" && "$1" =~ ^[0-9]+$ ]]; then
          SELECTED_DEVICE_INDEX="$1"
        else
          FLUTTER_RUN_ARGS+=("$1")
        fi
        ;;
    esac
    shift
  done
}

android_device_connected() {
  command -v adb >/dev/null 2>&1 || return 1
  adb devices | awk '
    NR > 1 && $2 == "device" { found = 1 }
    END { exit found ? 0 : 1 }
  '
}

android_emulator_available() {
  flutter emulators | awk -v id="${ANDROID_EMULATOR_ID}" '
    $1 == id { found = 1 }
    END { exit found ? 0 : 1 }
  '
}

wait_for_android_device() {
  local deadline=$((SECONDS + ANDROID_EMULATOR_BOOT_TIMEOUT_SECONDS))
  while ((SECONDS < deadline)); do
    if android_device_connected; then
      return 0
    fi
    sleep 5
  done

  return 1
}

adb_device_ids() {
  command -v adb >/dev/null 2>&1 || return 0
  adb devices | awk 'NR > 1 && $2 == "device" { print $1 }'
}

first_android_emulator_serial() {
  adb_device_ids | awk '/^emulator-/ { print; exit }'
}

new_android_emulator_serial() {
  local before_file="$1"
  adb_device_ids | awk -v before_file="${before_file}" '
    BEGIN {
      while ((getline line < before_file) > 0) {
        before[line] = 1
      }
    }
    /^emulator-/ && !($1 in before) {
      print
      exit
    }
  '
}

launch_selected_android_emulator() {
  local emulator_id="$1"
  local before_file deadline serial

  command -v flutter >/dev/null 2>&1 || fail "flutter not found"
  command -v adb >/dev/null 2>&1 || fail "adb not found"

  before_file="$(mktemp -t helpsupport-adb-before.XXXXXX)"
  adb_device_ids >"${before_file}"

  printf '正在启动安卓模拟器：%s\n' "${emulator_id}" >&2
  if ! flutter emulators --launch "${emulator_id}" >/dev/null 2>&1; then
    rm -f "${before_file}"
    fail "安卓模拟器启动失败，请手动执行：flutter emulators --launch ${emulator_id}"
  fi

  deadline=$((SECONDS + ANDROID_EMULATOR_BOOT_TIMEOUT_SECONDS))
  while ((SECONDS < deadline)); do
    serial="$(new_android_emulator_serial "${before_file}")"
    if [[ -n "${serial}" ]]; then
      rm -f "${before_file}"
      printf '安卓模拟器已连接：%s\n' "${serial}" >&2
      printf '%s\n' "${serial}"
      return
    fi

    serial="$(first_android_emulator_serial)"
    if [[ -n "${serial}" ]]; then
      rm -f "${before_file}"
      printf '安卓模拟器已连接：%s\n' "${serial}" >&2
      printf '%s\n' "${serial}"
      return
    fi

    sleep 5
  done

  rm -f "${before_file}"
  fail "安卓模拟器启动超时，稍后可重新执行 ./run_app.sh"
}

launch_android_emulator_if_needed() {
  [[ "${AUTO_LAUNCH_ANDROID_EMULATOR}" == "1" ]] || return 0
  command -v flutter >/dev/null 2>&1 || return 0
  command -v adb >/dev/null 2>&1 || return 0
  android_device_connected && return 0

  if ! android_emulator_available; then
    printf '未找到安卓模拟器 %s，跳过自动启动。\n' "${ANDROID_EMULATOR_ID}" >&2
    return
  fi

  printf '未检测到已连接安卓设备，正在启动安卓模拟器：%s\n' "${ANDROID_EMULATOR_ID}" >&2
  flutter emulators --launch "${ANDROID_EMULATOR_ID}" >/dev/null 2>&1 || {
    printf '安卓模拟器启动命令失败，请手动执行：flutter emulators --launch %s\n' "${ANDROID_EMULATOR_ID}" >&2
    return
  }

  if wait_for_android_device; then
    printf '安卓模拟器已连接。\n' >&2
  else
    printf '安卓模拟器启动超时，稍后可重新执行 ./run_app.sh。\n' >&2
  fi
}

manual_device_input() {
  printf '无法自动生成设备序号，下面是 flutter devices 原始输出：\n' >&2
  flutter devices >&2
  printf '\n请输入要运行的设备 ID: ' >&2

  local device_id
  read -r device_id
  [[ -n "${device_id}" ]] || fail "设备 ID 不能为空"
  printf '%s\n' "${device_id}"
}

select_device() {
  local preferred_index="${1:-}"

  if ! command -v python3 >/dev/null 2>&1; then
    if [[ -n "${preferred_index}" ]]; then
      printf '当前环境无法自动解析设备序号，将改为手动输入设备 ID。\n' >&2
    fi
    manual_device_input
    return
  fi

  local devices_json json_file adb_file emulators_file devices_file
  if ! devices_json="$(flutter devices --machine 2>/dev/null)"; then
    if [[ -n "${preferred_index}" ]]; then
      printf '无法读取 Flutter 设备列表，将改为手动输入设备 ID。\n' >&2
    fi
    manual_device_input
    return
  fi

  json_file="$(mktemp -t helpsupport-flutter-devices-json.XXXXXX)"
  adb_file="$(mktemp -t helpsupport-adb-devices.XXXXXX)"
  emulators_file="$(mktemp -t helpsupport-flutter-emulators.XXXXXX)"
  devices_file="$(mktemp -t helpsupport-flutter-devices.XXXXXX)"
  printf '%s' "${devices_json}" >"${json_file}"
  if command -v adb >/dev/null 2>&1; then
    adb devices -l >"${adb_file}" 2>/dev/null || true
  fi
  flutter emulators >"${emulators_file}" 2>/dev/null || true

  if ! python3 - "${json_file}" "${adb_file}" "${emulators_file}" >"${devices_file}" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    devices = json.load(handle)

with open(sys.argv[2], "r", encoding="utf-8") as handle:
    adb_devices = handle.read().splitlines()

with open(sys.argv[3], "r", encoding="utf-8") as handle:
    emulators = handle.read().splitlines()

rows = []
row_by_id = {}

def add_row(device_id, name, platform, kind, source, launch_id=""):
    if not device_id:
        return

    current = row_by_id.get(device_id)
    if current:
        if source not in current["source"].split("+"):
            current["source"] = f'{current["source"]}+{source}'
        if not current["launch_id"] and launch_id:
            current["launch_id"] = launch_id
        return

    row = {
        "id": device_id,
        "name": name or device_id,
        "platform": platform or "",
        "kind": kind or "device",
        "source": source,
        "launch_id": launch_id,
    }
    rows.append(row)
    row_by_id[device_id] = row

for device in devices:
    if device.get("isSupported") is False:
        continue
    device_id = device.get("id") or ""
    name = device.get("name") or device.get("displayName") or device_id
    platform = device.get("targetPlatform") or device.get("platform") or ""
    kind = "emulator" if device.get("emulator") or device_id.startswith("emulator-") else "device"
    add_row(device_id, name, platform, kind, "flutter")

for line in adb_devices:
    stripped = line.strip()
    if not stripped or stripped.startswith("List of devices"):
        continue
    parts = stripped.split()
    if len(parts) < 2 or parts[1] != "device":
        continue

    device_id = parts[0]
    attrs = dict(part.split(":", 1) for part in parts[2:] if ":" in part)
    model = attrs.get("model") or attrs.get("product") or device_id
    kind = "adb-emulator" if device_id.startswith("emulator-") else "adb-device"
    add_row(device_id, model, "android", kind, "adb")

for line in emulators:
    if "•" not in line:
        continue
    parts = [part.strip() for part in line.split("•")]
    if len(parts) < 4:
        continue
    emulator_id, name, _manufacturer, platform = parts[:4]
    if not emulator_id or emulator_id == "Id" or platform != "android":
        continue
    add_row(emulator_id, name, platform, "launchable-emulator", "emulator", emulator_id)

for row in rows:
    print(
        "\t".join(
            [
                row["id"],
                row["name"],
                row["platform"],
                row["kind"],
                row["source"],
                row["launch_id"],
            ]
        )
    )
PY
  then
    rm -f "${json_file}" "${adb_file}" "${emulators_file}" "${devices_file}"
    manual_device_input
    return
  fi

  local count=0 line id name platform kind source launch_id
  local ids=() names=() platforms=() kinds=() sources=() launch_ids=()
  while IFS=$'\t' read -r id name platform kind source launch_id; do
    [[ -n "${id}" ]] || continue
    ids[count]="${id}"
    names[count]="${name}"
    platforms[count]="${platform}"
    kinds[count]="${kind}"
    sources[count]="${source}"
    launch_ids[count]="${launch_id}"
    count=$((count + 1))
  done <"${devices_file}"

  rm -f "${json_file}" "${adb_file}" "${emulators_file}" "${devices_file}"

  if [[ "${count}" -eq 0 ]]; then
    fail "未发现可运行的 Flutter 设备、ADB 设备或可启动安卓模拟器"
  fi

  printf '当前可用设备和模拟器：\n' >&2
  local index
  for ((index = 0; index < count; index++)); do
    printf '  %d) %s [%s, %s, source=%s] id=%s\n' \
      "$((index + 1))" \
      "${names[index]}" \
      "${platforms[index]}" \
      "${kinds[index]}" \
      "${sources[index]}" \
      "${ids[index]}" >&2
  done

  if [[ -n "${preferred_index}" ]]; then
    local preferred_number=$((10#${preferred_index}))
    if [[ "${preferred_number}" -ge 1 ]] && [[ "${preferred_number}" -le "${count}" ]]; then
      local selected_index=$((preferred_number - 1))
      if [[ -n "${launch_ids[selected_index]}" ]]; then
        launch_selected_android_emulator "${launch_ids[selected_index]}"
        return
      fi
      printf '%s\n' "${ids[selected_index]}"
      return
    fi

    fail "设备序号 ${preferred_index} 不在可选范围 1-${count} 内"
  fi

  local choice
  while true; do
    if [[ "${count}" -eq 1 ]]; then
      printf '请选择设备序号 [1]: ' >&2
    else
      printf '请选择设备序号 [1-%d]: ' "${count}" >&2
    fi
    read -r choice
    [[ -n "${choice}" ]] || choice=1

    if [[ "${choice}" =~ ^[0-9]+$ ]] &&
      [[ "${choice}" -ge 1 ]] &&
      [[ "${choice}" -le "${count}" ]]; then
      local selected_index=$((choice - 1))
      if [[ -n "${launch_ids[selected_index]}" ]]; then
        launch_selected_android_emulator "${launch_ids[selected_index]}"
        return
      fi
      printf '%s\n' "${ids[selected_index]}"
      return
    fi

    printf '无效选择，请重新输入。\n' >&2
  done
}

main() {
  parse_args "$@"

  setup_android_sdk_path
  require_command flutter
  [[ -d "${FLUTTER_APP_DIR}" ]] || fail "flutter_app directory not found"

  cd "${FLUTTER_APP_DIR}"
  launch_android_emulator_if_needed

  local device_id api_base_url
  device_id="$(select_device "${SELECTED_DEVICE_INDEX}")"
  api_base_url="$(sed -n "s/.*static const apiBaseUrl = \\([^;]*\\);.*/\\1/p" "${API_CONFIG_FILE}" | head -n 1)"
  if [[ "${api_base_url}" == *packagedApiBaseUrl* ]]; then
    api_base_url="$(sed -n "s/.*packagedApiBaseUrl = '\\([^']*\\)'.*/\\1/p" "${API_CONFIG_FILE}" | head -n 1)"
  elif [[ "${api_base_url}" == *localApiBaseUrl* ]]; then
    api_base_url="$(sed -n "s/.*localApiBaseUrl = '\\([^']*\\)'.*/\\1/p" "${API_CONFIG_FILE}" | head -n 1)"
  else
    api_base_url="$(sed -n "s/.*apiBaseUrl = '\\([^']*\\)'.*/\\1/p" "${API_CONFIG_FILE}" | head -n 1)"
  fi

  printf '使用设备: %s\n' "${device_id}"
  if [[ -n "${api_base_url}" ]]; then
    printf 'API Base URL: %s\n' "${api_base_url}"
  fi
  printf '如需改回本机联调，请把 %s 中的 apiBaseUrl 改成 localApiBaseUrl。\n' "${API_CONFIG_FILE}"
  print_flutter_run_help

  if ((${#FLUTTER_RUN_ARGS[@]} > 0)); then
    exec flutter run -d "${device_id}" "${FLUTTER_RUN_ARGS[@]}"
  fi

  exec flutter run -d "${device_id}"
}

main "$@"
