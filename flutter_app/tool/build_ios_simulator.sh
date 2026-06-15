#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DERIVED_DATA_PATH="${FLUTTER_APP_DIR}/build/ios_simulator_derived"
APP_PATH="${DERIVED_DATA_PATH}/Build/Products/Debug-iphonesimulator/Runner.app"
API_BASE_URL="${HELP_SUPPORT_API_BASE_URL:-http://10.0.0.6:8787}"
IOS_DEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET:-15.0}"

usage() {
  cat <<'USAGE'
Build the Flutter iOS simulator app, install it to a simulator, and launch it.

Usage:
  ./tool/build_ios_simulator.sh [extra xcodebuild args]

Environment:
  IOS_SIMULATOR_UDID       Target simulator UDID. Highest priority.
  IOS_SIMULATOR_NAME       Target simulator name, for example "iPhone 17".
  IOS_BUNDLE_ID            Bundle id override. Default is read from Runner.app.
  HELP_SUPPORT_API_BASE_URL API base URL. Default: http://10.0.0.6:8787
  HELP_SUPPORT_LLAMA_LIBRARY_PATH Optional dart-define override for llama runtime.
  HELP_SUPPORT_LLAMA_GPU_LAYERS Optional dart-define override for llama GPU layers.
  HELP_SUPPORT_LLAMA_IOS_RUNTIME_DIR Optional directory containing iOS llama dylibs.
  IOS_DEPLOYMENT_TARGET    iOS deployment target for generated Swift package. Default: 15.0
  REFRESH_IOS_SPM=1        Repair Swift Package cache and dependency resolution.
  PUB_GET=1                Force flutter pub get.
  CLEAN=1                  Run flutter clean before building.

Examples:
  ./tool/build_ios_simulator.sh
  IOS_SIMULATOR_NAME="iPhone 17" ./tool/build_ios_simulator.sh
  HELP_SUPPORT_API_BASE_URL=http://127.0.0.1:8787 ./tool/build_ios_simulator.sh
USAGE
}

log() {
  printf '==> %s\n' "$*"
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "$1 not found"
}

udid_from_booted_simulator() {
  xcrun simctl list devices booted | awk '
    /Booted/ {
      if (match($0, /\([0-9A-Fa-f-]{36}\)/)) {
        print substr($0, RSTART + 1, RLENGTH - 2)
        exit
      }
    }
  '
}

udid_by_simulator_name() {
  local name="$1"
  xcrun simctl list devices available | awk -v name="$name" '
    index($0, name " (") > 0 {
      if (match($0, /\([0-9A-Fa-f-]{36}\)/)) {
        print substr($0, RSTART + 1, RLENGTH - 2)
        exit
      }
    }
  '
}

first_available_iphone_udid() {
  xcrun simctl list devices available | awk '
    /^-- / { next }
    /iPhone/ && /(Booted|Shutdown)/ {
      if (match($0, /\([0-9A-Fa-f-]{36}\)/)) {
        print substr($0, RSTART + 1, RLENGTH - 2)
        exit
      }
    }
  '
}

simulator_label() {
  local udid="$1"
  xcrun simctl list devices | awk -v udid="$udid" '
    index($0, udid) > 0 {
      sub(/^[[:space:]]+/, "", $0)
      print
      exit
    }
  '
}

select_simulator_udid() {
  if [[ -n "${IOS_SIMULATOR_UDID:-}" ]]; then
    printf '%s\n' "${IOS_SIMULATOR_UDID}"
    return
  fi

  if [[ -n "${IOS_SIMULATOR_NAME:-}" ]]; then
    udid_by_simulator_name "${IOS_SIMULATOR_NAME}"
    return
  fi

  local booted_udid
  booted_udid="$(udid_from_booted_simulator)"
  if [[ -n "${booted_udid}" ]]; then
    printf '%s\n' "${booted_udid}"
    return
  fi

  first_available_iphone_udid
}

is_simulator_booted() {
  local udid="$1"
  xcrun simctl list devices booted | grep -q "${udid}"
}

boot_simulator_if_needed() {
  local udid="$1"
  if is_simulator_booted "${udid}"; then
    return
  fi

  log "Booting simulator: ${udid}"
  xcrun simctl boot "${udid}" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "${udid}" -b
}

read_bundle_id() {
  if [[ -n "${IOS_BUNDLE_ID:-}" ]]; then
    printf '%s\n' "${IOS_BUNDLE_ID}"
    return
  fi

  /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "${APP_PATH}/Info.plist"
}

patch_generated_plugin_package() {
  local package_file="ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift"
  [[ -f "${package_file}" ]] || return

  if grep -q '.iOS("13.0")' "${package_file}"; then
    log "Patching generated plugin package deployment target to iOS ${IOS_DEPLOYMENT_TARGET}"
    perl -0pi -e "s/\\.iOS\\(\"13\\.0\"\\)/.iOS\\(\"${IOS_DEPLOYMENT_TARGET}\"\\)/g" "${package_file}"
  fi
}

