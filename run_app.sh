#!/usr/bin/env bash
set -euo pipefail

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
  [[ -d "${dir}" ]] || return
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

launch_android_emulator_if_needed() {
  [[ "${AUTO_LAUNCH_ANDROID_EMULATOR}" == "1" ]] || return
  command -v flutter >/dev/null 2>&1 || return
  command -v adb >/dev/null 2>&1 || return
  android_device_connected && return

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
  if ! command -v python3 >/dev/null 2>&1; then
    manual_device_input
    return
  fi

  local devices_json json_file devices_file
  if ! devices_json="$(flutter devices --machine 2>/dev/null)"; then
    manual_device_input
    return
  fi

  json_file="$(mktemp -t helpsupport-flutter-devices-json.XXXXXX)"
  devices_file="$(mktemp -t helpsupport-flutter-devices.XXXXXX)"
  printf '%s' "${devices_json}" >"${json_file}"

  if ! python3 - "${json_file}" >"${devices_file}" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    devices = json.load(handle)

for device in devices:
    if device.get("isSupported") is False:
        continue
    device_id = device.get("id") or ""
    name = device.get("name") or device.get("displayName") or device_id
    platform = device.get("targetPlatform") or device.get("platform") or ""
    simulator = "simulator" if device.get("emulator") else "device"
    if device_id:
        print(f"{device_id}\t{name}\t{platform}\t{simulator}")
PY
  then
    rm -f "${json_file}" "${devices_file}"
    manual_device_input
    return
  fi

  local count=0 line id name platform simulator
  local ids=() names=() platforms=() simulators=()
  while IFS=$'\t' read -r id name platform simulator; do
    [[ -n "${id}" ]] || continue
    ids[count]="${id}"
    names[count]="${name}"
    platforms[count]="${platform}"
    simulators[count]="${simulator}"
    count=$((count + 1))
  done <"${devices_file}"

  rm -f "${json_file}" "${devices_file}"

  if [[ "${count}" -eq 0 ]]; then
    fail "未发现可运行的 Flutter 设备，请先连接真机或启动模拟器"
  fi

  printf '当前可用 Flutter 设备：\n' >&2
  local index
  for ((index = 0; index < count; index++)); do
    printf '  %d) %s [%s, %s] id=%s\n' \
      "$((index + 1))" \
      "${names[index]}" \
      "${platforms[index]}" \
      "${simulators[index]}" \
      "${ids[index]}" >&2
  done

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
      printf '%s\n' "${ids[selected_index]}"
      return
    fi

    printf '无效选择，请重新输入。\n' >&2
  done
}

main() {
  setup_android_sdk_path
  require_command flutter
  [[ -d "${FLUTTER_APP_DIR}" ]] || fail "flutter_app directory not found"

  cd "${FLUTTER_APP_DIR}"
  launch_android_emulator_if_needed

  local device_id api_base_url
  device_id="$(select_device)"
  api_base_url="$(sed -n "s/.*apiBaseUrl = '\\([^']*\\)'.*/\\1/p" "${API_CONFIG_FILE}" | head -n 1)"

  printf '使用设备: %s\n' "${device_id}"
  if [[ -n "${api_base_url}" ]]; then
    printf 'API Base URL: %s\n' "${api_base_url}"
  fi
  printf '如需修改 API 地址，请编辑 %s。\n' "${API_CONFIG_FILE}"
  print_flutter_run_help

  exec flutter run -d "${device_id}" "$@"
}

main "$@"