clear_ios_spm_cache() {
  if [[ "${REFRESH_IOS_SPM:-0}" != "1" ]]; then
    return
  fi

  local cache_dir="${HOME}/Library/Caches/org.swift.swiftpm/repositories"
  local resolved_file="ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved"
  [[ -d "${cache_dir}" && -f "${resolved_file}" ]] || return

  log "Clearing Swift Package repository cache for this project"
  while IFS= read -r identity; do
    [[ -n "${identity}" ]] || continue
    find "${cache_dir}" -maxdepth 1 -type d -name "${identity}-*" -exec rm -rf {} +
  done < <(awk -F'"' '/"identity"/ { print $4 }' "${resolved_file}")
}

dart_define_value() {
  local defines=(
    "HELP_SUPPORT_API_BASE_URL=${API_BASE_URL}"
  )
  if [[ -n "${HELP_SUPPORT_LLAMA_LIBRARY_PATH:-}" ]]; then
    defines+=("HELP_SUPPORT_LLAMA_LIBRARY_PATH=${HELP_SUPPORT_LLAMA_LIBRARY_PATH}")
  fi
  if [[ -n "${HELP_SUPPORT_LLAMA_GPU_LAYERS:-}" ]]; then
    defines+=("HELP_SUPPORT_LLAMA_GPU_LAYERS=${HELP_SUPPORT_LLAMA_GPU_LAYERS}")
  fi

  local encoded=() define
  for define in "${defines[@]}"; do
    encoded+=("$(printf '%s' "${define}" | base64 | tr -d '\n')")
  done
  local IFS=,
  printf '%s' "${encoded[*]}"
}

run_pub_get_if_needed() {
  local package_config=".dart_tool/package_config.json"

  if [[ "${PUB_GET:-0}" == "1" ||
    ! -f "${package_config}" ||
    pubspec.yaml -nt "${package_config}" ||
    pubspec.lock -nt "${package_config}" ]]; then
    log "Running flutter pub get"
    flutter pub get
    return
  fi

  log "Skipping flutter pub get"
}

resolve_ios_packages() {
  local simulator_udid="$1"
  if [[ "${REFRESH_IOS_SPM:-0}" != "1" ]]; then
    return
  fi

  require_command xcodebuild
  log "Resolving iOS Swift Package dependencies"
  xcodebuild \
    -resolvePackageDependencies \
    -workspace ios/Runner.xcworkspace \
    -scheme Runner \
    -sdk iphonesimulator \
    -destination "platform=iOS Simulator,id=${simulator_udid}" \
    -disablePackageRepositoryCache
}

verify_ios_llama_runtime() {
  local runtime_path="${APP_PATH}/Frameworks/libllama.dylib"
  [[ -f "${runtime_path}" ]] ||
    fail "iOS llama runtime not found in app bundle: ${runtime_path}"
  log "iOS llama runtime bundled: ${runtime_path}"
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  require_command flutter
  require_command xcrun
  require_command xcodebuild
  require_command open

  cd "${FLUTTER_APP_DIR}"

  local simulator_udid simulator_info bundle_id
  simulator_udid="$(select_simulator_udid)"
  [[ -n "${simulator_udid}" ]] || fail "No available iOS simulator found"

  simulator_info="$(simulator_label "${simulator_udid}")"
  log "Target simulator: ${simulator_info:-${simulator_udid}}"
  boot_simulator_if_needed "${simulator_udid}"
  open -a Simulator --args -CurrentDeviceUDID "${simulator_udid}" >/dev/null 2>&1 || true

  if [[ "${CLEAN:-0}" == "1" ]]; then
    log "Running flutter clean"
    flutter clean
  fi

  run_pub_get_if_needed
  patch_generated_plugin_package
  clear_ios_spm_cache
  resolve_ios_packages "${simulator_udid}"
  local xcodebuild_args=(
    -quiet
    -workspace ios/Runner.xcworkspace
    -scheme Runner
    -configuration Debug
    -sdk iphonesimulator
    -destination "platform=iOS Simulator,id=${simulator_udid}"
    -derivedDataPath "${DERIVED_DATA_PATH}"
  )
  if [[ "${REFRESH_IOS_SPM:-0}" == "1" ]]; then
    xcodebuild_args+=(-disablePackageRepositoryCache)
  fi
  xcodebuild_args+=(ONLY_ACTIVE_ARCH=YES "$@" build)

  log "Building iOS simulator app with xcodebuild"
  DART_DEFINES="$(dart_define_value)" xcodebuild "${xcodebuild_args[@]}"

  [[ -d "${APP_PATH}" ]] || fail "Build output not found: ${APP_PATH}"
  verify_ios_llama_runtime
  bundle_id="$(read_bundle_id)"
  [[ -n "${bundle_id}" ]] || fail "Unable to read bundle id from ${APP_PATH}/Info.plist"

  log "Installing ${APP_PATH}"
  xcrun simctl install "${simulator_udid}" "${APP_PATH}"

  log "Launching ${bundle_id}"
  xcrun simctl terminate "${simulator_udid}" "${bundle_id}" >/dev/null 2>&1 || true
  xcrun simctl launch "${simulator_udid}" "${bundle_id}"

  log "Done"
}

main "$@"
